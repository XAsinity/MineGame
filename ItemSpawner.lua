local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local ItemSpawner = {}

-- A DataStore to track all globally assigned UniqueIDs
local uniqueIDStore = DataStoreService:GetDataStore("UniqueIDStore")

-- Helper: Generate a globally unique chest ID
function ItemSpawner.generateUniqueChestID(player)
	local uniqueID
	repeat
		-- Use a combination of JobId, timestamp, and random number
		local jobId = game.JobId or "UnknownJob" -- Unique ID for the server
		local timestamp = os.time() -- Current time in seconds
		local randomPart = math.random(1, 1e9) -- Random component
		uniqueID = tostring(jobId) .. "-" .. tostring(timestamp) .. "-" .. tostring(randomPart)

		-- Check with the DataStore if the ID is already used
		local success, exists = pcall(function()
			return uniqueIDStore:GetAsync(uniqueID)
		end)
		if not success then
			warn("Error checking UniqueID in DataStore:", exists)
		end
	until not exists

	-- Save the new UniqueID to the DataStore
	local success, err = pcall(function()
		uniqueIDStore:SetAsync(uniqueID, true)
	end)
	if not success then
		warn("Error saving UniqueID to DataStore:", err)
	end

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

	-- Generate and assign a globally unique ID to the chest
	local uniqueID = ItemSpawner.generateUniqueChestID()
	local chestIDValue = Instance.new("StringValue")
	chestIDValue.Name = "UniqueID"
	chestIDValue.Value = uniqueID
	chestIDValue.Parent = chest

	print("Spawned chest with UniqueID:", uniqueID, "at position:", chest.Position)

	chest.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
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