local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local OreDefinitions = require(ReplicatedStorage:WaitForChild("OreDefinitions"))
local ItemSpawner = require(ServerScriptService:WaitForChild("ItemSpawner"))

-- === Folders for each world ===
local oresFolder = Workspace:FindFirstChild("Ores") or Instance.new("Folder", Workspace)
oresFolder.Name = "Ores"
local chestsFolder = Workspace:FindFirstChild("Chests") or Instance.new("Folder", Workspace)
chestsFolder.Name = "Chests"

local volcanoOresFolder = Workspace:FindFirstChild("VolcanoOres") or Instance.new("Folder", Workspace)
volcanoOresFolder.Name = "VolcanoOres"
local volcanoChestsFolder = Workspace:FindFirstChild("VolcanoChests") or Instance.new("Folder", Workspace)
volcanoChestsFolder.Name = "VolcanoChests"

-- === Regions for each world ===
local spawnRegion = Workspace:WaitForChild("SpawnRegion")
local spawnRegion2 = Workspace:WaitForChild("SpawnRegion2") -- volcano world

-- === Centralized Ore Types (from OreDefinitions) ===
local baseOreTypes = {}
local volcanoOreTypes = {}
for _, def in ipairs(OreDefinitions.oreTypes) do
	if def.world == "base" then
		table.insert(baseOreTypes, def)
	elseif def.world == "volcano" then
		table.insert(volcanoOreTypes, def)
	end
end

local maxOres = 4500
local oresBatchSize = 300    -- Number of ores to spawn per batch
local oresBatchDelay = 0.1   -- Delay (in seconds) between each batch
local minDistanceBetweenOres = 5
local terrain = Workspace.Terrain
local randomGenerator = Random.new()
local chestModel = ReplicatedStorage:WaitForChild("Chest")

-- === Events ===
local manualResetEvent = ReplicatedStorage:FindFirstChild("ManualResetEvent") or Instance.new("RemoteEvent")
manualResetEvent.Name = "ManualResetEvent"
manualResetEvent.Parent = ReplicatedStorage

local volcanoResetEvent = ReplicatedStorage:FindFirstChild("VolcanoResetEvent") or Instance.new("RemoteEvent")
volcanoResetEvent.Name = "VolcanoResetEvent"
volcanoResetEvent.Parent = ReplicatedStorage

math.randomseed(os.time())

-- === Helper functions (shared) ===
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

-- Teleport each player to their last touched spawn plate (defaults to OverWorld)
local function teleportPlayersToLastPlate()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local plate = player:GetAttribute("LastTouchedSpawnPlate")
			local spawnName
			if plate == "Volcano" then
				spawnName = "VolcanoSpawnLocation"
			else
				spawnName = "SpawnLocation"
			end
			local spawnLocation = Workspace:FindFirstChild(spawnName)
			if spawnLocation then
				player.Character.HumanoidRootPart.CFrame = spawnLocation.CFrame + Vector3.new(0, 5, 0)
			end
		end
	end
	print("All players teleported to their last touched spawn plate!")
end

-- Only clear/fill the region you are managing!
local function fillRegion(region, material)
	local cframe = CFrame.new(region.Position)
	local size = region.Size
	terrain:FillBlock(cframe, size, material)
end

local function clearRegion(region)
	local cframe = CFrame.new(region.Position)
	local size = region.Size
	terrain:FillBlock(cframe, size, Enum.Material.Air)
end

-- Batch spawn ores for performance
local function batchSpawnOres(region, oreTypesParam, oresFolder, existingObjects, maxOres, onComplete)
	coroutine.wrap(function()
		for _, oreType in ipairs(oreTypesParam) do
			local oresSpawned = 0
			local batch = {}
			for i = 1, maxOres do
				if randomGenerator:NextNumber(0, 1) < oreType.frequency then
					local position = getRandomPosition(region, oreType.depthRange, oreType.overlapChance)
					if isPositionValid(position, existingObjects) then
						table.insert(batch, {oreType = oreType, position = position})
						oresSpawned = oresSpawned + 1
					end
				end
				if #batch >= oresBatchSize then
					for _, oreData in ipairs(batch) do
						local ore = ItemSpawner.spawnOre(oreData.oreType, oreData.position, oresFolder)
						table.insert(existingObjects, ore)
					end
					batch = {}
					task.wait(oresBatchDelay)
				end
			end
			-- Final batch
			if #batch > 0 then
				for _, oreData in ipairs(batch) do
					local ore = ItemSpawner.spawnOre(oreData.oreType, oreData.position, oresFolder)
					table.insert(existingObjects, ore)
				end
				task.wait(oresBatchDelay)
			end
		end
		if onComplete then
			onComplete()
		end
	end)()
end

local function resetWorld(region, oresFolder, chestsFolder, oreTypesParam, terrainMaterial, callback)
	print("[RESET WORLD] Region:", region.Name, "Ores:", table.concat((function()
		local t = {}
		for _,v in ipairs(oreTypesParam) do table.insert(t, v.name) end
		return t
	end)(), ", "))
	clearRegion(region)
	fillRegion(region, terrainMaterial)
	for _, child in pairs(oresFolder:GetChildren()) do child:Destroy() end
	for _, child in pairs(chestsFolder:GetChildren()) do child:Destroy() end

	local existingObjects = {}

	batchSpawnOres(region, oreTypesParam, oresFolder, existingObjects, maxOres, function()
		-- Spawn Chests (rare, 1-3 per reset, not guaranteed)
		local chestAttempts = 10
		local chestsSpawned = 0
		local maxChests = math.random(1, 3)
		local playersList = Players:GetPlayers()
		print("Chest spawning: maxChests =", maxChests, "chestAttempts =", chestAttempts, "players =", #playersList)
		for i = 1, chestAttempts do
			if chestsSpawned >= maxChests then
				print("Max chests spawned ("..maxChests.."), breaking.")
				break
			end
			local chance = randomGenerator:NextNumber(0, 1)
			print(string.format("Chest attempt %d/%d, roll=%.3f", i, chestAttempts, chance))
			if chance < 0.07 then
				local chestPosition = getRandomPosition(region, {0, 1}, 0)
				if not isPositionValid(chestPosition, existingObjects) then
					print("Chest position not valid, skipping this attempt.")
				elseif #playersList == 0 then
					print("No players in game, skipping chest spawn.")
				else
					local targetPlayer = playersList[math.random(1, #playersList)]
					local chest = ItemSpawner.spawnChest(chestModel, chestPosition, chestsFolder, targetPlayer)
					print("Spawned chest at", tostring(chestPosition), "for player", targetPlayer.Name)
					table.insert(existingObjects, chest)
					chestsSpawned += 1
				end
			else
				print("Chest not spawned on this attempt (roll too high).")
			end
		end
		print("Chests spawned this reset:", chestsSpawned)
		print(region.Name .. " terrain and ores have been reset!")
		if callback then callback() end
	end)
end

-- === Unified reset for both worlds with batching and delay ===
local function resetAllWorlds()
	resetWorld(spawnRegion, oresFolder, chestsFolder, baseOreTypes, Enum.Material.LeafyGrass, function()
		task.wait(2) -- 2 second delay before resetting the volcano world
		resetWorld(spawnRegion2, volcanoOresFolder, volcanoChestsFolder, volcanoOreTypes, Enum.Material.Basalt, function()
			-- After both resets, teleport all players to their correct spawn
			teleportPlayersToLastPlate()
		end)
	end)
end

-- On player join: ensure attribute is set and force OverWorld spawn
Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("LastTouchedSpawnPlate", "OverWorld")
	player.CharacterAdded:Connect(function(character)
		local spawnLocation = Workspace:FindFirstChild("SpawnLocation")
		if spawnLocation then
			local hrp = character:WaitForChild("HumanoidRootPart")
			hrp.CFrame = spawnLocation.CFrame + Vector3.new(0, 5, 0)
		end
	end)
end)

-- === Event hooks ===
manualResetEvent.OnServerEvent:Connect(function(player)
	print(player.Name .. " triggered a manual reset for ALL worlds (batched)!")
	resetAllWorlds()
end)

volcanoResetEvent.OnServerEvent:Connect(function(player)
	print(player.Name .. " triggered a manual reset for ALL worlds (batched)!")
	resetAllWorlds()
end)

-- === Automated resets ===
task.spawn(function()
	while true do
		task.wait(300)
		resetAllWorlds()
	end
end)

-- === Initial setup ===
resetAllWorlds()