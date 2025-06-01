local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local terrain = Workspace:FindFirstChild("Terrain")
local mineEvent = ReplicatedStorage:WaitForChild("MineEvent")

-- Module dependencies
local PickaxeUtils = require(ReplicatedStorage:WaitForChild("PickaxeUtils"))
local InventoryModule = require(ServerScriptService:WaitForChild("InventoryModule"))

-- Function to locate the currently equipped pickaxe
local function getEquippedPickaxe(player)
	-- Check both the Backpack and Character for the pickaxe
	local backpackPickaxe = player.Backpack:FindFirstChildWhichIsA("Tool")
	local characterPickaxe = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
	return characterPickaxe or backpackPickaxe
end

-- Function to grant a pickaxe to a player
local function grantPickaxeToPlayer(player, pickaxeData)
	print("Granting pickaxe to player:", player.Name)

	-- Clone the Starter Pickaxe Tool from ReplicatedStorage
	local basePickaxeTool = ReplicatedStorage:FindFirstChild("Starter Pickaxe")
	if not basePickaxeTool or basePickaxeTool.ClassName ~= "Tool" then
		warn("Starter Pickaxe in ReplicatedStorage is missing or not a Tool!")
		return
	end

	local pickaxeTool = basePickaxeTool:Clone()
	pickaxeTool.Name = pickaxeData.Name

	-- Attach value objects to the pickaxe tool
	local durabilityValue = Instance.new("IntValue")
	durabilityValue.Name = "Durability"
	durabilityValue.Value = pickaxeData.Durability
	durabilityValue.Parent = pickaxeTool

	local miningSizeValue = Instance.new("IntValue")
	miningSizeValue.Name = "MiningSize"
	miningSizeValue.Value = pickaxeData.MiningSize
	miningSizeValue.Parent = pickaxeTool

	local rarityValue = Instance.new("StringValue")
	rarityValue.Name = "Rarity"
	rarityValue.Value = pickaxeData.Rarity
	rarityValue.Parent = pickaxeTool

	-- Place the pickaxe in the player's Backpack, retry if necessary
	local function equipToBackpack()
		local backpack = player:FindFirstChild("Backpack")
		if backpack then
			pickaxeTool.Parent = backpack
			print("Pickaxe added to player's backpack:", player.Name)
		else
			warn("Player's Backpack not found:", player.Name, "Retrying in 0.1s")
			task.delay(0.1, function()
				local retryBackpack = player:FindFirstChild("Backpack")
				if retryBackpack then
					pickaxeTool.Parent = retryBackpack
					print("Pickaxe added to player's backpack after retry:", player.Name)
				else
					warn("Still no Backpack for player after retry:", player.Name)
				end
			end)
		end
	end

	equipToBackpack()
end

-- Function to handle mining logic
local function mineTerrain(player, targetPosition, miningSize)
	print("mineTerrain called for player:", player.Name, "with target position:", targetPosition)

	-- Locate the player's equipped pickaxe
	local equippedPickaxe = getEquippedPickaxe(player)
	if not equippedPickaxe then
		warn("Equipped pickaxe not found for player:", player.Name)
		return
	end

	-- Ensure the pickaxe has its Durability attribute
	local durabilityValue = equippedPickaxe:FindFirstChild("Durability")
	if not durabilityValue or not durabilityValue:IsA("IntValue") then
		warn("Durability value missing or invalid for pickaxe:", equippedPickaxe.Name)
		return
	end

	-- Check if there is enough durability to mine
	if durabilityValue.Value > 0 then
		-- Decrement durability
		durabilityValue.Value -= 1
		print(player.Name .. "'s pickaxe durability decreased to:", durabilityValue.Value)

		-- Save the updated durability to the player's data
		local pickaxesFolder = player:FindFirstChild("Data") and player.Data:FindFirstChild("Pickaxes")
		if pickaxesFolder then
			local pickaxeData = pickaxesFolder:FindFirstChild(equippedPickaxe.Name)
			if pickaxeData then
				local durabilityData = pickaxeData:FindFirstChild("Durability")
				if durabilityData then
					durabilityData.Value = durabilityValue.Value
					print("Durability value saved for pickaxe:", equippedPickaxe.Name)
				end
			end
		end

		-- Perform terrain modification
		local radius = miningSize * 1.5
		local centerPosition = targetPosition

		local success, err = pcall(function()
			for x = -radius, radius, 4 do
				for y = -radius, radius, 4 do
					for z = -radius, radius, 4 do
						local offset = Vector3.new(x, y, z)
						local distanceFromCenter = offset.Magnitude
						local position = centerPosition + offset

						if distanceFromCenter <= radius then
							terrain:FillBlock(CFrame.new(position), Vector3.new(4, 4, 4), Enum.Material.Air)
						end
					end
				end
			end
		end)

		if success then
			print("Terrain successfully deleted at:", centerPosition)
		else
			warn("Error deleting terrain:", err)
		end
	else
		print(player.Name .. "'s pickaxe is broken! Mining is disabled.")
		-- Optionally: Fire a RemoteEvent to notify the client/UI
	end
end

-- Event listener for mining
mineEvent.OnServerEvent:Connect(function(player, targetPosition, miningSize)
	if not player or not targetPosition or not miningSize then
		warn("Invalid player, target position, or mining size passed to MineEvent!")
		return
	end

	print("MineEvent received from player:", player.Name, "Target Position:", targetPosition, "Mining Size:", miningSize)
	mineTerrain(player, targetPosition, miningSize)
end)

-- Export the grantPickaxeToPlayer for use in other scripts (optional)
return {
	grantPickaxeToPlayer = grantPickaxeToPlayer,
}