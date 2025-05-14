local ReplicatedStorage = game:GetService("ReplicatedStorage")
local removeChestEvent = ReplicatedStorage:WaitForChild("RemoveChestEvent")
local requestRandomPickaxeEvent = ReplicatedStorage:FindFirstChild("RequestRandomPickaxeEvent")

-- Validate that the event exists
if not requestRandomPickaxeEvent or not requestRandomPickaxeEvent:IsA("RemoteEvent") then
	warn("RequestRandomPickaxeEvent does not exist or is not a RemoteEvent in ReplicatedStorage!")
	return
end

-- Table to track pending confirmations
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
	if chest then
		if chest.Value > 0 then
			-- Mark chest as pending confirmation
			pendingConfirmations[chestName] = false

			-- Decrease chest count or remove chest
			if chest.Value > 1 then
				chest.Value -= 1
				removeChestEvent:FireClient(player, chestName, false) -- Notify client to decrease count
				print(player.Name .. " opened chest: " .. chestName .. ", count decreased to: " .. chest.Value)
			else
				chest:Destroy()
				removeChestEvent:FireClient(player, chestName, true) -- Notify client to remove chest
				print(player.Name .. " opened chest: " .. chestName .. ", chest removed completely.")
			end

			-- Wait for confirmation
			local startTime = os.clock()
			while not pendingConfirmations[chestName] do
				task.wait(0.1) -- Wait briefly
				if os.clock() - startTime > 5 then -- Timeout after 5 seconds
					warn("Chest confirmation timeout for player: " .. player.Name .. ", chest: " .. chestName)
					return -- Do not proceed with the pickaxe event
				end
			end

			-- Fire pickaxe event only if confirmation was received
			requestRandomPickaxeEvent:FireClient(player, chestName)
			print("Pickaxe event fired for player: " .. player.Name .. " after chest confirmation.")
		else
			warn("Chest does not exist or has zero quantity for player:", player.Name)
		end
	else
		warn("Chest not found in data for player:", player.Name)
	end
end

-- Listen for OpenChestEvent
ReplicatedStorage:WaitForChild("OpenChestEvent").OnServerEvent:Connect(openChest)

-- Listen for RemoveChestEvent confirmation from client
removeChestEvent.OnServerEvent:Connect(function(player, chestName)
	print("Confirmation received for chest removal: " .. chestName .. " from player: " .. player.Name)
	pendingConfirmations[chestName] = true
end)