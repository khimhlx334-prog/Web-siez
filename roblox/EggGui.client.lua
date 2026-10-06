-- ============================================================
-- 🥚 EGG ISLE · EggGui v3 (LocalScript → StarterPlayerScripts)
-- UI สไตล์เกมฮิต: แผงเขียวหัวลายทาง + X แดง · ไอคอนขวา · สถานะซ้ายล่าง
-- ดัชนี ??? · สัตว์เลี้ยงลอยตามตัว · ป้ายประกาศแอดมิน
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local plr = Players.LocalPlayer

local evHatch = ReplicatedStorage:WaitForChild("Hatch")
local evAnn = ReplicatedStorage:WaitForChild("Announce")

local PETS = {
	{ id = "cat", name = "แมวส้ม", emoji = "🐱", rarity = "ธรรมดา", power = 1 },
	{ id = "dog", name = "คอร์กี้", emoji = "🐶", rarity = "ธรรมดา", power = 1 },
	{ id = "rab", name = "กระต่ายขาว", emoji = "🐰", rarity = "ธรรมดา", power = 1 },
	{ id = "pan", name = "แพนด้า", emoji = "🐼", rarity = "ไม่ธรรมดา", power = 3 },
	{ id = "cap", name = "คาปิบาร่า", emoji = "🦫", rarity = "ไม่ธรรมดา", power = 3 },
	{ id = "ele", name = "ช้างชมพู", emoji = "🐘", rarity = "หายาก", power = 10 },
	{ id = "lio", name = "สิงโตทอง", emoji = "🦁", rarity = "หายาก", power = 10 },
	{ id = "dra", name = "มังกรน้ำแข็ง", emoji = "🐉", rarity = "มหากาพย์", power = 40 },
	{ id = "uni", name = "ยูนิคอร์นรุ้ง", emoji = "🦄", rarity = "มหากาพย์", power = 40 },
	{ id = "gld", name = "ดราก้อนทอง", emoji = "🐲", rarity = "ตำนาน", power = 200 },
	{ id = "phx", name = "ฟีนิกซ์จักรวาล", emoji = "🌟", rarity = "ตำนาน", power = 200 },
}
local RARITY_COLOR = {
	["ธรรมดา"] = Color3.fromRGB(160, 160, 160),
	["ไม่ธรรมดา"] = Color3.fromRGB(61, 220, 132),
	["หายาก"] = Color3.fromRGB(64, 156, 255),
	["มหากาพย์"] = Color3.fromRGB(177, 101, 255),
	["ตำนาน"] = Color3.fromRGB(255, 190, 40),
}
local EGG_LIST = {
	{ id = "basic", label = "ไข่ธรรมดา", emoji = "🥚", cost = 100, bg = Color3.fromRGB(240, 240, 235) },
	{ id = "rare", label = "ไข่หายาก", emoji = "🥚", cost = 1500, bg = Color3.fromRGB(90, 160, 255) },
	{ id = "leg", label = "ไข่ตำนาน", emoji = "🥚", cost = 30000, bg = Color3.fromRGB(255, 190, 40) },
}

local gui = Instance.new("ScreenGui"); gui.Name = "EggIsleGui"; gui.ResetOnSpawn = false
gui.Parent = plr:WaitForChild("PlayerGui")

local function fmt(n)
	local s = tostring(math.floor(n or 0))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end
local function stroke(p, color, th)
	local s = Instance.new("UIStroke"); s.Color = color or Color3.fromRGB(0, 0, 0); s.Thickness = th or 2; s.Parent = p; return s
end
local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = p; return c end

-- ---------- สแต็กสถานะซ้ายล่าง (สไตล์เกมฮิต) ----------
local stack = Instance.new("Frame"); stack.Size = UDim2.fromOffset(210, 78)
stack.Position = UDim2.new(0, 12, 1, -90); stack.AnchorPoint = Vector2.new(0, 0)
stack.BackgroundTransparency = 1; stack.Parent = gui
local coinTxt = Instance.new("TextLabel"); coinTxt.Size = UDim2.new(1, 0, 0, 40); coinTxt.Position = UDim2.fromOffset(0, 0)
coinTxt.BackgroundTransparency = 1; coinTxt.Font = Enum.Font.GothamBlack; coinTxt.TextScaled = true
coinTxt.TextXAlignment = Enum.TextXAlignment.Left
coinTxt.TextColor3 = Color3.fromRGB(255, 220, 60); coinTxt.TextStrokeTransparency = 0; coinTxt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
coinTxt.Parent = stack
local powTxt = Instance.new("TextLabel"); powTxt.Size = UDim2.new(1, 0, 0, 34); powTxt.Position = UDim2.fromOffset(0, 42)
powTxt.BackgroundTransparency = 1; powTxt.Font = Enum.Font.GothamBlack; powTxt.TextScaled = true
powTxt.TextXAlignment = Enum.TextXAlignment.Left
powTxt.TextColor3 = Color3.fromRGB(120, 220, 255); powTxt.TextStrokeTransparency = 0; powTxt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
powTxt.Parent = stack

-- ---------- คอลัมน์ไอคอนขวา ----------
local function iconBtn(name, emoji, bg, ypos)
	local b = Instance.new("TextButton"); b.Name = name; b.Size = UDim2.fromOffset(62, 62)
	b.Position = UDim2.new(1, -74, 0, ypos); b.BackgroundColor3 = bg
	b.Font = Enum.Font.GothamBlack; b.TextScaled = true; b.Text = emoji; b.TextColor3 = Color3.fromRGB(255, 255, 255)
	corner(b, 12); stroke(b, Color3.fromRGB(0, 0, 0), 3)
	local inStroke = Instance.new("UIStroke"); inStroke.Color = Color3.fromRGB(255, 255, 255); inStroke.Thickness = 2; inStroke.Transparency = 0.4; inStroke.Parent = b
	b.Parent = gui
	return b
end
local hatchBtn = iconBtn("Hatch", "🥚", Color3.fromRGB(230, 60, 60), 120)
local collBtn = iconBtn("Coll", "🐾", Color3.fromRGB(250, 150, 50), 194)

-- ---------- ตัวสร้างแผงสไตล์ฮิต (หัวเขียว + X แดง) ----------
local function makePanel(name, w, h)
	local f = Instance.new("Frame"); f.Name = name; f.Size = UDim2.fromOffset(w, h)
	f.Position = UDim2.new(0.5, 0, 0.5, 0); f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BackgroundColor3 = Color3.fromRGB(45, 48, 62); f.Visible = false
	corner(f, 12); stroke(f, Color3.fromRGB(0, 0, 0), 3); f.Parent = gui
	local head = Instance.new("Frame"); head.Size = UDim2.new(1, -8, 0, 44); head.Position = UDim2.fromOffset(4, 4)
	head.BackgroundColor3 = Color3.fromRGB(88, 200, 60); corner(head, 8); stroke(head, Color3.fromRGB(0, 0, 0), 2); head.Parent = f
	local shine = Instance.new("UIGradient"); shine.Rotation = 25; shine.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.25, Color3.fromRGB(190, 190, 190)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(190, 190, 190)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.75, Color3.fromRGB(190, 190, 190)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 190, 190)),
	}); shine.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.75), NumberSequenceKeypoint.new(1, 0.75)
	}); shine.Parent = head
	local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, -54, 1, 0); title.Position = UDim2.fromOffset(10, 0)
	title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBlack; title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left; title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextStrokeTransparency = 0; title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); title.Parent = head
	local x = Instance.new("TextButton"); x.Size = UDim2.fromOffset(36, 36); x.Position = UDim2.new(1, -42, 0, 4)
	x.BackgroundColor3 = Color3.fromRGB(220, 40, 40); x.Font = Enum.Font.GothamBlack; x.TextScaled = true
	x.Text = "X"; x.TextColor3 = Color3.fromRGB(255, 255, 255); corner(x, 6); stroke(x, Color3.fromRGB(0, 0, 0), 2); x.Parent = head
	x.Activated:Connect(function() f.Visible = false end)
	return f, title
end

-- ---------- แผงฟักไข่ ----------
local eggPanel, eggTitle = makePanel("EggShop", 300, 262)
eggTitle.Text = "🥚 ร้านฟักไข่"
local eggBody = Instance.new("Frame"); eggBody.Size = UDim2.new(1, -16, 1, -62); eggBody.Position = UDim2.fromOffset(8, 54)
eggBody.BackgroundTransparency = 1; eggBody.Parent = eggPanel
local eggList = Instance.new("UIListLayout"); eggList.Padding = UDim.new(0, 8)
eggList.HorizontalAlignment = Enum.HorizontalAlignment.Center; eggList.Parent = eggBody
for i, e in ipairs(EGG_LIST) do
	local row = Instance.new("TextButton"); row.Size = UDim2.new(1, 0, 0, 56)
	row.BackgroundColor3 = Color3.fromRGB(60, 64, 84); corner(row, 10); stroke(row, Color3.fromRGB(0, 0, 0), 2)
	row.Font = Enum.Font.GothamBlack; row.TextScaled = true; row.TextColor3 = Color3.fromRGB(255, 255, 255)
	row.Text = e.emoji .. " " .. e.label .. "   🪙 " .. fmt(e.cost)
	local bar = Instance.new("Frame"); bar.Size = UDim2.new(0, 8, 1, -8); bar.Position = UDim2.fromOffset(4, 4)
	bar.BackgroundColor3 = e.bg; corner(bar, 4); bar.Parent = row
	row.Activated:Connect(function() evHatch:FireServer(e.id) end)
	row.Parent = eggBody; row.LayoutOrder = i
end

-- ---------- แผงดัชนีสัตว์เลี้ยง ----------
local collPanel, collTitle = makePanel("PetIndex", 340, 360)
collTitle.Text = "🐾 ดัชนีสัตว์เลี้ยง"
local collBody = Instance.new("Frame"); collBody.Size = UDim2.new(1, -16, 1, -102); collBody.Position = UDim2.fromOffset(8, 54)
collBody.BackgroundTransparency = 1; collBody.Parent = collPanel
local grid = Instance.new("UIGridLayout"); grid.CellSize = UDim2.fromOffset(72, 78); grid.CellPadding = UDim2.fromOffset(6, 6)
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center; grid.Parent = collBody
local cells = {}
for i, p in ipairs(PETS) do
	local c = Instance.new("Frame"); c.Size = UDim2.fromOffset(72, 78)
	c.BackgroundColor3 = RARITY_COLOR[p.rarity]; corner(c, 8); stroke(c, Color3.fromRGB(0, 0, 0), 2); c.Parent = collBody
	local em = Instance.new("TextLabel"); em.Size = UDim2.new(1, 0, 0, 46); em.Position = UDim2.fromOffset(0, 2)
	em.BackgroundTransparency = 1; em.Font = Enum.Font.GothamBlack; em.TextScaled = true; em.Parent = c
	local nm = Instance.new("TextLabel"); nm.Size = UDim2.new(1, -4, 0, 24); nm.Position = UDim2.fromOffset(2, 50)
	nm.BackgroundTransparency = 1; nm.Font = Enum.Font.GothamBold; nm.TextScaled = true
	nm.TextColor3 = Color3.fromRGB(255, 255, 255); nm.TextStrokeTransparency = 0; nm.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); nm.Parent = c
	cells[p.id] = { em = em, nm = nm, frame = c }
end
local counter = Instance.new("TextLabel"); counter.Size = UDim2.new(0.92, 0, 0, 34)
counter.Position = UDim2.new(0.04, 0, 1, -40); counter.BackgroundColor3 = Color3.fromRGB(88, 200, 60)
corner(counter, 8); stroke(counter, Color3.fromRGB(0, 0, 0), 2)
counter.Font = Enum.Font.GothamBlack; counter.TextScaled = true; counter.TextColor3 = Color3.fromRGB(255, 255, 255)
counter.TextStrokeTransparency = 0; counter.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); counter.Parent = collPanel

hatchBtn.Activated:Connect(function() eggPanel.Visible = not eggPanel.Visible; collPanel.Visible = false end)
collBtn.Activated:Connect(function() collPanel.Visible = not collPanel.Visible; eggPanel.Visible = false end)

-- ---------- 📢 ป้ายประกาศแอดมิน ----------
local ann = Instance.new("TextLabel"); ann.Size = UDim2.new(0.8, 0, 0, 46)
ann.Position = UDim2.new(0.5, 0, 0, 70); ann.AnchorPoint = Vector2.new(0.5, 0)
ann.BackgroundColor3 = Color3.fromRGB(255, 90, 60); ann.BackgroundTransparency = 0.1
ann.Font = Enum.Font.GothamBlack; ann.TextScaled = true; ann.TextColor3 = Color3.fromRGB(255, 255, 255)
ann.TextWrapped = true; ann.Visible = false; ann.TextStrokeTransparency = 0.2
corner(ann, 12); stroke(ann, Color3.fromRGB(255, 255, 255), 2); ann.Parent = gui
evAnn.OnClientEvent:Connect(function(msg)
	ann.Text = "📢 " .. tostring(msg)
	ann.Visible = true
	task.delay(4.5, function() ann.Visible = false end)
end)

-- ---------- ป้ายผลฟัก ----------
local pop = Instance.new("Frame"); pop.Size = UDim2.fromOffset(250, 116)
pop.Position = UDim2.new(0.5, 0, 0.32, 0); pop.AnchorPoint = Vector2.new(0.5, 0.5)
pop.BackgroundColor3 = Color3.fromRGB(20, 24, 36); pop.Visible = false
corner(pop, 16); local pst = stroke(pop, Color3.fromRGB(255, 255, 255), 3); pop.Parent = gui
local popTxt = Instance.new("TextLabel"); popTxt.Size = UDim2.new(1, -12, 1, -8); popTxt.Position = UDim2.fromOffset(6, 4)
popTxt.BackgroundTransparency = 1; popTxt.Font = Enum.Font.GothamBlack; popTxt.TextScaled = true
popTxt.TextColor3 = Color3.fromRGB(255, 255, 255); popTxt.TextWrapped = true; popTxt.Parent = pop
evHatch.OnClientEvent:Connect(function(res)
	pst.Color = RARITY_COLOR[res.rarity] or Color3.fromRGB(255, 255, 255)
	popTxt.Text = res.emoji .. " " .. res.name .. "\n[" .. res.rarity .. "] พาวเวอร์ " .. res.power
	pop.Visible = true
	task.delay(2.2, function() pop.Visible = false end)
end)

-- ---------- 🐾 สัตว์เลี้ยงบล็อกกี้ 3D ลอยตามตัว (top-3 · ขนาดตามแรร์) ----------
local SCALE_OF = { ["ธรรมดา"] = 1, ["ไม่ธรรมดา"] = 1.15, ["หายาก"] = 1.35, ["มหากาพย์"] = 1.6, ["ตำนาน"] = 1.9 }
local function buildPet(id, scale)
	local folder = Instance.new("Folder"); folder.Parent = workspace
	local core = Instance.new("Part"); core.Size = Vector3.new(0.2, 0.2, 0.2); core.Transparency = 1
	core.Anchored = true; core.CanCollide = false; core.CanQuery = false; core.CanTouch = false; core.Parent = folder
	local function add(shape, size, off, c, rot, mat)
		local p = Instance.new("Part"); p.Shape = shape
		p.Size = Vector3.new(size[1] * scale, size[2] * scale, size[3] * scale)
		p.Color = c; p.Material = mat or Enum.Material.SmoothPlastic
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		local w = Instance.new("Weld"); w.Part0 = core; w.Part1 = p
		local r = rot and CFrame.Angles(math.rad(rot[1]), math.rad(rot[2]), math.rad(rot[3])) or CFrame.new()
		w.C0 = CFrame.new(off[1] * scale, off[2] * scale, off[3] * scale) * r
		p.Parent = folder
	end
	local BK, BL = Enum.PartType.Block, Enum.PartType.Ball
	local function legs(c, w_, h, x, z)
		for _, px in ipairs({ -x, x }) do for _, pz in ipairs({ -z, z }) do
			add(BK, { w_, h, w_ }, { px, h / 2, pz }, c)
		end end
	end
	local function head(c, hy, hz, s)
		add(BK, { s, s * 0.9, s }, { 0, hy, hz }, c)
	end
	local WH = Color3.fromRGB(250, 250, 250)
	if id == "cat" then
		local OR = Color3.fromRGB(240, 140, 60)
		add(BK, { 1.5, 1, 2.1 }, { 0, 1, 0 }, OR); add(BK, { 1.2, 0.5, 1.4 }, { 0, 0.72, 0.2 }, WH)
		head(OR, 1.75, 1.35, 1.05); add(BK, { 0.5, 0.3, 0.3 }, { 0, 1.55, 1.95 }, WH)
		add(BK, { 0.3, 0.45, 0.12 }, { -0.35, 2.4, 1.3 }, OR, { 0, 0, 20 }); add(BK, { 0.3, 0.45, 0.12 }, { 0.35, 2.4, 1.3 }, OR, { 0, 0, -20 })
		add(BK, { 0.2, 0.2, 0.9 }, { 0, 1.3, -1.25 }, OR, { 45, 0, 0 }); legs(OR, 0.32, 0.75, 0.5, 0.75)
	elseif id == "dog" then
		local CR, BR = Color3.fromRGB(230, 190, 140), Color3.fromRGB(170, 110, 60)
		add(BK, { 1.5, 1, 2.1 }, { 0, 1, 0 }, CR); add(BK, { 1.2, 0.5, 1.4 }, { 0, 0.72, 0.2 }, WH)
		head(CR, 1.75, 1.35, 1.05); add(BK, { 0.5, 0.3, 0.3 }, { 0, 1.55, 1.95 }, WH)
		add(BK, { 0.35, 0.6, 0.15 }, { -0.38, 2.45, 1.3 }, BR, { 0, 0, 15 }); add(BK, { 0.35, 0.6, 0.15 }, { 0.38, 2.45, 1.3 }, BR, { 0, 0, -15 })
		add(BK, { 0.18, 0.3, 0.3 }, { 0, 1.2, -1.2 }, WH); legs(BR, 0.3, 0.6, 0.5, 0.75)
	elseif id == "rab" then
		add(BK, { 1.4, 1, 1.9 }, { 0, 1, 0 }, WH); head(WH, 1.7, 1.25, 1)
		add(BK, { 0.22, 1.1, 0.18 }, { -0.25, 2.7, 1.15 }, WH, { 10, 0, 8 }); add(BK, { 0.22, 1.1, 0.18 }, { 0.25, 2.7, 1.15 }, WH, { 10, 0, -8 })
		add(BL, { 0.4, 0.4, 0.4 }, { 0, 1, -1.1 }, WH); legs(WH, 0.3, 0.7, 0.45, 0.7)
	elseif id == "pan" then
		local BKc = Color3.fromRGB(35, 35, 40)
		add(BK, { 1.6, 1.1, 2.1 }, { 0, 1, 0 }, WH); head(WH, 1.8, 1.35, 1.1)
		add(BK, { 0.3, 0.3, 0.15 }, { -0.4, 2.45, 1.3 }, BKc); add(BK, { 0.3, 0.3, 0.15 }, { 0.4, 2.45, 1.3 }, BKc)
		add(BK, { 0.24, 0.3, 0.1 }, { -0.26, 1.9, 1.9 }, BKc); add(BK, { 0.24, 0.3, 0.1 }, { 0.26, 1.9, 1.9 }, BKc)
		legs(BKc, 0.34, 0.75, 0.55, 0.75)
	elseif id == "cap" then
		local CB = Color3.fromRGB(150, 100, 60)
		add(BK, { 1.7, 1.2, 2.3 }, { 0, 1, 0 }, CB); add(BK, { 1, 0.9, 1.1 }, { 0, 1.5, 1.55 }, CB)
		add(BK, { 0.5, 0.35, 0.4 }, { 0, 1.25, 2.1 }, Color3.fromRGB(120, 80, 50))
		add(BK, { 0.18, 0.2, 0.1 }, { -0.32, 2.05, 1.5 }, CB); add(BK, { 0.18, 0.2, 0.1 }, { 0.32, 2.05, 1.5 }, CB)
		legs(CB, 0.36, 0.7, 0.55, 0.8)
	elseif id == "ele" then
		local PK = Color3.fromRGB(250, 170, 190)
		add(BK, { 2, 1.5, 2.6 }, { 0, 1.3, 0 }, PK); add(BL, { 1.3, 1.3, 1.3 }, { 0, 2, 1.6 }, PK)
		add(BK, { 0.4, 1.3, 0.4 }, { 0, 1.5, 2.5 }, PK, { 50, 0, 0 })
		add(BK, { 0.15, 0.9, 0.7 }, { -0.8, 2, 1.5 }, PK); add(BK, { 0.15, 0.9, 0.7 }, { 0.8, 2, 1.5 }, PK)
		legs(PK, 0.5, 0.9, 0.7, 0.95)
	elseif id == "lio" then
		local GD, MN = Color3.fromRGB(230, 180, 60), Color3.fromRGB(170, 110, 40)
		add(BK, { 1.6, 1.1, 2.2 }, { 0, 1, 0 }, GD)
		add(BL, { 1.7, 1.7, 1.2 }, { 0, 1.8, 1.2 }, MN); add(BK, { 0.9, 0.8, 0.9 }, { 0, 1.8, 1.75 }, GD)
		add(BK, { 0.2, 0.2, 0.8 }, { 0, 1.2, -1.3 }, GD, { 30, 0, 0 }); add(BL, { 0.35, 0.35, 0.35 }, { 0, 0.9, -1.75 }, MN)
		legs(GD, 0.34, 0.75, 0.55, 0.8)
	elseif id == "dra" then
		local IB, IC = Color3.fromRGB(140, 200, 255), Color3.fromRGB(225, 245, 255)
		add(BK, { 1.6, 1.1, 2.4 }, { 0, 1, 0 }, IB); add(BK, { 0.9, 0.7, 1.1 }, { 0, 1.8, 1.5 }, IB)
		add(BK, { 0.25, 0.5, 0.2 }, { -0.25, 2.35, 1.4 }, IC, { 0, 0, 10 }); add(BK, { 0.25, 0.5, 0.2 }, { 0.25, 2.35, 1.4 }, IC, { 0, 0, -10 })
		add(BK, { 0.2, 0.5, 0.2 }, { 0, 1.75, 0.2 }, IC); add(BK, { 0.2, 0.5, 0.2 }, { 0, 1.75, -0.6 }, IC)
		add(BK, { 1.6, 0.12, 1 }, { -1.1, 1.9, 0 }, IC, { 0, 0, 30 }, Enum.Material.Neon); add(BK, { 1.6, 0.12, 1 }, { 1.1, 1.9, 0 }, IC, { 0, 0, -30 }, Enum.Material.Neon)
		legs(IB, 0.36, 0.75, 0.55, 0.85)
	elseif id == "uni" then
		add(BK, { 1.5, 1.1, 2.2 }, { 0, 1.05, 0 }, WH); head(WH, 1.85, 1.4, 1)
		add(BK, { 0.15, 0.9, 0.15 }, { 0, 2.6, 1.6 }, Color3.fromRGB(255, 220, 120), { 20, 0, 0 })
		add(BK, { 0.3, 0.35, 0.5 }, { 0, 2.05, 1 }, Color3.fromRGB(255, 90, 120)); add(BK, { 0.3, 0.35, 0.5 }, { 0, 1.85, 0.6 }, Color3.fromRGB(255, 220, 80)); add(BK, { 0.3, 0.35, 0.5 }, { 0, 1.65, 0.2 }, Color3.fromRGB(90, 160, 255))
		legs(WH, 0.3, 0.85, 0.5, 0.8)
	elseif id == "gld" then
		local GG = Color3.fromRGB(255, 200, 60)
		add(BK, { 1.7, 1.2, 2.5 }, { 0, 1.05, 0 }, GG); add(BK, { 0.9, 0.7, 1.1 }, { 0, 1.9, 1.55 }, GG)
		add(BK, { 0.15, 0.5, 0.15 }, { -0.3, 2.5, 1.35 }, Color3.fromRGB(255, 245, 210), { 0, 0, 15 }); add(BK, { 0.15, 0.5, 0.15 }, { 0.3, 2.5, 1.35 }, Color3.fromRGB(255, 245, 210), { 0, 0, -15 })
		add(BK, { 1.8, 0.12, 1.2 }, { -1.2, 2, 0 }, Color3.fromRGB(255, 240, 180), { 0, 0, 35 }, Enum.Material.Neon); add(BK, { 1.8, 0.12, 1.2 }, { 1.2, 2, 0 }, Color3.fromRGB(255, 240, 180), { 0, 0, -35 }, Enum.Material.Neon)
		add(BK, { 0.25, 0.25, 1.1 }, { 0, 1.4, -1.4 }, GG, { 35, 0, 0 })
		legs(GG, 0.38, 0.8, 0.6, 0.9)
	else -- phx
		local PU, ON = Color3.fromRGB(150, 80, 220), Color3.fromRGB(255, 150, 60)
		add(BL, { 1.4, 1.3, 1.8 }, { 0, 1.2, 0 }, PU); add(BL, { 0.9, 0.9, 0.9 }, { 0, 2, 1 }, PU)
		add(BK, { 0.3, 0.2, 0.45 }, { 0, 1.9, 1.5 }, ON)
		add(BK, { 1.7, 0.12, 1.1 }, { -1.1, 1.7, 0 }, ON, { 0, 0, 35 }, Enum.Material.Neon); add(BK, { 1.7, 0.12, 1.1 }, { 1.1, 1.7, 0 }, ON, { 0, 0, -35 }, Enum.Material.Neon)
		add(BK, { 0.2, 0.8, 0.5 }, { -0.3, 1.1, -1.2 }, PU, { -30, 0, 0 }, Enum.Material.Neon); add(BK, { 0.2, 0.8, 0.5 }, { 0.3, 1.1, -1.2 }, PU, { -30, 0, 0 }, Enum.Material.Neon)
	end
	return core
end

local followers = {}
local lastPetsJSON = nil
local function buildFollowers()
	local json = plr:GetAttribute("PetsJSON") or "{}"
	if json == lastPetsJSON then return end
	lastPetsJSON = json
	for _, f in ipairs(followers) do f.core.Parent:Destroy() end
	followers = {}
	local ok, counts = pcall(function() return Http:JSONDecode(json) end)
	if not ok or type(counts) ~= "table" then return end
	local owned = {}
	for id, count in pairs(counts) do
		for _, p in ipairs(PETS) do
			if p.id == id and count > 0 then table.insert(owned, p) end
		end
	end
	table.sort(owned, function(a, b) return a.power > b.power end)
	for i = 1, math.min(3, #owned) do
		local core = buildPet(owned[i].id, SCALE_OF[owned[i].rarity] or 1)
		table.insert(followers, { core = core, angle = (i - 1) * (math.pi * 2 / 3), dist = 3.5 + i * 0.9 })
	end
end
task.spawn(function()
	while true do
		task.wait(1.5)
		pcall(buildFollowers)
	end
end)
task.spawn(function()
	local t = 0
	while true do
		RunService.Heartbeat:Wait()
		t += 0.03
		local char = plr.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			for i, f in ipairs(followers) do
				local a = f.angle + t * 0.9
				local pos = root.Position + Vector3.new(math.cos(a) * f.dist, 2.4 + math.sin(t * 2 + i) * 0.35, math.sin(a) * f.dist)
				f.core.CFrame = CFrame.new(pos, Vector3.new(root.Position.X, pos.Y, root.Position.Z))
			end
		end
	end
end)

-- ---------- อัปเดตข้อความ ----------
local function refresh()
	local ls = plr:FindFirstChild("leaderstats")
	if ls then
		coinTxt.Text = "💰 " .. fmt(ls.Coins.Value)
		powTxt.Text = "⚡ " .. fmt(plr:GetAttribute("Power") or 0)
	end
	-- ดัชนี
	local ok, counts = pcall(function() return Http:JSONDecode(plr:GetAttribute("PetsJSON") or "{}") end)
	if ok and type(counts) == "table" then
		local unlocked = 0
		for id, cell in pairs(cells) do
			local n = counts[id] or 0
			if n > 0 then
				unlocked += 1
				local p
				for _, q in ipairs(PETS) do if q.id == id then p = q end end
				cell.em.Text = p and p.emoji or "?"
				cell.nm.Text = (p and p.name or "") .. (n > 1 and (" x" .. n) or "")
				cell.frame.BackgroundTransparency = 0
			else
				cell.em.Text = "❓"
				cell.em.TextColor3 = Color3.fromRGB(30, 30, 40)
				cell.nm.Text = "???"
				cell.frame.BackgroundTransparency = 0.35
			end
		end
		counter.Text = "ปลดล็อกแล้ว " .. unlocked .. "/" .. #PETS
	end
end
task.spawn(function() while true do task.wait(0.5) pcall(refresh) end end)
