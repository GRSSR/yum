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
	f = io.open(location, "w")
	f:write(file)
	f:close()
end

local function help()
	print("usage yum install|list")
end

local function installHelp()
	print("usage yum install [package]")
	error()
end

local function parsePackage(response)
	files = {}
	for line in response.body:gmatch("[^\r\n]+") do
		local parsed = redString.split(line)
		files[#files+1] = {}
		files[#files].name = parsed[1]
		files[#files].installLocation = parsed[2]
		files[#files].has = parsed[3] 
	end
	return files
end

sovietProtocol.init(PROTOCOL_CHANNEL, LISTEN_CHANNEL)

if not sovietProtocol.hello(PROTOCOL_CHANNEL) then
	print("Yum server is asleep :(")
	error()
end

if method == "install" then
	if not package then installHelp() end
	if file then
		print("Getting file "..file)
	end
	sovietProtocol.send(PROTOCOL_CHANNEL, LISTEN_CHANNEL, "install", package, file)

	replyChannel, response = sovietProtocol.listen()
	if response.method == "file" then
		installFile(response.id, response.body)
	elseif response.method == "package_list" then
		local file = {}
		for line in response.body:gmatch("[^\r\n]+") do
			local parsed = redString.split(line)
			file.name = parsed[1]
			file.installLocation = parsed[2]
			file.has = parsed[3] 
			sovietProtocol.send(PROTOCOL_CHANNEL, LISTEN_CHANNEL, "install", package, file.name)
			replyChannel, response = sovietProtocol.listen()

			if response.method == "file" then
				installFile(response.id, response.body)
			end
		end
	end
elseif method ==  "list" then
	sovietProtocol.send(PROTOCOL_CHANNEL, LISTEN_CHANNEL, "list", package)
	local reply, response = sovietProtocol.listen()
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
