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

-- ---------- 🐾 สัตว์เลี้ยงลอยตามตัว (top-3 พาวเวอร์ · ขนาดตามพลัง) ----------
local followers = {}
local function buildFollowers()
	for _, f in ipairs(followers) do f.part:Destroy() end
	followers = {}
	local ok, counts = pcall(function() return Http:JSONDecode(plr:GetAttribute("PetsJSON") or "{}") end)
	if not ok or type(counts) ~= "table" then return end
	local owned = {}
	for id, count in pairs(counts) do
		for _, p in ipairs(PETS) do
			if p.id == id then
				for _ = 1, math.min(count, 3) do table.insert(owned, p) end
			end
		end
	end
	table.sort(owned, function(a, b) return a.power > b.power end)
	for i = 1, math.min(3, #owned) do
		local part = Instance.new("Part"); part.Size = Vector3.new(0.5, 0.5, 0.5)
		part.Anchored = true; part.CanCollide = false; part.CanQuery = false; part.CanTouch = false
		part.Transparency = 1; part.Parent = workspace
		local bb = Instance.new("BillboardGui"); bb.AlwaysOnTop = true
		local sz = 60 + math.min(90, owned[i].power)
		bb.Size = UDim2.fromOffset(sz, sz); bb.Parent = part
		local t = Instance.new("TextLabel"); t.Size = UDim2.new(1, 0, 1, 0); t.BackgroundTransparency = 1
		t.Font = Enum.Font.GothamBlack; t.TextScaled = true; t.Text = owned[i].emoji; t.Parent = bb
		table.insert(followers, { part = part, angle = (i - 1) * (math.pi * 2 / 3), dist = 3 + i * 0.8 })
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
		for i, f in ipairs(followers) do
			if root then
				local a = f.angle + t * 1.2
				local pos = root.Position + Vector3.new(math.cos(a) * f.dist, 2.2 + math.sin(t * 2 + i) * 0.4, math.sin(a) * f.dist)
				f.part.Position = pos
			end
		end
	end
end)

-- ---------- อัปเดตข้อความ ----------
local function refresh()
	local ls = plr:FindFirstChild("leaderstats")
	if ls then
		coinTxt.Text = "🪙 " .. fmt(ls.Coins.Value)
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
