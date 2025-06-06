local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local OreDefinitions = require(ReplicatedStorage:WaitForChild("OreDefinitions"))
local validOres = OreDefinitions.validOres

local showSellBubbleEvent = ReplicatedStorage:FindFirstChild("ShowSellBubbleEvent")
showSellBubbleEvent.Name = "ShowSellBubbleEvent"
showSellBubbleEvent.Parent = ReplicatedStorage

-- Use the oreValues lookup table from OreDefinitions for dynamic pricing!
local oreValues = OreDefinitions.oreValues

local function sellOres(player)
	local inventory = player:FindFirstChild("Inventory")
	if not inventory then
		warn("No inventory found for player:", player.Name)
		showSellBubbleEvent:FireClient(player, 0)
		return
	end

	local totalCoins = 0

	for _, oreItem in ipairs(inventory:GetChildren()) do
		if validOres[oreItem.Name] then
			local oreValue = oreItem.Value
			local orePrice = oreValues[oreItem.Name] or 10 -- fallback to 10 if somehow missing
			totalCoins += oreValue * orePrice
			oreItem.Value = 0
		end
	end

	local dataFolder = player:FindFirstChild("Data")
	if dataFolder then
		local coins = dataFolder:FindFirstChild("Coins")
		if coins then
			coins.Value += totalCoins
		end
	end

	-- Always fire the bubble event, even if nothing was sold!
	showSellBubbleEvent:FireClient(player, totalCoins)

	print("[Sell] " .. player.Name .. " sold all ores for " .. totalCoins .. " coins.")
end

local sellOreEvent = ReplicatedStorage:WaitForChild("SellOreEvent")
sellOreEvent.OnServerEvent:Connect(sellOres)