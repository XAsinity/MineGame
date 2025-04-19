local ToolDefinitions = {}

-- Define rarities and their probabilities
ToolDefinitions.Rarities = {
	Common = 60, -- 60% chance
	Uncommon = 25, -- 25% chance
	Rare = 10, -- 10% chance
	Epic = 4, -- 4% chance
	Legendary = 1 -- 1% chance
}

-- Define base tools (names and base mining sizes)
ToolDefinitions.BaseTools = {
	{ Name = "Starter Pickaxe", MiningSize = 4 }, -- Fixed size for starter pickaxe
	{ Name = "Bronze Pickaxe", MiningSize = 6 },
	{ Name = "Silver Pickaxe", MiningSize = 8 },
	{ Name = "Gold Pickaxe", MiningSize = 10 },
	{ Name = "Platinum Pickaxe", MiningSize = 12 }
}

return ToolDefinitions
