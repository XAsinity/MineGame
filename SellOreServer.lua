local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Require the centralized OreDefinitions module
local OreDefinitions = require(ReplicatedStorage:WaitForChild("OreDefinitions"))

-- Use the validOres table from OreDefinitions
local validOres = OreDefinitions.validOres

local function sellOres(player)
	-- Access the player's inventory
	local inventory = player:FindFirstChild("Inventory")
	if not inventory then
		warn("No inventory found for player:", player.Name)
		return
	end

	local totalCoins = 0

	-- Iterate through the inventory and sell ores
	for _, oreItem in ipairs(inventory:GetChildren()) do
		if validOres[oreItem.Name] then
			local oreValue = oreItem.Value -- Amount of ore
			local orePrice = 10 -- Set a base price for each ore, or fetch it dynamically
			totalCoins += oreValue * orePrice
			oreItem.Value = 0 -- Reset the ore count after selling

			print("[Sell] Selling " .. oreValue .. " of " .. oreItem.Name .. " for " .. (oreValue * orePrice) .. " coins.")
		end
	end

	-- Update the player's coins
	local dataFolder = player:FindFirstChild("Data")
	if dataFolder then
		local coins = dataFolder:FindFirstChild("Coins")
		if coins then
			coins.Value += totalCoins
		end
	end

	print("[Sell] " .. player.Name .. " sold all ores for " .. totalCoins .. " coins.")
end

-- Listen for a remote event to sell ores
local sellOreEvent = ReplicatedStorage:WaitForChild("SellOreEvent")
sellOreEvent.OnServerEvent:Connect(sellOres)