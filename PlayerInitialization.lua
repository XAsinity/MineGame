local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Debug function to print all instances of a Coins value
local function debugCoinsPlacement(player)
	local dataFolder = player:FindFirstChild("Data")
	if dataFolder then
		for _, child in pairs(dataFolder:GetDescendants()) do
			if child.Name == "Coins" then
				print("Coins found in:", child.Parent.Name, "Parent's Parent:", child.Parent.Parent and child.Parent.Parent.Name or "None")
			end
		end
	end
end

-- Function to ensure the player's Data folder and nested folders exist
local function initializePlayerData(player)
	-- Ensure Data folder exists
	local dataFolder = player:FindFirstChild("Data")
	if not dataFolder then
		dataFolder = Instance.new("Folder")
		dataFolder.Name = "Data"
		dataFolder.Parent = player
	end

	-- Ensure Coins value exists directly in the Data folder
	local coins = dataFolder:FindFirstChild("Coins")
	if not coins then
		coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Value = 0 -- Default value
		coins.Parent = dataFolder
		print("Coins value created directly in Data folder for player:", player.Name)
	end

	-- Ensure Pickaxe folder exists
	local pickaxeFolder = dataFolder:FindFirstChild("Pickaxe")
	if not pickaxeFolder then
		pickaxeFolder = Instance.new("Folder")
		pickaxeFolder.Name = "Pickaxe"
		pickaxeFolder.Parent = dataFolder
		print("Pickaxe folder created for player:", player.Name)
	end

	-- Ensure Pickaxes folder exists
	local pickaxesFolder = dataFolder:FindFirstChild("Pickaxes")
	if not pickaxesFolder then
		pickaxesFolder = Instance.new("Folder")
		pickaxesFolder.Name = "Pickaxes"
		pickaxesFolder.Parent = dataFolder
		print("Pickaxes folder created for player:", player.Name)
	end

	-- Ensure Ores folder exists
	local oresFolder = dataFolder:FindFirstChild("Ores")
	if not oresFolder then
		oresFolder = Instance.new("Folder")
		oresFolder.Name = "Ores"
		oresFolder.Parent = dataFolder
		print("Ores folder created for player:", player.Name)
	end

	-- Add default ores if missing
	local defaultOres = {"Gold", "Copper", "Coal", "Iron"}
	for _, oreName in ipairs(defaultOres) do
		if not oresFolder:FindFirstChild(oreName) then
			local oreValue = Instance.new("IntValue")
			oreValue.Name = oreName
			oreValue.Value = 0 -- Default value
			oreValue.Parent = oresFolder
			print("Ore value created:", oreName, "for player:", player.Name)
		end
	end

	-- Ensure Chests folder exists (but do not create new chests, as they should be tied to the unique ID system)
	local chestsFolder = dataFolder:FindFirstChild("Chests")
	if not chestsFolder then
		chestsFolder = Instance.new("Folder")
		chestsFolder.Name = "Chests"
		chestsFolder.Parent = dataFolder
		print("Chests folder created for player:", player.Name)
	end

	-- Debug: Print Coins placements
	debugCoinsPlacement(player)
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

	-- Add the pickaxe to the player's pickaxe inventory
	local pickaxesFolder = player:FindFirstChild("Data") and player.Data:FindFirstChild("Pickaxes")
	if pickaxesFolder and not pickaxesFolder:FindFirstChild("Starter Pickaxe") then
		newPickaxe.Parent = pickaxesFolder
		print("Starter Pickaxe given to player:", player.Name)
	else
		warn("Starter Pickaxe already exists for player:", player.Name)
	end
end

-- When a player joins the game
Players.PlayerAdded:Connect(function(player)
	-- Initialize player Data and ensure all folders exist
	initializePlayerData(player)

	player.CharacterAdded:Connect(function()
		wait(1) -- Delay to ensure the player's character and data folders are fully loaded

		-- Give the player a starter pickaxe if they don't already have one
		local pickaxesFolder = player:FindFirstChild("Data") and player.Data:FindFirstChild("Pickaxes")
		if pickaxesFolder and #pickaxesFolder:GetChildren() == 0 then
			giveStarterPickaxe(player)
		end
	end)
end)