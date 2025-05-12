local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PickaxeUtils = require(ReplicatedStorage:WaitForChild("PickaxeUtils"))

-- Utility: Prints player's current Backpack tools for debugging
local function debugInventory(player)
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		print("Player's inventory:")
		local toolCount = 0
		for _, tool in pairs(backpack:GetChildren()) do
			if tool:IsA("Tool") then
				toolCount += 1
				print("Tool:", tool.Name)
				for _, child in pairs(tool:GetDescendants()) do
					print("  Child:", child.Name, "Class:", child.ClassName)
				end
			end
		end
		print("Total tools in inventory:", toolCount)
	else
		warn("Backpack not found for player:", player.Name)
	end
end

-- Grants a pickaxe to the player, dynamically creating MiningSize, Rarity, and Durability
local function grantPickaxeToPlayer(player, pickaxe)
	-- Fetch the Starter Pickaxe model from ReplicatedStorage
	local starterPickaxeModel = ReplicatedStorage:FindFirstChild("Starter Pickaxe")
	if not starterPickaxeModel then
		warn("Starter Pickaxe model not found in ReplicatedStorage!")
		return
	end

	-- Clone the pickaxe model
	local newPickaxe = starterPickaxeModel:Clone()
	newPickaxe.Name = pickaxe.Name .. " (" .. pickaxe.Rarity .. ")"

	-- Dynamically create and assign the MiningSize value
	local miningSizeValue = newPickaxe:FindFirstChild("MiningSize") or Instance.new("IntValue")
	miningSizeValue.Name = "MiningSize"
	miningSizeValue.Value = pickaxe.MiningSize
	miningSizeValue.Parent = newPickaxe
	print("MiningSize set to:", miningSizeValue.Value)

	-- Dynamically create and assign the Rarity value
	local rarityValue = newPickaxe:FindFirstChild("Rarity") or Instance.new("StringValue")
	rarityValue.Name = "Rarity"
	rarityValue.Value = pickaxe.Rarity
	rarityValue.Parent = newPickaxe
	print("Rarity set to:", rarityValue.Value)

	-- Dynamically create and assign the Durability value
	local durabilityValue = newPickaxe:FindFirstChild("Durability") or Instance.new("IntValue")
	durabilityValue.Name = "Durability"
	durabilityValue.Value = pickaxe.Durability
	durabilityValue.Parent = newPickaxe
	print("Durability set to:", durabilityValue.Value)

	-- Place the pickaxe in the player's Backpack
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		newPickaxe.Parent = backpack
		print("Granted new pickaxe to player:", pickaxe.Name, "with MiningSize:", miningSizeValue.Value, ", Rarity:", rarityValue.Value, ", and Durability:", durabilityValue.Value)
	else
		warn("Player's Backpack not found!")
	end

	-- Debug inventory after granting the pickaxe
	debugInventory(player)
end

-- Example: When a player joins, only grant a starter pickaxe if they don't have one
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		-- Wait for Backpack
		repeat wait() until player:FindFirstChild("Backpack")
		debugInventory(player)

		local alreadyHasPickaxe = false
		for _, tool in pairs(player.Backpack:GetChildren()) do
			if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
				alreadyHasPickaxe = true
				break
			end
		end

		if not alreadyHasPickaxe then
			-- Grant a starter pickaxe (always common)
			print("Granting starter pickaxe to player:", player.Name)
			local starterPickaxe = PickaxeUtils.rollPickaxe()
			starterPickaxe.Name = "Starter Pickaxe" -- Override name for starter pickaxe
			starterPickaxe.Rarity = "Common" -- Ensure starter pickaxe is always Common
			starterPickaxe.MiningSize = 4 -- Fixed mining size for starter pickaxe
			starterPickaxe.Durability = 100 -- Fixed durability for starter pickaxe
			grantPickaxeToPlayer(player, starterPickaxe)
		else
			print("Player already has a pickaxe. No starter pickaxe granted.")
		end
	end)
end)