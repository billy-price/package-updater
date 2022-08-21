local args = {...}

if #args ~= 2 then

	print("Incorrect number of arguments. Supply place_id and output file path")
	print("Usage: rbx-download place_id <output>")
	return
end

local placeId, output = table.unpack(args)

print("Downloading place "..placeId)
local game = remodel.readPlaceAsset(placeId)

print("Writing place file "..output)
remodel.writePlaceFile(game, output)