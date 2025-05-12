local PickaxeUtils = require(game:GetService("ReplicatedStorage"):WaitForChild("PickaxeUtils"))
local ToolDefinitions = {}

-- Roll a random pickaxe
function ToolDefinitions.rollPickaxe()
	return PickaxeUtils.rollPickaxe()
end

return ToolDefinitions