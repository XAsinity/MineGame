local Players = game:GetService("Players")

-- Function to equip a tool
local function equipPickaxe(player, pickaxeName)
	local dataFolder = player:FindFirstChild("Data")
	if not dataFolder then return end

	local toolsFolder = dataFolder:FindFirstChild("Tools")
	if not toolsFolder then return end

	local selectedTool = toolsFolder:FindFirstChild(pickaxeName)
	if selectedTool then
		local equippedTool = dataFolder:FindFirstChild("EquippedTool")
		if not equippedTool then
			equippedTool = Instance.new("StringValue")
			equippedTool.Name = "EquippedTool"
			equippedTool.Parent = dataFolder
		end

		equippedTool.Value = pickaxeName
		print(player.Name .. " equipped:", pickaxeName)
	else
		warn("Tool not found in inventory:", pickaxeName)
	end
end
