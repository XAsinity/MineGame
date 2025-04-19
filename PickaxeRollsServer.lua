local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")
local Players = game:GetService("Players")
local ToolDefinitions = require(ReplicatedStorage:WaitForChild("ToolDefinitions"))

local function debugInventory(player)
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		print("Player's inventory:")
		for _, tool in pairs(backpack:GetChildren()) do
			if tool:IsA("Tool") then
				print("Tool:", tool.Name)
				for _, child in pairs(tool:GetDescendants()) do
					print("  Child:", child.Name, "Class:", child.ClassName)
				end
			end
		end
	else
		warn("Backpack not found for player:", player.Name)
	end
end

-- Function to roll for a random pickaxe
local function rollPickaxe()
	local rarities = {
		Common = 60,
		Uncommon = 25,
		Rare = 10,
		Epic = 4,
		Legendary = 1,
	}

	local totalWeight = 0
	for _, weight in pairs(rarities) do
		totalWeight += weight
	end

	local roll = math.random(1, totalWeight)
	local currentWeight = 0
	local selectedRarity

	for rarity, weight in pairs(rarities) do
		currentWeight += weight
		if roll <= currentWeight then
			selectedRarity = rarity
			break
		end
	end

	local pickaxeTypes = {
		{ Name = "Bronze Pickaxe", MiningSize = 6 },
		{ Name = "Silver Pickaxe", MiningSize = 8 },
		{ Name = "Gold Pickaxe", MiningSize = 10 },
		{ Name = "Platinum Pickaxe", MiningSize = 12 },
	}

	local pickaxe = pickaxeTypes[math.random(1, #pickaxeTypes)]
	pickaxe.Rarity = selectedRarity
	return pickaxe
end

-- Function to grant a rolled pickaxe to a player
local function grantPickaxeToPlayer(player, pickaxe)
	-- Create a new pickaxe
	local newPickaxe = Instance.new("Tool")
	newPickaxe.Name = pickaxe.Name .. " (" .. pickaxe.Rarity .. ")"

	-- Add a handle to the pickaxe
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 4, 1)
	handle.Parent = newPickaxe

	-- Add a Pickaxe visual part
	local pickaxeVisual = Instance.new("UnionOperation")
	pickaxeVisual.Name = "Pickaxe"
	pickaxeVisual.Parent = handle

	-- Add a WeldConstraint to attach the visual to the handle
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = handle
	weldConstraint.Part1 = pickaxeVisual
	weldConstraint.Parent = handle

	-- Add a MiningSize value to the pickaxe
	local miningSizeValue = Instance.new("IntValue")
	miningSizeValue.Name = "MiningSize"
	miningSizeValue.Value = pickaxe.MiningSize
	miningSizeValue.Parent = handle

	-- Add the pickaxe to the player's Backpack
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		newPickaxe.Parent = backpack
		print("Granted new pickaxe to player:", pickaxe.Name, "with MiningSize:", miningSizeValue.Value)
	else
		warn("Player's Backpack not found!")
	end
end

-- Example trigger (e.g., from a button click)
local rollPickaxeEvent = Instance.new("RemoteEvent", ReplicatedStorage)
rollPickaxeEvent.Name = "RollPickaxeEvent"

rollPickaxeEvent.OnServerEvent:Connect(function(player)
	local pickaxe = rollPickaxe()
	grantPickaxeToPlayer(player, pickaxe)
end)

-- Example usage: Roll and grant a pickaxe when a player joins
Players.PlayerAdded:Connect(function(player)
	-- Wait until the player's Backpack and StarterGear are ready
	player.CharacterAdded:Wait()

	-- Debug the player's inventory before granting a pickaxe
	debugInventory(player)

	-- Check if the player already has a pickaxe in their Backpack
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, tool in pairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
				print("Player already has a pickaxe, skipping grant.")
				return -- Exit the function to avoid granting another pickaxe
			end
		end
	end

	-- Ensure no pickaxe is granted if the player already has one
	print("No pickaxe granted as player already has one.")
end)