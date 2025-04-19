local InventoryModule = {}

-- Synchronize Inventory with Data folders (Ores and Chests)
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

		print("Synchronized Data to Inventory for player:", player.Name) -- Debugging log
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

	-- Prevent duplicate processing by marking the item as collected
	if item:FindFirstChild("Collected") then
		return -- Exit early if the item has already been processed
	end

	local collectedFlag = Instance.new("BoolValue")
	collectedFlag.Name = "Collected"
	collectedFlag.Parent = item

	-- Check if the item is a chest
	if item:IsA("BasePart") and item:FindFirstChild("UniqueID") then
		local uniqueID = item.UniqueID.Value
		local chestName = "Chest_" .. uniqueID

		-- Add the chest to the inventory
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

		-- Synchronize with Data folder
		InventoryModule.syncInventoryWithData(player)

		-- Destroy the chest after collection
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

		-- Synchronize with Data folder
		InventoryModule.syncInventoryWithData(player)

		-- Destroy the ore after collection
		item:Destroy()
		print(player.Name .. " collected: " .. oreName)
	else
		warn("Unhandled item type:", item.Name)
	end
end

return InventoryModule