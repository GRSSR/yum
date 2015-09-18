os.loadAPI('/.sys/yggdrasil/yggdrasil')
os.loadAPI('/.sys/red_string')

YUM_ERRORS = {
	NO_ERROR = 0,
	PACKAGE_NOT_EXISTS = 1
}

if not yggdrasil.namespace_exists('yum') then
	yggdrasil.namespace_create('yum')
end

local i_yum = yggdrasil.namespace_open('yum')

local args = {...}

local yum  = nil

local method = args[1]
local package = args[2]
local sources = {
	'GRSSR'}

local Package = {}

local function Package:new(package_name)
	local obj = {
		name = package_name,
		version = nil,
		dependancies = {},
		files = {},
		base_url = nil
	}
	setmetatable(obj, self)
	self.__index = self
	obj.base_url = "https://raw.githubusercontent.com/GRSSR/".. package_name .."/master/"
	return obj
end



function Package:get_dependancies()
	for _, dependancy in pairs(self.dependancies) do
		local dependancy_pkg = Package:new(dependancy)
		dependancy_pkg:install()
	end
end

local function Package:retrieve_index()
	local index = http.get(self.base_url .. "index")
	if a == nil then
		return YUM_ERRORS.PACKAGE_NOT_EXISTS
	end

	local index_table = textutils.unserialize(index:readAll())
	self.dependancies = index_table.dependancies
	self.files = index_table.files
	self.version = index_table.version

	return YUM_ERRORS.NO_ERROR
end

function Package:install()
	-- get our index file
	err = self:retrieve_index()
	if err == YUM_ERRORS.PACKAGE_NOT_EXISTS then 
		return err
	end

	-- recursively deal with dependancies
	self:get_dependancies()

	for _, file_info in pairs(self.files) do
		print("getting ".. file_name)
		local file = http.get(self.base_url .. file.repo_location)
		local local_destination = io.open(file.install_location, 'w')
		local_destination:write(file:readAll())
		local_destination:close()
	end

end

function Package:update()
end

function Package:uninstall()
end

local function get_package_info(package)
end


local function help()
	print("usage yum install|list|replicate")
	error()
end

local function installHelp()
	print("usage yum install [package]")
	error()
end

if method == "install" then
	if not package then installHelp() end
	local pkg = Package:new(package)
	err = pkg:install()
	if err then
		print("oops")
	end

elseif method ==  "list" then
	print("NYI")
else
	help()
end
