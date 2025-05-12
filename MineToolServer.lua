local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local terrain = Workspace:FindFirstChild("Terrain")
local mineEvent = ReplicatedStorage:WaitForChild("MineEvent")

-- Module dependencies
local ToolDefinitions = require(ReplicatedStorage:WaitForChild("ToolDefinitions"))
local InventoryModule = require(ServerScriptService:WaitForChild("InventoryModule"))

if terrain then
	print("Active Terrain Instance:", terrain)
	print("Terrain Parent:", terrain.Parent)
else
	error("Terrain object not found in the Workspace!")
end

-------------------------------
-- Testing Utilities Section --
-------------------------------
-- (Safe to remove later)

-- Manual pickaxe grant event for testing
local requestRandomPickaxeEvent = ReplicatedStorage:FindFirstChild("RequestRandomPickaxeEvent")
if not requestRandomPickaxeEvent then
	requestRandomPickaxeEvent = Instance.new("RemoteEvent")
	requestRandomPickaxeEvent.Name = "RequestRandomPickaxeEvent"
	requestRandomPickaxeEvent.Parent = ReplicatedStorage
end

local function grantRandomPickaxe(player)
	local pickaxeDef = ToolDefinitions.rollPickaxe()
	InventoryModule.grantPickaxeToPlayer(player, pickaxeDef)
end

requestRandomPickaxeEvent.OnServerEvent:Connect(function(player)
	grantRandomPickaxe(player)
end)

-------------------------------
--      Mining Section       --
-------------------------------

-- Accept miningSize directly from the client
local function mineTerrain(player, targetPosition, miningSize)
	print("mineTerrain called for player:", player.Name, "with target position:", targetPosition)

	local character = player.Character
	if not character then
		warn("Player's character not found!")
		return
	end

	-- Find the equipped tool (any pickaxe with Handle and MiningSize)
	local equippedTool
	for _, tool in ipairs(character:GetChildren()) do
		if tool:IsA("Tool") then
			local handle = tool:FindFirstChild("Handle")
			if handle and handle:FindFirstChild("MiningSize") then
				equippedTool = tool
				break
			end
		end
	end

	if not equippedTool then
		warn("No valid pickaxe equipped for player:", player.Name)
		return
	end

	local handle = equippedTool:FindFirstChild("Handle")
	if not handle then
		warn("Handle is missing from equipped pickaxe!")
		return
	end

	local miningSizeValue = handle:FindFirstChild("MiningSize")
	if not miningSizeValue then
		warn("MiningSize value is missing from equipped pickaxe!")
		return
	end

	print(player.Name .. " is mining with size:", miningSize)

	local radius = miningSize * 1.5
	local centerPosition = targetPosition

	local success, err = pcall(function()
		for x = -radius, radius, 4 do
			for y = -radius, radius, 4 do
				for z = -radius, radius, 4 do
					local offset = Vector3.new(x, y, z)
					local distanceFromCenter = offset.Magnitude
					local position = centerPosition + offset

					if distanceFromCenter <= radius then
						terrain:FillBlock(CFrame.new(position), Vector3.new(4, 4, 4), Enum.Material.Air)
					end
				end
			end
		end
	end)

	if success then
		print("Terrain successfully deleted at:", centerPosition)
	else
		warn("Error deleting terrain:", err)
	end
end

mineEvent.OnServerEvent:Connect(function(player, targetPosition, miningSize)
	if not player or not targetPosition or not miningSize then
		warn("Invalid player, target position, or mining size passed to MineEvent!")
		return
	end

	print("MineEvent received from player:", player.Name, "Target Position:", targetPosition, "Mining Size:", miningSize)
	mineTerrain(player, targetPosition, miningSize)
end)