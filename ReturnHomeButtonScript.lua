local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local button = script.Parent
local spawnLocation = Workspace:WaitForChild("SpawnLocation")

button.MouseButton1Click:Connect(function()
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    -- Ensure the player is teleported to the correct spawn location
    humanoidRootPart.CFrame = spawnLocation.CFrame + Vector3.new(0, 3, 0) -- Offset to prevent clipping into the ground
end)

