local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ItemSpawner = require(game.ServerScriptService:WaitForChild("ItemSpawner"))
local ShopPurchaseEvent = ReplicatedStorage:WaitForChild("ShopPurchaseEvent")
local inventoryUpdateEvent = ReplicatedStorage:WaitForChild("InventoryUpdateEvent")

local CHEST_COST = 500

ShopPurchaseEvent.OnServerEvent:Connect(function(player, amount)
	amount = math.clamp(tonumber(amount) or 1, 1, 99)
	local totalCost = amount * CHEST_COST

	-- Find coins
	local dataFolder = player:FindFirstChild("Data")
	if not dataFolder then return end
	local coins = dataFolder:FindFirstChild("Coins")
	if not coins or not coins:IsA("IntValue") then return end

	if coins.Value < totalCost then
		warn(player.Name .. " tried to buy chests but doesn't have enough coins!")
		return
	end

	-- Subtract coins
	coins.Value = coins.Value - totalCost

	-- Grant the chests directly as IntValues (simulate pickup)
	for i = 1, amount do
		local uniqueID = ItemSpawner.generateUniqueChestID(player)
		local chestName = "Chest_" .. uniqueID

		-- Ensure Chests folder in Data
		local chestsFolder = dataFolder:FindFirstChild("Chests")
		if not chestsFolder then
			chestsFolder = Instance.new("Folder")
			chestsFolder.Name = "Chests"
			chestsFolder.Parent = dataFolder
		end

		-- Grant to Data.Chests
		local dataChest = chestsFolder:FindFirstChild(chestName)
		if dataChest then
			dataChest.Value = dataChest.Value + 1
		else
			dataChest = Instance.new("IntValue")
			dataChest.Name = chestName
			dataChest.Value = 1
			dataChest.Parent = chestsFolder
		end

		-- Grant to Inventory (flat structure, for UI)
		local inventory = player:FindFirstChild("Inventory")
		if inventory then
			local invChest = inventory:FindFirstChild(chestName)
			if invChest then
				invChest.Value = invChest.Value + 1
			else
				invChest = Instance.new("IntValue")
				invChest.Name = chestName
				invChest.Value = 1
				invChest.Parent = inventory
			end
		end
	end

	print(player.Name .. " purchased " .. amount .. " unique chests for " .. totalCost .. " coins!")
	inventoryUpdateEvent:FireClient(player)
end)