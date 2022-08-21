local updatePackage = require "update-package"

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

local args = {...}

if #args >=2 or (#args == 1 and args[1] ~= "no_prompt") then

	print("Incorrect usage. Please run one of the following")
	print("remodel run fullUpdate.lua")
	print("remodel run fullUpdate.lua no_prompt")
	return
end

local noPrompt = args[1] == "no_prompt"

if os.getenv("REMODEL_AUTH") == nil then
	print("Authentication required for REMODEL - please set REMODEL_AUTH environment variable")
	print("See https://github.com/rojo-rbx/remodel#authentication")
end

local function execute(command)
	print("> " ..  command)
	local success, exitCode = os.execute(command)
	if not success then
		os.exit(exitCode)
	end
end


if not next(config.PackageProjectFiles) then
	print("No packages to build - configure config.lua (see PackageProjectFiles)")
end

local packages = {}

for packageName, projectFile in pairs(config.PackageProjectFiles) do

	local packageFileName = packageName..".rbxm"
	execute(
		("rojo build -o \"%s\" \"%s\"")
		:format(packageFileName, projectFile)
	)

	packages[packageName] = remodel.readModelFile(packageFileName)[1]
end

if not next(config.PlaceIds) then
	print("No placeIds to download - configure config.lua (see PlaceIds)")
end

for placeName, placeId in pairs(config.PlaceIds) do

	print(string.rep("-", 80))
	print(placeName)
	print(string.rep("-", 80))

	print("Downloading placeId "..placeId)
	local game = remodel.readPlaceAsset(placeId)

	local packageChangeLogs = {}

	for packageName, package in pairs(packages) do

		local destination = config.PackageDestination[packageName](game)

		packageChangeLogs[packageName] = updatePackage(package, destination, not noPrompt)
	end

	if next(packageChangeLogs) then

		local timeStamp = os.date("!%m/%d/%Y %I:%M:%S %p")

		local changeLog = "Update at "..timeStamp.."\n"

		for packageName, packageChangeLog in pairs(packageChangeLogs) do
			changeLog = changeLog..(("[%s]\n%s\n"):format(packageName, packageChangeLog))
		end

		local changeLogScript = game:GetService("ServerStorage"):FindFirstChild("PackageUpdateChangeLog")
		if not changeLogScript then
			changeLogScript = Instance.new("Script")
			changeLogScript.Name = "PackageUpdateChangeLog"
			changeLogScript.Parent = game:GetService("ServerStorage")
		end

		remodel.setRawProperty(changeLogScript, "Source", "String", "--[[\nTHIS SCRIPT WILL BE REPLACED EVERY PACKAGE UPDATE\n\n"..changeLog.."]]--")

		print("Publishing updated place to "..placeId, "(timestamp: "..timeStamp..")")
		remodel.writeExistingPlaceAsset(game, placeId)
		print(("Version History: https://www.roblox.com/places/%s/update#"):format(placeId))
	else
		print("No changes made to "..placeName..". Not publishing.")
	end
end