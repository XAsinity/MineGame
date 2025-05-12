local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Debug function to print the structure of the player's pickaxe inventory
local function debugPickaxeInventory(player)
	local pickaxeFolder = player:FindFirstChild("Data") and player.Data:FindFirstChild("Pickaxe")
	if pickaxeFolder then
		print("Player's pickaxe inventory:")
		for _, pickaxe in pairs(pickaxeFolder:GetChildren()) do
			print("Pickaxe:", pickaxe.Name)
			for _, child in pairs(pickaxe:GetDescendants()) do
				print("  Child:", child.Name, "Class:", child.ClassName)
			end
		end
	else
		warn("Pickaxe folder not found for player:", player.Name)
	end
end

-- Function to initialize the player's Data folder and Pickaxe folder
local function initializePlayerData(player)
	-- Ensure Data folder exists
	local dataFolder = player:FindFirstChild("Data")
	if not dataFolder then
		dataFolder = Instance.new("Folder")
		dataFolder.Name = "Data"
		dataFolder.Parent = player
	end

	-- Ensure Pickaxe folder exists
	local pickaxeFolder = dataFolder:FindFirstChild("Pickaxe")
	if not pickaxeFolder then
		pickaxeFolder = Instance.new("Folder")
		pickaxeFolder.Name = "Pickaxe"
		pickaxeFolder.Parent = dataFolder
		print("Pickaxe folder created for player:", player.Name)
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

	-- Add the pickaxe to the player's pickaxe inventory
	local pickaxeFolder = player:FindFirstChild("Data") and player.Data:FindFirstChild("Pickaxe")
	if pickaxeFolder then
		newPickaxe.Parent = pickaxeFolder
		print("Starter Pickaxe given to player:", player.Name)
		-- Debug the player's pickaxe inventory after adding the pickaxe
		debugPickaxeInventory(player)
	else
		warn("Pickaxe folder not found for player:", player.Name)
	end
end

-- When a player joins the game
Players.PlayerAdded:Connect(function(player)
	-- Initialize player Data and Pickaxe folder
	initializePlayerData(player)

	player.CharacterAdded:Connect(function()
		-- Give the player a starter pickaxe
		giveStarterPickaxe(player)
	end)
end)