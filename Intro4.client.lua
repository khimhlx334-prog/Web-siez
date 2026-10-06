-- ============================================================
-- EGG ISLE v4 · Intro4 (LocalScript → StarterPlayerScripts)
-- คัทซีนผู้เล่นใหม่: เรือโดนสัตว์ประหลาดโจมตี → จม → ตื่นบนเกาะ 1 (ข้ามได้)
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local WS = workspace
local plr = Players.LocalPlayer
local evIntro = ReplicatedStorage:WaitForChild("IntroDone")

local need = plr:GetAttribute("NeedIntro")
if need == nil then
	plr:GetAttributeChangedSignal("NeedIntro"):Wait()
	need = plr:GetAttribute("NeedIntro")
end
if not need then return end

local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")
task.wait(1)

-- ---------- จอ overlay ----------
local gui = Instance.new("ScreenGui"); gui.Name = "IntroGui"; gui.ResetOnSpawn = false; gui.Parent = plr:WaitForChild("PlayerGui")
local fade = Instance.new("Frame"); fade.Size = UDim2.new(1, 0, 1, 0); fade.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
fade.BackgroundTransparency = 1; fade.BorderSizePixel = 0; fade.Parent = gui
local cap = Instance.new("TextLabel"); cap.Size = UDim2.new(0.85, 0, 0, 60)
cap.Position = UDim2.new(0.5, 0, 0.82, 0); cap.AnchorPoint = Vector2.new(0.5, 0.5)
cap.BackgroundTransparency = 1; cap.Font = Enum.Font.GothamBlack; cap.TextScaled = true
cap.TextColor3 = Color3.fromRGB(255, 255, 255); cap.TextStrokeTransparency = 0; cap.TextWrapped = true; cap.Parent = gui
local skip = Instance.new("TextButton"); skip.Size = UDim2.fromOffset(120, 44)
skip.Position = UDim2.new(1, -130, 1, -56); skip.BackgroundColor3 = Color3.fromRGB(40, 44, 60)
skip.Font = Enum.Font.GothamBlack; skip.TextScaled = true; skip.Text = "ข้าม "
skip.TextColor3 = Color3.fromRGB(255, 255, 255); skip.Parent = gui
local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(0, 10); uc.Parent = skip

local function setFade(t, time_)
	TweenService:Create(fade, TweenInfo.new(time_), { BackgroundTransparency = t }):Play()
end
local function say(t) cap.Text = t end

-- ---------- ฉากในทะเล ----------
local base = Vector3.new(2200, 0, 2200)
local set = Instance.new("Folder"); set.Parent = WS
local function prt(size, pos, color, mat)
	local p = Instance.new("Part"); p.Size = size; p.Position = base + pos; p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic; p.Anchored = true; p.CanCollide = false; p.Parent = set; return p
end
local hull = prt(Vector3.new(8, 2, 14), Vector3.new(0, 1.2, 0), Color3.fromRGB(180, 80, 50), Enum.Material.Wood)
local deck = prt(Vector3.new(6.5, 0.5, 12), Vector3.new(0, 2.5, 0), Color3.fromRGB(220, 180, 120), Enum.Material.Wood)
local mast = prt(Vector3.new(0.4, 6, 0.4), Vector3.new(0, 5.5, -2), Color3.fromRGB(90, 60, 40), Enum.Material.Wood)
local sail = prt(Vector3.new(5, 4, 0.2), Vector3.new(0, 6.5, -2), Color3.fromRGB(245, 245, 240))
-- สัตว์ประหลาด (งูทะเลบล็อกกี้)
local segs = {}
for i = 1, 6 do
	local s = prt(Vector3.new(4 - i * 0.4, 4 - i * 0.4, 4 - i * 0.4), Vector3.new(14, -8, 20 - i * 4), Color3.fromRGB(40, 140, 90))
	table.insert(segs, s)
end
local head = prt(Vector3.new(5, 4, 6), Vector3.new(14, -8, 24), Color3.fromRGB(40, 140, 90))
local jaw = prt(Vector3.new(4, 1.5, 4), Vector3.new(14, -10.5, 26), Color3.fromRGB(20, 90, 60))
local eyeL = prt(Vector3.new(0.8, 0.8, 0.8), Vector3.new(12.5, -6.5, 26.5), Color3.fromRGB(255, 60, 60), Enum.Material.Neon)
local eyeR = prt(Vector3.new(0.8, 0.8, 0.8), Vector3.new(15.5, -6.5, 26.5), Color3.fromRGB(255, 60, 60), Enum.Material.Neon)

local cam = WS.CurrentCamera
cam.CameraType = Enum.CameraType.Scriptable
hum.WalkSpeed = 0

local done = false
local function finish()
	if done then return end
	done = true
	setFade(1, 0.4)
	task.wait(0.5)
	set:Destroy()
	cam.CameraType = Enum.CameraType.Custom
	cam.Subject = hum
	hum.WalkSpeed = 16
	skip:Destroy(); cap:Destroy()
	fade.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	fade.BackgroundTransparency = 0
	TweenService:Create(fade, TweenInfo.new(1), { BackgroundTransparency = 1 }):Play()
	task.delay(1.3, function() gui:Destroy() end)
	evIntro:FireServer()
end
skip.Activated:Connect(finish)

task.spawn(function()
	-- 1) เฟดเข้า เห็นเรือแล่น
	setFade(1, 0)
	task.wait(0.3)
	setFade(0.35, 1.2)
	say("หลังการเดินทางอันยาวนาน... ทะเลแห่งเกาะไข่ก็อยู่ตรงหน้า")
	local t0 = tick()
	while tick() - t0 < 4 and not done do
		local k = (tick() - t0) / 4
		hull.Position = base + Vector3.new(0, 1.2, -k * 30)
		deck.Position = base + Vector3.new(0, 2.5, -k * 30)
		mast.Position = base + Vector3.new(0, 5.5, -2 - k * 30)
		sail.Position = base + Vector3.new(0, 6.5, -2 - k * 30)
		cam.CFrame = CFrame.new(base + Vector3.new(0, 7, 16 - k * 30), base + Vector3.new(0, 3, -10 - k * 30))
		task.wait()
	end
	if done then return end
	-- 2) น้ำสั่น
	say("!? ผิวน้ำสั่นแรงขึ้นเรื่อย ๆ... มีอะไรบางอย่างใหญ่โตอยู่ใต้เรา")
	for i = 1, 12 do
		cam.CFrame = cam.CFrame * CFrame.new(math.random() * 0.3 - 0.15, math.random() * 0.3 - 0.15, 0)
		task.wait(0.05)
	end
	if done then return end
	-- 3) สัตว์ประหลาดโผล่
	say("ผู้พิทักษ์แห่งเกาะอเวจี!! มันจำหน้าผู้บุกรุกได้แม่นยำ!")
	TweenService:Create(head, TweenInfo.new(0.8, Enum.EasingStyle.Back), { Position = base + Vector3.new(6, 7, 10) }):Play()
	TweenService:Create(jaw, TweenInfo.new(0.8, Enum.EasingStyle.Back), { Position = base + Vector3.new(6, 4.5, 12) }):Play()
	TweenService:Create(eyeL, TweenInfo.new(0.8), { Position = base + Vector3.new(4.5, 8.5, 12.5) }):Play()
	TweenService:Create(eyeR, TweenInfo.new(0.8), { Position = base + Vector3.new(7.5, 8.5, 12.5) }):Play()
	for i, s in ipairs(segs) do
		TweenService:Create(s, TweenInfo.new(0.6, Enum.EasingStyle.Back), { Position = base + Vector3.new(8 + i, 5 - i * 0.5, 14 + i * 3) }):Play()
	end
	task.wait(1.4)
	if done then return end
	-- 4) เรือพัง
	say("ตู้ม!! เรือแตกแล้ว—!")
	TweenService:Create(hull, TweenInfo.new(0.7), { Position = base + Vector3.new(-6, 0, -4), Rotation = Vector3.new(30, 0, 40) }):Play()
	TweenService:Create(deck, TweenInfo.new(0.7), { Position = base + Vector3.new(5, 1, -2), Rotation = Vector3.new(-20, 0, -35) }):Play()
	TweenService:Create(sail, TweenInfo.new(0.9), { Position = base + Vector3.new(2, 3, -8), Rotation = Vector3.new(60, 20, 0) }):Play()
	for i = 1, 16 do
		cam.CFrame = cam.CFrame * CFrame.new(math.random() * 0.6 - 0.3, math.random() * 0.6 - 0.3, 0)
		task.wait(0.04)
	end
	if done then return end
	-- 5) จม
	say("ตุ๊บ... ตุ๊บ... (ทุกอย่างมืดลง)")
	fade.BackgroundColor3 = Color3.fromRGB(10, 40, 90)
	setFade(0.15, 1.2)
	cam.CFrame = cam.CFrame + Vector3.new(0, -6, 0)
	task.wait(1.6)
	if done then return end
	-- 6) ตื่นบนเกาะ
	setFade(1, 0.8)
	say("")
	task.wait(1)
	finish()
	-- ป้ายต้อนรับหลังตื่น
	local wel = Instance.new("TextLabel"); wel.Size = UDim2.new(0.85, 0, 0, 60)
	wel.Position = UDim2.new(0.5, 0, 0.2, 0); wel.AnchorPoint = Vector2.new(0.5, 0)
	wel.BackgroundTransparency = 1; wel.Font = Enum.Font.GothamBlack; wel.TextScaled = true
	wel.TextColor3 = Color3.fromRGB(255, 255, 255); wel.TextStrokeTransparency = 0; wel.TextWrapped = true
	wel.Text = "ยินดีต้อนรับสู่ Egg Isle! กลางคืนนี้... ออกเรือไปหาไข่ใบแรกของคุณเถอะ"
	local g2 = Instance.new("ScreenGui"); g2.Parent = plr.PlayerGui; wel.Parent = g2
	task.delay(5, function() g2:Destroy() end)
end)
