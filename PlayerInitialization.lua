local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Debug function to print the structure of the player's inventory
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

-- Function to give the player a Starter Pickaxe
local function giveStarterPickaxe(player)
	local starterPickaxeTemplate = ReplicatedStorage:FindFirstChild("Starter Pickaxe")
	if not starterPickaxeTemplate then
		warn("Starter Pickaxe template not found in ReplicatedStorage!")
		return
	end

	-- Clone the pickaxe
	local newPickaxe = starterPickaxeTemplate:Clone()
	newPickaxe.Name = "Starter Pickaxe"

	-- Debug: Verify the structure of the cloned pickaxe
	print("Cloning Starter Pickaxe...")
	print("Cloned Starter Pickaxe structure:")
	for _, descendant in pairs(newPickaxe:GetDescendants()) do
		print("  Child:", descendant.Name, "Class:", descendant.ClassName)
	end

	-- Check for the Handle and MiningSize in the cloned pickaxe
	local handle = newPickaxe:FindFirstChild("Handle")
	if handle then
		print("Handle found in cloned Starter Pickaxe.")
		local miningSize = handle:FindFirstChild("MiningSize")
		if miningSize then
			print("MiningSize value exists with Value:", miningSize.Value)
		else
			warn("MiningSize value missing in cloned Starter Pickaxe!")
		end
	else
		warn("Handle missing in cloned Starter Pickaxe!")
	end

	-- Add the pickaxe to the player's inventory
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		newPickaxe.Parent = backpack
		print("Starter Pickaxe given to player:", player.Name)
		-- Debug the player's inventory after adding the pickaxe
		debugInventory(player)
	else
		warn("Backpack not found for player:", player.Name)
	end
end

-- When a player joins the game
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		-- Give the player a starter pickaxe
		giveStarterPickaxe(player)
	end)
end)