--[[
	For updating packages in a place file.
	Supply place file and package names matching config.lua keys.
	Usage: update <place_file> [<package_name>, ...]
--]]

local updatePackage = require "update-package"

local args = {...}

if #args < 1 then

	print("Incorrect number of arguments. Supply place file and package names matching config.lua keys")
	print("Usage: remodel run update <place_file> [<package_name>, ...]")
	return
end

if os.rename("config.lua", "config.lua") == nil then
	print("Creating ./config.lua - please configure.")

	local file = io.open("config.lua", "w")
	file:write(
[[local PackageProjectFiles = {
	-- e.g. metaboard = /path/to/metaboard/release.project.json
}

local getSSS = function(game)
	return game:GetService("ServerScriptService")
end

local getChatModules = function(game)
	local Chat = game:GetService("Chat")
	local ChatModules = Chat:FindFirstChild("ChatModules")

	if not ChatModules then

		ChatModules = Instance.new("Folder")
		ChatModules.Name = "ChatModules"

		local InsertDefaultModules = Instance.new("BoolValue")
		InsertDefaultModules.Name = "InsertDefaultModules"
		remodel.setRawProperty(InsertDefaultModules, "Value", "Bool", true)

		InsertDefaultModules.Parent = ChatModules
		ChatModules.Parent = Chat
	end

	return ChatModules
end

local PackageDestination = {
	-- -- examples (keys must match PackageProjectFiles)
	-- metaboard = getSSS,
	-- metaportal = getSSS,
	-- admin = getChatModules,
}

local PlaceIds = {
	-- Key does not need to match actual published name of place
	-- e.g. TRS = "123456789",
}

return {
	PackageProjectFiles = PackageProjectFiles,
	PackageDestination = PackageDestination,
	PlaceIds = PlaceIds
}
]])
	file:close()
	return
end

local config = require "config"

local placeFilePath = args[1]

print("Reading place file")
local game = remodel.readPlaceFile(placeFilePath)

local packagePaths = {select(2, ...)}

for _, path in ipairs(packagePaths) do

	local package = remodel.readModelFile(path)[1]

	assert(config.PackageProjectFiles[package.Name], package.Name.." is not a recognised key in config.PackageProjectFiles")

	local destination = config.PackageDestination[package.Name](game)

	updatePackage(package, destination, true)
end


print("Writing place file")
remodel.writePlaceFile(game, placeFilePath)