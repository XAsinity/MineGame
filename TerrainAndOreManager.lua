local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local OreDefinitions = require(ReplicatedStorage:WaitForChild("OreDefinitions"))
local ItemSpawner = require(ServerScriptService:WaitForChild("ItemSpawner"))

local oresFolder = Workspace:FindFirstChild("Ores") or Instance.new("Folder", Workspace)
oresFolder.Name = "Ores"
local chestsFolder = Workspace:FindFirstChild("Chests") or Instance.new("Folder", Workspace)
chestsFolder.Name = "Chests"

local oreTypes = OreDefinitions.oreTypes
local maxOres = 3000
local spawnRegion = Workspace:WaitForChild("SpawnRegion")
local randomGenerator = Random.new()
local minDistanceBetweenOres = 5

local terrain = Workspace.Terrain
local manualResetEvent = ReplicatedStorage:FindFirstChild("ManualResetEvent") or Instance.new("RemoteEvent")
manualResetEvent.Name = "ManualResetEvent"
manualResetEvent.Parent = ReplicatedStorage

local chestModel = ReplicatedStorage:WaitForChild("Chest")

math.randomseed(os.time())

-- Helper functions
local function getRandomPosition(region, depthRange, overlapChance)
	local min = region.Position - region.Size / 2
	local max = region.Position + region.Size / 2

	local useRandomDepth = randomGenerator:NextNumber(0, 1) < (overlapChance or 0)
	local y

	if useRandomDepth then
		y = randomGenerator:NextNumber(min.Y, max.Y)
	else
		local heightMin = min.Y + (region.Size.Y * depthRange[1])
		local heightMax = min.Y + (region.Size.Y * depthRange[2])
		y = randomGenerator:NextNumber(heightMin, heightMax)
	end

	local x = randomGenerator:NextNumber(min.X, max.X)
	local z = randomGenerator:NextNumber(min.Z, max.Z)

	return Vector3.new(x, y, z)
end

local function isPositionValid(position, existingObjects)
	for _, obj in ipairs(existingObjects) do
		if (obj.Position - position).Magnitude < minDistanceBetweenOres then
			return false
		end
	end
	return true
end

-- Terrain/ores logic
local function generateTerrainFromSpawnRegion()
	print("Generating terrain from SpawnRegion...")
	terrain:Clear()
	local spawnRegionSize = spawnRegion.Size
	local spawnRegionPosition = spawnRegion.Position
	terrain:FillBlock(CFrame.new(spawnRegionPosition), spawnRegionSize, Enum.Material.LeafyGrass)
	pcall(function() terrain.Decoration = false end)
	print("Terrain generation complete!")
end

local function teleportPlayersToSpawn()
	local spawnLocation = Workspace:FindFirstChild("SpawnLocation")
	if spawnLocation then
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				player.Character.HumanoidRootPart.CFrame = spawnLocation.CFrame
			end
		end
		print("All players teleported to SpawnLocation!")
	else
		warn("SpawnLocation not found! Unable to teleport players.")
	end
end

local function resetTerrainAndOres()
	generateTerrainFromSpawnRegion()
	-- Re-spawn ores and chests
	for _, child in pairs(oresFolder:GetChildren()) do child:Destroy() end
	for _, child in pairs(chestsFolder:GetChildren()) do child:Destroy() end

	local existingObjects = {}

	for _, oreType in ipairs(oreTypes) do
		for i = 1, maxOres do
			if randomGenerator:NextNumber(0, 1) < oreType.frequency then
				local position = getRandomPosition(spawnRegion, oreType.depthRange, oreType.overlapChance)
				if isPositionValid(position, existingObjects) then
					local ore = ItemSpawner.spawnOre(oreType, position, oresFolder)
					table.insert(existingObjects, ore)
				end
			end
		end
	end

	if randomGenerator:NextNumber(0, 1) < 0.005 then
		local chestPosition = getRandomPosition(spawnRegion, {0, 1}, 0)
		if isPositionValid(chestPosition, existingObjects) then
			local chest = ItemSpawner.spawnChest(chestModel, chestPosition, chestsFolder, Players:GetPlayers()[1])
			table.insert(existingObjects, chest)
		end
	end

	teleportPlayersToSpawn()
	print("Terrain and ores have been reset, and players have been teleported!")
end

-- Remote/auto reset
manualResetEvent.OnServerEvent:Connect(function(player)
	print(player.Name .. " triggered a manual reset!")
	resetTerrainAndOres()
end)

task.spawn(function()
	while true do
		task.wait(300)
		resetTerrainAndOres()
	end
end)

-- Initial setup
generateTerrainFromSpawnRegion()
resetTerrainAndOres()