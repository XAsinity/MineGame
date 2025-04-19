local Players = game:GetService("Players")

-- Function to create leaderstats for a player
local function setupLeaderstats(player)
	-- Create the leaderstats folder
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	-- Create the Coins value inside leaderstats
	local coinsStat = Instance.new("IntValue")
	coinsStat.Name = "Coins"
	coinsStat.Parent = leaderstats

	-- Wait for the player's Data folder and Coins value to exist
	local dataFolder = player:WaitForChild("Data", 5) -- Wait up to 5 seconds for the Data folder
	if not dataFolder then
		warn("Data folder not found for player: " .. player.Name)
		return
	end

	local playerCoins = dataFolder:WaitForChild("Coins", 5) -- Wait up to 5 seconds for the Coins value
	if not playerCoins then
		warn("Coins value not found in Data folder for player: " .. player.Name)
		return
	end

	-- Set the initial Coins value in leaderstats
	coinsStat.Value = playerCoins.Value

	-- Update leaderstats Coins value whenever Data.Coins changes
	playerCoins.Changed:Connect(function(newValue)
		coinsStat.Value = newValue
	end)

	print("Leaderstats setup complete for player: " .. player.Name)
end

-- Event when a player joins the game
Players.PlayerAdded:Connect(function(player)
	setupLeaderstats(player)
end)

-- Optional: Handle player removal (cleanup, if necessary)
Players.PlayerRemoving:Connect(function(player)
	print("Player " .. player.Name .. " has left the game.")
end)