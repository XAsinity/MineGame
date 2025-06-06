local ReplicatedStorage = game:GetService("ReplicatedStorage")
local removeChestEvent = ReplicatedStorage:WaitForChild("RemoveChestEvent")
local requestRandomPickaxeEvent = ReplicatedStorage:WaitForChild("RequestRandomPickaxeEvent")
local inventoryUpdateEvent = ReplicatedStorage:WaitForChild("InventoryUpdateEvent") -- Added this line
local InventoryModule = require(game:GetService("ServerScriptService"):WaitForChild("InventoryModule"))

-- Table to track pending confirmations for this session
local pendingConfirmations = {}

-- Function to handle chest opening
local function openChest(player, chestName)
	local dataFolder = player:FindFirstChild("Data")
	if not dataFolder then
		warn("Data folder not found for player:", player.Name)
		return
	end

	local chestsFolder = dataFolder:FindFirstChild("Chests")
	if not chestsFolder then
		warn("Chests folder not found for player:", player.Name)
		return
	end

	local chest = chestsFolder:FindFirstChild(chestName)
	if chest and chest:IsA("IntValue") then
		if chest.Value > 0 then
			local confirmKey = player.UserId .. "_" .. chestName
			pendingConfirmations[confirmKey] = false

			-- Decrease chest count or remove chest
			if chest.Value > 1 then
				chest.Value -= 1
				removeChestEvent:FireClient(player, chestName, false)
				print(player.Name .. " opened chest: " .. chestName .. ", count decreased to: " .. chest.Value)
			else
				chest:Destroy()
				removeChestEvent:FireClient(player, chestName, true)
				print(player.Name .. " opened chest: " .. chestName .. ", chest removed completely.")
			end

			-- Sync Inventory to reflect removal for UI/logic
			if InventoryModule and InventoryModule.syncInventoryWithData then
				InventoryModule.syncInventoryWithData(player)
			end

			-- **NEW: Fire UI update for inventory panel**
			inventoryUpdateEvent:FireClient(player)

			-- Wait for confirmation
			local startTime = os.clock()
			while not pendingConfirmations[confirmKey] do
				task.wait(0.1)
				if os.clock() - startTime > 5 then
					warn("Chest confirmation timeout for player: " .. player.Name .. ", chest: " .. chestName)
					return
				end
			end
			pendingConfirmations[confirmKey] = nil

			-- Now, just fire the event to the client to show animation/trigger pickaxe grant
			requestRandomPickaxeEvent:FireClient(player)
			print("[DEBUG] RequestRandomPickaxeEvent fired to client for player: " .. player.Name)
		else
			warn("Chest does not exist or has zero quantity for player:", player.Name)
		end
	else
		warn("Chest not found in data for player:", player.Name)
	end
end

ReplicatedStorage:WaitForChild("OpenChestEvent").OnServerEvent:Connect(openChest)

removeChestEvent.OnServerEvent:Connect(function(player, chestName)
	local confirmKey = player.UserId .. "_" .. chestName
	print("Confirmation received for chest removal: " .. chestName .. " from player: " .. player.Name)
	pendingConfirmations[confirmKey] = true
end)