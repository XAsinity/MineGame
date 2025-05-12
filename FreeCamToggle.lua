local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = game.Workspace.CurrentCamera

local freeCamEnabled = false
local player = Players.LocalPlayer
local moveDirection = Vector3.new(0, 0, 0)
local mouseDelta = Vector2.new(0, 0)

local function toggleFreeCam()
    freeCamEnabled = not freeCamEnabled
    if freeCamEnabled then
        Camera.CameraType = Enum.CameraType.Scriptable
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    else
        Camera.CameraType = Enum.CameraType.Custom
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.KeyCode == Enum.KeyCode.C then
            toggleFreeCam()
        elseif input.KeyCode == Enum.KeyCode.W then
            moveDirection = moveDirection + Vector3.new(0, 0, -1)
        elseif input.KeyCode == Enum.KeyCode.S then
            moveDirection = moveDirection + Vector3.new(0, 0, 1)
        elseif input.KeyCode == Enum.KeyCode.A then
            moveDirection = moveDirection + Vector3.new(-1, 0, 0)
        elseif input.KeyCode == Enum.KeyCode.D then
            moveDirection = moveDirection + Vector3.new(1, 0, 0)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then
        moveDirection = moveDirection - Vector3.new(0, 0, -1)
    elseif input.KeyCode == Enum.KeyCode.S then
        moveDirection = moveDirection - Vector3.new(0, 0, 1)
    elseif input.KeyCode == Enum.KeyCode.A then
        moveDirection = moveDirection - Vector3.new(-1, 0, 0)
    elseif input.KeyCode == Enum.KeyCode.D then
        moveDirection = moveDirection - Vector3.new(1, 0, 0)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        mouseDelta = input.Delta
    end
end)

RunService.RenderStepped:Connect(function(deltaTime)
    if freeCamEnabled then
        local cameraCFrame = Camera.CFrame
        local lookVector = cameraCFrame.LookVector
        local rightVector = cameraCFrame.RightVector

        local moveVector = (lookVector * moveDirection.Z + rightVector * moveDirection.X) * deltaTime * 50
        Camera.CFrame = Camera.CFrame + moveVector

        local yaw = -mouseDelta.X * 0.1
        local pitch = -mouseDelta.Y * 0.1
        Camera.CFrame = Camera.CFrame * CFrame.Angles(math.rad(pitch), math.rad(yaw), 0)

        mouseDelta = Vector2.new(0, 0)
    end
end)

