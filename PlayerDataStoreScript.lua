-- Services
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- DataStore
local playerDataStore = DataStoreService:GetDataStore("PlayerDataStore")

-- Helper function to serialize data for saving
local function serializePlayerData(player)
	local dataFolder = player:FindFirstChild("Data")
	if not dataFolder then
		warn("Data folder not found for player:", player.Name)
		return nil
	end

	local data = {}

	-- Save ores
	local oresFolder = dataFolder:FindFirstChild("Ores")
	if oresFolder then
		data.ores = {}
		for _, oreValue in pairs(oresFolder:GetChildren()) do
			data.ores[oreValue.Name] = oreValue.Value
		end
		print("Serialized Ores for", player.Name, ":", data.ores)
	else
		warn("Ores folder not found for player:", player.Name)
	end

	-- Save chests
	local chestsFolder = dataFolder:FindFirstChild("Chests")
	if chestsFolder then
		data.chests = {}
		for _, chestValue in pairs(chestsFolder:GetChildren()) do
			data.chests[chestValue.Name] = chestValue.Value
		end
		print("Serialized Chests for", player.Name, ":", data.chests)
	else
		warn("Chests folder not found for player:", player.Name)
	end

	-- Save coins
	local coins = dataFolder:FindFirstChild("Coins")
	if coins then
		data.coins = coins.Value
		print("Serialized Coins for", player.Name, ":", coins.Value)
	else
		warn("Coins value not found for player:", player.Name)
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
		print("Serialized Pickaxes for", player.Name, ":", data.pickaxes)
	else
		warn("Pickaxes folder not found for player:", player.Name)
	end

	return data
end

-- Helper function to deserialize data on player join
local function deserializePlayerData(player, data)
	if not data then
		warn("No data to deserialize for player:", player.Name)
		return
	end

	print("Deserializing data for player:", player.Name, ":", data)

	local dataFolder = player:FindFirstChild("Data")
	if not dataFolder then
		warn("Data folder missing. Initialization should ensure its existence.")
		return
	end

	-- Load ores
	local oresFolder = dataFolder:FindFirstChild("Ores") or Instance.new("Folder", dataFolder)
	oresFolder.Name = "Ores"

	if data.ores then
		for oreType, value in pairs(data.ores) do
			local oreValue = oresFolder:FindFirstChild(oreType) or Instance.new("IntValue", oresFolder)
			oreValue.Name = oreType
			oreValue.Value = value
			print("Loaded Ore:", oreType, "Value:", value)
		end
	else
		warn("No ores data found for player:", player.Name)
	end

	-- Load chests
	local chestsFolder = dataFolder:FindFirstChild("Chests") or Instance.new("Folder", dataFolder)
	chestsFolder.Name = "Chests"

	if data.chests then
		for chestType, value in pairs(data.chests) do
			local chestValue = chestsFolder:FindFirstChild(chestType) or Instance.new("IntValue", chestsFolder)
			chestValue.Name = chestType
			chestValue.Value = value
			print("Loaded Chest:", chestType, "Value:", value)
		end
	else
		warn("No chests data found for player:", player.Name)
	end

	-- Load coins
	local coins = dataFolder:FindFirstChild("Coins") or Instance.new("IntValue", dataFolder)
	coins.Name = "Coins"
	coins.Value = data.coins or 0
	print("Loaded Coins for", player.Name, ":", coins.Value)

	-- Load pickaxes
	local pickaxesFolder = dataFolder:FindFirstChild("Pickaxes") or Instance.new("Folder", dataFolder)
	pickaxesFolder.Name = "Pickaxes"

	if data.pickaxes then
		for _, pickaxeData in pairs(data.pickaxes) do
			local pickaxe = pickaxesFolder:FindFirstChild(pickaxeData.Name) or Instance.new("Folder", pickaxesFolder)
			pickaxe.Name = pickaxeData.Name

			local miningSize = pickaxe:FindFirstChild("MiningSize") or Instance.new("IntValue", pickaxe)
			miningSize.Name = "MiningSize"
			miningSize.Value = pickaxeData.MiningSize

			local durability = pickaxe:FindFirstChild("Durability") or Instance.new("IntValue", pickaxe)
			durability.Name = "Durability"
			durability.Value = pickaxeData.Durability

			local rarity = pickaxe:FindFirstChild("Rarity") or Instance.new("StringValue", pickaxe)
			rarity.Name = "Rarity"
			rarity.Value = pickaxeData.Rarity

			print("Loaded Pickaxe:", pickaxeData)
		end
	else
		warn("No pickaxes data found for player:", player.Name)
	end
end

-- Save player data on leave
local function savePlayerData(player)
	local key = "Player_" .. player.UserId
	local data = serializePlayerData(player)

	if data then
		local success, errorMessage = pcall(function()
			playerDataStore:SetAsync(key, data)
		end)
		if success then
			print("Data successfully saved for player:", player.Name)
		else
			warn("Failed to save data for player:", player.Name, "Error:", errorMessage)
		end
	else
		warn("No data to save for player:", player.Name)
	end
end

-- Load player data on join
local function loadPlayerData(player)
	local key = "Player_" .. player.UserId
	local success, data = pcall(function()
		return playerDataStore:GetAsync(key)
	end)

	if success then
		print("Data successfully loaded for player:", player.Name, "Data:", data)
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