local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local InventoryModule = require(ServerScriptService:WaitForChild("InventoryModule"))

local defaultOres = {"Gold", "Copper", "Coal", "Iron"}

-- Debug function to print all instances of a Coins value
local function debugCoinsPlacement(player)
	local dataFolder = player:FindFirstChild("Data")
	if dataFolder then
		for _, child in pairs(dataFolder:GetDescendants()) do
			if child.Name == "Coins" then
				print("Coins found in:", child.Parent.Name, "Parent's Parent:", child.Parent.Parent and child.Parent.Parent.Name or "None")
			end
		end
	end
end

-- Debugging: print inventory and backpack contents (fixes for folders)
local function debugInventoryAndBackpack(player)
	local inventory = player:FindFirstChild("Inventory")
	if not inventory then
		warn("[DEBUG] No Inventory found for", player.Name)
	else
		print("[DEBUG] Inventory contents for", player.Name, ":")
		for _, child in ipairs(inventory:GetChildren()) do
			print("    [Inventory]", child.Name, child.ClassName)
			if child:IsA("Folder") then
				for _, sub in ipairs(child:GetChildren()) do
					if sub:IsA("ValueBase") then
						print("        [Sub]", sub.Name, sub.ClassName, "[Value: " .. tostring(sub.Value) .. "]")
					else
						print("        [Sub]", sub.Name, sub.ClassName)
					end
				end
			end
		end
	end
	-- Backpack debug is safe to keep, but does not equip or manipulate tools!
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then
		warn("[DEBUG] No Backpack found for", player.Name)
	else
		print("[DEBUG] Backpack tools for", player.Name, ":")
		for _, tool in ipairs(backpack:GetChildren()) do
			print("    [Backpack]", tool.Name, tool.ClassName)
			for _, stat in ipairs(tool:GetChildren()) do
				if stat:IsA("ValueBase") then
					print("        [ToolStat]", stat.Name, stat.ClassName, "[Value: " .. tostring(stat.Value) .. "]")
				else
					print("        [ToolStat]", stat.Name, stat.ClassName)
				end
			end
		end
	end
end

-- Function to ensure the player's Data folder and nested folders exist
local function initializePlayerData(player)
	local dataFolder = player:FindFirstChild("Data")
	if not dataFolder then
		dataFolder = Instance.new("Folder")
		dataFolder.Name = "Data"
		dataFolder.Parent = player
	end

	local coins = dataFolder:FindFirstChild("Coins")
	if not coins then
		coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Value = 0
		coins.Parent = dataFolder
		print("Coins value created directly in Data folder for player:", player.Name)
	end

	local pickaxeFolder = dataFolder:FindFirstChild("Pickaxe")
	if pickaxeFolder then
		pickaxeFolder:Destroy()
	end

	local pickaxesFolder = dataFolder:FindFirstChild("Pickaxes")
	if not pickaxesFolder then
		pickaxesFolder = Instance.new("Folder")
		pickaxesFolder.Name = "Pickaxes"
		pickaxesFolder.Parent = dataFolder
		print("Pickaxes folder created for player:", player.Name)
	end

	local oresFolder = dataFolder:FindFirstChild("Ores")
	if not oresFolder then
		oresFolder = Instance.new("Folder")
		oresFolder.Name = "Ores"
		oresFolder.Parent = dataFolder
		print("Ores folder created for player:", player.Name)
	end

	for _, oreName in ipairs(defaultOres) do
		if not oresFolder:FindFirstChild(oreName) then
			local oreValue = Instance.new("IntValue")
			oreValue.Name = oreName
			oreValue.Value = 0
			oreValue.Parent = oresFolder
			print("Ore value created:", oreName, "for player:", player.Name)
		end
	end

	local chestsFolder = dataFolder:FindFirstChild("Chests")
	if not chestsFolder then
		chestsFolder = Instance.new("Folder")
		chestsFolder.Name = "Chests"
		chestsFolder.Parent = dataFolder
		print("Chests folder created for player:", player.Name)
	end

	debugCoinsPlacement(player)
end

-- Function to ensure the player's Inventory folder and nested folders/values exist and mirror Data
local function initializePlayerInventory(player)
	InventoryModule.setupPlayerInventory(player)
end

-- Function to copy Data values/folders into Inventory for UI
local function syncInventoryWithData(player)
	InventoryModule.syncInventoryWithData(player)
end

-- Function to give the player a Starter Pickaxe (to Data.Pickaxes only)
local function giveStarterPickaxe(player)
	local pickaxesFolder = player:FindFirstChild("Data") and player.Data:FindFirstChild("Pickaxes")
	if pickaxesFolder and not pickaxesFolder:FindFirstChild("Starter Pickaxe") then
		local starterData = Instance.new("Folder")
		starterData.Name = "Starter Pickaxe"
		local miningSize = Instance.new("IntValue")
		miningSize.Name = "MiningSize"
		miningSize.Value = 1
		miningSize.Parent = starterData
		local durability = Instance.new("IntValue")
		durability.Name = "Durability"
		durability.Value = 100
		durability.Parent = starterData
		local rarity = Instance.new("StringValue")
		rarity.Name = "Rarity"
		rarity.Value = "Common"
		rarity.Parent = starterData
		starterData.Parent = pickaxesFolder
		print("Starter Pickaxe given to player:", player.Name)
	end
end

Players.PlayerAdded:Connect(function(player)
	initializePlayerData(player)
	initializePlayerInventory(player)
	local pickaxesFolder = player:FindFirstChild("Data") and player.Data:FindFirstChild("Pickaxes")
	if pickaxesFolder and #pickaxesFolder:GetChildren() == 0 then
		giveStarterPickaxe(player)
	end
	syncInventoryWithData(player)
	debugInventoryAndBackpack(player)
end)