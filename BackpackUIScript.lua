local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local playerGui = player:WaitForChild("PlayerGui")
local inventoryGui = playerGui:WaitForChild("InventoryGui")
local backpackUI = inventoryGui:WaitForChild("BackpackUI")

-- Buttons (children of BackpackUI)
local backpackButton = backpackUI:WaitForChild("BackpackButton")
local oreTabButton = backpackUI:WaitForChild("OreButton")
local chestTabButton = backpackUI:WaitForChild("ChestINVENTORY")
local openButton = backpackUI:WaitForChild("OpenButton") -- Button to open the selected chest

-- Panels
local inventoryPanel = inventoryGui:WaitForChild("InventoryPanel") -- Displays ore information
local chestInventoryFrame = chestTabButton:WaitForChild("ScrollingFrame") -- Displays chest inventory

-- Chest Slots (inside ScrollingFrame under ChestINVENTORY)
local chestSlots = {}
for i = 1, 10 do
	local slot = chestInventoryFrame:FindFirstChild("ChestSlot" .. i)
	if slot then
		table.insert(chestSlots, slot)
	else
		warn("ChestSlot" .. i .. " not found in ChestINVENTORY > ScrollingFrame!")
	end
end

-- Ore UI mapping
local ores = {
	Coal = {
		Image = inventoryPanel:WaitForChild("CoalImage"),
		Count = inventoryPanel:WaitForChild("CoalCount"),
	},
	Iron = {
		Image = inventoryPanel:WaitForChild("IronImage"),
		Count = inventoryPanel:WaitForChild("IronCount"),
	},
	Copper = {
		Image = inventoryPanel:WaitForChild("CopperImage"),
		Count = inventoryPanel:WaitForChild("CopperCount"),
	},
	Gold = {
		Image = inventoryPanel:WaitForChild("GoldImage"),
		Count = inventoryPanel:WaitForChild("GoldCount"),
	},
}

-- Remote Events
local openChestEvent = ReplicatedStorage:WaitForChild("OpenChestEvent")
local requestRandomPickaxeEvent = ReplicatedStorage:WaitForChild("RequestRandomPickaxeEvent")
local removeChestEvent = ReplicatedStorage:WaitForChild("RemoveChestEvent") -- New event to remove chest from data

-- Selected chest info
local selectedChest = nil

-- Function to clear all chest slots
local function clearChestSlots()
	for _, slot in ipairs(chestSlots) do
		slot.Visible = false
		slot:SetAttribute("ChestName", nil)
		local textLabel = slot:FindFirstChild("TextLabel")
		if textLabel then
			textLabel.Text = ""
		end
	end
end

-- Function to update chest slots
local function updateChestSlots()
	clearChestSlots()

	local dataFolder = player:FindFirstChild("Data")
	if dataFolder then
		local chestsFolder = dataFolder:FindFirstChild("Chests")
		if chestsFolder then
			local chestIndex = 1
			for _, chest in ipairs(chestsFolder:GetChildren()) do
				if chest:IsA("IntValue") and chestIndex <= #chestSlots then
					local slot = chestSlots[chestIndex]
					slot.Visible = true
					slot:SetAttribute("ChestName", chest.Name)
					slot:SetAttribute("ChestCount", chest.Value)

					local textLabel = slot:FindFirstChild("TextLabel")
					if textLabel then
						textLabel.Text = chest.Name .. " x" .. chest.Value
					end

					chestIndex += 1
				end
			end
		else
			print("No Chests folder found in player data.")
		end
	else
		print("No Data folder found for player.")
	end
end

-- Function to select a chest
local function selectChest(slot)
	selectedChest = slot:GetAttribute("ChestName")
	print("Selected chest:", selectedChest)
end

-- Connect chest slots to selection functionality
for _, slot in ipairs(chestSlots) do
	slot.MouseButton1Click:Connect(function()
		selectChest(slot)
	end)
end

-- Function to open a chest
local function openSelectedChest()
	if selectedChest then
		local dataFolder = player:FindFirstChild("Data")
		if dataFolder then
			local chestsFolder = dataFolder:FindFirstChild("Chests")
			if chestsFolder then
				local chestToOpen = chestsFolder:FindFirstChild(selectedChest)
				if chestToOpen then
					-- Decrease chest count or remove chest
					if chestToOpen.Value > 1 then
						-- Decrease chest count locally
						chestToOpen.Value -= 1
						removeChestEvent:FireServer(selectedChest, false) -- Notify server to decrease count
					else
						-- Destroy chest locally
						chestToOpen:Destroy()
						removeChestEvent:FireServer(selectedChest, true) -- Notify server to remove chest
					end

					-- Trigger events
					openChestEvent:FireServer(selectedChest)
					requestRandomPickaxeEvent:FireServer(selectedChest)

					-- Update chest slots
					updateChestSlots()

					print("Opened chest:", selectedChest)
					selectedChest = nil -- Deselect chest after opening
				else
					print("Chest no longer exists.")
				end
			end
		end
	else
		print("No chest selected!")
	end
end

-- Connect the open button to the open function
openButton.MouseButton1Click:Connect(openSelectedChest)

-- Function to update ore UI
local function updateOreCount(oreName, newValue)
	if ores[oreName] then
		ores[oreName].Count.Text = newValue .. "x"
	end
end

-- Connect live ore updates
local function connectLiveUpdates()
	local dataFolder = player:FindFirstChild("Data")
	if dataFolder then
		local oresFolder = dataFolder:FindFirstChild("Ores")
		if oresFolder then
			for oreName, uiElements in pairs(ores) do
				local oreValue = oresFolder:FindFirstChild(oreName)
				if oreValue then
					oreValue.Changed:Connect(function(newValue)
						updateOreCount(oreName, newValue)
					end)
					updateOreCount(oreName, oreValue.Value)
				else
					warn("Ore type not found in player's Ores folder:", oreName)
				end
			end
		else
			warn("Ores folder not found in player's Data folder:", player.Name)
		end
	else
		warn("Data folder not found for player:", player.Name)
	end
end

-- Hide all inventory panels and buttons
local function hideAllPanels()
	inventoryGui.Enabled = false
	inventoryPanel.Visible = false
	chestInventoryFrame.Visible = false
	oreTabButton.Visible = false
	chestTabButton.Visible = false
	openButton.Visible = false
	clearChestSlots()
end

-- Show ores, hide chests
local function showOreTab()
	hideAllPanels()
	inventoryGui.Enabled = true
	inventoryPanel.Visible = true
	oreTabButton.Visible = true
	chestTabButton.Visible = true
end

-- Show chests, hide ores
local function showChestTab()
	hideAllPanels()
	inventoryGui.Enabled = true
	chestInventoryFrame.Visible = true
	oreTabButton.Visible = true
	chestTabButton.Visible = true
	openButton.Visible = true
	updateChestSlots()
end

-- Toggle inventory GUI visibility
local function toggleInventory()
	if inventoryGui.Enabled then
		hideAllPanels()
	else
		showOreTab() -- Default to showing the ore panel
	end
end

-- Initial setup
hideAllPanels()
inventoryGui.Enabled = false

-- Backpack button: toggles inventory open/close
backpackButton.MouseButton1Click:Connect(toggleInventory)

-- Tab button connections
oreTabButton.MouseButton1Click:Connect(showOreTab)
chestTabButton.MouseButton1Click:Connect(showChestTab)

-- Connect live updates
connectLiveUpdates()
player:WaitForChild("Data"):WaitForChild("Chests").ChildAdded:Connect(updateChestSlots)
player:WaitForChild("Data"):WaitForChild("Chests").ChildRemoved:Connect(updateChestSlots)