-- Place this LocalScript in StarterPlayerScripts or StarterGui (NOT ServerScriptService)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RequestRandomPickaxeEvent = ReplicatedStorage:WaitForChild("RequestRandomPickaxeEvent")

RequestRandomPickaxeEvent.OnClientEvent:Connect(function()
	-- Optional: Play your chest opening animation or UI here
	-- When animation is finished (or instantly if no animation), request the pickaxe:
	RequestRandomPickaxeEvent:FireServer()
end)