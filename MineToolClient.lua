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

		-- Check if the tool has required attributes for mining
		local miningSizeValue = tool:FindFirstChild("MiningSize")
		local durabilityValue = tool:FindFirstChild("Durability")

		-- Validate MiningSize
		if not miningSizeValue or not miningSizeValue:IsA("IntValue") then
			warn("MiningSize value missing in the tool! Please ensure the tool has a valid MiningSize IntValue.")
			return
		end

		-- Validate Durability
		if not durabilityValue or not durabilityValue:IsA("IntValue") then
			warn("Durability value missing in the tool! Please ensure the tool has a valid Durability IntValue.")
			return
		end

		-- Check if the tool has sufficient durability to mine
		if durabilityValue.Value <= 0 then
			warn("The tool has no durability left and cannot be used for mining.")
			return
		end

		-- Validate that the target is terrain
		if target.ClassName == "Terrain" then
			-- Fire the mining event to the server with the target position and mining size
			local miningSize = miningSizeValue.Value
			mineEvent:FireServer(targetPosition, miningSize)

			-- Reduce the tool's durability after mining
			durabilityValue.Value = durabilityValue.Value - 1
			print("Fired MineEvent with position:", targetPosition, "and size:", miningSize, ". Remaining durability:", durabilityValue.Value)

			-- Check if the tool is fully broken after mining
			if durabilityValue.Value <= 0 then
				-- Notify the player visually or audibly that the tool is broken
				print("The tool has broken and can no longer be used.")
				-- Optionally, you can fire an event to indicate the tool is broken
				-- For example: ReplicatedStorage:WaitForChild("ToolBrokenEvent"):FireServer(tool)
			end
		else
			print("Target is not part of the terrain!")
		end
	else
		print("No target found to mine!")
	end
end)