local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local NPC_NAME = "OreSellerNPC"
local npc = workspace:WaitForChild(NPC_NAME)

-- Listen to SellFeedbackEvent instead of ShowSellBubbleEvent
local sellFeedbackEvent = ReplicatedStorage:WaitForChild("SellFeedbackEvent")


local TextChatService = game:GetService("TextChatService")


sellFeedbackEvent.OnClientEvent:Connect(function(amount)
	-- Use the Head part for displaying the bubble
	local head = npc:FindFirstChild("Head")
	if head then
		local message
		if tonumber(amount) and tonumber(amount) > 0 then
			message = string.format("Hey, Thanks for the rocks kid! Here is %s. Coins!", amount)
		else
			message = "Ya got nothing to sell kid, get back out there and get to mining!"
		end
		TextChatService:DisplayBubble(head, message)
	else
		warn("NPC does not have a valid part for displaying bubble.")
	end
end)
