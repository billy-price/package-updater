local args = {...}

if #args ~= 2 then

	print("Incorrect number of arguments. Supply place file and placeId")
	print("Usage: rbx-upload <place_file> place_id")
	return
end

local placeFilePath, placeId = table.unpack(args)

print("Reading place file")
local game = remodel.readPlaceFile(placeFilePath)

print("Uploading place to "..placeId)
remodel.writeExistingPlaceAsset(game, placeId)