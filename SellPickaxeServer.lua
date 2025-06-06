local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Only WAIT for the events, never create them at runtime!
local sellPickaxeEvent = ReplicatedStorage:WaitForChild("SellPickaxeEvent")
local inventoryUpdateEvent = ReplicatedStorage:WaitForChild("InventoryUpdateEvent")

local InventoryModule = require(ServerScriptService:WaitForChild("InventoryModule"))

-- Helper function to calculate the value of a pickaxe
local function calculatePickaxeValue(miningSize, durability, rarity)
	local rarityMultiplier = {
		Common = 1,
		Uncommon = 1.5,
		Rare = 2,
		Epic = 3,
		Legendary = 5
	}
	return math.floor((miningSize + durability) * (rarityMultiplier[rarity] or 1))
end

-- Helper to remove Tool instance from Backpack and Character
local function removePickaxeTool(player, pickaxeName)
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character
	if backpack then
		local tool = backpack:FindFirstChild(pickaxeName)
		if tool then tool:Destroy() end
	end
	if character then
		local tool = character:FindFirstChild(pickaxeName)
		if tool then tool:Destroy() end
	end
end

-- Handle selling a pickaxe
sellPickaxeEvent.OnServerEvent:Connect(function(player, pickaxeName)
	local dataFolder = player:FindFirstChild("Data")
	if not dataFolder then return end

	local pickaxesFolder = dataFolder:FindFirstChild("Pickaxes")
	if not pickaxesFolder then
		warn("Pickaxes folder not found in data for player:", player.Name)
		return
	end

	local pickaxe = pickaxesFolder:FindFirstChild(pickaxeName)
	if pickaxe then
		-- Calculate the value
		local miningSize = pickaxe:FindFirstChild("MiningSize") and pickaxe.MiningSize.Value or 0
		local durability = pickaxe:FindFirstChild("Durability") and pickaxe.Durability.Value or 0
		local rarity = pickaxe:FindFirstChild("Rarity") and pickaxe.Rarity.Value or "Common"
		local coinValue = calculatePickaxeValue(miningSize, durability, rarity)

		-- Add coins to the player
		local coins = dataFolder:FindFirstChild("Coins")
		if coins then
			coins.Value = coins.Value + coinValue
			print("Added", coinValue, "coins to", player.Name)
		end

		-- Remove the pickaxe from both Data and Inventory
		pickaxe:Destroy()
		print("Pickaxe removed from data:", pickaxeName)
		InventoryModule.removePickaxeFromInventory(player, pickaxeName)

		-- Remove the Tool from Backpack and Character
		removePickaxeTool(player, pickaxeName)

		-- Sync inventory so UI updates
		InventoryModule.syncInventoryWithData(player)

		-- Notify client to update UI immediately
		print("[SERVER] Firing InventoryUpdateEvent for", player.Name)
		inventoryUpdateEvent:FireClient(player)
		print("[SERVER] Fired InventoryUpdateEvent for", player.Name)
	else
		warn("Pickaxe not found in data:", pickaxeName)
	end
end)