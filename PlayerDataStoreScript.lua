-- Services
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- DataStore
local playerDataStore = DataStoreService:GetDataStore("PlayerDataStore")

-- Helper function to serialize data for saving
local function serializePlayerData(player)
	local dataFolder = player:FindFirstChild("Data")
	if not dataFolder then return nil end

	local data = {}

	-- Save ores
	local oresFolder = dataFolder:FindFirstChild("Ores")
	if oresFolder then
		data.ores = {}
		for _, oreValue in pairs(oresFolder:GetChildren()) do
			data.ores[oreValue.Name] = oreValue.Value
		end
	end

	-- Save chests
	local chestsFolder = dataFolder:FindFirstChild("Chests")
	if chestsFolder then
		data.chests = {}
		for _, chestValue in pairs(chestsFolder:GetChildren()) do
			data.chests[chestValue.Name] = chestValue.Value
		end
	end

	-- Save coins
	local coins = dataFolder:FindFirstChild("Coins")
	if coins then
		data.coins = coins.Value
	end

	-- Save pickaxes
	local pickaxesFolder = dataFolder:FindFirstChild("Pickaxes")
	if pickaxesFolder then
		data.pickaxes = {}
		for _, pickaxe in pairs(pickaxesFolder:GetChildren()) do
			table.insert(data.pickaxes, {
				Name = pickaxe.Name,
				MiningSize = pickaxe:FindFirstChild("MiningSize") and pickaxe.MiningSize.Value or 0,
				Durability = pickaxe:FindFirstChild("Durability") and pickaxe.Durability.Value or 0,
				Rarity = pickaxe:FindFirstChild("Rarity") and pickaxe.Rarity.Value or "Unknown"
			})
		end
	end

	return data
end

-- Helper function to deserialize data on player join
local function deserializePlayerData(player, data)
	if not data then return end

	local dataFolder = player:FindFirstChild("Data")
	if not dataFolder then
		dataFolder = Instance.new("Folder")
		dataFolder.Name = "Data"
		dataFolder.Parent = player
	end

	-- Load ores
	local oresFolder = Instance.new("Folder")
	oresFolder.Name = "Ores"
	oresFolder.Parent = dataFolder

	if data.ores then
		for oreType, value in pairs(data.ores) do
			local oreValue = Instance.new("IntValue")
			oreValue.Name = oreType
			oreValue.Value = value
			oreValue.Parent = oresFolder
		end
	end

	-- Load chests
	local chestsFolder = Instance.new("Folder")
	chestsFolder.Name = "Chests"
	chestsFolder.Parent = dataFolder

	if data.chests then
		for chestType, value in pairs(data.chests) do
			local chestValue = Instance.new("IntValue")
			chestValue.Name = chestType
			chestValue.Value = value
			chestValue.Parent = chestsFolder
		end
	end

	-- Load coins
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = data.coins or 0
	coins.Parent = dataFolder

	-- Load pickaxes
	local pickaxesFolder = Instance.new("Folder")
	pickaxesFolder.Name = "Pickaxes"
	pickaxesFolder.Parent = dataFolder

	if data.pickaxes then
		for _, pickaxeData in pairs(data.pickaxes) do
			local pickaxe = Instance.new("Folder")
			pickaxe.Name = pickaxeData.Name
			pickaxe.Parent = pickaxesFolder

			local miningSize = Instance.new("IntValue")
			miningSize.Name = "MiningSize"
			miningSize.Value = pickaxeData.MiningSize
			miningSize.Parent = pickaxe

			local durability = Instance.new("IntValue")
			durability.Name = "Durability"
			durability.Value = pickaxeData.Durability
			durability.Parent = pickaxe

			local rarity = Instance.new("StringValue")
			rarity.Name = "Rarity"
			rarity.Value = pickaxeData.Rarity
			rarity.Parent = pickaxe
		end
	end
end

-- Save player data on leave
local function savePlayerData(player)
	local key = "Player_" .. player.UserId
	local data = serializePlayerData(player)

	if data then
		pcall(function()
			playerDataStore:SetAsync(key, data)
		end)
	end
end

-- Load player data on join
local function loadPlayerData(player)
	local key = "Player_" .. player.UserId
	local success, data = pcall(function()
		return playerDataStore:GetAsync(key)
	end)

	if success then
		deserializePlayerData(player, data)
	else
		warn("Failed to load data for player:", player.Name)
	end
end

-- PlayerAdded: Load data when a player joins
Players.PlayerAdded:Connect(function(player)
	loadPlayerData(player)
end)

-- PlayerRemoving: Save data when a player leaves
Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
end)