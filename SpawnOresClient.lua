local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local spawnOresEvent = ReplicatedStorage:WaitForChild("SpawnOresEvent")

-- Listen for the T key press
UserInputService.InputBegan:Connect(function(input, isProcessed)
	if isProcessed then return end
	if input.KeyCode == Enum.KeyCode.T then
		spawnOresEvent:FireServer()
		print("SpawnOresEvent fired to the server!")
	end
end)