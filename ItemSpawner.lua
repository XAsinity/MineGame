local Players = game:GetService("Players")

local ItemSpawner = {}

-- Helper: Generate a unique chest ID
function ItemSpawner.generateUniqueChestID(player)
	local inventory = player and player:FindFirstChild("Inventory")
	if not inventory then return math.random(1, 1e9) end

	local uniqueID
	repeat
		uniqueID = math.random(1, 1e9)
	until not inventory:FindFirstChild("Chest_" .. uniqueID)

	return uniqueID
end

-- Shared function to spawn an ore
function ItemSpawner.spawnOre(oreType, position, oresFolder)
	local ore = oreType.template:Clone()
	ore.Position = position
	ore.Anchored = true
	ore.Name = oreType.name
	ore.Parent = oresFolder

	print("Spawned ore:", ore.Name, "at position:", ore.Position)

	ore.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			local dataFolder = player:FindFirstChild("Data")
			if dataFolder then
				local oresSubFolder = dataFolder:FindFirstChild("Ores")
				if oresSubFolder then
					local oreValue = oresSubFolder:FindFirstChild(oreType.name)
					if oreValue then
						oreValue.Value += 1
						print(player.Name .. " collected " .. oreType.name .. " (x" .. oreValue.Value .. ")")
					else
						warn("Ore type not found in player's Ores folder:", oreType.name)
					end
				else
					warn("Ores folder not found in player's Data folder:", player.Name)
				end
			else
				warn("Data folder not found for player:", player.Name)
			end
			ore:Destroy()
		end
	end)
	return ore
end

function ItemSpawner.spawnChest(chestTemplate, position, chestsFolder, player)
	local chest = chestTemplate:Clone()
	chest.Position = position
	chest.Anchored = true
	chest.Parent = chestsFolder

	local uniqueID = ItemSpawner.generateUniqueChestID(player)
	local chestIDValue = Instance.new("IntValue")
	chestIDValue.Name = "UniqueID"
	chestIDValue.Value = uniqueID
	chestIDValue.Parent = chest

	print("Spawned chest with UniqueID:", uniqueID, "at position:", chest.Position)

	chest.Touched:Connect(function(hit)
		local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
		if player then
			local dataFolder = player:FindFirstChild("Data")
			local inventory = player:FindFirstChild("Inventory")

			if not dataFolder or not inventory then return end

			-- Ensure Chests folder in Data
			local chestsDataFolder = dataFolder:FindFirstChild("Chests")
			if not chestsDataFolder then
				chestsDataFolder = Instance.new("Folder")
				chestsDataFolder.Name = "Chests"
				chestsDataFolder.Parent = dataFolder
			end

			local chestName = "Chest_" .. uniqueID

			-- Update Data.Chests
			local dataChest = chestsDataFolder:FindFirstChild(chestName)
			if dataChest then
				dataChest.Value = dataChest.Value + 1
			else
				dataChest = Instance.new("IntValue")
				dataChest.Name = chestName
				dataChest.Value = 1
				dataChest.Parent = chestsDataFolder
			end

			-- Update Inventory (flat structure)
			local invChest = inventory:FindFirstChild(chestName)
			if invChest then
				invChest.Value = invChest.Value + 1
			else
				invChest = Instance.new("IntValue")
				invChest.Name = chestName
				invChest.Value = 1
				invChest.Parent = inventory
			end

			print(player.Name .. " collected chest with UniqueID:", uniqueID)
			chest:Destroy()
		end
	end)
	return chest
end

return ItemSpawner
