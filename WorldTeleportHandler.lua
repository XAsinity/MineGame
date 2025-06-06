local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local teleportEvent = ReplicatedStorage:WaitForChild("TeleportToWorldEvent")

local spawnMap = {
	["Volcano"] = "VolcanoSpawnLocation",
	["Overworld"] = "SpawnLocation", -- Standardize to "Overworld" to match UI/client usage
	["Original"] = "SpawnLocation"   -- Support legacy calls
}

teleportEvent.OnServerEvent:Connect(function(player, worldName)
	-- Accept both "Overworld" and "Original" for spawn
	if worldName == "Original" then
		worldName = "Overworld"
	end

	local spawnName = spawnMap[worldName]
	if not spawnName then
		warn("Unknown worldName: " .. tostring(worldName))
		return
	end
	local spawnLocation = Workspace:FindFirstChild(spawnName)
	if spawnLocation and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		player.Character.HumanoidRootPart.CFrame = spawnLocation.CFrame
		-- Set the player's LastTouchedSpawnPlate attribute for correct respawn/reset behavior
		if worldName == "Volcano" then
			player:SetAttribute("LastTouchedSpawnPlate", "Volcano")
		else
			player:SetAttribute("LastTouchedSpawnPlate", "OverWorld")
		end
	else
		warn("Teleport failed: Missing spawn or character.")
	end
end)