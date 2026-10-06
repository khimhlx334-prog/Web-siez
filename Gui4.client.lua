-- ============================================================
-- EGG ISLE v4 · Gui4 (LocalScript → StarterPlayerScripts)
-- HUD สไตล์ซิมฮิต: ฟอนต์ FredokaOne ขอบดำ · ไม่ใช้อิโมจิ · เงิน $ แบบย่อ
-- กดค้าง 3 วิเก็บไข่ · แผง เรือ/สวน/ดัชนี/ฟิวส์/เทรล/หีบ · แจ้งผู้ดูแลสไตล์แชท
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local WS = workspace
local plr = Players.LocalPlayer

local evNote = ReplicatedStorage:WaitForChild("Note")
local evPhase = ReplicatedStorage:WaitForChild("Phase")
local evBoatIn = ReplicatedStorage:WaitForChild("BoatIn")
local evAct = ReplicatedStorage:WaitForChild("Act")
local evPick = ReplicatedStorage:WaitForChild("Pick")

local FONT = Enum.Font.FredokaOne
local PET_NAME = { cat = "แมวส้ม", dog = "คอร์กี้", rab = "กระต่ายขาว", pan = "แพนด้า", cap = "คาปิบาร่า", ele = "ช้างชมพู", lio = "สิงโตทอง", dra = "มังกรน้ำแข็ง", uni = "ยูนิคอร์นรุ้ง", gld = "ดราก้อนทอง", phx = "ฟีนิกซ์จักรวาล" }
local PET_PWR = { cat = 1, dog = 1, rab = 1, pan = 3, cap = 3, ele = 10, lio = 10, dra = 40, uni = 40, gld = 200, phx = 200 }
local SELL_VALUE = { [1] = 50, [3] = 150, [10] = 500, [40] = 2000, [200] = 10000 }
local BOAT_COST = { [2] = 1000, [3] = 5000, [4] = 25000, [5] = 100000 }
local GARDEN_COST = { [2] = 500, [3] = 2500, [4] = 10000, [5] = 50000, [6] = 200000 }
local TRAILS = {
	{ name = "เทรลลมเขียว", mult = 1.5, cost = 2500, color = Color3.fromRGB(80, 220, 90) },
	{ name = "เทรลน้ำแข็ง", mult = 2, cost = 10000, color = Color3.fromRGB(120, 200, 255) },
	{ name = "เทรลเพลิง", mult = 2.5, cost = 40000, color = Color3.fromRGB(255, 120, 50) },
}
local ISL_NAME = { [2] = "เกาะทุ่งหญ้า", [3] = "เกาะทะเลทราย", [4] = "เกาะน้ำแข็ง", [5] = "เกาะอเวจี" }
local POOL_SIZE = { [2] = 4, [3] = 3, [4] = 2, [5] = 2 }

local gui = Instance.new("ScreenGui"); gui.Name = "EggIsleGui"; gui.ResetOnSpawn = false
gui.Parent = plr:WaitForChild("PlayerGui")

local function short(n)
	n = math.floor(n or 0)
	local units = { "", "K", "M", "B", "T", "Qa" }
	local i = 1; local v = n
	while v >= 1000 and i < 6 do v = v / 1000; i += 1 end
	if i == 1 then return tostring(n) end
	local s = string.format("%.1f", v)
	if s:sub(-2) == ".0" then s = s:sub(1, -3) end
	return s .. units[i]
end
local function stroke(p, c, t) local s = Instance.new("UIStroke"); s.Color = c or Color3.fromRGB(0, 0, 0); s.Thickness = t or 2; s.Parent = p end
local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = p end
local function txt(parent, size, pos, color, align)
	local t = Instance.new("TextLabel"); t.Size = size; t.Position = pos or UDim2.new()
	t.BackgroundTransparency = 1; t.Font = FONT; t.TextScaled = true; t.TextColor3 = color
	t.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); t.TextXAlignment = align or Enum.TextXAlignment.Left
	t.Parent = parent; return t
end

-- ---------- สถานะซ้ายล่าง ----------
local stack = Instance.new("Frame"); stack.Size = UDim2.fromOffset(240, 118); stack.Position = UDim2.new(0, 12, 1, -130)
stack.BackgroundTransparency = 1; stack.Parent = gui
local moneyTxt = txt(stack, UDim2.new(1, 0, 0, 42), UDim2.new(), Color3.fromRGB(140, 255, 90))
local incTxt = txt(stack, UDim2.new(1, 0, 0, 34), UDim2.fromOffset(0, 42), Color3.fromRGB(120, 220, 255))
local miscTxt = txt(stack, UDim2.new(1, 0, 0, 34), UDim2.fromOffset(0, 78), Color3.fromRGB(255, 220, 120))

-- ---------- เฟสกลางบน ----------
local phasePill = Instance.new("TextLabel"); phasePill.Size = UDim2.fromOffset(220, 44)
phasePill.Position = UDim2.new(0.5, 0, 0, 14); phasePill.AnchorPoint = Vector2.new(0.5, 0)
phasePill.BackgroundColor3 = Color3.fromRGB(20, 24, 38); phasePill.BackgroundTransparency = 0.2
phasePill.Font = FONT; phasePill.TextScaled = true; phasePill.TextColor3 = Color3.fromRGB(255, 255, 255)
corner(phasePill, 12); stroke(phasePill, Color3.fromRGB(255, 255, 255), 2); phasePill.Parent = gui
evPhase.OnClientEvent:Connect(function(st)
	local mm = math.floor(st.t / 60); local ss = st.t % 60
	phasePill.Text = (st.phase == "day" and "กลางวัน " or "กลางคืน ") .. mm .. ":" .. string.format("%02d", ss)
end)

-- ---------- ถือไข่ ----------
local carryPill = Instance.new("TextLabel"); carryPill.Size = UDim2.new(0.7, 0, 0, 40)
carryPill.Position = UDim2.new(0.5, 0, 0, 66); carryPill.AnchorPoint = Vector2.new(0.5, 0)
carryPill.BackgroundColor3 = Color3.fromRGB(255, 150, 40); carryPill.Font = FONT
carryPill.TextScaled = true; carryPill.TextColor3 = Color3.fromRGB(255, 255, 255); carryPill.Visible = false
corner(carryPill, 10); stroke(carryPill); carryPill.Parent = gui

-- ---------- แจ้งผู้ดูแลสไตล์แชท (ชื่อเขียว + ข้อความขาวขอบดำ) ----------
local adminBox = Instance.new("Frame"); adminBox.Size = UDim2.new(0.85, 0, 0, 64)
adminBox.Position = UDim2.new(0.5, 0, 0, 116); adminBox.AnchorPoint = Vector2.new(0.5, 0)
adminBox.BackgroundTransparency = 1; adminBox.Visible = false; adminBox.Parent = gui
local adminName = txt(adminBox, UDim2.new(1, 0, 0, 30), UDim2.new(), Color3.fromRGB(90, 230, 90), Enum.TextXAlignment.Center)
adminName.TextStrokeTransparency = 0
local adminMsg = txt(adminBox, UDim2.new(1, 0, 0, 32), UDim2.fromOffset(0, 30), Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Center)
adminMsg.TextWrapped = true
-- ---------- ป๊อปอัพ ----------
local pop = Instance.new("Frame"); pop.Size = UDim2.fromOffset(280, 90)
pop.Position = UDim2.new(0.5, 0, 0.3, 0); pop.AnchorPoint = Vector2.new(0.5, 0.5)
pop.BackgroundColor3 = Color3.fromRGB(20, 24, 36); pop.Visible = false
corner(pop, 14); stroke(pop, Color3.fromRGB(255, 255, 255), 3)
local popTxt = txt(pop, UDim2.new(1, -12, 1, -8), UDim2.fromOffset(6, 4), Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Center)
popTxt.TextWrapped = true; pop.Parent = gui
evNote.OnClientEvent:Connect(function(kind, text)
	if kind == "admin" then
		adminName.Text = "ผู้ดูแล"
		adminMsg.Text = tostring(text)
		adminBox.Visible = true
		task.delay(5, function() adminBox.Visible = false end)
		pcall(function()
			game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
				Text = "[ผู้ดูแล] " .. tostring(text), Color = Color3.fromRGB(90, 230, 90), Font = FONT,
			})
		end)
	elseif kind == "ban" then
		adminName.Text = "ประกาศ"
		adminName.TextColor3 = Color3.fromRGB(255, 220, 90)
		adminMsg.Text = tostring(text)
		adminBox.Visible = true
		task.delay(5, function() adminBox.Visible = false end)
	else
		popTxt.Text = tostring(text); pop.Visible = true
		task.delay(2.5, function() pop.Visible = false end)
	end
end)

-- ---------- แผง ----------
local function makePanel(name, w, h, title)
	local f = Instance.new("Frame"); f.Size = UDim2.fromOffset(w, h)
	f.Position = UDim2.new(0.5, 0, 0.5, 0); f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BackgroundColor3 = Color3.fromRGB(45, 48, 62); f.Visible = false
	corner(f, 12); stroke(f, Color3.fromRGB(0, 0, 0), 3); f.Parent = gui
	local head = Instance.new("Frame"); head.Size = UDim2.new(1, -8, 0, 44); head.Position = UDim2.fromOffset(4, 4)
	head.BackgroundColor3 = Color3.fromRGB(170, 60, 220); corner(head, 8); stroke(head, Color3.fromRGB(0, 0, 0), 2); head.Parent = f
	local t = txt(head, UDim2.new(1, -54, 1, 0), UDim2.fromOffset(10, 0), Color3.fromRGB(255, 255, 255))
	t.Text = title
	local x = Instance.new("TextButton"); x.Size = UDim2.fromOffset(36, 36); x.Position = UDim2.new(1, -42, 0, 4)
	x.BackgroundColor3 = Color3.fromRGB(220, 40, 40); x.Font = FONT; x.TextScaled = true
	x.Text = "X"; x.TextColor3 = Color3.fromRGB(255, 255, 255); corner(x, 6); stroke(x, Color3.fromRGB(0, 0, 0), 2); x.Parent = head
	x.Activated:Connect(function() f.Visible = false end)
	local body = Instance.new("Frame"); body.Size = UDim2.new(1, -16, 1, -60); body.Position = UDim2.fromOffset(8, 52)
	body.BackgroundTransparency = 1; body.Parent = f
	return f, body
end
local function bigBtn(parent, text, color, h)
	local b = Instance.new("TextButton"); b.Size = UDim2.new(1, 0, 0, h or 46)
	b.BackgroundColor3 = color; b.Font = FONT; b.TextScaled = true
	b.TextColor3 = Color3.fromRGB(255, 255, 255); corner(b, 10); stroke(b, Color3.fromRGB(0, 0, 0), 2)
	b.Text = text; b.Parent = parent; return b
end

-- ---------- แผงเรือ ----------
local boatPanel, boatBody = makePanel("Boat", 300, 240, "เรือของฉัน")
local bl = Instance.new("UIListLayout"); bl.Padding = UDim.new(0, 8); bl.Parent = boatBody
local boatInfo = txt(boatBody, UDim2.new(1, 0, 0, 40)); boatInfo.TextWrapped = true
local boardBtn = bigBtn(boatBody, "ขึ้นเรือ", Color3.fromRGB(60, 140, 220))
boardBtn.Activated:Connect(function()
	if (plr:GetAttribute("OnBoat") or 0) > 0 then evAct:FireServer("leave") else evAct:FireServer("board") end
end)
local upBoatBtn = bigBtn(boatBody, "อัปเรือ", Color3.fromRGB(88, 200, 60))
upBoatBtn.Activated:Connect(function() evAct:FireServer("upboat") end)

-- ---------- แผงสวน + ขาย ----------
local gardenPanel, gardenBody = makePanel("Garden", 320, 340, "สวนของฉัน")
local gl = Instance.new("UIListLayout"); gl.Padding = UDim.new(0, 6); gl.Parent = gardenBody
local gardenInfo = txt(gardenBody, UDim2.new(1, 0, 0, 36)); gardenInfo.TextWrapped = true
local upGardenBtn = bigBtn(gardenBody, "อัปสวน", Color3.fromRGB(88, 200, 60), 40)
upGardenBtn.Activated:Connect(function() evAct:FireServer("upgarden") end)
local petScroll = Instance.new("ScrollingFrame"); petScroll.Size = UDim2.new(1, 0, 1, -96)
petScroll.BackgroundTransparency = 1; petScroll.ScrollBarThickness = 4; petScroll.Parent = gardenBody

-- ---------- แผงดัชนี ----------
local idxPanel, idxBody = makePanel("Index", 300, 290, "ดัชนีเกาะ")
local il = Instance.new("UIListLayout"); il.Padding = UDim.new(0, 8); il.Parent = idxBody
local idxRows = {}
for isl = 2, 5 do
	local r = Instance.new("TextLabel"); r.Size = UDim2.new(1, 0, 0, 44)
	r.BackgroundColor3 = Color3.fromRGB(60, 64, 84); r.Font = FONT; r.TextScaled = true
	r.TextColor3 = Color3.fromRGB(255, 255, 255); corner(r, 10); stroke(r, Color3.fromRGB(0, 0, 0), 2); r.Parent = idxBody
	idxRows[isl] = r
end

-- ---------- แผงฟิวส์ ----------
local fusePanel, fuseBody = makePanel("Fuse", 300, 320, "เครื่องฟิวส์")
local fl = Instance.new("UIListLayout"); fl.Padding = UDim.new(0, 6); fl.Parent = fuseBody
local fuseInfo = txt(fuseBody, UDim2.new(1, 0, 0, 52), UDim2.new(), Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Center)
fuseInfo.TextWrapped = true
fuseInfo.Text = "นำสัตว์เดียวกัน 3 ตัวมาฟิวส์ = ร่างยักษ์ พลัง x2"
local fuseScroll = Instance.new("ScrollingFrame"); fuseScroll.Size = UDim2.new(1, 0, 1, -60)
fuseScroll.BackgroundTransparency = 1; fuseScroll.ScrollBarThickness = 4; fuseScroll.Parent = fuseBody

-- ---------- แผงเทรล ----------
local trailPanel, trailBody = makePanel("Trail", 300, 280, "ร้านเทรล")
local tl = Instance.new("UIListLayout"); tl.Padding = UDim.new(0, 8); tl.Parent = trailBody
local trailBtns = {}
for i, t in ipairs(TRAILS) do
	local b = bigBtn(trailBody, t.name .. " x" .. t.mult .. " · $" .. short(t.cost), t.color, 52)
	b.Activated:Connect(function() evAct:FireServer("trail", i) end)
	trailBtns[i] = b
end

-- ---------- แผงหีบ ----------
local giftPanel, giftBody = makePanel("Gift", 280, 160, "หีบสมบัติฟรี")
local giftBtn = bigBtn(giftBody, "เปิดหีบฟรี (+$750 / 20 ชม.)", Color3.fromRGB(255, 190, 40), 60)
giftBtn.Position = UDim2.new(0, 0, 0.5, -10)
giftBtn.Activated:Connect(function() evAct:FireServer("gift") end)

-- ---------- ปุ่มขวา (ข้อความไทย ไม่ใช้อิโมจิ) ----------
local menuDefs = {
	{ "เรือ", Color3.fromRGB(60, 140, 220), boatPanel },
	{ "สวน", Color3.fromRGB(250, 150, 50), gardenPanel },
	{ "ดัชนี", Color3.fromRGB(150, 90, 200), idxPanel },
	{ "ฟิวส์", Color3.fromRGB(220, 60, 180), fusePanel },
	{ "เทรล", Color3.fromRGB(60, 190, 200), trailPanel },
	{ "หีบ", Color3.fromRGB(255, 190, 40), giftPanel },
}
local allPanels = {}
for i, m in ipairs(menuDefs) do
	local b = Instance.new("TextButton"); b.Size = UDim2.fromOffset(64, 48)
	b.Position = UDim2.new(1, -76, 0, 110 + (i - 1) * 56); b.BackgroundColor3 = m[2]
	b.Font = FONT; b.TextScaled = true; b.Text = m[1]; b.TextColor3 = Color3.fromRGB(255, 255, 255)
	corner(b, 12); stroke(b, Color3.fromRGB(0, 0, 0), 3); b.Parent = gui
	table.insert(allPanels, m[3])
	b.Activated:Connect(function()
		for _, p in ipairs(allPanels) do p.Visible = (p == m[3]) and not p.Visible or false end
	end)
end

-- ---------- กดค้างเก็บไข่ ----------
local holdBtn = Instance.new("TextButton"); holdBtn.Size = UDim2.fromOffset(150, 150)
holdBtn.Position = UDim2.new(0.5, 0, 1, -110); holdBtn.AnchorPoint = Vector2.new(0.5, 0.5)
holdBtn.BackgroundColor3 = Color3.fromRGB(30, 34, 48); holdBtn.BackgroundTransparency = 0.25
holdBtn.Font = FONT; holdBtn.TextScaled = true; holdBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
holdBtn.Text = "กดค้าง\nเก็บไข่"; holdBtn.Visible = false
corner(holdBtn, 999); stroke(holdBtn, Color3.fromRGB(255, 255, 255), 3); holdBtn.Parent = gui
local holdFill = Instance.new("Frame"); holdFill.Size = UDim2.new(0, 0, 1, 0)
holdFill.BackgroundColor3 = Color3.fromRGB(120, 220, 90); holdFill.BackgroundTransparency = 0.5
holdFill.Parent = holdBtn
local hc2 = Instance.new("UICorner"); hc2.CornerRadius = UDim.new(1, 0); hc2.Parent = holdFill

local nearEgg = nil
local holdTime = 0
local holding = false
local eDown = false
UserInputService.InputBegan:Connect(function(inp, gp)
	if gp then return end
	if inp.KeyCode == Enum.KeyCode.E then eDown = true end
end)
UserInputService.InputEnded:Connect(function(inp)
	if inp.KeyCode == Enum.KeyCode.E then eDown = false end
end)
holdBtn.MouseButton1Down:Connect(function() holding = true end)
holdBtn.MouseButton1Up:Connect(function() holding = false end)
holdBtn.MouseLeave:Connect(function() holding = false end)

task.spawn(function()
	while true do
		task.wait(0.1)
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		-- หาไข่ใกล้สุด
		nearEgg = nil
		if hrp and not ((plr:GetAttribute("Carrying") or 0) > 0) then
			local w3 = WS:FindFirstChild("World3")
			if w3 then
				for _, d in ipairs(w3:GetDescendants()) do
					if d.Name == "EggLive" and (d.Position - hrp.Position).Magnitude < 9 then
						nearEgg = d; break
					end
				end
			end
		end
		holdBtn.Visible = nearEgg ~= nil
		if not nearEgg then holdTime = 0; holdFill.Size = UDim2.new(0, 0, 1, 0) end
		if nearEgg and (holding or eDown) then
			holdTime += 0.1
			holdFill.Size = UDim2.new(math.min(1, holdTime / 3), 0, 1, 0)
			if holdTime >= 3 then
				evPick:FireServer(nearEgg)
				holdTime = 0; holding = false
				holdFill.Size = UDim2.new(0, 0, 1, 0)
			end
		else
			holdTime = math.max(0, holdTime - 0.2)
			holdFill.Size = UDim2.new(math.min(1, holdTime / 3), 0, 1, 0)
		end
	end
end)

-- ---------- แพดขับเรือ ----------
local pad = Instance.new("Frame"); pad.Size = UDim2.fromOffset(150, 150)
pad.Position = UDim2.new(1, -90, 1, -170); pad.AnchorPoint = Vector2.new(0.5, 0.5)
pad.BackgroundTransparency = 1; pad.Visible = false; pad.Parent = gui
local input = { th = 0, tu = 0 }
local function padBtn(text, pos, dn, up)
	local b = Instance.new("TextButton"); b.Size = UDim2.fromOffset(52, 52); b.Position = pos
	b.AnchorPoint = Vector2.new(0.5, 0.5); b.BackgroundColor3 = Color3.fromRGB(30, 34, 48)
	b.BackgroundTransparency = 0.2; b.Font = FONT; b.TextScaled = true
	b.Text = text; b.TextColor3 = Color3.fromRGB(255, 255, 255); corner(b, 12); stroke(b, Color3.fromRGB(255, 255, 255), 2); b.Parent = pad
	b.MouseButton1Down:Connect(dn); b.MouseButton1Up:Connect(up); b.MouseLeave:Connect(up)
end
padBtn("^", UDim2.new(0.5, 0, 0, 26), function() input.th = 1 end, function() input.th = 0 end)
padBtn("v", UDim2.new(0.5, 0, 1, -26), function() input.th = -0.4 end, function() input.th = 0 end)
padBtn("<", UDim2.new(0, 26, 0.5, 0), function() input.tu = 1 end, function() input.tu = 0 end)
padBtn(">", UDim2.new(1, -26, 0.5, 0), function() input.tu = -1 end, function() input.tu = 0 end)
task.spawn(function()
	while true do
		task.wait(0.1)
		if (plr:GetAttribute("OnBoat") or 0) > 0 then evBoatIn:FireServer(input.th, input.tu) end
	end
end)

-- ---------- ลีดเดอร์บอร์ด 3D ----------
task.spawn(function()
	local w3 = WS:FindFirstChild("World3")
	local board = w3 and w3:FindFirstChild("LeaderBoard3D")
	if not board then return end
	local bb = Instance.new("BillboardGui"); bb.Size = UDim2.new(0, 300, 0, 260); bb.AlwaysOnTop = true; bb.Parent = board
	local list = txt(bb, UDim2.new(1, -10, 1, -10), UDim2.fromOffset(5, 5), Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Left)
	list.TextWrapped = false
	while true do
		task.wait(2)
		local rows = {}
		for _, p in ipairs(Players:GetPlayers()) do
			table.insert(rows, { name = p.Name, inc = p:GetAttribute("Income") or 0 })
		end
		table.sort(rows, function(a, b) return a.inc > b.inc end)
		local s = "อันดับรายได้/วินาที\n"
		for i = 1, math.min(5, #rows) do
			s ..= i .. ". " .. rows[i].name:sub(1, 12) .. "  $" .. short(rows[i].inc) .. "/วิ\n"
		end
		list.Text = s
	end
end)

-- ---------- เทรลพาร์ติเคิล ----------
local lastTrail = -1
task.spawn(function()
	while true do
		task.wait(1)
		local lvl = plr:GetAttribute("TrailLvl") or 0
		if lvl ~= lastTrail then
			lastTrail = lvl
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				for _, c in ipairs(hrp:GetChildren()) do if c.Name == "MyTrail" then c:Destroy() end end
				if lvl > 0 and TRAILS[lvl] then
					local at = Instance.new("Attachment"); at.Name = "TrailAt"; at.Parent = hrp
					local tr = Instance.new("Trail"); tr.Name = "MyTrail"; tr.Attachment0 = at; tr.Attachment1 = at
					tr.Color = ColorSequence.new(TRAILS[lvl].color)
					tr.Lifetime = 0.6; tr.Width = NumberSequence.new(1.5, 0)
					local pe = Instance.new("ParticleEmitter"); pe.Name = "MyTrail"; pe.Color = ColorSequence.new(TRAILS[lvl].color)
					pe.Rate = 40; pe.Lifetime = NumberRange.new(0.4, 0.7); pe.Speed = 4; pe.Parent = hrp
				end
			end
		end
	end
end)

-- ---------- รีเฟรช ----------
local function refresh()
	local ls = plr:FindFirstChild("leaderstats")
	if ls then moneyTxt.Text = "$" .. short(ls.Money.Value) end
	incTxt.Text = "+$" .. short(plr:GetAttribute("Income") or 0) .. "/วินาที (สวน)"
	local blvl = plr:GetAttribute("BoatLvl") or 1
	miscTxt.Text = "เรือ Lv" .. blvl .. " · สวน #" .. (plr:GetAttribute("Slot") or 1) .. " · เทรล x" .. (plr:GetAttribute("TrailLvl") or 0)
	local bc = BOAT_COST[blvl + 1]
	upBoatBtn.Text = bc and ("อัปเรือ $" .. short(bc)) or "เรือเต็มขั้นแล้ว!"
	boatInfo.Text = "ความเร็วเรือปัจจุบัน x" .. math.floor(16 * math.pow(1.5, blvl - 1))
	boardBtn.Text = (plr:GetAttribute("OnBoat") or 0) > 0 and "ลงเรือ" or "ขึ้นเรือ (ยืนใกล้เรือ)"
	local glvl = plr:GetAttribute("GardenLvl") or 1
	local gc = GARDEN_COST[glvl + 1]
	upGardenBtn.Text = gc and ("อัปสวน $" .. short(gc)) or "สวนเต็มขั้นแล้ว!"
	-- สวน/ขาย
	local ok, counts = pcall(function() return Http:JSONDecode(plr:GetAttribute("PetsJSON") or "{}") end)
	if ok and type(counts) == "table" then
		local n = 0
		for _ in pairs(counts) do n += 1 end
		gardenInfo.Text = "ช่อง " .. (plr:GetAttribute("Slots") or 3) .. " · ชนิดสัตว์ " .. n
		petScroll:ClearAllChildren()
		local pl2 = Instance.new("UIListLayout"); pl2.Padding = UDim.new(0, 5); pl2.Parent = petScroll
		for en, cnt in pairs(counts) do
			local base, big = en, false
			if base:sub(1, 3) == "BIG" then big = true; base = base:sub(4) end
			local pw = PET_PWR[base] or 1
			local row = Instance.new("Frame"); row.Size = UDim2.new(1, -4, 0, 34)
			row.BackgroundColor3 = Color3.fromRGB(34, 40, 60); corner(row, 8); row.Parent = petScroll
			local lab = txt(row, UDim2.new(0.62, 0, 1, 0), UDim2.fromOffset(6, 0), Color3.fromRGB(255, 255, 255))
			lab.Text = (PET_NAME[base] or base) .. (big and "ยักษ์" or "") .. " x" .. cnt
			local val = (SELL_VALUE[pw] or 50) * (big and 3 or 1)
			local sb = Instance.new("TextButton"); sb.Size = UDim2.new(0.34, -4, 0.8, 0)
			sb.Position = UDim2.new(0.65, 0, 0.1, 0); sb.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
			sb.Font = FONT; sb.TextScaled = true; sb.Text = "ขาย $" .. short(val)
			sb.TextColor3 = Color3.fromRGB(255, 255, 255); corner(sb, 6); sb.Parent = row
			sb.Activated:Connect(function() evAct:FireServer("sell", en) end)
		end
		-- ฟิวส์ลิสต์
		fuseScroll:ClearAllChildren()
		local fl2 = Instance.new("UIListLayout"); fl2.Padding = UDim.new(0, 5); fl2.Parent = fuseScroll
		for en, cnt in pairs(counts) do
			if en:sub(1, 3) ~= "BIG" then
				local row = Instance.new("Frame"); row.Size = UDim2.new(1, -4, 0, 36)
				row.BackgroundColor3 = Color3.fromRGB(34, 40, 60); corner(row, 8); row.Parent = fuseScroll
				local lab = txt(row, UDim2.new(0.55, 0, 1, 0), UDim2.fromOffset(6, 0), Color3.fromRGB(255, 255, 255))
				lab.Text = (PET_NAME[en] or en) .. " " .. cnt .. "/3"
				local fb = Instance.new("TextButton"); fb.Size = UDim2.new(0.4, -4, 0.8, 0)
				fb.Position = UDim2.new(0.6, 0, 0.1, 0)
				fb.BackgroundColor3 = cnt >= 3 and Color3.fromRGB(88, 200, 60) or Color3.fromRGB(90, 95, 110)
				fb.Font = FONT; fb.TextScaled = true; fb.Text = "ฟิวส์"
				fb.TextColor3 = Color3.fromRGB(255, 255, 255); corner(fb, 6); fb.Parent = row
				fb.Activated:Connect(function() evAct:FireServer("fuse", en) end)
			end
		end
	end
	-- ดัชนี
	local ok2, idx = pcall(function() return Http:JSONDecode(plr:GetAttribute("IndexJSON") or "{}") end)
	if ok2 and type(idx) == "table" then
		for isl = 2, 5 do
			local got = 0
			local arr = idx[tostring(isl)] or idx[isl]
			if type(arr) == "table" then got = #arr end
			local done = got >= POOL_SIZE[isl]
			idxRows[isl].Text = "เกาะ " .. isl .. " " .. ISL_NAME[isl] .. "  " .. got .. "/" .. POOL_SIZE[isl] .. (done and "  [ไม้ปลดล็อก]" or "")
		end
	end
	-- ถือไข่
	local cw = plr:GetAttribute("CarryWeight") or 0
	carryPill.Visible = cw > 0
	if cw > 0 then
		local sp = math.clamp(16 - cw * 0.06, 6, 16)
		carryPill.Text = "ถือไข่ " .. cw .. " กก. — เดิน " .. string.format("%.1f", sp) .. " (ยิ่งหนักยิ่งช้า)"
	end
	pad.Visible = (plr:GetAttribute("OnBoat") or 0) > 0
	-- เทรลปุ่มสถานะ
	for i, t in ipairs(TRAILS) do
		trailBtns[i].Text = t.name .. " x" .. t.mult .. " · $" .. short(t.cost)
	end
end
task.spawn(function() while true do task.wait(0.5) pcall(refresh) end end)
