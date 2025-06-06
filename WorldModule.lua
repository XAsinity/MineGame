-- Place in ServerScriptService as a ModuleScript named "WorldModule"
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldModule = {}

-- Define world properties here for easy editing/expansion
WorldModule.Worlds = {
	Overworld = {
		Name = "Overworld",
		Cost = 0,
		DataKey = "OverworldUnlocked", -- Always true for everyone
		SpawnName = "SpawnLocation",    -- Name of the spawn part
		PlateAttribute = "OverWorld"
	},
	Volcano = {
		Name = "Volcano",
		Cost = 50000,
		DataKey = "VolcanoUnlocked",
		SpawnName = "VolcanoSpawnLocation",
		PlateAttribute = "Volcano"
	}
}

-- Utility: Get or create a player's Data folder and world unlocks
function WorldModule.GetOrCreateWorldData(player)
	local dataFolder = player:FindFirstChild("Data")
	if not dataFolder then
		dataFolder = Instance.new("Folder")
		dataFolder.Name = "Data"
		dataFolder.Parent = player
	end

	-- Ensure world unlock boolvalues exist
	for _, world in pairs(WorldModule.Worlds) do
		local key = world.DataKey
		local unlock = dataFolder:FindFirstChild(key)
		if not unlock then
			unlock = Instance.new("BoolValue")
			unlock.Name = key
			unlock.Value = world.Cost == 0 -- Only overworld should default to unlocked
			unlock.Parent = dataFolder
		end
	end

	return dataFolder
end

-- Check if a world is unlocked
function WorldModule.IsWorldUnlocked(player, worldKey)
	local dataFolder = WorldModule.GetOrCreateWorldData(player)
	local world = WorldModule.Worlds[worldKey]
	if not world then return false end
	local unlock = dataFolder:FindFirstChild(world.DataKey)
	return unlock and unlock.Value
end

-- Try to unlock a world (returns true/false and error/message)
function WorldModule.TryUnlockWorld(player, worldKey)
	local world = WorldModule.Worlds[worldKey]
	if not world then
		return false, "World does not exist."
	end
	if world.Cost == 0 then
		return false, "This world does not require unlocking."
	end
	local dataFolder = WorldModule.GetOrCreateWorldData(player)
	local unlock = dataFolder:FindFirstChild(world.DataKey)
	if unlock and unlock.Value then
		return false, "World already unlocked."
	end

	-- Check coin balance
	local coinsObj = dataFolder:FindFirstChild("Coins")
	if not coinsObj or coinsObj.Value < world.Cost then
		return false, "Not enough coins to unlock this world."
	end

	-- Deduct coins and unlock
	coinsObj.Value = coinsObj.Value - world.Cost
	unlock.Value = true

	-- Fire bindable event to trigger saving
	local saveWorldUnlockEvent = ReplicatedStorage:FindFirstChild("SaveWorldUnlockEvent")
	if saveWorldUnlockEvent and saveWorldUnlockEvent:IsA("BindableEvent") then
		saveWorldUnlockEvent:Fire(player, worldKey)
	end

	return true, "World unlocked!"
end

-- Teleport player to a world (assumes unlocked)
function WorldModule.TeleportToWorld(player, worldKey)
	local world = WorldModule.Worlds[worldKey]
	if not world then return false, "World does not exist." end

	local spawnName = world.SpawnName
	local spawnLocation = workspace:FindFirstChild(spawnName)
	if not spawnLocation then
		return false, "Spawn location not found."
	end

	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		player.Character.HumanoidRootPart.CFrame = spawnLocation.CFrame
		-- Set attribute for spawn plate logic
		if world.PlateAttribute then
			player:SetAttribute("LastTouchedSpawnPlate", world.PlateAttribute)
		end
		return true, "Teleported to " .. world.Name
	else
		return false, "Could not teleport (character missing)."
	end
end

return WorldModule