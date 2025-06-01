-- Services
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local removeChestEvent = ReplicatedStorage:WaitForChild("RemoveChestEvent")
local sellPickaxeEvent = ReplicatedStorage:WaitForChild("SellPickaxeEvent") -- Event for selling pickaxes

-- Wait for InventoryModule in ServerScriptService
local InventoryModule
local success, err = pcall(function()
	InventoryModule = require(ServerScriptService:WaitForChild("InventoryModule"))
end)

if not success then
	warn("Failed to load InventoryModule:", err)
end

-- DataStore
local playerDataStore = DataStoreService:GetDataStore("PlayerDataStore")

-- Helper function to recreate all owned pickaxes as Tools in the Backpack
local function grantAllPickaxesToBackpack(player)
	local dataPickaxes = player:FindFirstChild("Data") and player.Data:FindFirstChild("Pickaxes")
	local backpack = player:FindFirstChild("Backpack")
	if not (dataPickaxes and backpack) then
		warn("Missing Data.Pickaxes or Backpack for player:", player.Name)
		return
	end

	print("Running grantAllPickaxesToBackpack for", player.Name)

	-- Remove existing pickaxes/tools to avoid duplicates
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			tool:Destroy()
		end
	end

	-- For each owned pickaxe in Data.Pickaxes, clone the template and add stats
	for _, pickaxeFolder in ipairs(dataPickaxes:GetChildren()) do
		local toolTemplate = ReplicatedStorage:FindFirstChild("Starter Pickaxe")
		if toolTemplate then
			local tool = toolTemplate:Clone()
			tool.Name = pickaxeFolder.Name
			for _, statName in ipairs({"MiningSize", "Durability", "Rarity"}) do
				local valueObj = pickaxeFolder:FindFirstChild(statName)
				if valueObj then
					local newValue
					if valueObj:IsA("IntValue") then
						newValue = Instance.new("IntValue")
					elseif valueObj:IsA("StringValue") then
						newValue = Instance.new("StringValue")
					end
					if newValue then
						newValue.Name = statName
						newValue.Value = valueObj.Value
						newValue.Parent = tool
					end
				end
			end
			tool.Parent = backpack
			print("Recreated and added pickaxe to backpack:", tool.Name)
		else
			warn("Starter Pickaxe template missing in ReplicatedStorage!")
		end
	end
end

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

	-- Save pickaxes (limit to 20)
	local pickaxesFolder = dataFolder:FindFirstChild("Pickaxes")
	if pickaxesFolder then
		data.pickaxes = {}
		local count = 0
		for _, pickaxe in ipairs(pickaxesFolder:GetChildren()) do
			if count >= 20 then break end
			table.insert(data.pickaxes, {
				Name = pickaxe.Name,
				MiningSize = pickaxe:FindFirstChild("MiningSize") and pickaxe.MiningSize.Value or 0,
				Durability = pickaxe:FindFirstChild("Durability") and pickaxe.Durability.Value or 0,
				Rarity = pickaxe:FindFirstChild("Rarity") and pickaxe.Rarity.Value or "Unknown"
			})
			count += 1
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

	-- Load and recreate pickaxes (limit to 20)
	local pickaxesFolder = dataFolder:FindFirstChild("Pickaxes") or Instance.new("Folder", dataFolder)
	pickaxesFolder.Name = "Pickaxes"

	if data.pickaxes then
		for i, pickaxeData in ipairs(data.pickaxes) do
			if i > 20 then break end
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

	-- Mark that pickaxes are ready
	player:SetAttribute("PickaxesReady", true)
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

		-- Synchronize inventory with data
		if InventoryModule then
			InventoryModule.syncInventoryWithData(player)
		else
			warn("InventoryModule is missing. Cannot synchronize inventory.")
		end
	else
		warn("Failed to load data for player:", player.Name)
	end
end

-- Function to remove a pickaxe from player data
local function removePickaxeFromData(player, pickaxeName)
	local dataFolder = player:FindFirstChild("Data")
	if not dataFolder then
		warn("Data folder not found for player:", player.Name)
		return
	end

	local pickaxesFolder = dataFolder:FindFirstChild("Pickaxes")
	if not pickaxesFolder then
		warn("Pickaxes folder not found in data for player:", player.Name)
		return
	end

	-- Function to delete the pickaxe
	local pickaxe = pickaxesFolder:FindFirstChild(pickaxeName)
	if pickaxe then
		pickaxe:Destroy()
		print("Pickaxe removed from data:", pickaxeName)
	else
		warn("Pickaxe not found in data:", pickaxeName)
	end
end
removeChestEvent.OnServerEvent:Connect(function(player, chestName, removeCompletely)
	local dataFolder = player:FindFirstChild("Data")
	if not dataFolder then
		warn("Data folder not found for player:", player.Name)
		return
	end

	local chestsFolder = dataFolder:FindFirstChild("Chests")
	if not chestsFolder then
		warn("Chests folder not found for player:", player.Name)
		return
	end

	-- Attempt to delete or decrement chest
	local chest = chestsFolder:FindFirstChild(chestName)
	if chest then
		if removeCompletely then
			chest:Destroy()
			print("Chest completely removed from inventory:", chestName)
		else
			chest.Value = math.max(chest.Value - 1, 0)
			print("Chest count decreased in inventory:", chestName, "New count:", chest.Value)
			if chest.Value == 0 then
				chest:Destroy()
			end
		end
		-- <<<<<<<< THIS LINE IS THE FIX >>>>>>>>
		if InventoryModule and InventoryModule.syncInventoryWithData then
			InventoryModule.syncInventoryWithData(player)
		end
	else
		warn("Chest not found in inventory for player:", player.Name)
	end
end)

-- Listen for SellPickaxeEvent from client
sellPickaxeEvent.OnServerEvent:Connect(function(player, pickaxeName)
	-- Remove pickaxe from data
	removePickaxeFromData(player, pickaxeName)
end)

-- PlayerAdded: Load data when a player joins
Players.PlayerAdded:Connect(function(player)
	loadPlayerData(player)

	player.CharacterAdded:Connect(function()
		-- Wait until Backpack exists
		while not player:FindFirstChild("Backpack") do
			task.wait(0.1)
		end
		-- Wait until Pickaxes are loaded
		while not player:GetAttribute("PickaxesReady") do
			task.wait(0.1)
		end

		-- Wait for at least one pickaxe or a short timeout (so an empty backpack is possible)
		local dataPickaxes = player:FindFirstChild("Data") and player.Data:FindFirstChild("Pickaxes")
		local waited = 0
		while dataPickaxes and #dataPickaxes:GetChildren() == 0 and waited < 2 do
			task.wait(0.2)
			waited = waited + 0.2
		end

		grantAllPickaxesToBackpack(player)

		-- Listen for new pickaxes being added while in game (handles chests, purchases, etc)
		if dataPickaxes then
			dataPickaxes.ChildAdded:Connect(function(child)
				grantAllPickaxesToBackpack(player)
			end)
		end
	end)
end)

-- PlayerRemoving: Save data when a player leaves
Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
end)