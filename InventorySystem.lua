local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local OreDefinitions = require(ReplicatedStorage:WaitForChild("OreDefinitions"))
local InventoryModule = require(ServerScriptService:WaitForChild("InventoryModule"))
local ToolDefinitions = require(ReplicatedStorage:WaitForChild("ToolDefinitions"))

local validOres = OreDefinitions.validOres

-- RemoteEvent for chest removal
local removeChestEvent = ReplicatedStorage:WaitForChild("RemoveChestEvent")

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

local function removeChestFromInventory(player, chestName, removeCompletely)
	local inventory = player:FindFirstChild("Inventory")
	if not inventory then
		warn("Inventory folder not found for player:", player.Name)
		return
	end

	-- Function to delete or decrement the chest
	local function deleteChest()
		local chest = inventory:FindFirstChild(chestName)
		if chest then
			if removeCompletely then
				-- Remove the chest entirely
				chest:Destroy()
				print("Chest completely removed from inventory:", chestName)
			else
				-- Decrease the chest count
				if chest:IsA("IntValue") then
					chest.Value = math.max(chest.Value - 1, 0)
					print("Chest count decreased in inventory:", chestName, "New count:", chest.Value)
					if chest.Value == 0 then
						chest:Destroy()
						print("Chest removed after count reached 0:", chestName)
					end
				end
			end
		else
			warn("Chest not found in inventory:", chestName)
		end
	end

	-- Run delete logic twice
	deleteChest()
	task.wait(0.1) -- Short delay before retrying
	deleteChest()

	-- Verify deletion
	local remainingChest = inventory:FindFirstChild(chestName)
	if remainingChest then
		print("Chest still exists in inventory after deletion attempts. Forcing removal:", chestName)
		remainingChest:Destroy()
	else
		print("Chest successfully removed from inventory after verification:", chestName)
	end
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

	-- Listen for the RemoveChestEvent
	removeChestEvent.OnServerEvent:Connect(function(player, chestName, removeCompletely)
		removeChestFromInventory(player, chestName, removeCompletely)
	end)
end

initialize()