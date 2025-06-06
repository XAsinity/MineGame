-- Place in ServerScriptService
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local WorldModule = require(script.Parent:WaitForChild("WorldModule"))

-- RemoteEvents (should exist in ReplicatedStorage)
local unlockWorldEvent = ReplicatedStorage:WaitForChild("WorldUnlockRequest")
local teleportWorldEvent = ReplicatedStorage:WaitForChild("WorldTeleportRequest")
local worldUnlockStatusEvent = ReplicatedStorage:WaitForChild("WorldUnlockStatusEvent")

-- Helper: send unlock status for all worlds to a player
local function sendAllWorldStatuses(player)
	for worldKey, _ in pairs(WorldModule.Worlds) do
		local unlocked = WorldModule.IsWorldUnlocked(player, worldKey)
		worldUnlockStatusEvent:FireClient(player, worldKey, unlocked)
	end
end

-- On player join, initialize their world data and send status
Players.PlayerAdded:Connect(function(player)
	WorldModule.GetOrCreateWorldData(player)
	-- Wait a tick for UI to load on client before firing events
	task.wait(1)
	sendAllWorldStatuses(player)
end)

-- Handle unlock requests
unlockWorldEvent.OnServerEvent:Connect(function(player, worldKey)
	if worldKey == "StatusRequest" then
		sendAllWorldStatuses(player)
		return
	end

	local success, message = WorldModule.TryUnlockWorld(player, worldKey)
	-- Send updated status back for this world
	worldUnlockStatusEvent:FireClient(player, worldKey, WorldModule.IsWorldUnlocked(player, worldKey))
	-- Optionally, you can also surface the message to the player (e.g., with a notification RemoteEvent)
end)

-- Handle teleport requests
teleportWorldEvent.OnServerEvent:Connect(function(player, worldKey)
	-- Only teleport if world is unlocked
	if WorldModule.IsWorldUnlocked(player, worldKey) then
		WorldModule.TeleportToWorld(player, worldKey)
	else
		-- Optionally notify: world not unlocked
	end
end)
