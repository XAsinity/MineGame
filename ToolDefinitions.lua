local ToolDefinitions = {}

-- Rarity weights (can be changed for balancing)
ToolDefinitions.Rarities = {
	Common = 60,
	Uncommon = 25,
	Rare = 10,
	Epic = 4,
	Legendary = 1
}

ToolDefinitions.RarityList = {
	"Common", "Uncommon", "Rare", "Epic", "Legendary"
}

-- MiningSize ranges and weighted subranges for each rarity
ToolDefinitions.RarityMiningRanges = {
	Common = {
		overall = {min = 1, max = 6},
		favored = {min = 1, max = 4},  -- 80% chance to be in this favored range
		favoredWeight = 0.8,
		decimalStep = 0.1
	},
	Uncommon = {
		overall = {min = 2, max = 8},
		favored = {min = 4, max = 6},
		favoredWeight = 0.7,
		decimalStep = 0.1
	},
	Rare = {
		overall = {min = 3, max = 10},
		favored = {min = 6, max = 8},
		favoredWeight = 0.7,
		decimalStep = 0.1
	},
	Epic = {
		overall = {min = 4, max = 12},
		favored = {min = 6, max = 10},
		favoredWeight = 0.65,
		decimalStep = 0.1
	},
	Legendary = {
		overall = {min = 6, max = 14},
		favored = {min = 8, max = 12},
		favoredWeight = 0.6,
		decimalStep = 0.1
	}
}

-- Returns a random float in [min, max] in increments of step
local function randomIncrement(min, max, step)
	local steps = math.floor((max - min) / step + 0.5)
	local value = min + step * math.random(0, steps)
	return math.floor(value * 100 + 0.5) / 100  -- round to 2 decimal places
end

-- Roll for a random rarity based on weights
function ToolDefinitions.rollRarity()
	local totalWeight = 0
	for _, weight in pairs(ToolDefinitions.Rarities) do
		totalWeight = totalWeight + weight
	end

	local roll = math.random(1, totalWeight)
	local currentWeight = 0
	for rarity, weight in pairs(ToolDefinitions.Rarities) do
		currentWeight = currentWeight + weight
		if roll <= currentWeight then
			return rarity
		end
	end
	return "Common"
end

-- Roll a random MiningSize for a given rarity
function ToolDefinitions.rollMiningSize(rarity)
	local range = ToolDefinitions.RarityMiningRanges[rarity]
	if not range then
		range = ToolDefinitions.RarityMiningRanges["Common"]
	end

	local useFavored = math.random() <= range.favoredWeight
	local min, max
	if useFavored then
		min, max = range.favored.min, range.favored.max
	else
		min, max = range.overall.min, range.overall.max
	end
	return randomIncrement(min, max, range.decimalStep)
end

-- Roll a random pickaxe
function ToolDefinitions.rollPickaxe()
	local rarity = ToolDefinitions.rollRarity()
	local miningSize = ToolDefinitions.rollMiningSize(rarity)
	return {
		Name = rarity .. " Pickaxe",
		MiningSize = miningSize,
		Rarity = rarity
	}
end

-- Returns info for a fixed pickaxe by name (legacy support)
function ToolDefinitions.getPickaxeByName(name)
	-- Now just returns a default value, can be expanded later if needed
	for rarity, _ in pairs(ToolDefinitions.Rarities) do
		if name == rarity .. " Pickaxe" then
			return {
				Name = rarity .. " Pickaxe",
				MiningSize = ToolDefinitions.rollMiningSize(rarity),
				Rarity = rarity
			}
		end
	end
	return nil
end

return ToolDefinitions

