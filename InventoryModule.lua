local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PickaxeUtils = require(ReplicatedStorage:WaitForChild("PickaxeUtils"))
local InventoryModule = {}

-- Grants a pickaxe to the player
function InventoryModule.grantPickaxeToPlayer(player, pickaxe)
	local starterPickaxeModel = ReplicatedStorage:FindFirstChild("Starter Pickaxe")
	if not starterPickaxeModel then
		warn("Starter Pickaxe model not found in ReplicatedStorage!")
		return
	end

	-- Clone the pickaxe model
	local newPickaxe = starterPickaxeModel:Clone()
	newPickaxe.Name = pickaxe.Name .. " (" .. pickaxe.Rarity .. ")"

	-- Update the MiningSize value
	local miningSizeValue = newPickaxe:FindFirstChild("MiningSize")
	if miningSizeValue then
		miningSizeValue.Value = pickaxe.MiningSize -- Assign the randomized mining size
		print("MiningSize updated to:", miningSizeValue.Value)
	else
		-- If MiningSize doesn't exist, create it
		miningSizeValue = Instance.new("IntValue")
		miningSizeValue.Name = "MiningSize"
		miningSizeValue.Value = pickaxe.MiningSize
		miningSizeValue.Parent = newPickaxe
		warn("MiningSize value was missing. Created dynamically.")
	end

	-- Update the Rarity value
	local rarityValue = newPickaxe:FindFirstChild("Rarity")
	if rarityValue then
		rarityValue.Value = pickaxe.Rarity -- Assign the randomized rarity
		print("Rarity updated to:", rarityValue.Value)
	else
		-- If Rarity doesn't exist, create it
		rarityValue = Instance.new("StringValue")
		rarityValue.Name = "Rarity"
		rarityValue.Value = pickaxe.Rarity
		rarityValue.Parent = newPickaxe
		warn("Rarity value was missing. Created dynamically.")
	end

	-- Update the Durability value
	local durabilityValue = newPickaxe:FindFirstChild("Durability")
	if durabilityValue then
		durabilityValue.Value = pickaxe.Durability -- Assign the randomized durability
		print("Durability updated to:", durabilityValue.Value)
	else
		-- If Durability doesn't exist, create it
		durabilityValue = Instance.new("IntValue")
		durabilityValue.Name = "Durability"
		durabilityValue.Value = pickaxe.Durability
		durabilityValue.Parent = newPickaxe
		warn("Durability value was missing. Created dynamically.")
	end

	-- Add the pickaxe to the player's Backpack
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		newPickaxe.Parent = backpack
		print("Granted new pickaxe to player:", pickaxe.Name, "with MiningSize:", miningSizeValue.Value, ", Rarity:", rarityValue.Value, ", and Durability:", durabilityValue.Value)
	else
		warn("Player's Backpack not found!")
	end
end

-- Synchronize Inventory with Data folders (Ores, Chests, Pickaxes)
function InventoryModule.syncInventoryWithData(player)
	local inventory = player:FindFirstChild("Inventory")
	local dataFolder = player:FindFirstChild("Data")

	if inventory and dataFolder then
		-- Synchronize from Data.Chests to Inventory
		local chestsFolder = dataFolder:FindFirstChild("Chests")
		if chestsFolder then
			for _, chestData in pairs(chestsFolder:GetChildren()) do
				if chestData:IsA("IntValue") then
					local chestItem = inventory:FindFirstChild(chestData.Name)
					if chestItem then
						chestItem.Value = chestData.Value
					else
						chestItem = Instance.new("IntValue")
						chestItem.Name = chestData.Name
						chestItem.Value = chestData.Value
						chestItem.Parent = inventory
					end
				end
			end
		else
			warn("Chests folder not found for player:", player.Name)
		end

		-- Synchronize from Data.Ores to Inventory
		local oresFolder = dataFolder:FindFirstChild("Ores")
		if oresFolder then
			for _, oreData in pairs(oresFolder:GetChildren()) do
				if oreData:IsA("IntValue") then
					local oreItem = inventory:FindFirstChild(oreData.Name)
					if oreItem then
						oreItem.Value = oreData.Value
					else
						oreItem = Instance.new("IntValue")
						oreItem.Name = oreData.Name
						oreItem.Value = oreData.Value
						oreItem.Parent = inventory
					end
				end
			end
		else
			warn("Ores folder not found for player:", player.Name)
		end

		-- Synchronize from Data.Pickaxes to Inventory
		local pickaxesFolder = dataFolder:FindFirstChild("Pickaxes")
		if pickaxesFolder then
			for _, pickaxe in pairs(pickaxesFolder:GetChildren()) do
				local pickaxeItem = inventory:FindFirstChild(pickaxe.Name)
				if not pickaxeItem then
					pickaxeItem = Instance.new("Folder")
					pickaxeItem.Name = pickaxe.Name
					pickaxeItem.Parent = inventory

					-- Add MiningSize
					local miningSize = pickaxe:FindFirstChild("MiningSize")
					if miningSize then
						local miningSizeValue = Instance.new("IntValue")
						miningSizeValue.Name = "MiningSize"
						miningSizeValue.Value = miningSize.Value
						miningSizeValue.Parent = pickaxeItem
					end

					-- Add Durability
					local durability = pickaxe:FindFirstChild("Durability")
					if durability then
						local durabilityValue = Instance.new("IntValue")
						durabilityValue.Name = "Durability"
						durabilityValue.Value = durability.Value
						durabilityValue.Parent = pickaxeItem
					end

					-- Add Rarity
					local rarity = pickaxe:FindFirstChild("Rarity")
					if rarity then
						local rarityValue = Instance.new("StringValue")
						rarityValue.Name = "Rarity"
						rarityValue.Value = rarity.Value
						rarityValue.Parent = pickaxeItem
					end
				end
			end
		else
			warn("Pickaxes folder not found for player:", player.Name)
		end

		print("Synchronized Data to Inventory for player:", player.Name)
	else
		warn("Inventory or Data folder missing for player:", player.Name)
	end
end

-- Handle item collection (distinguishing ores and chests)
function InventoryModule.handleItemTouched(item, player, validOres)
	local inventory = player:FindFirstChild("Inventory")

	if not inventory then
		warn("Inventory folder missing for player:", player.Name)
		return
	end

	if item:FindFirstChild("Collected") then
		return
	end

	local collectedFlag = Instance.new("BoolValue")
	collectedFlag.Name = "Collected"
	collectedFlag.Parent = item

	-- Check if the item is a chest
	if item:IsA("BasePart") and item:FindFirstChild("UniqueID") then
		local uniqueID = item.UniqueID.Value
		local chestName = "Chest_" .. uniqueID

		local chestItem = inventory:FindFirstChild(chestName)
		if chestItem then
			chestItem.Value += 1
			print("Updated Inventory: " .. chestName .. " now has " .. chestItem.Value)
		else
			local newChestItem = Instance.new("IntValue")
			newChestItem.Name = chestName
			newChestItem.Value = 1
			newChestItem.Parent = inventory
			print("Added new chest to Inventory: " .. chestName)
		end

		InventoryModule.syncInventoryWithData(player)

		item:Destroy()
		print(player.Name .. " collected chest with ID:", uniqueID)
		return
	end

	-- Check if the item is an ore
	if item:IsA("BasePart") and validOres[item.Name] then
		local oreName = item.Name
		local oreItem = inventory:FindFirstChild(oreName)
		if oreItem then
			oreItem.Value += 1
			print("Updated Inventory: " .. oreName .. " now has " .. oreItem.Value)
		else
			warn("Ore type not found in Inventory: " .. oreName)
		end

		InventoryModule.syncInventoryWithData(player)

		item:Destroy()
		print(player.Name .. " collected: " .. oreName)
	else
		warn("Unhandled item type:", item.Name)
	end
end

return InventoryModule