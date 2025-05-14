local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Get references to the GUI elements with timeout handling
local muteGui = player:WaitForChild("PlayerGui"):WaitForChild("MuteButton", 5)
if not muteGui then
	warn("MuteButton GUI not found in PlayerGui!")
	return
end

local onButton = muteGui:WaitForChild("On", 5)
local offButton = muteGui:WaitForChild("Off", 5)
local music = muteGui:WaitForChild("BackgroundMusic", 5)

-- Debugging: Confirm elements are found
if onButton then
	print("On Button found (ImageButton):", onButton)
else
	warn("On Button not found in MuteButton GUI!")
end

if offButton then
	print("Off Button found (ImageButton):", offButton)
else
	warn("Off Button not found in MuteButton GUI!")
end

if music and music:IsA("Sound") then
	print("BackgroundMusic found:", music)
else
	warn("BackgroundMusic not found or is not a valid Sound object!")
	return
end

-- Ensure only one button is visible at game start
onButton.Visible = true
offButton.Visible = false

-- Play the music when the game starts
music.Looped = true -- Ensure the music loops
music:Play()
print("Background music started.")

-- Function to handle the On button click
onButton.MouseButton1Click:Connect(function()
	print("On Button clicked!")
	onButton.Visible = false
	offButton.Visible = true

	-- Pause the music
	if music and music:IsA("Sound") then
		music:Pause()
		print("Music paused.")
	end
end)

-- Function to handle the Off button click
offButton.MouseButton1Click:Connect(function()
	print("Off Button clicked!")
	offButton.Visible = false
	onButton.Visible = true

	-- Play the music
	if music and music:IsA("Sound") then
		music:Play()
		print("Music resumed.")
	end
end)