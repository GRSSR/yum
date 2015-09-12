PROTOCOL_CHANNEL = 137
LISTEN_CHANNEL = os.getComputerID()
os.loadAPI("api/redString")
os.loadAPI("api/sovietProtocol")
os.loadAPI('/.sys/yggdrasil/yggdrasil')

if not yggdrasil.namespace_exists('yum') then
	yggdrasil.namespace_create('yum')
end

local i_yum = yggdrasil.namespace_open('yum')

sovietProtocol.setDebugLevel(0)
local args = {...}

local yum  = nil

local method = args[1]
local package = args[2]
local file = args[3]

local function installFile(location, file)
	print("installing "..location)
	local f = io.open(location, "w")
	f:write(file)
	f:close()
end

local function install_package(name)
	print('installing '..name)
	local file = {}
	yum:send("install", name)
	replyChannel, response = yum:listen()
	if response.method == "package_list" then
		for line in response.body:gmatch("[^\r\n]+") do
			local parsed = redString.split(line)
			if parsed[1] == "package" then
				install_package(parsed[2])
			elseif parsed[1] == "alias" then
				if NONIX then
					print('Setting up alias '..parsed[2])
					nonix.register_alias(parsed[2], parsed[3])
				end
			else
				file.name = parsed[1]
				file.installLocation = parsed[2]
				file.hash = parsed[3]
				file.package = name
				yum:send("install", file.package, file.name)
				replyChannel, response = yum:listen()
				if response.method == "file" then
					installFile(response.id, response.body)
				end
			end
		end
	else
		print('not a package')
		error()
	end
end

local function help()
	print("usage yum install|list|replicate")
	error()
end

local function installHelp()
	print("usage yum install [package]")
	error()
end

local function parsePackage(response)
	local files = {}
	for line in response.body:gmatch("[^\r\n]+") do
		local parsed = redString.split(line)
		files[#files+1] = {}
		files[#files].name = parsed[1]
		files[#files].installLocation = parsed[2]
		files[#files].has = parsed[3] 
	end
	return files
end


for side, modem in pairs(sovietProtocol.findModems()) do 
	local possible = sovietProtocol.Protocol:new("yum", PROTOCOL_CHANNEL, LISTEN_CHANNEL, side)
	if possible:hello() then
		yum = possible
		break;
	else
		possible:tearDown()
	end
end

if not yum:hello() then
	print("Yum server is asleep :(")
	error()
end

if method == "install" then
	if not package then installHelp() end
	install_package(package)

elseif method ==  "list" then
	yum:send("list", package)
	local reply, response = yum:listen()
	local fileList = parsePackage(response)

	if package then
		print("files in package "..package..":")
	else
		print("Packages available: ")
	end
	for i, file in pairs(fileList) do
		print (file.name)
	end
elseif method == "replicate" then
	yum:send("replicate", "list")
	local replyChannel, response = yum:listen()
	if response.method == "file_list" then
		print(response.body)
		for fileName in response.body:gmatch("[^\r\n]+") do
			yum:send("replicate", fileName)
			local reply, response = yum:listen()
			installFile(response.id, response.body)
		end
	end
else
	help()
end
