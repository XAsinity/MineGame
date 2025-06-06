local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local coinsTextLabel = script.Parent

-- The name of the IntValue in leaderstats that holds the coins.
-- This MUST match the name used in your Leaderstats server script (Instance_1_10921).
local COINS_STAT_NAME = "Coins"

local leaderstats = LocalPlayer:WaitForChild("leaderstats")
local coinsObject = leaderstats:WaitForChild(COINS_STAT_NAME)

-- Table of suffixes and their values
local suffixes = {
    {10^63, "Vg"}, {10^60, "Nd"}, {10^57, "Od"}, {10^54, "Spd"}, {10^51, "Sxd"}, {10^48, "Qtd"}, {10^45, "Qd"}, 
    {10^42, "Td"}, {10^39, "Dd"}, {10^36, "Ud"}, {10^33, "D"}, {10^30, "N"}, {10^27, "O"}, {10^24, "Sp"}, 
    {10^21, "Sx"}, {10^18, "Qt"}, {10^15, "Q"}, {10^12, "T"}, {10^9, "B"}, {10^6, "M"}, {10^3, "K"}
}

-- Function to format the number with suffixes
local function formatNumber(number)
    if not number or number < 0 then
        return "0"
    end

    for i, suffixInfo in suffixes do
        local value = suffixInfo[1]
        local suffix = suffixInfo[2]
        if number >= value then
            local formattedNum = number / value
            -- Check if the number is a whole number or needs one decimal place
            if formattedNum % 1 == 0 then
                return string.format("%d%s", formattedNum, suffix)
            else
                return string.format("%.1f%s", formattedNum, suffix)
            end
        end
    end
    return tostring(math.floor(number)) -- Return the number as is if less than 1000, floored
end

-- Function to update the TextLabel with the formatted coins
local function updateCoinsDisplay(newCoinsValue)
    if coinsTextLabel then
        coinsTextLabel.Text = formatNumber(newCoinsValue)
    end
end

-- Initial update when the script runs
if coinsObject then
    updateCoinsDisplay(coinsObject.Value)
end

-- Connect to the .Changed event to update the text whenever the coins value changes
if coinsObject then
    coinsObject.Changed:Connect(function(newCoinsValue)
        updateCoinsDisplay(newCoinsValue)
    end)
end

