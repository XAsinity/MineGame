local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local OreDefinitions = require(ReplicatedStorage:WaitForChild("OreDefinitions"))
local PickaxeUtils = require(ReplicatedStorage:WaitForChild("PickaxeUtils"))
local ToolDefinitions = require(ReplicatedStorage:WaitForChild("ToolDefinitions"))

local InventoryModule = {}

local validOres = OreDefinitions.validOres

-- === FULL LIST OF ORES (update here if new ores are added) ===
local ALL_ORE_TYPES = {"Gold", "Copper", "Coal", "Iron", "Diamonds", "Lead", "Nickel"}
local DEFAULT_ORES = ALL_ORE_TYPES

-- === Utility Debugging ===

local function debugInventory(player)
	local inventory = player:FindFirstChild("Inventory")
	if not inventory then
		warn("[DEBUG] No Inventory found for", player.Name)
		return
	end
	print("[DEBUG] Inventory for", player.Name)
	for _, child in ipairs(inventory:GetChildren()) do
		print("    [Inventory]", child.Name, child.ClassName)
		if child:IsA("Folder") then
			for _, sub in ipairs(child:GetChildren()) do
				if sub:IsA("ValueBase") then
					print("        [Sub]", sub.Name, sub.ClassName, "[Value: "..tostring(sub.Value).."]")
				else
					print("        [Sub]", sub.Name, sub.ClassName)
				end
			end
		end
	end
end

local function debugBackpack(player)
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then
		warn("[DEBUG] No Backpack found for", player.Name)
		return
	end
	print("[DEBUG] Backpack for", player.Name)
	for _, tool in ipairs(backpack:GetChildren()) do
		print("    [Backpack]", tool.Name, tool.ClassName)
		for _, stat in ipairs(tool:GetChildren()) do
			if stat:IsA("ValueBase") then
				print("        [ToolStat]", stat.Name, stat.ClassName, "[Value: "..tostring(stat.Value).."]")
			else
				print("        [ToolStat]", stat.Name, stat.ClassName)
			end
		end
	end
end

-- === Inventory Setup ===

function InventoryModule.setupPlayerInventory(player)
	local inventory = player:FindFirstChild("Inventory")
	if not inventory then
		inventory = Instance.new("Folder")
		inventory.Name = "Inventory"
		inventory.Parent = player

		-- Add all ores as IntValues
		for _, oreName in ipairs(ALL_ORE_TYPES) do
			local ore = Instance.new("IntValue")
			ore.Name = oreName
			ore.Value = 0
			ore.Parent = inventory
		end

		local chestsFolder = Instance.new("Folder")
		chestsFolder.Name = "Chests"
		chestsFolder.Parent = inventory

		local pickaxesFolder = Instance.new("Folder")
		pickaxesFolder.Name = "Pickaxes"
		pickaxesFolder.Parent = inventory

		print("[DEBUG] Inventory folder created for player:", player.Name)
		debugInventory(player)
	else
		-- Ensure all ores exist even if inventory was created before the update
		for _, oreName in ipairs(ALL_ORE_TYPES) do
			if not inventory:FindFirstChild(oreName) then
				local ore = Instance.new("IntValue")
				ore.Name = oreName
				ore.Value = 0
				ore.Parent = inventory
				print("[DEBUG] Added missing ore to Inventory:", oreName, "for player:", player.Name)
			end
		end
		print("[DEBUG] Inventory already exists for player:", player.Name)
	end
end

-- === Pickaxe Management ===

function InventoryModule.hasReachedPickaxeLimit(player)
	local inventory = player:FindFirstChild("Inventory")
	if not inventory then
		warn("[DEBUG] No Inventory found for hasReachedPickaxeLimit check on", player.Name)
		return false
	end
	local pickaxesFolder = inventory:FindFirstChild("Pickaxes")
	if not pickaxesFolder then
		warn("[DEBUG] No Pickaxes folder found in Inventory for hasReachedPickaxeLimit check on", player.Name)
		return false
	end
	return #pickaxesFolder:GetChildren() >= 20
end

function InventoryModule.initializePickaxe(pickaxeFolder, pickaxeName, miningSize, durability, rarity, pickaxeId)
	pickaxeFolder.Name = pickaxeName

	local miningSizeValue = pickaxeFolder:FindFirstChild("MiningSize") or Instance.new("IntValue", pickaxeFolder)
	miningSizeValue.Name = "MiningSize"
	miningSizeValue.Value = miningSize or 0

	local durabilityValue = pickaxeFolder:FindFirstChild("Durability") or Instance.new("IntValue", pickaxeFolder)
	durabilityValue.Name = "Durability"
	durabilityValue.Value = durability or 0

	local rarityValue = pickaxeFolder:FindFirstChild("Rarity") or Instance.new("StringValue", pickaxeFolder)
	rarityValue.Name = "Rarity"
	rarityValue.Value = rarity or "Unknown"

	local idValue = pickaxeFolder:FindFirstChild("PickaxeId") or Instance.new("StringValue", pickaxeFolder)
	idValue.Name = "PickaxeId"
	idValue.Value = pickaxeId or ""

	print("[DEBUG] Initialized pickaxe stats:", pickaxeName, "MiningSize:", miningSizeValue.Value, "Durability:", durabilityValue.Value, "Rarity:", rarityValue.Value, "PickaxeId:", idValue.Value)
end

function InventoryModule.addPickaxeToInventory(player, pickaxeName, miningSize, durability, rarity, pickaxeId)
	local inventory = player:FindFirstChild("Inventory")
	if not inventory then
		warn("[DEBUG] Inventory not found for player:", player.Name)
		return
	end

	local pickaxesFolder = inventory:FindFirstChild("Pickaxes")
	if not pickaxesFolder then
		warn("[DEBUG] Pickaxes folder not found for player:", player.Name)
		return
	end

	if InventoryModule.hasReachedPickaxeLimit(player) then
		warn("[DEBUG] Cannot add pickaxe: Player has reached the pickaxe limit!")
		return
	end

	local newPickaxe = Instance.new("Folder", pickaxesFolder)
	InventoryModule.initializePickaxe(newPickaxe, pickaxeName, miningSize, durability, rarity, pickaxeId)
	print("[DEBUG] Added new pickaxe to inventory:", pickaxeName, "for player:", player.Name)
	debugInventory(player)
end

function InventoryModule.removePickaxeFromInventory(player, pickaxeName)
	local inventory = player:FindFirstChild("Inventory")
	if not inventory then
		warn("[DEBUG] No Inventory found for removePickaxeFromInventory on", player.Name)
		return
	end
	local pickaxesFolder = inventory:FindFirstChild("Pickaxes")
	if not pickaxesFolder then
		warn("[DEBUG] No Pickaxes folder in Inventory for removePickaxeFromInventory on", player.Name)
		return
	end

	local function deletePickaxe()
		local pickaxe = pickaxesFolder:FindFirstChild(pickaxeName)
		if pickaxe then
			pickaxe:Destroy()
			print("[DEBUG] Pickaxe completely removed from inventory:", pickaxeName, "for player:", player.Name)
		end
	end

	deletePickaxe()
	task.wait(0.1)
	deletePickaxe()

	local remainingPickaxe = pickaxesFolder:FindFirstChild(pickaxeName)
	if remainingPickaxe then
		print("[DEBUG] Pickaxe still exists in inventory after deletion attempts. Forcing removal:", pickaxeName)
		remainingPickaxe:Destroy()
	else
		print("[DEBUG] Pickaxe successfully removed from inventory after verification:", pickaxeName)
	end
	debugInventory(player)
end

-- === Pickaxe Equip Logic (Backpack) ===

function InventoryModule.equipPickaxe(player, pickaxeName)
	local pickaxesFolder = player:FindFirstChild("Data") and player.Data:FindFirstChild("Pickaxes")
	if not pickaxesFolder then
		warn("[DEBUG] No Pickaxes data folder! Cannot equip pickaxe for", player.Name)
		return
	end

	local pickaxeData = pickaxesFolder:FindFirstChild(pickaxeName)
	if not pickaxeData then
		warn("[DEBUG] No such pickaxe in data:", pickaxeName, "for", player.Name)
		return
	end

	-- Remove any existing pickaxe tools from backpack
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then
		warn("[DEBUG] No Backpack found for", player.Name, "when equipping pickaxe")
		return
	end

	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			tool:Destroy()
		end
	end

	-- Find the template tool in ReplicatedStorage
	local toolTemplate = ReplicatedStorage:FindFirstChild("Starter Pickaxe")
	if not toolTemplate then
		warn("[DEBUG] No pickaxe tool template found for", pickaxeName, "when equipping for", player.Name)
		return
	end

	-- Clone, set up stats, and parent to backpack
	local tool = toolTemplate:Clone()
	tool.Name = pickaxeData.Name
	for _, statName in ipairs({"MiningSize", "Durability", "Rarity", "PickaxeId"}) do
		local valueObj = pickaxeData:FindFirstChild(statName)
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
	print("[DEBUG] Equipped pickaxe '" .. pickaxeName .. "' to " .. player.Name .. "'s Backpack")
	debugBackpack(player)
end

-- === Chest Management, Inventory/Data Sync, Item Collection (unchanged) ===

function InventoryModule.addChestToInventory(player, chestName)
	local dataFolder = player:FindFirstChild("Data")
	if not dataFolder then
		warn("[DEBUG] addChestToInventory: Data folder not found for player:", player.Name)
		return
	end
	local dataChests = dataFolder:FindFirstChild("Chests")
	if not dataChests then
		dataChests = Instance.new("Folder")
		dataChests.Name = "Chests"
		dataChests.Parent = dataFolder
	end

	local chestValue = dataChests:FindFirstChild(chestName)
	if chestValue then
		chestValue.Value += 1
	else
		chestValue = Instance.new("IntValue")
		chestValue.Name = chestName
		chestValue.Value = 1
		chestValue.Parent = dataChests
	end

	InventoryModule.syncInventoryWithData(player)

	print("[DEBUG] Chest added:", chestName, "for player:", player.Name)
	debugInventory(player)
end

function InventoryModule.removeChestFromInventory(player, chestName, removeCompletely)
	local dataFolder = player:FindFirstChild("Data")
	if not dataFolder then
		warn("[DEBUG] removeChestFromInventory: Data folder not found for player:", player.Name)
		return
	end
	local dataChests = dataFolder:FindFirstChild("Chests")
	if not dataChests then
		warn("[DEBUG] removeChestFromInventory: No Chests folder in Data for player:", player.Name)
		return
	end

	local function deleteDataChest()
		local chest = dataChests:FindFirstChild(chestName)
		if chest then
			if removeCompletely then
				chest:Destroy()
				print("[DEBUG] Chest completely removed from data:", chestName, "for player:", player.Name)
			elseif chest:IsA("IntValue") then
				chest.Value = math.max(chest.Value - 1, 0)
				if chest.Value == 0 then
					chest:Destroy()
					print("[DEBUG] Chest removed from data after count reached 0:", chestName, "for player:", player.Name)
				end
			end
		end
	end

	deleteDataChest()
	task.wait(0.1)
	deleteDataChest()

	local remainingChest = dataChests:FindFirstChild(chestName)
	if remainingChest then
		print("[DEBUG] Chest still exists in data after deletion attempts. Forcing removal:", chestName)
		remainingChest:Destroy()
	else
		print("[DEBUG] Chest successfully removed from data after verification:", chestName)
	end

	InventoryModule.syncInventoryWithData(player)
	debugInventory(player)
end

function InventoryModule.syncInventoryWithData(player)
	local inventory = player:FindFirstChild("Inventory")
	local dataFolder = player:FindFirstChild("Data")
	if not (inventory and dataFolder) then
		warn("[DEBUG] Cannot sync Inventory: missing Data or Inventory folder for player", player.Name)
		return
	end

	-- --- Sync Ores (ALL ORES) ---
	local oresFolder = dataFolder:FindFirstChild("Ores")
	for _, oreName in ipairs(ALL_ORE_TYPES) do
		local dataOre = oresFolder and oresFolder:FindFirstChild(oreName)
		local invOre = inventory:FindFirstChild(oreName)
		if invOre and dataOre then
			invOre.Value = dataOre.Value
		elseif invOre then
			invOre.Value = 0
		elseif dataOre then
			-- Inventory missing the ore, create it for safety
			local newInvOre = Instance.new("IntValue")
			newInvOre.Name = oreName
			newInvOre.Value = dataOre.Value
			newInvOre.Parent = inventory
			print("[DEBUG] (sync) Added missing ore to Inventory:", oreName, "for player:", player.Name)
		end
	end

	-- --- Sync Chests ---
	local chestsFolder = dataFolder:FindFirstChild("Chests")
	local invChestsFolder = inventory:FindFirstChild("Chests")
	for _, child in ipairs(invChestsFolder:GetChildren()) do
		child:Destroy()
	end
	if chestsFolder then
		for _, chestData in ipairs(chestsFolder:GetChildren()) do
			if chestData:IsA("IntValue") then
				local chestItem = Instance.new("IntValue")
				chestItem.Name = chestData.Name
				chestItem.Value = chestData.Value
				chestItem.Parent = invChestsFolder
			end
		end
	end
	for _, child in ipairs(inventory:GetChildren()) do
		if child:IsA("IntValue") and child.Name:match("^Chest_") then
			child:Destroy()
		end
	end

	-- --- Sync Pickaxes ---
	local pickaxesDataFolder = dataFolder:FindFirstChild("Pickaxes")
	local invPickaxesFolder = inventory:FindFirstChild("Pickaxes")
	for _, child in ipairs(invPickaxesFolder:GetChildren()) do
		child:Destroy()
	end
	if pickaxesDataFolder then
		for _, pickaxe in ipairs(pickaxesDataFolder:GetChildren()) do
			if pickaxe:IsA("Folder") then
				local invPickaxe = Instance.new("Folder")
				invPickaxe.Name = pickaxe.Name
				for _, statName in ipairs({"MiningSize", "Durability", "Rarity", "PickaxeId"}) do
					local dataStat = pickaxe:FindFirstChild(statName)
					if dataStat then
						local stat
						if dataStat:IsA("IntValue") then
							stat = Instance.new("IntValue")
						elseif dataStat:IsA("StringValue") then
							stat = Instance.new("StringValue")
						end
						if stat then
							stat.Name = statName
							stat.Value = dataStat.Value
							stat.Parent = invPickaxe
						end
					end
				end
				invPickaxe.Parent = invPickaxesFolder
			end
		end
	end

	print("[DEBUG] Synchronized Data to Inventory for player:", player.Name)
	debugInventory(player)
end

function InventoryModule.handleItemTouched(item, player, validOres)
	local inventory = player:FindFirstChild("Inventory")
	if not inventory then
		warn("[DEBUG] handleItemTouched: No inventory for player:", player.Name)
		return
	end

	if item:FindFirstChild("Collected") then return end

	local collectedFlag = Instance.new("BoolValue")
	collectedFlag.Name = "Collected"
	collectedFlag.Parent = item

	if item:IsA("BasePart") and item:FindFirstChild("UniqueID") then
		local uniqueID = item.UniqueID.Value
		local chestName = "Chest_" .. uniqueID

		InventoryModule.addChestToInventory(player, chestName)
		item:Destroy()
		print("[DEBUG]", player.Name, "collected chest with ID:", uniqueID)
		return
	end

	if item:IsA("BasePart") and validOres[item.Name] then
		local oreName = item.Name
		local oreItem = inventory:FindFirstChild(oreName)
		if oreItem then
			oreItem.Value += 1
			print("[DEBUG] Updated Inventory:", oreName, "now has", oreItem.Value, "for player:", player.Name)
		end
		InventoryModule.syncInventoryWithData(player)
		item:Destroy()
		print("[DEBUG]", player.Name, "collected:", oreName)
	end
	debugInventory(player)
end

return InventoryModule