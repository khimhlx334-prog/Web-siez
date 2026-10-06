-- ============================================================
-- 🥚 EGG ISLE v3 · Gui3 (LocalScript → StarterPlayerScripts)
-- HUD: สถานะซ้ายล่าง · เฟสด้านบน · ปุ่มขวา (เรือ/สวน/ดัชนี) · แพดขับเรือ
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local plr = Players.LocalPlayer

local evNote = ReplicatedStorage:WaitForChild("Note")
local evPhase = ReplicatedStorage:WaitForChild("Phase")
local evBoatIn = ReplicatedStorage:WaitForChild("BoatIn")
local evAct = ReplicatedStorage:WaitForChild("Act")

local POOL_SIZE = { [2] = 4, [3] = 3, [4] = 2, [5] = 2 }
local ISL_NAME = { [2] = "เกาะทุ่งหญ้า", [3] = "เกาะทะเลทราย", [4] = "เกาะน้ำแข็ง", [5] = "เกาะอเวจี" }
local PET_EMOJI = { cat = "🐱", dog = "🐶", rab = "🐰", pan = "🐼", cap = "🦫", ele = "🐘", lio = "🦁", dra = "🐉", uni = "🦄", gld = "🐲", phx = "🌟" }
local PET_NAME = { cat = "แมวส้ม", dog = "คอร์กี้", rab = "กระต่ายขาว", pan = "แพนด้า", cap = "คาปิบาร่า", ele = "ช้างชมพู", lio = "สิงโตทอง", dra = "มังกรน้ำแข็ง", uni = "ยูนิคอร์นรุ้ง", gld = "ดราก้อนทอง", phx = "ฟีนิกซ์จักรวาล" }
local BOAT_COST = { [2] = 1000, [3] = 5000, [4] = 25000, [5] = 100000 }
local GARDEN_COST = { [2] = 500, [3] = 2500, [4] = 10000, [5] = 50000, [6] = 200000 }

local gui = Instance.new("ScreenGui"); gui.Name = "EggIsleGui"; gui.ResetOnSpawn = false
gui.Parent = plr:WaitForChild("PlayerGui")

local function fmt(n)
	local s = tostring(math.floor(n or 0))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end
local function stroke(p, c, t) local s = Instance.new("UIStroke"); s.Color = c or Color3.fromRGB(0, 0, 0); s.Thickness = t or 2; s.Parent = p end
local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = p end

-- ---------- สถานะซ้ายล่าง ----------
local stack = Instance.new("Frame"); stack.Size = UDim2.fromOffset(230, 118); stack.Position = UDim2.new(0, 12, 1, -130)
stack.BackgroundTransparency = 1; stack.Parent = gui
local coinTxt = Instance.new("TextLabel"); coinTxt.Size = UDim2.new(1, 0, 0, 40)
coinTxt.BackgroundTransparency = 1; coinTxt.Font = Enum.Font.GothamBlack; coinTxt.TextScaled = true
coinTxt.TextXAlignment = Enum.TextXAlignment.Left; coinTxt.TextColor3 = Color3.fromRGB(255, 220, 60)
coinTxt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); coinTxt.Parent = stack
local powTxt = Instance.new("TextLabel"); powTxt.Size = UDim2.new(1, 0, 0, 34); powTxt.Position = UDim2.fromOffset(0, 40)
powTxt.BackgroundTransparency = 1; powTxt.Font = Enum.Font.GothamBlack; powTxt.TextScaled = true
powTxt.TextXAlignment = Enum.TextXAlignment.Left; powTxt.TextColor3 = Color3.fromRGB(120, 220, 255)
powTxt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); powTxt.Parent = stack
local boatTxt = Instance.new("TextLabel"); boatTxt.Size = UDim2.new(1, 0, 0, 34); boatTxt.Position = UDim2.fromOffset(0, 78)
boatTxt.BackgroundTransparency = 1; boatTxt.Font = Enum.Font.GothamBlack; boatTxt.TextScaled = true
boatTxt.TextXAlignment = Enum.TextXAlignment.Left; boatTxt.TextColor3 = Color3.fromRGB(160, 255, 160)
boatTxt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); boatTxt.Parent = gui == nil and stack or stack

-- ---------- เฟสกลางบน ----------
local phasePill = Instance.new("TextLabel"); phasePill.Size = UDim2.fromOffset(200, 44)
phasePill.Position = UDim2.new(0.5, 0, 0, 14); phasePill.AnchorPoint = Vector2.new(0.5, 0)
phasePill.BackgroundColor3 = Color3.fromRGB(20, 24, 38); phasePill.BackgroundTransparency = 0.2
phasePill.Font = Enum.Font.GothamBlack; phasePill.TextScaled = true; phasePill.TextColor3 = Color3.fromRGB(255, 255, 255)
corner(phasePill, 12); stroke(phasePill, Color3.fromRGB(255, 255, 255), 2); phasePill.Parent = gui
evPhase.OnClientEvent:Connect(function(st)
	local mm = math.floor(st.t / 60); local ss = st.t % 60
	phasePill.Text = (st.phase == "day" and "☀️ " or "🌙 ") .. mm .. ":" .. string.format("%02d", ss)
end)

-- ---------- ถือไข่ ----------
local carryPill = Instance.new("TextLabel"); carryPill.Size = UDim2.new(0.7, 0, 0, 40)
carryPill.Position = UDim2.new(0.5, 0, 0, 66); carryPill.AnchorPoint = Vector2.new(0.5, 0)
carryPill.BackgroundColor3 = Color3.fromRGB(255, 150, 40); carryPill.Font = Enum.Font.GothamBlack
carryPill.TextScaled = true; carryPill.TextColor3 = Color3.fromRGB(255, 255, 255); carryPill.Visible = false
corner(carryPill, 10); stroke(carryPill); carryPill.Parent = gui

-- ---------- ป้ายประกาศ + ป๊อปอัพ ----------
local ban = Instance.new("TextLabel"); ban.Size = UDim2.new(0.8, 0, 0, 50)
ban.Position = UDim2.new(0.5, 0, 0, 112); ban.AnchorPoint = Vector2.new(0.5, 0)
ban.BackgroundColor3 = Color3.fromRGB(230, 80, 50); ban.Font = Enum.Font.GothamBlack; ban.TextScaled = true
ban.TextColor3 = Color3.fromRGB(255, 255, 255); ban.TextWrapped = true; ban.Visible = false
corner(ban, 12); stroke(ban, Color3.fromRGB(255, 255, 255), 2); ban.Parent = gui
local pop = Instance.new("Frame"); pop.Size = UDim2.fromOffset(260, 100)
pop.Position = UDim2.new(0.5, 0, 0.3, 0); pop.AnchorPoint = Vector2.new(0.5, 0.5)
pop.BackgroundColor3 = Color3.fromRGB(20, 24, 36); pop.Visible = false
corner(pop, 14); stroke(pop, Color3.fromRGB(255, 255, 255), 3)
local popTxt = Instance.new("TextLabel"); popTxt.Size = UDim2.new(1, -12, 1, -8); popTxt.Position = UDim2.fromOffset(6, 4)
popTxt.BackgroundTransparency = 1; popTxt.Font = Enum.Font.GothamBlack; popTxt.TextScaled = true
popTxt.TextColor3 = Color3.fromRGB(255, 255, 255); popTxt.TextWrapped = true; popTxt.Parent = pop
pop.Parent = gui
evNote.OnClientEvent:Connect(function(kind, text)
	if kind == "ban" then
		ban.Text = tostring(text); ban.Visible = true
		task.delay(4.5, function() ban.Visible = false end)
	else
		popTxt.Text = tostring(text); pop.Visible = true
		task.delay(2.5, function() pop.Visible = false end)
	end
end)

-- ---------- แผงสไตล์ฮิต ----------
local function makePanel(name, w, h, title)
	local f = Instance.new("Frame"); f.Size = UDim2.fromOffset(w, h)
	f.Position = UDim2.new(0.5, 0, 0.5, 0); f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BackgroundColor3 = Color3.fromRGB(45, 48, 62); f.Visible = false
	corner(f, 12); stroke(f, Color3.fromRGB(0, 0, 0), 3); f.Parent = gui
	local head = Instance.new("Frame"); head.Size = UDim2.new(1, -8, 0, 44); head.Position = UDim2.fromOffset(4, 4)
	head.BackgroundColor3 = Color3.fromRGB(88, 200, 60); corner(head, 8); stroke(head, Color3.fromRGB(0, 0, 0), 2); head.Parent = f
	local t = Instance.new("TextLabel"); t.Size = UDim2.new(1, -54, 1, 0); t.Position = UDim2.fromOffset(10, 0)
	t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBlack; t.TextScaled = true
	t.TextXAlignment = Enum.TextXAlignment.Left; t.TextColor3 = Color3.fromRGB(255, 255, 255)
	t.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); t.Text = title; t.Parent = head
	local x = Instance.new("TextButton"); x.Size = UDim2.fromOffset(36, 36); x.Position = UDim2.new(1, -42, 0, 4)
	x.BackgroundColor3 = Color3.fromRGB(220, 40, 40); x.Font = Enum.Font.GothamBlack; x.TextScaled = true
	x.Text = "X"; x.TextColor3 = Color3.fromRGB(255, 255, 255); corner(x, 6); stroke(x, Color3.fromRGB(0, 0, 0), 2); x.Parent = head
	x.Activated:Connect(function() f.Visible = false end)
	local body = Instance.new("Frame"); body.Size = UDim2.new(1, -16, 1, -60); body.Position = UDim2.fromOffset(8, 52)
	body.BackgroundTransparency = 1; body.Parent = f
	return f, body
end
local function bigBtn(parent, text, color, h)
	local b = Instance.new("TextButton"); b.Size = UDim2.new(1, 0, 0, h or 48)
	b.BackgroundColor3 = color; b.Font = Enum.Font.GothamBlack; b.TextScaled = true
	b.TextColor3 = Color3.fromRGB(255, 255, 255); corner(b, 10); stroke(b, Color3.fromRGB(0, 0, 0), 2)
	b.Text = text; b.Parent = parent; return b
end

-- ---------- แผงเรือ ----------
local boatPanel, boatBody = makePanel("Boat", 300, 250, "⛵ เรือของฉัน")
local bl = Instance.new("UIListLayout"); bl.Padding = UDim.new(0, 8); bl.Parent = boatBody
local boatInfo = Instance.new("TextLabel"); boatInfo.Size = UDim2.new(1, 0, 0, 44)
boatInfo.BackgroundTransparency = 1; boatInfo.Font = Enum.Font.GothamBlack; boatInfo.TextScaled = true
boatInfo.TextColor3 = Color3.fromRGB(255, 255, 255); boatInfo.TextWrapped = true; boatInfo.Parent = boatBody
local boardBtn = bigBtn(boatBody, "⛵ ขึ้นเรือ", Color3.fromRGB(60, 140, 220))
boardBtn.Activated:Connect(function()
	if (plr:GetAttribute("OnBoat") or 0) > 0 then evAct:FireServer("leave") else evAct:FireServer("board") end
end)
local upBoatBtn = bigBtn(boatBody, "อัปเรือ", Color3.fromRGB(88, 200, 60))
upBoatBtn.Activated:Connect(function() evAct:FireServer("upboat") end)

-- ---------- แผงสวน ----------
local gardenPanel, gardenBody = makePanel("Garden", 320, 330, "🏡 สวนของฉัน")
local gl = Instance.new("UIListLayout"); gl.Padding = UDim.new(0, 8); gl.Parent = gardenBody
local gardenInfo = Instance.new("TextLabel"); gardenInfo.Size = UDim2.new(1, 0, 0, 40)
gardenInfo.BackgroundTransparency = 1; gardenInfo.Font = Enum.Font.GothamBlack; gardenInfo.TextScaled = true
gardenInfo.TextColor3 = Color3.fromRGB(255, 255, 255); gardenInfo.TextWrapped = true; gardenInfo.Parent = gardenBody
local upGardenBtn = bigBtn(gardenBody, "อัปสวน", Color3.fromRGB(88, 200, 60))
upGardenBtn.Activated:Connect(function() evAct:FireServer("upgarden") end)
local petScroll = Instance.new("ScrollingFrame"); petScroll.Size = UDim2.new(1, 0, 1, -110)
petScroll.BackgroundTransparency = 1; petScroll.ScrollBarThickness = 4; petScroll.Parent = gardenBody
local pl = Instance.new("UIListLayout"); pl.Padding = UDim.new(0, 5); pl.Parent = petScroll

-- ---------- แผงดัชนี ----------
local idxPanel, idxBody = makePanel("Index", 300, 300, "📖 ดัชนีเกาะ")
local il = Instance.new("UIListLayout"); il.Padding = UDim.new(0, 8); il.Parent = idxBody
local idxRows = {}
for isl = 2, 5 do
	local r = Instance.new("TextLabel"); r.Size = UDim2.new(1, 0, 0, 44)
	r.BackgroundColor3 = Color3.fromRGB(60, 64, 84); r.Font = Enum.Font.GothamBlack; r.TextScaled = true
	r.TextColor3 = Color3.fromRGB(255, 255, 255); corner(r, 10); stroke(r, Color3.fromRGB(0, 0, 0), 2); r.Parent = idxBody
	idxRows[isl] = r
end

-- ---------- ไอคอนขวา ----------
local function iconBtn(emoji, bg, ypos)
	local b = Instance.new("TextButton"); b.Size = UDim2.fromOffset(60, 60)
	b.Position = UDim2.new(1, -72, 0, ypos); b.BackgroundColor3 = bg
	b.Font = Enum.Font.GothamBlack; b.TextScaled = true; b.Text = emoji; b.TextColor3 = Color3.fromRGB(255, 255, 255)
	corner(b, 12); stroke(b, Color3.fromRGB(0, 0, 0), 3); b.Parent = gui; return b
end
local bBoat = iconBtn("⛵", Color3.fromRGB(60, 140, 220), 120)
local bGarden = iconBtn("🏡", Color3.fromRGB(250, 150, 50), 190)
local bIdx = iconBtn("📖", Color3.fromRGB(150, 90, 200), 260)
bBoat.Activated:Connect(function() boatPanel.Visible = not boatPanel.Visible; gardenPanel.Visible = false; idxPanel.Visible = false end)
bGarden.Activated:Connect(function() gardenPanel.Visible = not gardenPanel.Visible; boatPanel.Visible = false; idxPanel.Visible = false end)
bIdx.Activated:Connect(function() idxPanel.Visible = not idxPanel.Visible; boatPanel.Visible = false; gardenPanel.Visible = false end)

-- ---------- แพดขับเรือ ----------
local pad = Instance.new("Frame"); pad.Size = UDim2.fromOffset(150, 150)
pad.Position = UDim2.new(1, -90, 1, -170); pad.AnchorPoint = Vector2.new(0.5, 0.5)
pad.BackgroundTransparency = 1; pad.Visible = false; pad.Parent = gui
local input = { th = 0, tu = 0 }
local function padBtn(text, pos, dn, up)
	local b = Instance.new("TextButton"); b.Size = UDim2.fromOffset(52, 52); b.Position = pos
	b.AnchorPoint = Vector2.new(0.5, 0.5); b.BackgroundColor3 = Color3.fromRGB(30, 34, 48)
	b.BackgroundTransparency = 0.2; b.Font = Enum.Font.GothamBlack; b.TextScaled = true
	b.Text = text; b.TextColor3 = Color3.fromRGB(255, 255, 255); corner(b, 12); stroke(b, Color3.fromRGB(255, 255, 255), 2); b.Parent = pad
	b.MouseButton1Down:Connect(dn); b.MouseButton1Up:Connect(up)
	b.MouseLeave:Connect(up)
	return b
end
padBtn("▲", UDim2.new(0.5, 0, 0, 26), function() input.th = 1 end, function() input.th = 0 end)
padBtn("▼", UDim2.new(0.5, 0, 1, -26), function() input.th = -0.4 end, function() input.th = 0 end)
padBtn("◀", UDim2.new(0, 26, 0.5, 0), function() input.tu = 1 end, function() input.tu = 0 end)
padBtn("▶", UDim2.new(1, -26, 0.5, 0), function() input.tu = -1 end, function() input.tu = 0 end)
task.spawn(function()
	while true do
		task.wait(0.1)
		if (plr:GetAttribute("OnBoat") or 0) > 0 then
			evBoatIn:FireServer(input.th, input.tu)
		end
	end
end)

-- ---------- รีเฟรช ----------
local function refresh()
	local ls = plr:FindFirstChild("leaderstats")
	if ls then coinTxt.Text = "💰 " .. fmt(ls.Coins.Value) end
	local ok, counts = pcall(function() return Http:JSONDecode(plr:GetAttribute("PetsJSON") or "{}") end)
	local income = 0
	local nPets = 0
	if ok and type(counts) == "table" then
		local pows = {}
		for id, n in pairs(counts) do
			local pw = ({ cat = 1, dog = 1, rab = 1, pan = 3, cap = 3, ele = 10, lio = 10, dra = 40, uni = 40, gld = 200, phx = 200 })[id] or 1
			for _ = 1, n do table.insert(pows, pw) end
			nPets += n
		end
		table.sort(pows, function(a, b) return a > b end)
		local slots = plr:GetAttribute("Slots") or 3
		for i = 1, math.min(slots, #pows) do income += pows[i] end
		-- รายการสัตว์ในสวน
		petScroll:ClearAllChildren()
		Instance.new("UIListLayout", petScroll).Padding = UDim.new(0, 5)
		for id, n in pairs(counts) do
			local row = Instance.new("TextLabel"); row.Size = UDim2.new(1, -4, 0, 30)
			row.BackgroundColor3 = Color3.fromRGB(34, 40, 60); row.Font = Enum.Font.GothamBlack
			row.TextScaled = true; row.TextColor3 = Color3.fromRGB(255, 255, 255)
			row.Text = " " .. (PET_EMOJI[id] or "?") .. " " .. (PET_NAME[id] or id) .. " x" .. n
			corner(row, 8); row.Parent = petScroll
		end
		petScroll.CanvasSize = UDim2.new(0, 0, 0, nPets * 35 + 10)
	end
	powTxt.Text = "⚡ +" .. fmt(income) .. "/วิ (สวน)"
	local blvl = plr:GetAttribute("BoatLvl") or 1
	boatTxt.Text = "⛵ เรือ Lv" .. blvl .. " · สวน #" .. (plr:GetAttribute("Slot") or 1)
	local bc = BOAT_COST[blvl + 1]
	upBoatBtn.Text = bc and ("⛵ อัปเรือ 💰" .. fmt(bc)) or "⛵ เต็มขั้นแล้ว!"
	boatInfo.Text = "ความเร็วปัจจุบัน x" .. math.floor(16 * math.pow(1.5, blvl - 1))
	boardBtn.Text = (plr:GetAttribute("OnBoat") or 0) > 0 and "🚪 ลงเรือ" or "⛵ ขึ้นเรือ (ยืนใกล้เรือ)"
	local glvl = plr:GetAttribute("GardenLvl") or 1
	local gc = GARDEN_COST[glvl + 1]
	upGardenBtn.Text = gc and ("🏡 อัปสวน 💰" .. fmt(gc)) or "🏡 เต็มขั้นแล้ว!"
	gardenInfo.Text = "ช่องสัตว์ " .. (plr:GetAttribute("Slots") or 3) .. " · สัตว์ " .. nPets .. " ตัว"
	local carryingIsl = plr:GetAttribute("Carrying") or 0
	carryPill.Visible = carryingIsl > 0
	if carryingIsl > 0 then carryPill.Text = "🥚 ถือไข่เกาะ " .. carryingIsl .. " — กลับไปฟักที่สวน!" end
	pad.Visible = (plr:GetAttribute("OnBoat") or 0) > 0
	-- ดัชนี
	local ok2, idx = pcall(function() return Http:JSONDecode(plr:GetAttribute("IndexJSON") or "{}") end)
	if ok2 and type(idx) == "table" then
		for isl = 2, 5 do
			local got = idx[tostring(isl)] and #idx[tostring(isl)] or (idx[isl] and #idx[isl] or 0)
			local done = got >= POOL_SIZE[isl]
			idxRows[isl].Text = "เกาะ " .. isl .. " " .. ISL_NAME[isl] .. "  " .. got .. "/" .. POOL_SIZE[isl] .. (done and "  🪵" or "")
		end
	end
end
task.spawn(function() while true do task.wait(0.5) pcall(refresh) end end)
