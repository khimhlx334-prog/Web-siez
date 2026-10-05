-- ============================================================
-- 🏝️ EGG ISLE · MapBuilder (Script → ServerScriptService)
-- สร้างเกาะทะเล + textures สวย ๆ ตอนเซิร์ฟเวอร์เริ่ม (เบาสำหรับมือถือ)
-- ============================================================
local WS = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local old = WS:FindFirstChild("MapDecor") if old then old:Destroy() end
local root = Instance.new("Folder"); root.Name = "MapDecor"; root.Parent = WS

local function block(size, pos, color, mat, collide)
	local p = Instance.new("Part"); p.Size = size; p.Position = pos; p.Color = color; p.Material = mat
	p.Anchored = true; p.CanCollide = collide ~= false; p.Parent = root; return p
end
local function cyl(r, h, pos, color, mat, collide)
	local p = Instance.new("Part"); p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(h, r * 2, r * 2); p.Orientation = Vector3.new(0, 0, 90)
	p.Position = pos; p.Color = color; p.Material = mat; p.Anchored = true
	p.CanCollide = collide ~= false; p.Parent = root; return p
end
local function ball(size, pos, color, mat)
	local p = Instance.new("Part"); p.Shape = Enum.PartType.Ball; p.Size = size; p.Position = pos
	p.Color = color; p.Material = mat; p.Anchored = true; p.CanCollide = false; p.Parent = root; return p
end
local function sign(parent, text, w, h, color)
	local b = Instance.new("BillboardGui"); b.Size = UDim2.new(0, w, 0, h); b.AlwaysOnTop = true; b.Parent = parent
	local t = Instance.new("TextLabel"); t.Size = UDim2.new(1, 0, 1, 0); t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold; t.TextScaled = true; t.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	t.Text = text; t.Parent = b; return b
end

-- 🌊 ทะเล: ย้อม Baseplate เป็นน้ำ
local bp = WS:FindFirstChild("Baseplate")
if bp then
	bp.Material = Enum.Material.Water
	bp.Color = Color3.fromRGB(25, 80, 150)
	bp.Size = Vector3.new(1200, 8, 1200)
	bp.Position = Vector3.new(0, -4, 0)
end

-- 🏝️ เกาะ: หาดทราย + เนินหญ้า
cyl(82, 5, Vector3.new(0, 2, 0), Color3.fromRGB(235, 210, 150), Enum.Material.Sand)
cyl(70, 7, Vector3.new(0, 3.2, 0), Color3.fromRGB(95, 175, 85), Enum.Material.Grass)

-- จุดเกิดใหม่บนเกาะ
for _, v in ipairs(WS:GetChildren()) do if v:IsA("SpawnLocation") then v:Destroy() end end
block(Vector3.new(16, 1, 16), Vector3.new(0, 7.2, 18), Color3.fromRGB(255, 220, 120), Enum.Material.Slate).Name = "SpawnIsle"

-- 🥚 ไข่ยักษ์กลางเกาะ (แลนด์มาร์กเรืองแสง)
cyl(7, 2.5, Vector3.new(0, 8, 0), Color3.fromRGB(120, 100, 80), Enum.Material.Slate)
local egg = ball(Vector3.new(8, 11, 8), Vector3.new(0, 14, 0), Color3.fromRGB(250, 250, 245), Enum.Material.SmoothPlastic)
local light = Instance.new("PointLight"); light.Color = Color3.fromRGB(255, 230, 150); light.Range = 40; light.Brightness = 2; light.Parent = egg
sign(egg, "🥚 EGG ISLE · เกาะฟักไข่", 260, 70, Color3.fromRGB(255, 240, 180))

-- แท่นโชว์ไข่ 3 ระดับ
local tiers = {
	{ "🥚 ไข่ธรรมดา · 100", Vector3.new(30, 0, 6), Color3.fromRGB(240, 240, 235) },
	{ "🥚 ไข่หายาก · 1,500", Vector3.new(-30, 0, 6), Color3.fromRGB(90, 160, 255) },
	{ "🥚 ไข่ตำนาน · 30,000", Vector3.new(0, 0, -34), Color3.fromRGB(255, 190, 40) },
}
for _, t in ipairs(tiers) do
	cyl(4, 2, Vector3.new(t[2].X, 7.7, t[2].Z), Color3.fromRGB(150, 140, 130), Enum.Material.Slate)
	local e = ball(Vector3.new(4, 5.4, 4), Vector3.new(t[2].X, 11.4, t[2].Z), t[3], Enum.Material.SmoothPlastic)
	sign(e, t[1], 200, 54)
end

-- 🌴 ต้นมะพร้าวรอบหาด
for i = 1, 7 do
	local a = math.rad(i * (360 / 7) + 15)
	local x, z = math.cos(a) * 76, math.sin(a) * 76
	cyl(0.7, 9, Vector3.new(x, 8.5, z), Color3.fromRGB(140, 100, 60), Enum.Material.Wood)
	for l = 1, 5 do
		local la = math.rad(l * 72)
		local leaf = block(Vector3.new(7, 0.4, 1.8),
			Vector3.new(x + math.cos(la) * 3, 13, z + math.sin(la) * 3),
			Color3.fromRGB(60, 150, 60), Enum.Material.Grass, false)
		leaf.Orientation = Vector3.new(0, math.deg(la), 18)
	end
end

-- 🪨 หินประดับบนหญ้า
for i = 1, 6 do
	local a = math.rad(i * 60 + 30)
	ball(Vector3.new(3, 2.4, 3), Vector3.new(math.cos(a) * 60, 7.2, math.sin(a) * 60), Color3.fromRGB(140, 140, 150), Enum.Material.Rock)
end

-- ☀️ แสง/บรรยากาศ
Lighting.ClockTime = 14.5
Lighting.Brightness = 1.6
Lighting.FogEnd = 900
Lighting.FogColor = Color3.fromRGB(170, 200, 230)
Lighting.Ambient = Color3.fromRGB(120, 130, 150)
Lighting.GlobalShadows = true
pcall(function() Lighting.Technology = Enum.Technology.Future end)
