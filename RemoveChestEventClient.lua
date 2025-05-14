local ReplicatedStorage = game:GetService("ReplicatedStorage")
local removeChestEvent = ReplicatedStorage:WaitForChild("RemoveChestEvent")

-- Listen for RemoveChestEvent from server
removeChestEvent.OnClientEvent:Connect(function(chestName, removeCompletely)
	local player = game.Players.LocalPlayer
	local dataFolder = player:FindFirstChild("Data")
	if not dataFolder then
		warn("Data folder not found for player: " .. player.Name)
		return
	end

	local chestsFolder = dataFolder:FindFirstChild("Chests")
	if not chestsFolder then
		warn("Chests folder not found for player: " .. player.Name)
		return
	end

	local chest = chestsFolder:FindFirstChild(chestName)
	if chest then
		if removeCompletely then
			chest:Destroy()
			print("Chest removed completely: " .. chestName)
		else
			chest.Value = math.max(chest.Value - 1, 0)
			print("Chest count decreased: " .. chestName .. ", new count: " .. chest.Value)
			if chest.Value == 0 then
				chest:Destroy()
			end
		end

		-- Send confirmation back to server
		removeChestEvent:FireServer(chestName)
	else
		warn("Chest not found locally for player: " .. player.Name)
	end
end)