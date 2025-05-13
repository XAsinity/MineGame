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

	-- Clone the Starter Pickaxe model
	local pickaxeModel = ReplicatedStorage:FindFirstChild("Starter Pickaxe"):Clone()
	pickaxeModel.Name = pickaxeData.Name

	-- Locate the Handle
	local handle = pickaxeModel:FindFirstChild("Handle")
	if not handle then
		warn("Handle is missing in the pickaxe model!")
		return
	end

	-- Clean up existing attributes on the handle
	for _, child in pairs(handle:GetChildren()) do
		if child.Name == "Durability" or child.Name == "MiningSize" or child.Name == "Rarity" then
			child:Destroy()
		end
	end

	-- Attach attributes to the pickaxe
	local durabilityValue = Instance.new("IntValue")
	durabilityValue.Name = "Durability"
	durabilityValue.Value = pickaxeData.Durability
	durabilityValue.Parent = pickaxeModel

	local miningSizeValue = Instance.new("IntValue")
	miningSizeValue.Name = "MiningSize"
	miningSizeValue.Value = pickaxeData.MiningSize
	miningSizeValue.Parent = pickaxeModel

	local rarityValue = Instance.new("StringValue")
	rarityValue.Name = "Rarity"
	rarityValue.Value = pickaxeData.Rarity
	rarityValue.Parent = pickaxeModel

	-- Place the pickaxe in the player's backpack
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		pickaxeModel.Parent = backpack
		print("Pickaxe added to player's backpack:", player.Name)
	else
		warn("Player's Backpack not found:", player.Name)
	end
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