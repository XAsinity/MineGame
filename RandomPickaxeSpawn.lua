local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")


-- Reference the RemoteEvent
local RequestRandomPickaxeEvent = ReplicatedStorage:WaitForChild("RequestRandomPickaxeEvent")

-- Listen for the "U" key press
UserInputService.InputBegan:Connect(function(input, isProcessed)
	if isProcessed then
		return
	end

	-- Check if the "U" key was pressed
	if input.KeyCode == Enum.KeyCode.U then
		print("Manual reset triggered on client!")
		RequestRandomPickaxeEvent:FireServer() -- Notify the server
	end
end)
