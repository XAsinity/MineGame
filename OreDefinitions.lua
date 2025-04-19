local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OreDefinitions = {}

-- Centralized ore definitions with all properties
OreDefinitions.oreTypes = {
	{name = "Coal", template = game.ReplicatedStorage:WaitForChild("Coal"), frequency = 0.7, depthRange = {0.7, 1.0}, overlapChance = 0.0},
	{name = "Iron", template = game.ReplicatedStorage:WaitForChild("Iron"), frequency = 0.5, depthRange = {0.4, 0.7}, overlapChance = 0.1},
	{name = "Copper", template = game.ReplicatedStorage:WaitForChild("Copper"), frequency = 0.5, depthRange = {0.4, 0.7}, overlapChance = 0.1},
	{name = "Gold", template = game.ReplicatedStorage:WaitForChild("Gold"), frequency = 0.3, depthRange = {0.0, 0.4}, overlapChance = 0.05}
}

OreDefinitions.validOres = {
	["Coal"] = true,
	["Iron"] = true,
	["Copper"] = true,
	["Gold"] = true
}

return OreDefinitions