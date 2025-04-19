local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Reference the RemoteEvent
local manualResetEvent = ReplicatedStorage:WaitForChild("ManualResetEvent")

-- Listen for the "Y" key press
UserInputService.InputBegan:Connect(function(input, isProcessed)
	if isProcessed then
		return
	end

	-- Check if the "Y" key was pressed
	if input.KeyCode == Enum.KeyCode.Y then
		print("Manual reset triggered on client!")
		manualResetEvent:FireServer() -- Notify the server
	end
end)
