local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local terrain = Workspace:FindFirstChild("Terrain")
local mineEvent = ReplicatedStorage:WaitForChild("MineEvent")

-- Module dependencies
local PickaxeUtils = require(ReplicatedStorage:WaitForChild("PickaxeUtils"))
local InventoryModule = require(ServerScriptService:WaitForChild("InventoryModule"))

if terrain then
	print("Active Terrain Instance:", terrain)
	print("Terrain Parent:", terrain.Parent)
else
	error("Terrain object not found in the Workspace!")
end

-------------------------------
-- Testing Utilities Section --
-------------------------------
-- (Safe to remove later)

-- Manual pickaxe grant event for testing
local requestRandomPickaxeEvent = ReplicatedStorage:FindFirstChild("RequestRandomPickaxeEvent")
if not requestRandomPickaxeEvent then
	requestRandomPickaxeEvent = Instance.new("RemoteEvent")
	requestRandomPickaxeEvent.Name = "RequestRandomPickaxeEvent"
	requestRandomPickaxeEvent.Parent = ReplicatedStorage
end

-- Grant a pickaxe to the player
local function grantPickaxeToPlayer(player, pickaxeData)
	-- Clone the pickaxe model
	local pickaxeModel = ReplicatedStorage:FindFirstChild("Starter Pickaxe"):Clone()
	pickaxeModel.Name = pickaxeData.Name

	-- Locate the Handle
	local handle = pickaxeModel:FindFirstChild("Handle")
	if not handle then
		warn("Handle is missing in the pickaxe model!")
		return
	end

	-- Ensure there are no duplicates: Clean up existing attributes
	for _, child in pairs(handle:GetChildren()) do
		if child.Name == "Durability" or child.Name == "MiningSize" or child.Name == "Rarity" then
			child:Destroy()
		end
	end

	-- Attach Durability
	local durabilityValue = Instance.new("IntValue")
	durabilityValue.Name = "Durability"
	durabilityValue.Value = pickaxeData.Durability
	durabilityValue.Parent = handle

	-- Attach MiningSize
	local miningSizeValue = Instance.new("IntValue")
	miningSizeValue.Name = "MiningSize"
	miningSizeValue.Value = pickaxeData.MiningSize
	miningSizeValue.Parent = handle

	-- Attach Rarity
	local rarityValue = Instance.new("StringValue")
	rarityValue.Name = "Rarity"
	rarityValue.Value = pickaxeData.Rarity
	rarityValue.Parent = handle

	-- Place the pickaxe in the player's backpack
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		pickaxeModel.Parent = backpack
	end
end

-- Grant a random pickaxe to the player
local function grantRandomPickaxe(player)
	local pickaxeDef = PickaxeUtils.rollPickaxe() -- Use PickaxeUtils to generate pickaxe data
	if not pickaxeDef then
		warn("Failed to roll a random pickaxe! Ensure PickaxeUtils.rollPickaxe() is defined and returns valid data.")
		return
	end

	grantPickaxeToPlayer(player, pickaxeDef)
end

requestRandomPickaxeEvent.OnServerEvent:Connect(function(player)
	grantRandomPickaxe(player)
end)

-------------------------------
--      Mining Section       --
-------------------------------

-- Accept miningSize directly from the client
local function mineTerrain(player, targetPosition, miningSize)
	print("mineTerrain called for player:", player.Name, "with target position:", targetPosition)

	local character = player.Character
	if not character then
		warn("Player's character not found!")
		return
	end

	-- Locate the player's Pickaxe folder and equipped pickaxe
	local dataFolder = player:FindFirstChild("Data")
	if not dataFolder then
		warn("Data folder missing for player:", player.Name)
		return
	end

	local pickaxeFolder = dataFolder:FindFirstChild("Pickaxe")
	if not pickaxeFolder then
		warn("Pickaxe folder missing in Data for player:", player.Name)
		return
	end

	local equippedPickaxeName = dataFolder:FindFirstChild("EquippedPickaxe")
	if not equippedPickaxeName or not equippedPickaxeName.Value then
		warn("No pickaxe equipped for player:", player.Name)
		return
	end

	local equippedPickaxe = pickaxeFolder:FindFirstChild(equippedPickaxeName.Value)
	if not equippedPickaxe then
		warn("Equipped pickaxe not found in Pickaxe folder for player:", player.Name)
		return
	end

	local handle = equippedPickaxe:FindFirstChild("Handle")
	if not handle then
		warn("Handle is missing from equipped pickaxe!")
		return
	end

	-- Debugging: Print the equipped pickaxe structure
	print("Inspecting equipped pickaxe structure...")
	for _, child in pairs(handle:GetChildren()) do
		print("Child:", child.Name, "Class:", child.ClassName)
	end

	-- Check and update the pickaxe's Durability
	local durabilityValue = handle:FindFirstChild("Durability")
	if not durabilityValue or not durabilityValue:IsA("IntValue") then
		warn("Durability value missing or invalid for pickaxe:", equippedPickaxe.Name)
		return
	end

	if durabilityValue.Value > 0 then
		-- Decrement durability
		durabilityValue.Value -= 1
		print(player.Name .. "'s pickaxe durability decreased to:", durabilityValue.Value)
	else
		-- Durability is 0; prevent mining
		print(player.Name .. "'s pickaxe is broken! Mining is disabled.")
		return
	end

	print(player.Name .. " is mining with size:", miningSize)

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
end

mineEvent.OnServerEvent:Connect(function(player, targetPosition, miningSize)
	if not player or not targetPosition or not miningSize then
		warn("Invalid player, target position, or mining size passed to MineEvent!")
		return
	end

	print("MineEvent received from player:", player.Name, "Target Position:", targetPosition, "Mining Size:", miningSize)
	mineTerrain(player, targetPosition, miningSize)
end)