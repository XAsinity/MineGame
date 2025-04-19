local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Require the centralized OreDefinitions module
local OreDefinitions = require(ReplicatedStorage:WaitForChild("OreDefinitions"))

local oresFolder = Instance.new("Folder")
oresFolder.Name = "Ores"
oresFolder.Parent = Workspace

local chestsFolder = Instance.new("Folder")
chestsFolder.Name = "Chests"
chestsFolder.Parent = Workspace

-- Use ore definitions from the centralized module
local oreTypes = OreDefinitions.oreTypes

local maxOres = 3000 -- Maximum number of ores to spawn at any time
local spawnRegion = Workspace:WaitForChild("SpawnRegion") -- Placeholder part defining the spawn area
local randomGenerator = Random.new()

-- Minimum distance between ores and chests to avoid overlap
local minDistanceBetweenOres = 5 -- Adjust as needed (5 studs)

-- Terrain backup
local terrain = Workspace.Terrain

-- RemoteEvent for manual reset
local manualResetEvent = ReplicatedStorage:FindFirstChild("ManualResetEvent") or Instance.new("RemoteEvent")
manualResetEvent.Name = "ManualResetEvent"
manualResetEvent.Parent = ReplicatedStorage

local chestModel = ReplicatedStorage:WaitForChild("Chest") -- Ensure "Chest" model exists in ReplicatedStorage

-- Ensure random seed is initialized for unique ID generation
math.randomseed(os.time())

-- Generate a unique chest ID
local function generateUniqueChestID(player)
	local inventory = player:FindFirstChild("Inventory")
	if not inventory then return math.random(1, 1e9) end

	local uniqueID
	repeat
		uniqueID = math.random(1, 1e9) -- Generate a random number between 1 and 1 billion
	until not inventory:FindFirstChild("Chest_" .. uniqueID) -- Ensure the ID is unique

	return uniqueID
end

-- Declare functions as local variables to avoid warnings
local generateTerrainFromSpawnRegion
local teleportPlayersToSpawn
local resetTerrainAndOres
local spawnOresAndChests
local getRandomPosition
local isPositionValid
local spawnOre
local spawnChest

-- Function to generate terrain based on SpawnRegion
function generateTerrainFromSpawnRegion()
	print("Generating terrain from SpawnRegion...")

	-- Clear existing terrain
	terrain:Clear()

	-- Use SpawnRegion to define the terrain size and position
	local spawnRegionSize = spawnRegion.Size
	local spawnRegionPosition = spawnRegion.Position

	-- Fill the terrain based on SpawnRegion dimensions
	terrain:FillBlock(CFrame.new(spawnRegionPosition), spawnRegionSize, Enum.Material.LeafyGrass)

	-- Optional: Disable decorative grass
	pcall(function()
		terrain.Decoration = false
	end)

	print("Terrain generation complete!")
end

-- Function to teleport players to the SpawnLocation
function teleportPlayersToSpawn()
	local spawnLocation = Workspace:FindFirstChild("SpawnLocation") -- Replace with your spawn location object or coordinates
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

-- Function to reset terrain and ores
function resetTerrainAndOres()
	-- Generate new terrain using SpawnRegion
	generateTerrainFromSpawnRegion()

	-- Respawn ores and chests
	spawnOresAndChests(spawnRegion)

	-- Teleport players to SpawnLocation
	teleportPlayersToSpawn()

	print("Terrain and ores have been reset, and players have been teleported!")
end

-- Function to spawn ores and chests in the terrain
function spawnOresAndChests(region)
	-- Clear any existing ores and chests
	for _, child in pairs(oresFolder:GetChildren()) do
		child:Destroy()
	end
	for _, child in pairs(chestsFolder:GetChildren()) do
		child:Destroy()
	end

	-- Keep track of existing objects to prevent overlap
	local existingObjects = {}

	-- Spawn new ores
	for _, oreType in ipairs(oreTypes) do
		for i = 1, maxOres do
			if randomGenerator:NextNumber(0, 1) < oreType.frequency then
				-- Randomly position the ore
				local position = getRandomPosition(region, oreType.depthRange, oreType.overlapChance)
				if isPositionValid(position, existingObjects) then
					-- Spawn ore
					spawnOre(oreType, position, existingObjects)
				end
			end
		end
	end

	-- Very rare chance to spawn chests
	if randomGenerator:NextNumber(0, 1) < 0.005 then -- 0.5% chance
		local chestPosition = getRandomPosition(region, {0, 1}, 0) -- Chests can spawn anywhere
		if isPositionValid(chestPosition, existingObjects) then
			spawnChest(chestPosition, existingObjects)
		end
	end

	print("Ores and chests have been spawned!")
end

-- Function to get a random position within the region
function getRandomPosition(region, depthRange, overlapChance)
	local min = region.Position - region.Size / 2
	local max = region.Position + region.Size / 2

	-- Decide whether to use the normal depth range or a random depth
	local useRandomDepth = randomGenerator:NextNumber(0, 1) < overlapChance
	local y

	if useRandomDepth then
		-- Completely random depth across the entire SpawnRegion
		y = randomGenerator:NextNumber(min.Y, max.Y)
	else
		-- Normal depth range based on the ore's layer
		local heightMin = min.Y + (region.Size.Y * depthRange[1])
		local heightMax = min.Y + (region.Size.Y * depthRange[2])
		y = randomGenerator:NextNumber(heightMin, heightMax)
	end

	local x = randomGenerator:NextNumber(min.X, max.X)
	local z = randomGenerator:NextNumber(min.Z, max.Z)

	return Vector3.new(x, y, z)
end

-- Function to validate positions
function isPositionValid(position, existingObjects)
	for _, obj in ipairs(existingObjects) do
		-- Check if the distance between the new position and the existing object is less than the minimum distance
		if (obj.Position - position).Magnitude < minDistanceBetweenOres then
			return false -- Position is too close to another object
		end
	end
	return true -- Position is valid
end

-- Function to spawn individual ores
function spawnOre(oreType, position, existingObjects)
	local ore = oreType.template:Clone()
	ore.Position = position
	ore.Anchored = true
	ore.Name = oreType.name -- Ensure the Name property matches validOres and inventory
	ore.Parent = oresFolder

	-- Add the new ore to the existing objects table for collision checks
	table.insert(existingObjects, ore)

	-- Debugging log
	print("Spawned ore:", ore.Name, "at position:", ore.Position)

	-- Ore collection logic
	ore.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			-- Access the player's Data folder created by PlayerDataStoreScript
			local dataFolder = player:FindFirstChild("Data")
			if dataFolder then
				local oresFolder = dataFolder:FindFirstChild("Ores")
				if oresFolder then
					-- Find the specific ore type and increment its value
					local oreValue = oresFolder:FindFirstChild(oreType.name)
					if oreValue then
						oreValue.Value = oreValue.Value + 1
						print(player.Name .. " collected " .. oreType.name .. " (x" .. oreValue.Value .. ")")
					else
						warn("Ore type not found in player's Ores folder:", oreType.name)
					end
				else
					warn("Ores folder not found in player's Data folder:", player.Name)
				end
			else
				warn("Data folder not found for player:", player.Name)
			end

			ore:Destroy()
		end
	end)
end

-- Function to spawn chests
function spawnChest(position, existingObjects)
	local chest = chestModel:Clone()
	chest.Position = position
	chest.Anchored = true
	chest.Parent = chestsFolder

	-- Assign a unique ID using the new logic
	local uniqueID = generateUniqueChestID(Players:GetPlayers()[1]) -- Example: Assign ID based on the first player
	local chestIDValue = Instance.new("IntValue")
	chestIDValue.Name = "UniqueID"
	chestIDValue.Value = uniqueID
	chestIDValue.Parent = chest

	-- Add the new chest to the existing objects table for collision checks
	table.insert(existingObjects, chest)

	-- Debugging log
	print("Spawned chest with UniqueID:", uniqueID, "at position:", chest.Position)

	-- Chest collection logic
	chest.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			local dataFolder = player:FindFirstChild("Data")
			if not dataFolder then return end

			local chestsFolder = dataFolder:FindFirstChild("Chests") or Instance.new("Folder", dataFolder)
			chestsFolder.Name = "Chests"

			local inventoryChestID = chestsFolder:FindFirstChild("Chest_" .. uniqueID)
			if inventoryChestID then
				inventoryChestID.Value += 1
			else
				local newChest = Instance.new("IntValue")
				newChest.Name = "Chest_" .. uniqueID
				newChest.Value = 1
				newChest.Parent = chestsFolder
			end

			print(player.Name .. " collected chest with UniqueID:", uniqueID)
			chest:Destroy()
		end
	end)
end

-- Listen for manual reset from the client
manualResetEvent.OnServerEvent:Connect(function(player)
	print(player.Name .. " triggered a manual reset!")
	resetTerrainAndOres()
end)

-- Automatic reset every 5 minutes
task.spawn(function()
	while true do
		task.wait(300) -- 5 minutes
		resetTerrainAndOres()
	end
end)

-- Initial setup: Generate terrain and spawn ores and chests
generateTerrainFromSpawnRegion()
spawnOresAndChests(spawnRegion)