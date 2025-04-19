local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Import InventoryModule
local InventoryModule = require(ServerScriptService:WaitForChild("InventoryModule"))

-- Require OreDefinitions from ReplicatedStorage
local OreDefinitions = require(ReplicatedStorage:WaitForChild("OreDefinitions"))
local validOres = OreDefinitions.validOres

-- Get chest template from ReplicatedStorage
local chestTemplate = ReplicatedStorage:WaitForChild("Chest")

math.randomseed(os.time())

-- Generate a unique chest ID
local function generateUniqueChestID(player)
	local inventory = player:FindFirstChild("Inventory")
	if not inventory then return math.random(1, 1e9) end

	local uniqueID
	repeat
		uniqueID = math.random(1, 1e9)
	until not inventory:FindFirstChild("Chest_" .. uniqueID)

	return uniqueID
end

-- Centralized function to spawn items (ores or chests)
local function spawnItem(itemTemplate, itemType, position, parent, player)
	local item = itemTemplate:Clone()
	item.Name = itemType.name
	item.Parent = parent or Workspace
	item.Position = position

	-- Assign metadata for inventory tracking
	if itemType.isChest then
		local uniqueID = generateUniqueChestID(player)
		local uniqueIDValue = Instance.new("IntValue")
		uniqueIDValue.Name = "UniqueID"
		uniqueIDValue.Value = uniqueID
		uniqueIDValue.Parent = item
		print("Spawned chest with UniqueID:", uniqueID)
	else
		print("Spawned ore:", itemType.name)
	end

	-- Setup collision handling for ores only
	if not itemType.isChest then
		item.Touched:Connect(function(hit)
			local character = hit.Parent
			if character and character:FindFirstChild("Humanoid") then
				local player = Players:GetPlayerFromCharacter(character)
				if player then
					print("Item touched:", item.Name)

					-- Handle ore collection using InventoryModule
					if validOres[item.Name] then
						InventoryModule.handleOreCollection(item, player)
					else
						warn("Unknown item type touched:", item.Name)
					end
				end
			end
		end)
	end

	return item
end

local function spawnOresAndChestNearPlayer(player)
	local character = player.Character
	if not character then
		warn("Player character not found!")
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		warn("HumanoidRootPart not found for player:", player.Name)
		return
	end

	-- Position ores relative to the player
	local spawnPosition = humanoidRootPart.Position + Vector3.new(0, 5, 0)

	-- Spawn ores
	for oreName, oreData in pairs(validOres) do
		if type(oreData) == "table" and oreData.template then
			local ore = spawnItem(oreData.template, { name = oreName, isChest = false }, spawnPosition + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5)))
			print("Spawned ore:", oreName, "at position:", ore.Position)
		else
			warn("Invalid ore data for:", oreName)
		end
	end

	-- Position chest 10 studs forward and 5 studs above the player
	local forwardVector = humanoidRootPart.CFrame.LookVector * 10
	local upwardVector = Vector3.new(0, 5, 0)
	local chestSpawnPosition = humanoidRootPart.Position + forwardVector + upwardVector

	-- Spawn a chest
	local chest = spawnItem(chestTemplate, { name = "Chest", isChest = true }, chestSpawnPosition, nil, player)

	print("Spawned ores and a chest near player:", player.Name)
end

-- Event listener for spawning
local spawnOresEvent = ReplicatedStorage:WaitForChild("SpawnOresEvent")
spawnOresEvent.OnServerEvent:Connect(function(player)
	print(player.Name .. " triggered SpawnOresEvent.")
	spawnOresAndChestNearPlayer(player)
end)