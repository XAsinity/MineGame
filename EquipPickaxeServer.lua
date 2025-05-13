local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local equipPickaxeEvent = ReplicatedStorage:WaitForChild("EquipPickaxeEvent") -- RemoteEvent for equipping pickaxes

-- Function to equip a pickaxe
local function equipPickaxe(player, pickaxeName)
	-- Locate required folders
	local dataFolder = player:FindFirstChild("Data")
	if not dataFolder then
		warn("Data folder missing for player:", player.Name)
		return
	end

	local pickaxeFolder = dataFolder:FindFirstChild("Pickaxes")
	if not pickaxeFolder then
		warn("Pickaxes folder missing in Data for player:", player.Name)
		return
	end

	-- Check if the pickaxe exists in the player's pickaxe inventory
	local selectedPickaxe = pickaxeFolder:FindFirstChild(pickaxeName)
	if not selectedPickaxe then
		warn("Pickaxe not found in inventory:", pickaxeName)
		return
	end

	-- Check if the player already has an equipped pickaxe
	local equippedPickaxe = dataFolder:FindFirstChild("EquippedPickaxe")
	if not equippedPickaxe then
		equippedPickaxe = Instance.new("StringValue")
		equippedPickaxe.Name = "EquippedPickaxe"
		equippedPickaxe.Parent = dataFolder
	end

	-- Update the equipped pickaxe value
	equippedPickaxe.Value = pickaxeName
	print(player.Name .. " equipped pickaxe:", pickaxeName)

	-- Optional: Send feedback to the client (e.g., UI update)
	if equipPickaxeEvent then
		equipPickaxeEvent:FireClient(player, pickaxeName)
	end
end

-- Event listener for client requests to equip a pickaxe
equipPickaxeEvent.OnServerEvent:Connect(function(player, pickaxeName)
	if not pickaxeName then
		warn("No pickaxe name provided by player:", player.Name)
		return
	end

	equipPickaxe(player, pickaxeName)
end)

-- Auto-equip a default pickaxe when the player's character is added
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		wait(1) -- Wait for the player's character to fully load

		-- Equip a default pickaxe (e.g., "Starter Pickaxe") if none is equipped
		local dataFolder = player:FindFirstChild("Data")
		if dataFolder then
			local equippedPickaxe = dataFolder:FindFirstChild("EquippedPickaxe")
			if not equippedPickaxe or equippedPickaxe.Value == "" then
				equipPickaxe(player, "Starter Pickaxe") -- Replace "Starter Pickaxe" with your default pickaxe name
			end
		end
	end)
end)