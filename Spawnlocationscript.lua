-- Place this Script inside each spawn plate (e.g. OverWorld or Volcano spawn plate)
local Players = game:GetService("Players")
local plate = script.Parent

-- Set this value to the string to store for each plate
-- For example: "OverWorld" for the main spawn, "Volcano" for the volcano world
local PLATE_NAME = plate.Name == "VolcanoSpawnPlate" and "Volcano" or "OverWorld"

plate.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		-- Set an attribute on the player to remember the last spawn plate they touched
		player:SetAttribute("LastTouchedSpawnPlate", PLATE_NAME)
		print(player.Name .. " touched spawn plate: " .. PLATE_NAME)
	end
end)
