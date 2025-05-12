local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Function to equip a pickaxe
local function equipPickaxe(player, pickaxeName)
	-- Locate required folders
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

	-- Check if the pickaxe exists in the player's pickaxe inventory
	local selectedPickaxe = pickaxeFolder:FindFirstChild(pickaxeName)
	if not selectedPickaxe then
		warn("Pickaxe not found in inventory:", pickaxeName)
		return
	end

	-- Equip the pickaxe
	local equippedPickaxe = dataFolder:FindFirstChild("EquippedPickaxe")
	if not equippedPickaxe then
		equippedPickaxe = Instance.new("StringValue")
		equippedPickaxe.Name = "EquippedPickaxe"
		equippedPickaxe.Parent = dataFolder
	end

	equippedPickaxe.Value = pickaxeName
	print(player.Name .. " equipped pickaxe:", pickaxeName)
end

-- Example usage: Equip a pickaxe for a player
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		wait(1) -- Wait for the player's character to fully load
		equipPickaxe(player, "Starter Pickaxe") -- Replace "Starter Pickaxe" with the desired pickaxe name
	end)
end)