print("Bootstrapping yum...")

YUM_ERRORS = {
	NO_ERROR = 0,
	PACKAGE_NOT_EXISTS = 1
}

local Package = {}

function Package:new(package_name)
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

function Package:retrieve_index()
	local index = http.get(self.base_url .. "index")
	print("getting index at ".. self.base_url .. "index")
	if index == nil then
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
		print("getting ".. file_info.install_location)
		local file = http.get(self.base_url .. file_info.repo_location)
		local local_destination = io.open(file_info.install_location, 'w')
		local_destination:write(file:readAll())
		local_destination:close()
	end

end

local pkg = Package:new("yum")
local err = pkg:install()
if err then
	print("oops")
end

shell.run("/.sys/yum/yum", "install", "yum")
