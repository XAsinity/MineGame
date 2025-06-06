local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OreDefinitions = {}

-- Centralized ore definitions with all properties (including coinValue and world)
OreDefinitions.oreTypes = {
	-- Base World Ores
	{name = "Coal",     template = ReplicatedStorage:WaitForChild("Coal"),     frequency = 0.7,  depthRange = {0.7, 1.0}, overlapChance = 0.0,  coinValue = 5,   world = "base"},
	{name = "Iron",     template = ReplicatedStorage:WaitForChild("Iron"),     frequency = 0.5,  depthRange = {0.4, 0.7}, overlapChance = 0.1,  coinValue = 15,  world = "base"},
	{name = "Copper",   template = ReplicatedStorage:WaitForChild("Copper"),   frequency = 0.5,  depthRange = {0.4, 0.7}, overlapChance = 0.1,  coinValue = 10,  world = "base"},
	{name = "Gold",     template = ReplicatedStorage:WaitForChild("Gold"),     frequency = 0.3,  depthRange = {0.0, 0.4}, overlapChance = 0.05, coinValue = 40,  world = "base"},

	-- Volcano World Ores
	{name = "Lead",     template = ReplicatedStorage:WaitForChild("Lead"),     frequency = 0.8,  depthRange = {0.7, 1.0}, overlapChance = 0.0,  coinValue = 8,   world = "volcano"},      -- Most common, top
	{name = "Nickel",   template = ReplicatedStorage:WaitForChild("Nickel"),   frequency = 0.6,  depthRange = {0.4, 0.7}, overlapChance = 0.07, coinValue = 20,  world = "volcano"},    -- 2nd most common, just below Lead
	{name = "Gold",     template = ReplicatedStorage:WaitForChild("Gold"),     frequency = 0.4,  depthRange = {0.2, 0.4}, overlapChance = 0.05, coinValue = 40,  world = "volcano"},    -- Gold for volcano, deeper than Nickel
	{name = "Diamonds", template = ReplicatedStorage:WaitForChild("Diamonds"), frequency = 0.15, depthRange = {0, 0.2},   overlapChance = 0.03, coinValue = 100, world = "volcano"}    -- Diamonds, very bottom/rarest
}

OreDefinitions.validOres = {
	-- Base Ores
	["Coal"] = true,
	["Iron"] = true,
	["Copper"] = true,
	["Gold"] = true,
	-- Volcano Ores
	["Lead"] = true,
	["Nickel"] = true,
	["Diamonds"] = true
}

-- Allows for quick ore value lookup by name:
OreDefinitions.oreValues = {}
for _, def in ipairs(OreDefinitions.oreTypes) do
	OreDefinitions.oreValues[def.name] = def.coinValue or 10 -- fallback/default
end

return OreDefinitions