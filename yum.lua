PROTOCOL_CHANNEL = 137
LISTEN_CHANNEL = os.getComputerID()

os.loadAPI("api/redString")
os.loadAPI("api/sovietProtocol")

sovietProtocol.setDebugLevel(0)
args = {...}

method = args[1]
package = args[2]
file = args[3]

local function installFile(location, file)
	print("installing "..location)
	local f = io.open(location, "w")
	f:write(file)
	f:close()
end

local function help()
	print("usage yum install|list")
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

local yum  = nil
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
	if file then
		print("Getting file "..file)
	end
	yum:send("install", package, file)

	replyChannel, response = yum:listen()
	if response.method == "file" then
		installFile(response.id, response.body)
	elseif response.method == "package_list" then
		local file = {}
		for line in response.body:gmatch("[^\r\n]+") do
			local parsed = redString.split(line)
			if parsed[1] == "depends:" then
				file.name = parsed[3]
				file.package = parsed[2]
			else
				file.name = parsed[1]
				file.installLocation = parsed[2]
				file.hash = parsed[3]
				file.package = package
			end
			yum:send("install", file.package, file.name)
			replyChannel, response = yum:listen()

			if response.method == "file" then
				installFile(response.id, response.body)
			end
		end
	end
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
else
	help()
end
