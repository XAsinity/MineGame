-- BackpackUIScript.lua - robust UI update using server confirmation for pickaxe sells, with pickaxe inventory debug

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local playerGui = player:WaitForChild("PlayerGui")
local inventoryGui = playerGui:WaitForChild("InventoryGui")
local backpackUI = inventoryGui:WaitForChild("BackpackUI")

-- Selected chest and pickaxe info
local selectedChest = nil
local selectedPickaxe = nil

-- Buttons
local backpackButton = backpackUI:WaitForChild("BackpackButton")
local oreTabButton = backpackUI:WaitForChild("OreButton")
local chestTabButton = backpackUI:WaitForChild("ChestINVENTORY")
local pickaxeTabButton = backpackUI:WaitForChild("PickaxeButton")
local openButton = backpackUI:WaitForChild("OpenButton")
local sellPickaxeButton = backpackUI:WaitForChild("SellPickaxeButton")

-- Panels and Frames
local inventoryPanel = inventoryGui:WaitForChild("InventoryPanel")
local chestInventoryFrame = chestTabButton:WaitForChild("ScrollingFrame")
local pickaxeInventoryFrame = pickaxeTabButton:WaitForChild("ScrollingPickaxeUI")

-- Chest and Pickaxe slots
local chestSlots = {}
for i = 1, 10 do
	local slot = chestInventoryFrame:FindFirstChild("ChestSlot" .. i)
	if slot then
		table.insert(chestSlots, slot)
		slot.MouseButton1Click:Connect(function()
			selectedChest = slot:GetAttribute("ChestName")
			print("Selected chest:", selectedChest)
		end)
	else
		warn("ChestSlot" .. i .. " not found in ChestINVENTORY > ScrollingFrame!")
	end
end

local pickaxeSlots = {}
local pickaxeStats = {}
for i = 1, 20 do
	local slot = pickaxeInventoryFrame:FindFirstChild("Pickaxe" .. i)
	local statLabel = pickaxeInventoryFrame:FindFirstChild("StatPickaxe" .. i)
	if slot and statLabel then
		table.insert(pickaxeSlots, slot)
		table.insert(pickaxeStats, statLabel)
		slot.MouseButton1Click:Connect(function()
			selectedPickaxe = slot:GetAttribute("PickaxeName")
			print("Selected pickaxe:", selectedPickaxe)
		end)
	else
		warn("Pickaxe" .. i .. " or StatPickaxe" .. i .. " not found in ScrollingPickaxeUI!")
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
local removeChestEvent = ReplicatedStorage:WaitForChild("RemoveChestEvent")
local sellPickaxeEvent = ReplicatedStorage:WaitForChild("SellPickaxeEvent")

-- Utility functions

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

local function updateChestSlots()
	print("DEBUG: updateChestSlots called")
	clearChestSlots()
	selectedChest = nil
	local dataFolder = player:FindFirstChild("Data")
	if dataFolder then
		local chestsFolder = dataFolder:FindFirstChild("Chests")
		if chestsFolder then
			local chestIndex = 1
			for _, chest in ipairs(chestsFolder:GetChildren()) do
				print("DEBUG: Chest found in folder:", chest.Name)
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
			-- Defensive clear
			for i = chestIndex, #chestSlots do
				local slot = chestSlots[i]
				slot.Visible = false
				slot:SetAttribute("ChestName", nil)
				local textLabel = slot:FindFirstChild("TextLabel")
				if textLabel then
					textLabel.Text = ""
				end
				print("DEBUG: Forcibly cleared chest slot", i)
			end
		else
			print("No Chests folder found in player data.")
		end
	else
		print("No Data folder found for player.")
	end
end

local function updateOreCounts()
	local dataFolder = player:FindFirstChild("Data")
	if dataFolder then
		local oresFolder = dataFolder:FindFirstChild("Ores")
		if oresFolder then
			for oreName, oreUI in pairs(ores) do
				local oreValueObj = oresFolder:FindFirstChild(oreName)
				if oreValueObj then
					oreUI.Count.Text = tostring(oreValueObj.Value)
				else
					oreUI.Count.Text = "0"
				end
			end
		else
			for _, oreUI in pairs(ores) do
				oreUI.Count.Text = "0"
			end
		end
	end
end

local function clearPickaxeSlots()
	for i, slot in ipairs(pickaxeSlots) do
		slot.Visible = false
		slot:SetAttribute("PickaxeName", nil)
		local statLabel = pickaxeStats[i]
		if statLabel then
			statLabel.Text = ""
			statLabel.Visible = false
		end
	end
end

local function updatePickaxeSlots()
	print("DEBUG: updatePickaxeSlots called")

	-- Wait for Inventory and Pickaxes folder to exist
	local inventory = player:FindFirstChild("Inventory")
	if not inventory then
		print("DEBUG: No Inventory folder found for player.")
		return
	end
	local pickaxesFolder = inventory:FindFirstChild("Pickaxes")
	if not pickaxesFolder then
		print("DEBUG: Pickaxes folder not found in inventory.")
		return
	end

	-- Debug print of all pickaxe folders
	local pickaxeChildren = pickaxesFolder:GetChildren()
	print("DEBUG: PickaxesFolder has", #pickaxeChildren, "children")
	for idx, pickaxe in ipairs(pickaxeChildren) do
		print("DEBUG: Pickaxe folder:", pickaxe.Name)
	end

	clearPickaxeSlots()
	selectedPickaxe = nil

	local pickaxeIndex = 1
	for _, pickaxe in ipairs(pickaxeChildren) do
		if pickaxe:IsA("Folder") and pickaxeIndex <= #pickaxeSlots then
			local slot = pickaxeSlots[pickaxeIndex]
			local statLabel = pickaxeStats[pickaxeIndex]
			slot.Visible = true
			slot:SetAttribute("PickaxeName", pickaxe.Name)
			local miningSize = pickaxe:FindFirstChild("MiningSize") and pickaxe.MiningSize.Value or 0
			local durability = pickaxe:FindFirstChild("Durability") and pickaxe.Durability.Value or 0
			local rarity = pickaxe:FindFirstChild("Rarity") and pickaxe.Rarity.Value or "Unknown"
			statLabel.Visible = true
			statLabel.Text = string.format("Size: %d | Durability: %d | Rarity: %s", miningSize, durability, rarity)
			pickaxeIndex += 1
		end
	end
	-- Defensive clear for any slots past the last pickaxe
	for i = pickaxeIndex, #pickaxeSlots do
		local slot = pickaxeSlots[i]
		slot.Visible = false
		slot:SetAttribute("PickaxeName", nil)
		local statLabel = pickaxeStats[i]
		if statLabel then
			statLabel.Text = ""
			statLabel.Visible = false
		end
		print("DEBUG: Forcibly cleared pickaxe slot", i)
	end
end

-- Button logic

local function openSelectedChest()
	if selectedChest then
		local dataFolder = player:FindFirstChild("Data")
		if dataFolder then
			local chestsFolder = dataFolder:FindFirstChild("Chests")
			local pickaxesFolder = dataFolder:FindFirstChild("Pickaxes")
			if pickaxesFolder and #pickaxesFolder:GetChildren() >= 20 then
				warn("Cannot open chest: Pickaxe limit reached!")
				return
			end
			if chestsFolder then
				local chest = chestsFolder:FindFirstChild(selectedChest)
				if chest then
					openChestEvent:FireServer(selectedChest)
					removeChestEvent:FireServer(selectedChest, chest.Value <= 1)
					chest.Value = math.max(chest.Value - 1, 0)
					if chest.Value == 0 then
						chest:Destroy()
					end
					print("Opened chest:", selectedChest)
					selectedChest = nil
				else
					print("Chest no longer exists.")
				end
			end
		end
	else
		print("No chest selected!")
	end
end

local function sellSelectedPickaxe()
	if selectedPickaxe then
		print("DEBUG: Selling pickaxe", selectedPickaxe)
		sellPickaxeEvent:FireServer(selectedPickaxe)
		-- Do NOT updatePickaxeSlots() here; wait for server confirmation!
		selectedPickaxe = nil
	else
		print("No pickaxe selected to sell!")
	end
end

-- Hide all inventory panels and buttons
local function hideAllPanels()
	inventoryGui.Enabled = false
	inventoryPanel.Visible = false
	chestInventoryFrame.Visible = false
	pickaxeInventoryFrame.Visible = false
	oreTabButton.Visible = false
	chestTabButton.Visible = false
	pickaxeTabButton.Visible = false
	openButton.Visible = false
	sellPickaxeButton.Visible = false
	clearChestSlots()
	clearPickaxeSlots()
end

-- Show ores, hide chests and pickaxes
local function showOreTab()
	hideAllPanels()
	inventoryGui.Enabled = true
	inventoryPanel.Visible = true
	oreTabButton.Visible = true
	chestTabButton.Visible = true
	pickaxeTabButton.Visible = true
	updateOreCounts()
end

-- Show chests, hide ores and pickaxes
local function showChestTab()
	hideAllPanels()
	inventoryGui.Enabled = true
	chestInventoryFrame.Visible = true
	oreTabButton.Visible = true
	chestTabButton.Visible = true
	pickaxeTabButton.Visible = true
	openButton.Visible = true
	updateChestSlots()
end

-- Show pickaxes, hide ores and chests
local function showPickaxeTab()
	hideAllPanels()
	inventoryGui.Enabled = true
	pickaxeInventoryFrame.Visible = true
	oreTabButton.Visible = true
	chestTabButton.Visible = true
	pickaxeTabButton.Visible = true
	sellPickaxeButton.Visible = true
	updatePickaxeSlots()
end

-- Toggle inventory GUI visibility
local function toggleInventory()
	if inventoryGui.Enabled then
		hideAllPanels()
	else
		showOreTab()
	end
end

-- Startup
hideAllPanels()
inventoryGui.Enabled = false

-- Button connections
backpackButton.MouseButton1Click:Connect(toggleInventory)
oreTabButton.MouseButton1Click:Connect(showOreTab)
chestTabButton.MouseButton1Click:Connect(showChestTab)
pickaxeTabButton.MouseButton1Click:Connect(showPickaxeTab)
openButton.MouseButton1Click:Connect(openSelectedChest)
sellPickaxeButton.MouseButton1Click:Connect(sellSelectedPickaxe)

-- Live update logic for ores and chests
player:WaitForChild("Data"):WaitForChild("Ores").ChildAdded:Connect(updateOreCounts)
player:WaitForChild("Data"):WaitForChild("Ores").ChildRemoved:Connect(updateOreCounts)
player:WaitForChild("Data"):WaitForChild("Ores").ChildChanged:Connect(updateOreCounts)
player:WaitForChild("Data"):WaitForChild("Chests").ChildAdded:Connect(updateChestSlots)
player:WaitForChild("Data"):WaitForChild("Chests").ChildRemoved:Connect(updateChestSlots)

-- SERVER CONFIRMATION FOR PICKAXE SELL  
sellPickaxeEvent.OnClientEvent:Connect(function()
	print("DEBUG: Server confirmed pickaxe sell, refreshing UI")
	updatePickaxeSlots()
	selectedPickaxe = nil
end)

-- Defensive: always update pickaxes when showing pickaxes tab
pickaxeTabButton.MouseButton1Click:Connect(updatePickaxeSlots)
