local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PickaxeUtils = require(ReplicatedStorage:WaitForChild("PickaxeUtils"))

-- Reference the inventory update event for UI refresh
local inventoryUpdateEvent = ReplicatedStorage:WaitForChild("InventoryUpdateEvent")

local function grantPickaxeToPlayer(player, pickaxe)
	-- Fetch the Starter Pickaxe model from ReplicatedStorage
	local starterPickaxeModel = ReplicatedStorage:FindFirstChild("Starter Pickaxe")
	if not starterPickaxeModel then
		warn("Starter Pickaxe model not found in ReplicatedStorage!")
		return
	end

	-- Clone the pickaxe model
	local newPickaxe = starterPickaxeModel:Clone()
	newPickaxe.Name = pickaxe.Name .. " (" .. pickaxe.Rarity .. ")"

	-- Ensure attributes are only added to the root tool, not its children
	for _, child in pairs(newPickaxe:GetDescendants()) do
		if child:IsA("IntValue") or child:IsA("StringValue") then
			child:Destroy()
		end
	end

	local miningSizeValue = Instance.new("IntValue")
	miningSizeValue.Name = "MiningSize"
	miningSizeValue.Value = pickaxe.MiningSize
	miningSizeValue.Parent = newPickaxe

	local durabilityValue = Instance.new("IntValue")
	durabilityValue.Name = "Durability"
	durabilityValue.Value = pickaxe.Durability
	durabilityValue.Parent = newPickaxe

	local rarityValue = Instance.new("StringValue")
	rarityValue.Name = "Rarity"
	rarityValue.Value = pickaxe.Rarity
	rarityValue.Parent = newPickaxe

	local pickaxeIdValue = Instance.new("StringValue")
	pickaxeIdValue.Name = "PickaxeId"
	pickaxeIdValue.Value = pickaxe.PickaxeId
	pickaxeIdValue.Parent = newPickaxe

	-- Place the pickaxe in the player's Backpack
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		newPickaxe.Parent = backpack
		print("Granted new pickaxe to player:", pickaxe.Name, "with ID:", pickaxe.PickaxeId, ", MiningSize:", pickaxe.MiningSize, ", Rarity:", pickaxe.Rarity, ", and Durability:", pickaxe.Durability)
	else
		warn("Player's Backpack not found!")
	end

	-- Add the pickaxe to the player's Data.Pickaxes folder
	local dataFolder = player:FindFirstChild("Data")
	if not dataFolder then
		dataFolder = Instance.new("Folder")
		dataFolder.Name = "Data"
		dataFolder.Parent = player
	end

	local pickaxesFolder = dataFolder:FindFirstChild("Pickaxes") or Instance.new("Folder")
	pickaxesFolder.Name = "Pickaxes"
	pickaxesFolder.Parent = dataFolder

	local pickaxeDataFolder = pickaxesFolder:FindFirstChild(pickaxe.PickaxeId) or Instance.new("Folder")
	pickaxeDataFolder.Name = pickaxe.PickaxeId
	pickaxeDataFolder.Parent = pickaxesFolder

	local durabilityData = pickaxeDataFolder:FindFirstChild("Durability") or Instance.new("IntValue")
	durabilityData.Name = "Durability"
	durabilityData.Value = pickaxe.Durability
	durabilityData.Parent = pickaxeDataFolder

	local miningSizeData = pickaxeDataFolder:FindFirstChild("MiningSize") or Instance.new("IntValue")
	miningSizeData.Name = "MiningSize"
	miningSizeData.Value = pickaxe.MiningSize
	miningSizeData.Parent = pickaxeDataFolder

	local rarityData = pickaxeDataFolder:FindFirstChild("Rarity") or Instance.new("StringValue")
	rarityData.Name = "Rarity"
	rarityData.Value = pickaxe.Rarity
	rarityData.Parent = pickaxeDataFolder

	print("Added pickaxe to Data.Pickaxes for player:", player.Name)
end

-- Event listener for RequestRandomPickaxeEvent
local RequestRandomPickaxeEvent = ReplicatedStorage:FindFirstChild("RequestRandomPickaxeEvent")
if RequestRandomPickaxeEvent then
	RequestRandomPickaxeEvent.OnServerEvent:Connect(function(player)
		print("RequestRandomPickaxeEvent received from player:", player.Name)

		-- Roll for a random pickaxe using PickaxeUtils
		local name, miningSize, durability, rarity, pickaxeId = PickaxeUtils.rollPickaxe()
		print("Rolled random pickaxe for player:", player.Name, "with ID:", pickaxeId, ", MiningSize:", miningSize, ", Rarity:", rarity, ", and Durability:", durability)

		-- Grant the rolled pickaxe to the player
		grantPickaxeToPlayer(player, {
			Name = name,
			MiningSize = miningSize,
			Durability = durability,
			Rarity = rarity,
			PickaxeId = pickaxeId
		})

		-- FIRE UI UPDATE EVENT AFTER GRANTING PICKAXE
		inventoryUpdateEvent:FireClient(player)
		print("[SERVER] Fired InventoryUpdateEvent for", player.Name, "after granting pickaxe")
	end)
else
	warn("RequestRandomPickaxeEvent not found in ReplicatedStorage!")
end