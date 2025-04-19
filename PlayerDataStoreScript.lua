-- Services
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- DataStore
local playerDataStore = DataStoreService:GetDataStore("PlayerDataStore")

-- Chest Template
local chestTemplate = ReplicatedStorage:WaitForChild("Chest")

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

-- Function to handle item collection (shared logic for ores and chests)
-- Function to handle item collection (shared logic for ores and chests)
local function handleCollection(item, player)
	local dataFolder = player:FindFirstChild("Data")
	if not dataFolder then
		warn("Data folder not found for player:", player.Name)
		return
	end

	-- Check if the item is a chest (has a UniqueID)
	if item:IsA("Model") and item:FindFirstChild("UniqueID") then
		-- Chest collection logic
		local inventoryFolder = dataFolder:FindFirstChild("Chests")
		if not inventoryFolder then
			inventoryFolder = Instance.new("Folder")
			inventoryFolder.Name = "Chests"
			inventoryFolder.Parent = dataFolder
		end

		local chestName = "Chest_" .. item.UniqueID.Value
		local chestItem = inventoryFolder:FindFirstChild(chestName)
		if chestItem then
			chestItem.Value += 1
			print(player.Name .. " already has chest:", chestName, "Count updated to:", chestItem.Value)
		else
			local newChestItem = Instance.new("IntValue")
			newChestItem.Name = chestName
			newChestItem.Value = 1
			newChestItem.Parent = inventoryFolder
			print("Added new chest to Inventory:", chestName)
		end

		-- Synchronize inventory and remove the chest
		print(player.Name .. " collected chest with ID:", item.UniqueID.Value)
		item:Destroy()
	elseif item:IsA("BasePart") then
		-- Ore collection logic
		local inventoryFolder = dataFolder:FindFirstChild("Ores")
		if not inventoryFolder then
			warn("Ores folder not found for player:", player.Name)
			return
		end

		local oreName = item.Name
		local oreItem = inventoryFolder:FindFirstChild(oreName)
		if oreItem then
			oreItem.Value += 1
			print(player.Name .. " collected ore:", oreName)
		else
			warn("Ore type not found in inventory:", oreName)
		end

		-- Destroy the ore after collection
		item:Destroy()
	else
		warn("Unhandled item type:", item.Name)
	end
end

-- Collision handling setup for spawned items
local function setupCollisionHandler(item, player)
	item.Touched:Connect(function(hit)
		local touchingPlayer = Players:GetPlayerFromCharacter(hit.Parent)
		if touchingPlayer then
			if item:FindFirstChild("UniqueID") then
				print("Chest touched:", item.Name)
			else
				print("Ore touched:", item.Name)
			end
			handleCollection(item, touchingPlayer)
		end
	end)
end

-- Spawn ores and a chest near the player
local function spawnOresAndChestNearPlayer(player)
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local spawnPosition = humanoidRootPart.Position + Vector3.new(0, 5, 0)

	-- Spawn ores
	local oreTypes = {"Coal", "Iron", "Copper", "Gold"}
	for _, oreTypeName in ipairs(oreTypes) do
		local oreTemplate = ReplicatedStorage:FindFirstChild(oreTypeName)
		if oreTemplate then
			local ore = oreTemplate:Clone()
			ore.Position = spawnPosition + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
			ore.Parent = Workspace
			setupCollisionHandler(ore, player)
			print("Spawned ore:", ore.Name)
		end
	end

	-- Spawn a chest
	local chest = chestTemplate:Clone()
	chest.Position = spawnPosition + Vector3.new(10, 0, 0) -- Offset the chest position
	chest.Parent = Workspace
	local uniqueID = math.random(1, 1e9)
	local uniqueIDValue = Instance.new("IntValue", chest)
	uniqueIDValue.Name = "UniqueID"
	uniqueIDValue.Value = uniqueID
	setupCollisionHandler(chest, player)
	print("Spawned chest with UniqueID:", uniqueID)

	print("Spawned ores and a chest near player:", player.Name)
end

-- Function to load player data
local function loadPlayerData(player)
	local key = "Player_" .. player.UserId
	local success, data = pcall(function()
		return playerDataStore:GetAsync(key)
	end)

	if success and data then
		print("Loaded data for player:", player.Name, data)

		local dataFolder = player:FindFirstChild("Data")
		if dataFolder then
			-- Load ores data
			local oresFolder = dataFolder:FindFirstChild("Ores")
			if oresFolder then
				local defaultOres = {"Coal", "Iron", "Copper", "Gold"}
				for _, oreType in ipairs(defaultOres) do
					local oreValue = oresFolder:FindFirstChild(oreType)
					if oreValue then
						oreValue.Value = data.ores and data.ores[oreType] or 0
					else
						-- Create missing ore entry if not found
						local newOre = Instance.new("IntValue")
						newOre.Name = oreType
						newOre.Value = data.ores and data.ores[oreType] or 0
						newOre.Parent = oresFolder
						print("Created missing ore entry:", oreType, "with count:", newOre.Value)
					end
				end
			else
				warn("Ores folder not found for player:", player.Name)
			end

			-- Load chest data
			if data.chests then
				local chestsFolder = dataFolder:FindFirstChild("Chests")
				if not chestsFolder then
					chestsFolder = Instance.new("Folder")
					chestsFolder.Name = "Chests"
					chestsFolder.Parent = dataFolder
				end

				for chestName, count in pairs(data.chests) do
					local chestValue = Instance.new("IntValue")
					chestValue.Name = chestName
					chestValue.Value = count
					chestValue.Parent = chestsFolder
				end
			end

			-- Load coins
			local coins = dataFolder:FindFirstChild("Coins")
			if coins then
				coins.Value = data.coins or 0
			end
		end
	else
		print("No data found for player:", player.Name, "Creating default data.")
	end
end

-- Function to save player data
local function savePlayerData(player)
	local dataFolder = player:FindFirstChild("Data")
	if not dataFolder then return end

	local oresFolder = dataFolder:FindFirstChild("Ores")
	local chestsFolder = dataFolder:FindFirstChild("Chests")

	local oresData = {}
	if oresFolder then
		for _, oreValue in pairs(oresFolder:GetChildren()) do
			oresData[oreValue.Name] = oreValue.Value
		end
	end

	local chestsData = {}
	if chestsFolder then
		for _, chestValue in pairs(chestsFolder:GetChildren()) do
			chestsData[chestValue.Name] = chestValue.Value
		end
	end

	local data = {
		ores = oresData,
		chests = chestsData,
		coins = dataFolder:FindFirstChild("Coins") and dataFolder.Coins.Value or 0
	}

	local key = "Player_" .. player.UserId
	pcall(function()
		playerDataStore:SetAsync(key, data)
	end)
end

-- PlayerAdded: Load data when a player joins
Players.PlayerAdded:Connect(function(player)
	local dataFolder = Instance.new("Folder")
	dataFolder.Name = "Data"
	dataFolder.Parent = player

	local oresFolder = Instance.new("Folder")
	oresFolder.Name = "Ores"
	oresFolder.Parent = dataFolder

	local defaultOres = {"Coal", "Iron", "Copper", "Gold"}
	for _, oreType in ipairs(defaultOres) do
		local oreValue = Instance.new("IntValue")
		oreValue.Name = oreType
		oreValue.Value = 0
		oreValue.Parent = oresFolder
	end

	local chestsFolder = Instance.new("Folder")
	chestsFolder.Name = "Chests"
	chestsFolder.Parent = dataFolder

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = dataFolder

	loadPlayerData(player)
end)

-- PlayerRemoving: Save data when a player leaves
Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
end)