local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local button = script.Parent

-- Assumes your world spawn locations are named "SpawnLocation" (OverWorld) and "VolcanoSpawnLocation"
local function getSpawnLocationByPlate(plate)
	if plate == "Volcano" then
		return Workspace:FindFirstChild("VolcanoSpawnLocation")
	else
		return Workspace:FindFirstChild("SpawnLocation")
	end
end

button.MouseButton1Click:Connect(function()
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	-- Read the last touched plate from the player's attribute
	local plate = player:GetAttribute("LastTouchedSpawnPlate")
	local spawnLocation = getSpawnLocationByPlate(plate)

	if spawnLocation then
		humanoidRootPart.CFrame = spawnLocation.CFrame + Vector3.new(0, 3, 0) -- Offset to prevent clipping into the ground
	else
		-- Fallback: always spawn in OverWorld
		local fallback = Workspace:FindFirstChild("SpawnLocation")
		if fallback then
			humanoidRootPart.CFrame = fallback.CFrame + Vector3.new(0, 3, 0)
		end
	end
end)