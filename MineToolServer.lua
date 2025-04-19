local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local terrain = Workspace:FindFirstChild("Terrain")
local mineEvent = ReplicatedStorage:WaitForChild("MineEvent") -- RemoteEvent for mining

-- Debugging: Print the active terrain instance
if terrain then
	print("Active Terrain Instance:", terrain)
	print("Terrain Parent:", terrain.Parent)
else
	error("Terrain object not found in the Workspace!")
end

-- Function to handle mining
local function mineTerrain(player, targetPosition)
	print("mineTerrain called for player:", player.Name, "with target position:", targetPosition)

	local character = player.Character
	if not character then
		warn("Player's character not found!")
		return
	end

	local equippedTool = character:FindFirstChild("Starter Pickaxe")
	if not equippedTool then
		warn("Starter Pickaxe not equipped or found in character for player:", player.Name)
		return
	end

	local handle = equippedTool:FindFirstChild("Handle")
	if not handle then
		warn("Handle is missing from Starter Pickaxe!")
		return
	end

	local miningSizeValue = handle:FindFirstChild("MiningSize")
	if not miningSizeValue then
		warn("MiningSize value is missing from Starter Pickaxe!")
		return
	end

	local miningSize = miningSizeValue.Value
	print(player.Name .. " is mining with size:", miningSize)

	-- Define a spherical mining region
	local radius = miningSize * 1.5 -- Adjust this multiplier for desired size
	local centerPosition = targetPosition -- Use the exact clicked position as the sphere center
	print("Creating spherical mining region at position:", centerPosition, "with radius:", radius)

	-- Attempt to mine the terrain in a spherical region
	local success, err = pcall(function()
		for x = -radius, radius, 4 do
			for y = -radius, radius, 4 do
				for z = -radius, radius, 4 do
					local offset = Vector3.new(x, y, z)
					local distanceFromCenter = offset.Magnitude
					local position = centerPosition + offset

					-- Check if the point is within the sphere
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

-- Event listener for mining
mineEvent.OnServerEvent:Connect(function(player, targetPosition)
	if not player or not targetPosition then
		warn("Invalid player or target position passed to MineEvent!")
		return
	end

	print("MineEvent received from player:", player.Name, "Target Position:", targetPosition)
	mineTerrain(player, targetPosition)
end)
