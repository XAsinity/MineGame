local ShopButton = script.Parent
local ScrollingFrame = ShopButton:FindFirstChild("ScrollingFrame")
local MinusButton = ShopButton:FindFirstChild("MinusButton")
local PlusButton = ShopButton:FindFirstChild("PlusButton")
local PurchaseButton1 = ShopButton:FindFirstChild("PurchaseButton1")
local TextLabel = ShopButton:FindFirstChild("TextLabel")
local TextLabel2 = ShopButton:FindFirstChild("TextLabel2")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopPurchaseEvent = ReplicatedStorage:FindFirstChild("ShopPurchaseEvent") or Instance.new("RemoteEvent")
ShopPurchaseEvent.Name = "ShopPurchaseEvent"
ShopPurchaseEvent.Parent = ReplicatedStorage

local minAmount = 1
local maxAmount = 99
local amount = 1
local pricePerChest = 500

-- Function to toggle all shop UI elements
local function setShopVisible(visible)
	ScrollingFrame.Visible = visible
	MinusButton.Visible = visible
	PlusButton.Visible = visible
	PurchaseButton1.Visible = visible
	TextLabel.Visible = visible
	TextLabel2.Visible = visible
end

-- Hide everything on start
setShopVisible(false)

-- Toggle shop UI on ShopButton click
ShopButton.MouseButton1Click:Connect(function()
	local newState = not ScrollingFrame.Visible
	setShopVisible(newState)
end)

-- Update amount/price label logic as before
local function updateUI()
	TextLabel.Text = tostring(amount)
	TextLabel2.Text = "Total: " .. tostring(amount * pricePerChest) .. " Coins"
end

updateUI()

MinusButton.MouseButton1Click:Connect(function()
	if amount > minAmount then
		amount = amount - 1
		updateUI()
	end
end)

PlusButton.MouseButton1Click:Connect(function()
	if amount < maxAmount then
		amount = amount + 1
		updateUI()
	end
end)

PurchaseButton1.MouseButton1Click:Connect(function()
	if amount >= minAmount and amount <= maxAmount then
		ShopPurchaseEvent:FireServer(amount)
	end
end)