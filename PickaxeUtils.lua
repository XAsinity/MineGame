local PickaxeUtils = {}

-- Rarity weights (can be changed for balancing)
PickaxeUtils.Rarities = {
	Common = 60,
	Uncommon = 25,
	Rare = 10,
	Epic = 4,
	Legendary = 1
}

PickaxeUtils.RarityList = {
	"Common", "Uncommon", "Rare", "Epic", "Legendary"
}

-- MiningSize ranges, Durability ranges, and weighted subranges for each rarity
PickaxeUtils.RarityMiningRanges = {
	Common = {
		overall = {min = 1, max = 6},
		favored = {min = 1, max = 4},
		favoredWeight = 0.8,
		decimalStep = 0.1,
		durability = {min = 20, max = 50}
	},
	Uncommon = {
		overall = {min = 2, max = 8},
		favored = {min = 4, max = 6},
		favoredWeight = 0.7,
		decimalStep = 0.1,
		durability = {min = 50, max = 100}
	},
	Rare = {
		overall = {min = 4, max = 10},
		favored = {min = 8, max = 10},
		favoredWeight = 0.6,
		decimalStep = 0.1,
		durability = {min = 100, max = 150}
	},
	Epic = {
		overall = {min = 7, max = 12},
		favored = {min = 10, max = 12},
		favoredWeight = 0.5,
		decimalStep = 0.1,
		durability = {min = 150, max = 200}
	},
	Legendary = {
		overall = {min = 10, max = 15},
		favored = {min = 13, max = 15},
		favoredWeight = 0.4,
		decimalStep = 0.1,
		durability = {min = 200, max = 300}
	}
}

-- Generate a unique identifier for a pickaxe
function PickaxeUtils.generatePickaxeId(rarity, durability)
	return rarity .. "_" .. durability .. "_" .. os.time()
end

-- Roll a random rarity
function PickaxeUtils.rollRarity()
	local totalWeight = 0
	for _, weight in pairs(PickaxeUtils.Rarities) do
		totalWeight += weight
	end

	local roll = math.random(1, totalWeight)
	local cumulativeWeight = 0

	for rarity, weight in pairs(PickaxeUtils.Rarities) do
		cumulativeWeight += weight
		if roll <= cumulativeWeight then
			return rarity
		end
	end

	-- Fallback in case of a misconfiguration
	warn("Rarity roll failed! Defaulting to Common.")
	return "Common"
end

-- Roll a random mining size based on rarity
function PickaxeUtils.rollMiningSize(rarity)
	local range = PickaxeUtils.RarityMiningRanges[rarity]
	local favored = math.random() <= range.favoredWeight
	local min, max

	if favored then
		min, max = range.favored.min, range.favored.max
	else
		min, max = range.overall.min, range.overall.max
	end

	-- Return rounded value for compatibility with in-game logic
	return math.floor(math.random() * (max - min) + min + 0.5)
end

-- Roll durability based on rarity
function PickaxeUtils.rollDurability(rarity)
	local range = PickaxeUtils.RarityMiningRanges[rarity].durability
	return math.random(range.min, range.max)
end

-- Roll a random pickaxe with a unique ID
function PickaxeUtils.rollPickaxe()
	local rarity = PickaxeUtils.rollRarity()
	local miningSize = PickaxeUtils.rollMiningSize(rarity)
	local durability = PickaxeUtils.rollDurability(rarity)
	local pickaxeId = PickaxeUtils.generatePickaxeId(rarity, durability)

	return {
		Name = rarity .. " Pickaxe",
		MiningSize = miningSize,
		Durability = durability,
		Rarity = rarity,
		PickaxeId = pickaxeId
	}
end

return PickaxeUtils