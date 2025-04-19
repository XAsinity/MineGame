local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Require the centralized OreDefinitions module and InventoryModule
local OreDefinitions = require(ReplicatedStorage:WaitForChild("OreDefinitions"))
local InventoryModule = require(ServerScriptService:WaitForChild("InventoryModule"))

-- Use the validOres table from OreDefinitions
local validOres = OreDefinitions.validOres

-- Setup collision detection for items (ores and chests)
local function setupItemCollision(item)
	item.Touched:Connect(function(hit)
		local character = hit.Parent
		if character and character:FindFirstChild("Humanoid") then
			local player = Players:GetPlayerFromCharacter(character)
			if player then
				print("Item touched:", item.Name) -- Debugging log
				InventoryModule.handleItemTouched(item, player, validOres)
			end
		end
	end)
	print("Collision handler set up for item:", item.Name) -- Debugging log
end

-- Setup inventory for players
local function setupPlayerInventory(player)
	-- Create the Inventory folder
	local inventory = Instance.new("Folder")
	inventory.Name = "Inventory"
	inventory.Parent = player

	-- Pre-populate Inventory with ores
	for oreName in pairs(validOres) do
		local ore = Instance.new("IntValue")
		ore.Name = oreName
		ore.Value = 0
		ore.Parent = inventory
	end

	print("Inventory folder created for player:", player.Name)
end

-- Initialize the system
local function initialize()
	Players.PlayerAdded:Connect(function(player)
		-- Setup inventory for the player when they join
		setupPlayerInventory(player)

		-- Synchronize inventory with saved data
		player.CharacterAdded:Connect(function()
			InventoryModule.syncInventoryWithData(player)
		end)
	end)

	-- Setup collision detection for ores and chests added to the Workspace
	Workspace.ChildAdded:Connect(function(child)
		if child:IsA("BasePart") then
			if validOres[child.Name] or child.Name == "Chest" then
				setupItemCollision(child)
			end
		end
	end)
end

initialize()