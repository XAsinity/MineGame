local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create events if they don't exist
local function createEvent(eventName)
	if not ReplicatedStorage:FindFirstChild(eventName) then
		local event = Instance.new("RemoteEvent")
		event.Name = eventName
		event.Parent = ReplicatedStorage
		print("Created RemoteEvent:", eventName)
	end
end

createEvent("MineEvent")
createEvent("OreCollectionEvent")
createEvent("SpawnOresEvent")
createEvent("SellOreEvent")
createEvent("SellFeedbackEvent")