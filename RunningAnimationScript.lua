-- Services
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Local Player and Character
local LocalPlayer = Players.LocalPlayer
local Character = script.Parent -- This script should be in StarterCharacterScripts
local Humanoid = Character:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")

-- Configuration
local NORMAL_WALK_SPEED = 16    -- Default Humanoid walk speed
local RUN_WALK_SPEED = 24       -- Boosted speed for running
-- IMPORTANT: Replace this with your desired running animation ID.
-- This ID (507767714) is a common R15 run animation.
-- If you use R6 characters, you'll need an R6-compatible run animation (e.g., rbxassetid://180426354).
local RUN_ANIMATION_ID = "rbxassetid://507767714"

-- Animation
local runAnimation = Instance.new("Animation")
runAnimation.AnimationId = RUN_ANIMATION_ID
-- runAnimation.Parent = Character -- Optional: Parent to character for organization if desired

local runAnimationTrack
if Animator then
    runAnimationTrack = Animator:LoadAnimation(runAnimation)
    if runAnimationTrack then
        runAnimationTrack.Looped = true
        runAnimationTrack.Priority = Enum.AnimationPriority.Action -- Higher priority to override walk
    else
        warn("Failed to load run animation track for character:", Character.Name)
    end
else
    warn("Animator not found for character:", Character.Name)
end

-- State
local isShiftPressed = false
local isRunning = false -- Tracks if we are currently in the "running" state

-- Function to start running
local function startRunning()
    if not isRunning and Humanoid and Humanoid.Health > 0 and runAnimationTrack then
        isRunning = true
        Humanoid.WalkSpeed = RUN_WALK_SPEED
        if not runAnimationTrack.IsPlaying then
            runAnimationTrack:Play()
        end
    end
end

-- Function to stop running
local function stopRunning()
    if isRunning and Humanoid and runAnimationTrack then
        isRunning = false
        Humanoid.WalkSpeed = NORMAL_WALK_SPEED
        if runAnimationTrack.IsPlaying then
            runAnimationTrack:Stop()
        end
    end
end

-- Function to update running state based on inputs and movement
local function updateRunningState()
    if not Humanoid or Humanoid.Health &lt;= 0 then
        stopRunning() -- Ensure stopped if humanoid is dead or missing
        return
    end

    -- Check if character is actually trying to move (MoveDirection magnitude > 0)
    local isTryingToMove = Humanoid.MoveDirection.Magnitude > 0.01 -- Small threshold

    if isShiftPressed and isTryingToMove then
        startRunning()
    else
        stopRunning()
    end
end

-- Handle Shift Key Press
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end -- Don't run if typing in a TextBox, etc.

    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        isShiftPressed = true
        updateRunningState()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    -- No gameProcessedEvent check here, as releasing shift should always update state.
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        isShiftPressed = false
        updateRunningState()
    end
end)

-- Handle Character Movement (W, A, S, D, or joystick)
if Humanoid then
    Humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
        updateRunningState()
    end)

    -- Handle character respawn/death
    Humanoid.Died:Connect(function()
        stopRunning() -- Stop running animation and reset speed if character dies
        isShiftPressed = false -- Reset shift state on death
    end)
end

-- Initial state setup
if Humanoid then
    Humanoid.WalkSpeed = NORMAL_WALK_SPEED -- Ensure default speed on spawn/script run
end
updateRunningState() -- Initial check

-- Clean up when character is removed (though script destruction usually handles this)
Character.AncestryChanged:Connect(function(_, parent)
    if not parent then
        if runAnimationTrack and runAnimationTrack.IsPlaying then
            runAnimationTrack:Stop()
        end
        -- Connections to UserInputService will be disconnected when the script is destroyed.
    end
end)

