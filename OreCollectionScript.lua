-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- RemoteEvent for ore collection
local OreCollectionEvent = ReplicatedStorage:FindFirstChild("OreCollectionEvent") or Instance.new("RemoteEvent")
OreCollectionEvent.Name = "OreCollectionEvent"
OreCollectionEvent.Parent = ReplicatedStorage

local OreDefinitions = require(game:GetService("ReplicatedStorage"):WaitForChild("OreDefinitions"))
local validOres = OreDefinitions.validOres

local function collectOre(player, oreType, quantity)
	-- Debugging: Start of function
	print("[collectOre] Function called for player:", player.Name, "Ore Type:", oreType, "Quantity:", quantity)

	-- Validate ore type
	if not validOres[oreType] then
		warn("[collectOre] Invalid ore type:", oreType)
		return
	end

	-- Validate quantity
	if type(quantity) ~= "number" or quantity <= 0 then
		warn("[collectOre] Invalid quantity:", quantity)
		return
	end

	-- Ensure the player has an Inventory folder
	local inventory = player:FindFirstChild("Inventory")
	if not inventory then
		inventory = Instance.new("Folder")
		inventory.Name = "Inventory"
		inventory.Parent = player
		print("[collectOre] Created Inventory folder for player:", player.Name)
	end

	-- Add the collected ores to the Inventory folder
	local oreItem = inventory:FindFirstChild(oreType)
	if oreItem then
		oreItem.Value += quantity -- Update the quantity if the ore already exists
		print("[collectOre] Updated Inventory: " .. player.Name .. " now has " .. oreItem.Value .. " of " .. oreType)
	else
		-- Create a new IntValue for the collected ore if it doesn't exist
		oreItem = Instance.new("IntValue")
		oreItem.Name = oreType
		oreItem.Value = quantity
		oreItem.Parent = inventory
		print("[collectOre] Added new ore to Inventory: " .. player.Name .. " collected " .. oreType .. ". Quantity: " .. oreItem.Value)
	end

	-- Update the player's Data.Ores folder for persistence
	local playerData = player:FindFirstChild("Data")
	if playerData then
		local oresFolder = playerData:FindFirstChild("Ores")
		if not oresFolder then
			oresFolder = Instance.new("Folder")
			oresFolder.Name = "Ores"
			oresFolder.Parent = playerData
			print("[collectOre] Created Ores folder in Data for player:", player.Name)
		end

		-- Update or create the ore data
		local oreData = oresFolder:FindFirstChild(oreType)
		if oreData then
			oreData.Value += quantity -- Update the ore count in Data
			print("[collectOre] Updated Data: " .. player.Name .. " now has " .. oreData.Value .. " of " .. oreType .. " in Data.")
		else
			-- Create a new IntValue in Data if it doesn't exist
			oreData = Instance.new("IntValue")
			oreData.Name = oreType
			oreData.Value = quantity
			oreData.Parent = oresFolder
			print("[collectOre] Added new ore to Data: " .. player.Name .. " collected " .. oreType .. ". Total: " .. oreData.Value)
		end
	else
		warn("[collectOre] No Data folder found for player:", player.Name)
	end
end

local function normalizeOreName(oreName)
	return oreName:sub(1, 1):upper() .. oreName:sub(2):lower()
end

OreCollectionEvent.OnServerEvent:Connect(function(player, oreType, quantity)
	oreType = normalizeOreName(oreType) -- Normalize the ore name
	print("[OreCollectionEvent] Triggered by player:", player.Name, "Ore Type:", oreType, "Quantity:", quantity)
	collectOre(player, oreType, quantity)
end)
