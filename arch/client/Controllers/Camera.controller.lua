-- ============================================================
-- EGG RAID · Controllers/Camera (ModuleScript → StarterPlayerScripts/Controllers)
-- Interface for cinematic camera control (intro, cutscenes,
-- island unlocks). The legacy Intro5 still owns the live intro;
-- this controller activates only when Enabled is flipped by the
-- future migration. No RenderStepped loops: all motion is
-- TweenService-driven and event-triggered.
-- ============================================================
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Camera = { Name = "Camera", Enabled = false }

local MODES = { Follow = Enum.CameraType.Custom, Scripted = Enum.CameraType.Scriptable }
local activeTween = nil

function Camera.Mode(modeName)
	local cam = Workspace.CurrentCamera
	if not cam or not MODES[modeName] then return end
	cam.CameraType = MODES[modeName]
end

function Camera.TweenTo(cframe, seconds, onComplete)
	local cam = Workspace.CurrentCamera
	if not cam then return end
	Camera.Mode("Scripted")
	if activeTween then activeTween:Cancel() end
	activeTween = TweenService:Create(cam, TweenInfo.new(seconds or 2, Enum.EasingStyle.Sine), { CFrame = cframe })
	if onComplete then
		activeTween.Completed:Once(function() onComplete() end)
	end
	activeTween:Play()
end

function Camera.FadeToPlayer()
	Camera.Mode("Follow")
	local plr = game:GetService("Players").LocalPlayer
	local char = plr.Character
	if char and char:FindFirstChild("Humanoid") then
		Workspace.CurrentCamera.CameraSubject = char.Humanoid
	end
	activeTween = nil
end

function Camera.Destroy()
	if activeTween then activeTween:Cancel() end
	Camera.FadeToPlayer()
end

return Camera
