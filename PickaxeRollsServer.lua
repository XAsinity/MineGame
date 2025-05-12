local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ToolDefinitions = require(ReplicatedStorage:WaitForChild("ToolDefinitions"))

-- Utility: Prints player's current Backpack tools for debugging
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

-- Grants a pickaxe to the player, includes rarity in name and MiningSize as value
local function grantPickaxeToPlayer(player, pickaxe)
	-- Create the pickaxe tool
	local newPickaxe = Instance.new("Tool")
	newPickaxe.Name = pickaxe.Name .. " (" .. pickaxe.Rarity .. ")"

	-- Handle and basic visual
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 4, 1)
	handle.Parent = newPickaxe

	-- Add a MiningSize value to the handle (for use in mining logic)
	local miningSizeValue = Instance.new("IntValue")
	miningSizeValue.Name = "MiningSize"
	miningSizeValue.Value = pickaxe.MiningSize
	miningSizeValue.Parent = handle

	-- Rarity value for reference (optional)
	local rarityValue = Instance.new("StringValue")
	rarityValue.Name = "Rarity"
	rarityValue.Value = pickaxe.Rarity
	rarityValue.Parent = newPickaxe

	-- Place in Backpack
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		newPickaxe.Parent = backpack
		print("Granted new pickaxe to player:", pickaxe.Name, "with MiningSize:", miningSizeValue.Value, "and Rarity:", pickaxe.Rarity)
	else
		warn("Player's Backpack not found!")
	end
end

-- Setup RemoteEvent for client/server communication
local rollPickaxeEvent = ReplicatedStorage:FindFirstChild("RollPickaxeEvent") or Instance.new("RemoteEvent", ReplicatedStorage)
rollPickaxeEvent.Name = "RollPickaxeEvent"

rollPickaxeEvent.OnServerEvent:Connect(function(player)
	local pickaxe = ToolDefinitions.rollPickaxe()
	grantPickaxeToPlayer(player, pickaxe)
end)

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
			local starterDef = ToolDefinitions.getPickaxeByName("Starter Pickaxe")
			if starterDef then
				grantPickaxeToPlayer(player, {
					Name = starterDef.Name,
					MiningSize = starterDef.MiningSize,
					Rarity = "Common"
				})
			else
				-- Fallback: grant a Bronze Pickaxe if Starter Pickaxe is not defined
				grantPickaxeToPlayer(player, {
					Name = "Bronze Pickaxe",
					MiningSize = 6,
					Rarity = "Common"
				})
			end
		end
	end)
end)