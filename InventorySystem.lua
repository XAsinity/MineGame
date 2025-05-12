local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local OreDefinitions = require(ReplicatedStorage:WaitForChild("OreDefinitions"))
local InventoryModule = require(ServerScriptService:WaitForChild("InventoryModule"))
local ToolDefinitions = require(ReplicatedStorage:WaitForChild("ToolDefinitions")) -- Add this line

local validOres = OreDefinitions.validOres

local function setupItemCollision(item)
	item.Touched:Connect(function(hit)
		local character = hit.Parent
		if character and character:FindFirstChild("Humanoid") then
			local player = Players:GetPlayerFromCharacter(character)
			if player then
				print("Item touched:", item.Name)
				InventoryModule.handleItemTouched(item, player, validOres)
			end
		end
	end)
	print("Collision handler set up for item:", item.Name)
end

local function setupPlayerInventory(player)
	local inventory = Instance.new("Folder")
	inventory.Name = "Inventory"
	inventory.Parent = player

	for oreName in pairs(validOres) do
		local ore = Instance.new("IntValue")
		ore.Name = oreName
		ore.Value = 0
		ore.Parent = inventory
	end

	print("Inventory folder created for player:", player.Name)
end

local function initialize()
	Players.PlayerAdded:Connect(function(player)
		setupPlayerInventory(player)
		player.CharacterAdded:Connect(function()
			InventoryModule.syncInventoryWithData(player)
		end)
	end)

	Workspace.ChildAdded:Connect(function(child)
		if child:IsA("BasePart") then
			if validOres[child.Name] or child.Name == "Chest" then
				setupItemCollision(child)
			end
		end
	end)
end

initialize()