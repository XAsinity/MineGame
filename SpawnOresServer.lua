local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local InventoryModule = require(ServerScriptService:WaitForChild("InventoryModule"))
local OreDefinitions = require(ReplicatedStorage:WaitForChild("OreDefinitions"))

local ItemSpawner = require(ServerScriptService:WaitForChild("ItemSpawner"))

local oresFolder = Workspace:FindFirstChild("Ores") or Instance.new("Folder", Workspace)
oresFolder.Name = "Ores"
local chestsFolder = Workspace:FindFirstChild("Chests") or Instance.new("Folder", Workspace)
chestsFolder.Name = "Chests"
local chestTemplate = ReplicatedStorage:WaitForChild("Chest")

math.randomseed(os.time())

local function spawnOresAndChestNearPlayer(player)
	local character = player.Character
	if not character then
		warn("Player character not found!")
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		warn("HumanoidRootPart not found for player:", player.Name)
		return
	end

	local spawnPosition = humanoidRootPart.Position + Vector3.new(5, 5, 0)

	for _, oreDef in ipairs(OreDefinitions.oreTypes) do
		local ore = ItemSpawner.spawnOre(oreDef, spawnPosition + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5)), oresFolder)
		print("Spawned ore:", oreDef.name, "at position:", ore.Position)
	end

	local forwardVector = humanoidRootPart.CFrame.LookVector * 10
	local upwardVector = Vector3.new(0, 5, 0)
	local chestSpawnPosition = humanoidRootPart.Position + forwardVector + upwardVector

	local chest = ItemSpawner.spawnChest(chestTemplate, chestSpawnPosition, chestsFolder, player)
	print("Spawned ores and a chest near player:", player.Name)
end

local spawnOresEvent = ReplicatedStorage:WaitForChild("SpawnOresEvent")
spawnOresEvent.OnServerEvent:Connect(function(player)
	print(player.Name .. " triggered SpawnOresEvent.")
	spawnOresAndChestNearPlayer(player)
end)