local function extractVersion(package)

	local ver = "unknown_version" do

		local versionStringValue = package:FindFirstChild("version")

		if versionStringValue and versionStringValue.ClassName == "StringValue" then

			ver = remodel.getRawProperty(versionStringValue, "Value")
		end
	end

	return ver
end

local function packageDescription(package)
	return ("%s@%s (%s)"):format(package.Name, extractVersion(package), package.ClassName)
end

return function(package, destination, askBeforeReplacing)

	print(("[%s]"):format(package.Name))

	local changeLog = ""

	local existingVersions = {}

	for _, instance in ipairs(destination:GetChildren()) do
		if instance.Name == package.Name then
			table.insert(existingVersions, instance)
		end
	end

	if #existingVersions >= 1 then

		print("Found existing versions in "..destination.Name)

		for _, instance in ipairs(existingVersions) do
			print("  "..packageDescription(instance))
		end

		if askBeforeReplacing then

			local answer
			local answerMap = { [""] = "y", y = "y", yes = "y", no = "n", n = "n" }

			repeat
				io.write(
					("Replace all %d versions with %s (Y/n)? "):format(#existingVersions, packageDescription(package))
				)
				io.flush()

				answer = answerMap[io.read("*line"):gsub("%s+", ""):lower()]

			until answer

			if answer == "n" then
				return nil
			end
		end

	end

	print(("Removing %d existing versions"):format(#existingVersions))

	for _, instance in ipairs(existingVersions) do
		instance.Parent = nil
		changeLog = changeLog..("Removed %s from %s\n"):format(packageDescription(instance), destination.Name)
	end

	print(("Writing %s to %s"):format(packageDescription(package), destination.Name))

	package.Parent = destination
	changeLog = changeLog..("Added %s to %s\n"):format(packageDescription(package), destination.Name)

	return changeLog
end