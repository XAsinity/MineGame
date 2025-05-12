local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local tool = script.Parent
local mineEvent = ReplicatedStorage:WaitForChild("MineEvent") -- RemoteEvent for mining

tool.Activated:Connect(function()
	local mouse = player:GetMouse()

	-- Ensure the player is aiming at something
	if mouse and mouse.Target then
		local target = mouse.Target
		local targetPosition = mouse.Hit.Position

		-- Check if the tool has a MiningSize value inside it
		local miningSizeValue = tool:FindFirstChild("MiningSize")
		if not miningSizeValue or not miningSizeValue:IsA("IntValue") then
			warn("MiningSize value missing in the tool! Please ensure the tool has a valid MiningSize IntValue.")
			return
		end

		-- Validate that the target is terrain
		if target.ClassName == "Terrain" then
			-- Fire the mining event to the server with the target position and mining size
			local miningSize = miningSizeValue.Value
			mineEvent:FireServer(targetPosition, miningSize)
			print("Fired MineEvent with position:", targetPosition, "and size:", miningSize)
		else
			print("Target is not part of the terrain!")
		end
	else
		print("No target found to mine!")
	end
end)