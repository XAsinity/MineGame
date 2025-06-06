local sellZone = script.Parent -- Reference to the SellZone part
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OreDefinitions = require(ReplicatedStorage:WaitForChild("OreDefinitions"))

-- Reference the SellFeedbackEvent
local sellFeedbackEvent = ReplicatedStorage:WaitForChild("SellFeedbackEvent")

-- Create a debounce table to track players
local debounce = {}

-- Function to handle when a player touches the SellZone
local function onTouch(otherPart)
	-- Check if the touching part belongs to a character
	local character = otherPart.Parent
	local player = Players:GetPlayerFromCharacter(character)

	if player then
		-- Check if the player is already in the debounce table
		if debounce[player] then
			return -- Exit if the player is already debounced
		end

		-- Add the player to the debounce table
		debounce[player] = true

		print("[SellZone] Player " .. player.Name .. " entered the SellZone.")

		-- Access the player's Data folder and Ores folder
		local dataFolder = player:FindFirstChild("Data")
		if not dataFolder then
			warn("[SellZone] No Data folder found for player:", player.Name)
			sellFeedbackEvent:FireClient(player, 0) -- Notify no ores to sell
			debounce[player] = nil -- Remove the player from debounce after processing
			return
		end

		local oresFolder = dataFolder:FindFirstChild("Ores")
		if not oresFolder then
			warn("[SellZone] No Ores folder found in Data for player:", player.Name)
			sellFeedbackEvent:FireClient(player, 0) -- Notify no ores to sell
			debounce[player] = nil -- Remove the player from debounce after processing
			return
		end

		local oreValues = OreDefinitions.oreValues
		local totalCoins = 0

		-- Iterate through the Ores folder and sell ores
		for _, oreValue in ipairs(oresFolder:GetChildren()) do
			if oreValue:IsA("IntValue") and oreValue.Value > 0 then
				local oreAmount = oreValue.Value
				local orePrice = oreValues[oreValue.Name] or 10 -- fallback to 10 coins if not found
				totalCoins += oreAmount * orePrice
				oreValue.Value = 0 -- Reset the ore count after selling

				print("[Sell] Selling " .. oreAmount .. " of " .. oreValue.Name .. " for " .. (oreAmount * orePrice) .. " coins.")
			end
		end

		-- Update the player's Coins in the Data folder
		local coins = dataFolder:FindFirstChild("Coins")
		if coins then
			coins.Value += totalCoins
		else
			warn("[SellZone] Coins object not found in Data for player:", player.Name)
		end

		-- Notify the player of the result via SellFeedbackEvent
		sellFeedbackEvent:FireClient(player, totalCoins)

		print("[SellZone] " .. player.Name .. " sold all ores for " .. totalCoins .. " coins.")

		-- Add a short delay before allowing the player to sell again
		task.wait(2) -- Adjust the delay as needed (2 seconds here)
		debounce[player] = nil -- Remove the player from the debounce table
	end
end

-- Connect the Touched event
sellZone.Touched:Connect(onTouch)

