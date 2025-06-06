-- Place this LocalScript under WorldSelectGui in StarterGui
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- RemoteEvents
local unlockWorldEvent = ReplicatedStorage:WaitForChild("WorldUnlockRequest")
local teleportWorldEvent = ReplicatedStorage:WaitForChild("WorldTeleportRequest")
local worldUnlockStatusEvent = ReplicatedStorage:WaitForChild("WorldUnlockStatusEvent")

-- UI references
local playerGui = player:WaitForChild("PlayerGui")
local worldSelectGui = playerGui:WaitForChild("WorldSelectGui")

-- Buttons (direct children of WorldSelectGui)
local openWorldMenuButton = worldSelectGui:WaitForChild("OpenWorldMenuButton")
local overworldTeleport = worldSelectGui:WaitForChild("OverWorldTeleport")
local volcanoButton = worldSelectGui:WaitForChild("VolcanoButton")
local unlockButton = worldSelectGui:WaitForChild("UnlockButton")
local volcanoTeleport = worldSelectGui:WaitForChild("VolcanoTeleport")

-- Panels and Texts (children of WorldMenu)
local worldMenu = worldSelectGui:WaitForChild("WorldMenu")
local volcanoText = worldMenu:WaitForChild("VolcanoText")
local overworldText = worldMenu:WaitForChild("OverWorldText")
-- Add any other panels or texts here as needed

-- State
local volcanoUnlocked = false
local menuOpen = false

-- Utility to show/hide world menu UI
local function setMenu(open)
	-- Only panels/texts are toggled as a group:
	worldMenu.Visible = open
	-- Buttons shown/hidden individually
	overworldTeleport.Visible = open
	volcanoButton.Visible = open and not volcanoUnlocked
	unlockButton.Visible = false -- Only visible when volcanoButton is pressed
	volcanoTeleport.Visible = open and volcanoUnlocked
	menuOpen = open
end

local function updateWorldUI()
	-- Overworld: always unlocked, teleport always visible (when menu is open)
	overworldTeleport.Visible = menuOpen

	-- Volcano
	volcanoButton.Visible = menuOpen and not volcanoUnlocked
	unlockButton.Visible = false
	volcanoTeleport.Visible = menuOpen and volcanoUnlocked

	-- Volcano text update
	if volcanoUnlocked then
		volcanoText.Text = "Volcano World unlocked!"
	else
		volcanoText.Text = "Volcano World - Unlock for 50,000 coins"
	end
end

-- Open/close menu
openWorldMenuButton.MouseButton1Click:Connect(function()
	setMenu(not menuOpen)
	updateWorldUI()
end)

-- Volcano select
volcanoButton.MouseButton1Click:Connect(function()
	unlockButton.Visible = true
end)

-- Unlock volcano button
unlockButton.MouseButton1Click:Connect(function()
	unlockButton.Visible = false
	unlockWorldEvent:FireServer("Volcano")
end)

-- Overworld teleport
overworldTeleport.MouseButton1Click:Connect(function()
	-- Set local attribute to OverWorld for last touched plate (for immediate UI feedback, server will also set this)
	if player.SetAttribute then
		player:SetAttribute("LastTouchedSpawnPlate", "OverWorld")
	end
	teleportWorldEvent:FireServer("Overworld")
end)

-- Volcano teleport
volcanoTeleport.MouseButton1Click:Connect(function()
	if volcanoUnlocked then
		if player.SetAttribute then
			player:SetAttribute("LastTouchedSpawnPlate", "Volcano")
		end
		teleportWorldEvent:FireServer("Volcano")
	end
end)

-- Server tells us if volcano is unlocked
local function setWorldUnlockStatus(worldKey, unlocked)
	if worldKey == "Volcano" then
		volcanoUnlocked = unlocked
		updateWorldUI()
	end
end

worldUnlockStatusEvent.OnClientEvent:Connect(setWorldUnlockStatus)

-- Request initial unlock status when GUI loads
unlockWorldEvent:FireServer("StatusRequest")

-- Initialize UI
setMenu(false)
updateWorldUI()