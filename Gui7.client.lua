-- ============================================================
-- EGG ISLE v7 · Gui7 (LocalScript → StarterPlayerScripts)
-- i18n (EN default, auto-detect) · bag · 3 boards · hold-3s pickup
-- FredokaOne + black stroke everywhere · no emojis
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local WS = workspace
local plr = Players.LocalPlayer
local LM = require(ReplicatedStorage:WaitForChild("EggLang"))
LM.set(LM.detect())

local evNote = ReplicatedStorage:WaitForChild("Note")
local evPhase = ReplicatedStorage:WaitForChild("Phase")
local evBoatIn = ReplicatedStorage:WaitForChild("BoatIn")
local evAct = ReplicatedStorage:WaitForChild("Act")
local evPick = ReplicatedStorage:WaitForChild("Pick")

local FONT = Enum.Font.FredokaOne
local BOAT_COST = { [2] = 1000, [3] = 5000, [4] = 25000, [5] = 100000 }
local GARDEN_COST = { [2] = 500, [3] = 2500, [4] = 10000, [5] = 50000, [6] = 200000 }
local TRAIL_META = {
	{ mult = 1.5, cost = 2500, color = Color3.fromRGB(80, 220, 90) },
	{ mult = 2, cost = 10000, color = Color3.fromRGB(120, 200, 255) },
	{ mult = 2.5, cost = 40000, color = Color3.fromRGB(255, 120, 50) },
}
local ISL_NAME = { [2] = "Grass Isle", [3] = "Desert Isle", [4] = "Ice Isle", [5] = "Shadow Isle" }
local POOL_SIZE = { [2] = 4, [3] = 3, [4] = 2, [5] = 2 }
local LANGS = { { "en", "English" }, { "th", "ไทย" }, { "es", "Español" }, { "pt", "Português" }, { "id", "Indonesia" }, { "vi", "Tiếng Việt" }, { "zh", "中文" }, { "ko", "한국어" }, { "ja", "日本語" } }

local gui = Instance.new("ScreenGui"); gui.Name = "EggIsleGui"; gui.ResetOnSpawn = false
gui.Parent = plr:WaitForChild("PlayerGui")

local function short(n)
	n = math.floor(n or 0)
	local units = { "", "K", "M", "B", "T", "Qa" }
	local i = 1; local v = n
	while v >= 1000 and i < 6 do v = v / 1000; i = i + 1 end
	if i == 1 then return tostring(n) end
	local s = string.format("%.1f", v)
	if s:sub(-2) == ".0" then s = s:sub(1, -3) end
	return s .. units[i]
end
local function stroke(p, c, t) local s = Instance.new("UIStroke"); s.Color = c or Color3.fromRGB(0, 0, 0); s.Thickness = t or 3; s.Parent = p end
local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = p end
local function txt(parent, size, pos, color, align)
	local t = Instance.new("TextLabel"); t.Size = size; t.Position = pos or UDim2.new()
	t.BackgroundTransparency = 1; t.Font = FONT; t.TextScaled = true; t.TextColor3 = color
	t.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); t.TextXAlignment = align or Enum.TextXAlignment.Left
	t.Parent = parent; return t
end
-- compose message keys with localized pet/rarity/trail names
local function compose(key, a, b, c)
	if key == "egg_summon" then return LM.tr(key, a, LM.petName(b), c) end
	if key == "hatch" then return LM.tr(key, LM.petName(a), LM.rarName(b)) end
	if key == "sold" then
		local nm = LM.petName(a)
		if tonumber(b) == 1 then nm = nm .. " " .. LM.tr("big") end
		return LM.tr("sold", nm, c)
	end
	if key == "fuse_ok" then return LM.tr(key, LM.petName(a)) end
	if key == "trail_on" then return LM.tr(key, LM.tr("trail" .. tostring(a)), b) end
	if key == "reveal" then return LM.tr(key, LM.petName(a)) end
	return LM.tr(key, a, b, c)
end

local function parseEn(en)
	local base, big = en, false
	if base:sub(1, 3) == "BIG" then big = true; base = base:sub(4) end
	local i = base:find("@")
	local w = nil
	if i then w = tonumber(base:sub(i + 1)); base = base:sub(1, i - 1) end
	return base, big, w
end
local function wMult(base, w)
	local bw = LM.WEIGHT[LM.PET_R[base]]
	if not w or not bw then return 1 end
	return math.clamp(w / bw, 0.5, 2)
end

-- ---------- status bottom-left ----------
local stack = Instance.new("Frame"); stack.Size = UDim2.fromOffset(250, 118); stack.Position = UDim2.new(0, 12, 1, -130)
stack.BackgroundTransparency = 1; stack.Parent = gui
local moneyTxt = txt(stack, UDim2.new(1, 0, 0, 42), UDim2.new(), Color3.fromRGB(140, 255, 90))
local incTxt = txt(stack, UDim2.new(1, 0, 0, 34), UDim2.fromOffset(0, 42), Color3.fromRGB(120, 220, 255))
local miscTxt = txt(stack, UDim2.new(1, 0, 0, 34), UDim2.fromOffset(0, 78), Color3.fromRGB(255, 220, 120))

-- ---------- phase pill ----------
local phasePill = Instance.new("TextLabel"); phasePill.Size = UDim2.fromOffset(220, 44)
phasePill.Position = UDim2.new(0.5, 0, 0, 14); phasePill.AnchorPoint = Vector2.new(0.5, 0)
phasePill.BackgroundColor3 = Color3.fromRGB(20, 24, 38); phasePill.BackgroundTransparency = 0.2
phasePill.Font = FONT; phasePill.TextScaled = true; phasePill.TextColor3 = Color3.fromRGB(255, 255, 255)
corner(phasePill, 12); stroke(phasePill, Color3.fromRGB(255, 255, 255), 2); phasePill.Parent = gui
local phaseState = { phase = "day", t = 180 }
evPhase.OnClientEvent:Connect(function(st) phaseState = st end)

-- ---------- carry pill ----------
local carryPill = Instance.new("TextLabel"); carryPill.Size = UDim2.new(0.7, 0, 0, 40)
carryPill.Position = UDim2.new(0.5, 0, 0, 66); carryPill.AnchorPoint = Vector2.new(0.5, 0)
carryPill.BackgroundColor3 = Color3.fromRGB(255, 150, 40); carryPill.Font = FONT
carryPill.TextScaled = true; carryPill.TextColor3 = Color3.fromRGB(255, 255, 255); carryPill.Visible = false
corner(carryPill, 10); stroke(carryPill); carryPill.Parent = gui

-- ---------- admin / announce banner ----------
local adminBox = Instance.new("Frame"); adminBox.Size = UDim2.new(0.85, 0, 0, 64)
adminBox.Position = UDim2.new(0.5, 0, 0, 116); adminBox.AnchorPoint = Vector2.new(0.5, 0)
adminBox.BackgroundTransparency = 1; adminBox.Visible = false; adminBox.Parent = gui
local adminName = txt(adminBox, UDim2.new(1, 0, 0, 30), UDim2.new(), Color3.fromRGB(90, 230, 90), Enum.TextXAlignment.Center)
adminName.TextStrokeTransparency = 0
local adminMsg = txt(adminBox, UDim2.new(1, 0, 0, 32), UDim2.fromOffset(0, 30), Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Center)
adminMsg.TextWrapped = true
-- ---------- popup ----------
local pop = Instance.new("Frame"); pop.Size = UDim2.fromOffset(280, 90)
pop.Position = UDim2.new(0.5, 0, 0.3, 0); pop.AnchorPoint = Vector2.new(0.5, 0.5)
pop.BackgroundColor3 = Color3.fromRGB(20, 24, 36); pop.Visible = false
corner(pop, 14); stroke(pop, Color3.fromRGB(255, 255, 255), 3)
local popTxt = txt(pop, UDim2.new(1, -12, 1, -8), UDim2.fromOffset(6, 4), Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Center)
popTxt.TextWrapped = true; pop.Parent = gui

evNote.OnClientEvent:Connect(function(kind, key, a, b, c)
	local text
	if key == "__raw" then text = tostring(a) else text = compose(key, a, b, c) end
	if kind == "admin" then
		adminName.Text = LM.tr("admin")
		adminName.TextColor3 = Color3.fromRGB(90, 230, 90)
		adminMsg.Text = text
		adminBox.Visible = true
		task.delay(5, function() adminBox.Visible = false end)
		pcall(function()
			game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
				Text = "[" .. LM.tr("admin") .. "] " .. text, Color = Color3.fromRGB(90, 230, 90), Font = FONT,
			})
		end)
	elseif kind == "ban" then
		adminName.Text = LM.tr("announce")
		adminName.TextColor3 = Color3.fromRGB(255, 220, 90)
		adminMsg.Text = text
		adminBox.Visible = true
		task.delay(5, function() adminBox.Visible = false end)
	elseif kind == "reveal" then
		revTxt.Text = text
		revBox.Visible = true
		task.delay(6, function() revBox.Visible = false end)
	else
		popTxt.Text = text; pop.Visible = true
		task.delay(2.5, function() pop.Visible = false end)
	end
end)

-- ---------- panels ----------
local function makePanel(name, w, h, titleKey)
	local f = Instance.new("Frame"); f.Size = UDim2.fromOffset(w, h)
	f.Position = UDim2.new(0.5, 0, 0.5, 0); f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BackgroundColor3 = Color3.fromRGB(45, 48, 62); f.Visible = false
	corner(f, 12); stroke(f, Color3.fromRGB(0, 0, 0), 3); f.Parent = gui
	local head = Instance.new("Frame"); head.Size = UDim2.new(1, -8, 0, 44); head.Position = UDim2.fromOffset(4, 4)
	head.BackgroundColor3 = Color3.fromRGB(170, 60, 220); corner(head, 8); stroke(head, Color3.fromRGB(0, 0, 0), 2); head.Parent = f
	local t = txt(head, UDim2.new(1, -54, 1, 0), UDim2.fromOffset(10, 0), Color3.fromRGB(255, 255, 255))
	t.Name = "Title"
	local x = Instance.new("TextButton"); x.Size = UDim2.fromOffset(36, 36); x.Position = UDim2.new(1, -42, 0, 4)
	x.BackgroundColor3 = Color3.fromRGB(220, 40, 40); x.Font = FONT; x.TextScaled = true
	x.Text = "X"; x.TextColor3 = Color3.fromRGB(255, 255, 255); corner(x, 6); stroke(x, Color3.fromRGB(0, 0, 0), 2); x.Parent = head
	x.Activated:Connect(function() f.Visible = false end)
	local body = Instance.new("Frame"); body.Size = UDim2.new(1, -16, 1, -60); body.Position = UDim2.fromOffset(8, 52)
	body.BackgroundTransparency = 1; body.Parent = f
	f:SetAttribute("TK", titleKey)
	return f, body, t
end
local function bigBtn(parent, text, color, h)
	local b = Instance.new("TextButton"); b.Size = UDim2.new(1, 0, 0, h or 46)
	b.BackgroundColor3 = color; b.Font = FONT; b.TextScaled = true
	b.TextColor3 = Color3.fromRGB(255, 255, 255); corner(b, 10); stroke(b, Color3.fromRGB(0, 0, 0), 2)
	b.Text = text; b.Parent = parent; return b
end

-- boat
local boatPanel, boatBody, boatTitle = makePanel("Boat", 300, 240, "t_boat")
local bl = Instance.new("UIListLayout"); bl.Padding = UDim.new(0, 8); bl.Parent = boatBody
local boatInfo = txt(boatBody, UDim2.new(1, 0, 0, 40)); boatInfo.TextWrapped = true
local boardBtn = bigBtn(boatBody, "", Color3.fromRGB(60, 140, 220))
boardBtn.Activated:Connect(function()
	if (plr:GetAttribute("OnBoat") or 0) > 0 then evAct:FireServer("leave") else evAct:FireServer("board") end
end)
local upBoatBtn = bigBtn(boatBody, "", Color3.fromRGB(88, 200, 60))
upBoatBtn.Activated:Connect(function() evAct:FireServer("upboat") end)

-- garden (active pets)
local gardenPanel, gardenBody, gardenTitle = makePanel("Garden", 320, 360, "t_garden")
local gl = Instance.new("UIListLayout"); gl.Padding = UDim.new(0, 6); gl.Parent = gardenBody
local gardenInfo = txt(gardenBody, UDim2.new(1, 0, 0, 36)); gardenInfo.TextWrapped = true
local upGardenBtn = bigBtn(gardenBody, "", Color3.fromRGB(88, 200, 60), 40)
upGardenBtn.Activated:Connect(function() evAct:FireServer("upgarden") end)
local petScroll = Instance.new("ScrollingFrame"); petScroll.Size = UDim2.new(1, 0, 1, -100)
petScroll.BackgroundTransparency = 1; petScroll.ScrollBarThickness = 4; petScroll.Parent = gardenBody

-- bag (overflow pets)
local bagPanel, bagBody, bagTitle = makePanel("Bag", 320, 320, "t_bag")
local bagInfo = txt(bagBody, UDim2.new(1, 0, 0, 36)); bagInfo.TextWrapped = true
local bagScroll = Instance.new("ScrollingFrame"); bagScroll.Size = UDim2.new(1, 0, 1, -44)
bagScroll.Position = UDim2.fromOffset(0, 40); bagScroll.BackgroundTransparency = 1; bagScroll.ScrollBarThickness = 4; bagScroll.Parent = bagBody

-- index (เงา + คำใบ้ · ??? ไม่มีใบ้)
local idxPanel, idxBody, idxTitle = makePanel("Index", 340, 400, "t_index")
local idxScroll = Instance.new("ScrollingFrame"); idxScroll.Size = UDim2.new(1, 0, 1, 0)
idxScroll.BackgroundTransparency = 1; idxScroll.ScrollBarThickness = 4; idxScroll.Parent = idxBody
local idxIL = Instance.new("UIListLayout"); idxIL.Padding = UDim.new(0, 4); idxIL.Parent = idxScroll
local idxList = {}
for isl = 2, 5 do
	local head = txt(idxScroll, UDim2.new(1, 0, 0, 30), UDim2.new(), Color3.fromRGB(255, 220, 120))
	local rows = {}
	for id, meta in pairs(LM.PET_META) do
		if meta.isl == isl or meta.isl == "all" then
			local row = Instance.new("Frame"); row.Size = UDim2.new(1, -4, 0, 38)
			row.BackgroundColor3 = Color3.fromRGB(34, 40, 60); corner(row, 8); row.Parent = idxScroll
			local chip = Instance.new("Frame"); chip.Size = UDim2.fromOffset(26, 26); chip.Position = UDim2.fromOffset(6, 6)
			corner(chip, 6); chip.BackgroundColor3 = Color3.fromRGB(15, 15, 18); chip.Parent = row
			local lab = txt(row, UDim2.new(1, -40, 1, 0), UDim2.fromOffset(38, 0), Color3.fromRGB(255, 255, 255))
			lab.TextWrapped = true
			rows[id] = { chip = chip, lab = lab }
		end
	end
	idxList[isl] = { head = head, rows = rows }
end

-- fuse
local fusePanel, fuseBody, fuseTitle = makePanel("Fuse", 300, 320, "t_fuse")
local fl = Instance.new("UIListLayout"); fl.Padding = UDim.new(0, 6); fl.Parent = fuseBody
local fuseInfo = txt(fuseBody, UDim2.new(1, 0, 0, 52), UDim2.new(), Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Center)
fuseInfo.TextWrapped = true
local fuseScroll = Instance.new("ScrollingFrame"); fuseScroll.Size = UDim2.new(1, 0, 1, -60)
fuseScroll.BackgroundTransparency = 1; fuseScroll.ScrollBarThickness = 4; fuseScroll.Parent = fuseBody

-- trail
local trailPanel, trailBody, trailTitle = makePanel("Trail", 300, 280, "t_trail")
local tl = Instance.new("UIListLayout"); tl.Padding = UDim.new(0, 8); tl.Parent = trailBody
local trailBtns = {}
for i, t in ipairs(TRAIL_META) do
	local b = bigBtn(trailBody, "", t.color, 52)
	b.Activated:Connect(function() evAct:FireServer("trail", i) end)
	trailBtns[i] = b
end

-- chest
local chestPanel, chestBody, chestTitle = makePanel("Chest", 280, 160, "t_chest")
local chestBtn = bigBtn(chestBody, "", Color3.fromRGB(255, 190, 40), 60)
chestBtn.Position = UDim2.new(0, 0, 0.5, -10)
chestBtn.Activated:Connect(function() evAct:FireServer("gift") end)

-- language
local langPanel, langBody, langTitle = makePanel("Lang", 300, 320, "t_lang")
local lgl = Instance.new("UIListLayout"); lgl.Padding = UDim.new(0, 6); lgl.Parent = langBody
for _, L in ipairs(LANGS) do
	local b = bigBtn(langBody, L[2], Color3.fromRGB(70, 120, 200), 40)
	b.Activated:Connect(function() LM.set(L[1]) end)
end

-- ---------- right menu ----------
local menuDefs = {
	{ "m_boat", Color3.fromRGB(60, 140, 220), boatPanel },
	{ "m_garden", Color3.fromRGB(250, 150, 50), gardenPanel },
	{ "m_bag", Color3.fromRGB(160, 120, 80), bagPanel },
	{ "m_index", Color3.fromRGB(150, 90, 200), idxPanel },
	{ "m_fuse", Color3.fromRGB(220, 60, 180), fusePanel },
	{ "m_trail", Color3.fromRGB(60, 190, 200), trailPanel },
	{ "m_chest", Color3.fromRGB(255, 190, 40), chestPanel },
}
local allPanels = { boatPanel, gardenPanel, bagPanel, idxPanel, fusePanel, trailPanel, chestPanel, langPanel }
for i, m in ipairs(menuDefs) do
	local b = Instance.new("TextButton"); b.Size = UDim2.fromOffset(64, 46)
	b.Position = UDim2.new(1, -76, 0, 120 + (i - 1) * 52); b.BackgroundColor3 = m[2]
	b.Font = FONT; b.TextScaled = true; b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Name = "MenuBtn" .. i
	corner(b, 12); stroke(b, Color3.fromRGB(0, 0, 0), 3); b.Parent = gui
	b:SetAttribute("MK", m[1])
	b.Activated:Connect(function()
		for _, p in ipairs(allPanels) do p.Visible = (p == m[3]) and not p.Visible or false end
	end)
end
-- top-right: LANG button near Roblox gear area
local langBtn = Instance.new("TextButton"); langBtn.Size = UDim2.fromOffset(64, 46)
langBtn.Position = UDim2.new(1, -76, 0, 12); langBtn.BackgroundColor3 = Color3.fromRGB(70, 120, 200)
langBtn.Font = FONT; langBtn.TextScaled = true; langBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
corner(langBtn, 12); stroke(langBtn, Color3.fromRGB(0, 0, 0), 3); langBtn.Parent = gui
langBtn.Activated:Connect(function()
	for _, p in ipairs(allPanels) do p.Visible = (p == langPanel) and not p.Visible or false end
end)

-- ---------- hold-to-grab ----------
local holdBtn = Instance.new("TextButton"); holdBtn.Size = UDim2.fromOffset(150, 150)
holdBtn.Position = UDim2.new(0.5, 0, 1, -110); holdBtn.AnchorPoint = Vector2.new(0.5, 0.5)
holdBtn.BackgroundColor3 = Color3.fromRGB(30, 34, 48); holdBtn.BackgroundTransparency = 0.25
holdBtn.Font = FONT; holdBtn.TextScaled = true; holdBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
holdBtn.Visible = false
corner(holdBtn, 999); stroke(holdBtn, Color3.fromRGB(255, 255, 255), 3); holdBtn.Parent = gui
local holdFill = Instance.new("Frame"); holdFill.Size = UDim2.new(0, 0, 1, 0)
holdFill.BackgroundColor3 = Color3.fromRGB(120, 220, 90); holdFill.BackgroundTransparency = 0.5
holdFill.Parent = holdBtn
local hc2 = Instance.new("UICorner"); hc2.CornerRadius = UDim.new(1, 0); hc2.Parent = holdFill

-- ---------- วางไข่ / ฟักไข่ ที่สวน ----------
local anyReady = false
local placeBtn = Instance.new("TextButton"); placeBtn.Size = UDim2.fromOffset(170, 60)
placeBtn.Position = UDim2.new(0.5, -190, 1, -100); placeBtn.AnchorPoint = Vector2.new(0.5, 0.5)
placeBtn.BackgroundColor3 = Color3.fromRGB(250, 150, 50); placeBtn.Font = FONT; placeBtn.TextScaled = true
placeBtn.TextColor3 = Color3.fromRGB(255, 255, 255); placeBtn.Visible = false
corner(placeBtn, 12); stroke(placeBtn, Color3.fromRGB(0, 0, 0), 3); placeBtn.Parent = gui
placeBtn.Activated:Connect(function() evAct:FireServer("place") end)
local hatchBtn = Instance.new("TextButton"); hatchBtn.Size = UDim2.fromOffset(170, 60)
hatchBtn.Position = UDim2.new(0.5, 190, 1, -100); hatchBtn.AnchorPoint = Vector2.new(0.5, 0.5)
hatchBtn.BackgroundColor3 = Color3.fromRGB(88, 200, 60); hatchBtn.Font = FONT; hatchBtn.TextScaled = true
hatchBtn.TextColor3 = Color3.fromRGB(255, 255, 255); hatchBtn.Visible = false
corner(hatchBtn, 12); stroke(hatchBtn, Color3.fromRGB(0, 0, 0), 3); hatchBtn.Parent = gui
hatchBtn.Activated:Connect(function() evAct:FireServer("hatch") end)

-- ---------- ??? reveal overlay ----------
local revBox = Instance.new("Frame"); revBox.Size = UDim2.new(0.9, 0, 0, 110)
revBox.Position = UDim2.new(0.5, 0, 0.4, 0); revBox.AnchorPoint = Vector2.new(0.5, 0.5)
revBox.BackgroundColor3 = Color3.fromRGB(10, 5, 20); revBox.BackgroundTransparency = 0.1
revBox.Visible = false; corner(revBox, 16); stroke(revBox, Color3.fromRGB(160, 60, 255), 4); revBox.Parent = gui
local revTxt = txt(revBox, UDim2.new(1, -16, 1, -10), UDim2.fromOffset(8, 5), Color3.fromRGB(255, 220, 120), Enum.TextXAlignment.Center)
revTxt.TextWrapped = true

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
			holdTime = holdTime + 0.1
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

-- ---------- boat pad ----------
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

-- ---------- 3 boards on island 1 ----------
local function attachBoard(partName, titleKey, getter, fmt)
	task.spawn(function()
		local w3 = WS:FindFirstChild("World3")
		if not w3 then task.wait(3) w3 = WS:FindFirstChild("World3") end
		local board = w3 and w3:FindFirstChild(partName)
		if not board then return end
		local bb = Instance.new("BillboardGui"); bb.Size = UDim2.new(0, 260, 0, 250); bb.AlwaysOnTop = true; bb.Parent = board
		local title = txt(bb, UDim2.new(1, -10, 0, 40), UDim2.fromOffset(5, 2), Color3.fromRGB(255, 240, 120), Enum.TextXAlignment.Center)
		local list = txt(bb, UDim2.new(1, -10, 1, -46), UDim2.fromOffset(5, 42), Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Left)
		while true do
			task.wait(2)
			title.Text = LM.tr(titleKey)
			local rows = {}
			for _, p in ipairs(Players:GetPlayers()) do
				table.insert(rows, { name = p.Name, val = getter(p) })
			end
			table.sort(rows, function(a, b) return a.val > b.val end)
			local s = ""
			for i = 1, math.min(6, #rows) do
				s = s .. i .. ". " .. rows[i].name:sub(1, 12) .. "  " .. fmt(rows[i]) .. "\n"
			end
			list.Text = s
		end
	end)
end
attachBoard("BoardA", "b_income", function(p) return p:GetAttribute("Income") or 0 end, function(r) return "$" .. short(r.val) .. "/s" end)
attachBoard("BoardB", "b_robux", function(p) return p:GetAttribute("RobuxSpent") or 0 end, function(r) return "R$" .. short(r.val) end)
attachBoard("BoardC", "b_play", function(p) return p:GetAttribute("PlayHours") or 0 end, function(r) return r.val .. "h" end)

-- ---------- trail particles ----------
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
				if lvl > 0 and TRAIL_META[lvl] then
					local at = Instance.new("Attachment"); at.Name = "TrailAt"; at.Parent = hrp
					local tr = Instance.new("Trail"); tr.Name = "MyTrail"; tr.Attachment0 = at; tr.Attachment1 = at
					tr.Color = ColorSequence.new(TRAIL_META[lvl].color)
					tr.Lifetime = 0.6; tr.Width = NumberSequence.new(1.5, 0)
					local pe = Instance.new("ParticleEmitter"); pe.Name = "MyTrail"; pe.Color = ColorSequence.new(TRAIL_META[lvl].color)
					pe.Rate = 40; pe.Lifetime = NumberRange.new(0.4, 0.7); pe.Speed = 4; pe.Parent = hrp
				end
			end
		end
	end
end)

-- ---------- guardian signs (localized) ----------
task.spawn(function()
	local done = {}
	while true do
		task.wait(2)
		local w3 = WS:FindFirstChild("World3")
		if w3 then
			for _, d in ipairs(w3:GetDescendants()) do
				if d.Name == "GBody" and not done[d] then
					done[d] = true
					local pet = d:GetAttribute("Pet")
					local bb = d:FindFirstChildOfClass("BillboardGui")
					local t = bb and bb:FindFirstChildOfClass("TextLabel")
					if t then
						task.spawn(function()
							while d.Parent do
								task.wait(1)
								t.Text = LM.tr("guard_name", LM.petName(pet))
							end
						end)
					end
				end
			end
		end
	end
end)

-- ---------- tutorial (skippable) ----------
local tutBox = Instance.new("Frame"); tutBox.Size = UDim2.fromOffset(430, 130)
tutBox.Position = UDim2.new(0.5, 0, 0, 190); tutBox.AnchorPoint = Vector2.new(0.5, 0)
tutBox.BackgroundColor3 = Color3.fromRGB(20, 24, 38); tutBox.BackgroundTransparency = 0.15
corner(tutBox, 14); stroke(tutBox, Color3.fromRGB(120, 220, 255), 3); tutBox.Parent = gui
local tutTitle = txt(tutBox, UDim2.new(1, -10, 0, 30), UDim2.fromOffset(5, 4), Color3.fromRGB(120, 220, 255), Enum.TextXAlignment.Center)
local tutTxt = txt(tutBox, UDim2.new(1, -14, 0, 50), UDim2.fromOffset(7, 34), Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Center)
tutTxt.TextWrapped = true
local tutSkip = Instance.new("TextButton"); tutSkip.Size = UDim2.fromOffset(120, 32)
tutSkip.Position = UDim2.new(0.5, 0, 1, -38); tutSkip.AnchorPoint = Vector2.new(0.5, 0)
tutSkip.BackgroundColor3 = Color3.fromRGB(90, 95, 110); tutSkip.Font = FONT; tutSkip.TextScaled = true
tutSkip.TextColor3 = Color3.fromRGB(255, 255, 255); corner(tutSkip, 8); stroke(tutSkip, Color3.fromRGB(0, 0, 0), 2); tutSkip.Parent = tutBox
tutSkip.Activated:Connect(function() evAct:FireServer("tutdone") end)
local tutMax = 1

-- ---------- refresh ----------
local function petEntries()
	local ok, counts = pcall(function() return Http:JSONDecode(plr:GetAttribute("PetsJSON") or "{}") end)
	if not ok or type(counts) ~= "table" then return {} end
	local list = {}
	for en, cnt in pairs(counts) do
		local base, big, w = parseEn(en)
		local pw = (LM.PWR[base] or 1) * wMult(base, w)
		table.insert(list, { en = en, base = base, big = big, cnt = cnt, w = w, pw = pw * (big and 2 or 1) })
	end
	table.sort(list, function(a, b) return a.pw > b.pw end)
	return list
end
local SELL_BY_RAR = { common = 50, uncommon = 150, rare = 500, epic = 2000, legendary = 10000, mythic = 50000, secret = 250000, divine = 1000000, mystery = 10000000, trash = 1 }
local function fmtTime(sec)
	sec = math.max(0, math.floor(sec))
	local h = math.floor(sec / 3600); local m = math.floor((sec % 3600) / 60); local s2 = sec % 60
	if h > 0 then return h .. "h " .. m .. "m" end
	if m > 0 then return m .. "m " .. s2 .. "s" end
	return s2 .. "s"
end
local GPOS_C = { Vector3.new(-30, 0, -20), Vector3.new(0, 0, -20), Vector3.new(30, 0, -20), Vector3.new(-30, 0, -48), Vector3.new(0, 0, -48), Vector3.new(30, 0, -48) }
local function sellRow(parent, entry)
	local val = math.floor((SELL_BY_RAR[LM.PET_R[entry.base]] or 50) * wMult(entry.base, entry.w) * (entry.big and 3 or 1))
	local row = Instance.new("Frame"); row.Size = UDim2.new(1, -4, 0, 34)
	row.BackgroundColor3 = Color3.fromRGB(34, 40, 60); corner(row, 8); row.Parent = parent
	local lab = txt(row, UDim2.new(0.62, 0, 1, 0), UDim2.fromOffset(6, 0), Color3.fromRGB(255, 255, 255))
	lab.Text = LM.petName(entry.base) .. (entry.big and (" " .. LM.tr("big")) or "") .. (entry.w and (" " .. entry.w .. "kg") or "") .. " x" .. entry.cnt
	local sb = Instance.new("TextButton"); sb.Size = UDim2.new(0.34, -4, 0.8, 0)
	sb.Position = UDim2.new(0.65, 0, 0.1, 0); sb.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	sb.Font = FONT; sb.TextScaled = true; sb.Text = LM.tr("sell") .. " $" .. short(val)
	sb.TextColor3 = Color3.fromRGB(255, 255, 255); corner(sb, 6); sb.Parent = row
	sb.Activated:Connect(function() evAct:FireServer("sell", entry.en) end)
end

local function refresh()
	local ls = plr:FindFirstChild("leaderstats")
	if ls then moneyTxt.Text = "$" .. short(ls.Money.Value) end
	incTxt.Text = "+$" .. short(plr:GetAttribute("Income") or 0) .. "/s"
	local blvl = plr:GetAttribute("BoatLvl") or 1
	miscTxt.Text = "Boat Lv" .. blvl .. " · Garden #" .. (plr:GetAttribute("Slot") or 1) .. " · Trail x" .. ((plr:GetAttribute("TrailLvl") or 0) == 0 and "-" or tostring(TRAIL_META[plr:GetAttribute("TrailLvl") or 0] and TRAIL_META[plr:GetAttribute("TrailLvl")].mult or "-"))
	-- panel titles + menu labels
	for _, p in ipairs(allPanels) do
		local tk = p:GetAttribute("TK")
		local head = p:FindFirstChildOfClass("Frame")
		if head then
			local t = head:FindFirstChild("Title")
			if t and tk then t.Text = LM.tr(tk) end
		end
	end
	for i = 1, #menuDefs do
		local b = gui:FindFirstChild("MenuBtn" .. i)
		if b then b.Text = LM.tr(menuDefs[i][1]) end
	end
	langBtn.Text = LM.cur:upper()
	-- phase + carry + hold
	local mm = math.floor(phaseState.t / 60); local ss = phaseState.t % 60
	phasePill.Text = LM.tr(phaseState.phase == "day" and "day" or "night") .. " " .. mm .. ":" .. string.format("%02d", ss)
	local cw = plr:GetAttribute("CarryWeight") or 0
	carryPill.Visible = cw > 0
	if cw > 0 then
		local sp = math.clamp(16 - cw * 0.06, 6, 16)
		carryPill.Text = LM.tr("carry", cw, string.format("%.1f", sp))
	end
	holdBtn.Text = LM.tr("holdbtn")
	pad.Visible = (plr:GetAttribute("OnBoat") or 0) > 0
	-- ปุ่มวางไข่/ฟักไข่ เมื่ออยู่ใกล้สวนตัวเอง
	local char2 = plr.Character
	local hrp2 = char2 and char2:FindFirstChild("HumanoidRootPart")
	local nearG = false
	if hrp2 then
		local gp = GPOS_C[plr:GetAttribute("Slot") or 1] + Vector3.new(0, 7, 0)
		nearG = (hrp2.Position - gp).Magnitude < 12
	end
	placeBtn.Text = LM.tr("place_egg")
	hatchBtn.Text = LM.tr("hatch_now")
	placeBtn.Visible = nearG and ((plr:GetAttribute("Carrying") or 0) > 0)
	hatchBtn.Visible = nearG and anyReady
	-- boat panel
	local bc = BOAT_COST[blvl + 1]
	upBoatBtn.Text = bc and (LM.tr("upboat") .. " $" .. short(bc)) or LM.tr("full_boat")
	boatInfo.Text = LM.tr("boat_spd", math.floor(16 * math.pow(1.5, blvl - 1)))
	boardBtn.Text = (plr:GetAttribute("OnBoat") or 0) > 0 and LM.tr("leave_btn") or LM.tr("board_btn")
	-- garden + bag split
	local entries = petEntries()
	local slots = plr:GetAttribute("Slots") or 8
	local activeN, bagN = 0, 0
	local used = 0
	for _, e in ipairs(entries) do
		local take = math.min(e.cnt, math.max(0, slots - used))
		e.activeCnt = take
		used = used + take
		if take > 0 then activeN = activeN + 1 end
		if e.cnt - take > 0 then bagN = bagN + 1 end
	end
	local glvl = plr:GetAttribute("GardenLvl") or 1
	local gc = GARDEN_COST[glvl + 1]
	upGardenBtn.Text = gc and (LM.tr("upgarden") .. " $" .. short(gc)) or LM.tr("full_garden")
	gardenInfo.Text = LM.tr("slots", slots, #entries) .. " · " .. LM.tr("active", used, slots)
	petScroll:ClearAllChildren()
	local pl2 = Instance.new("UIListLayout"); pl2.Padding = UDim.new(0, 5); pl2.Parent = petScroll
	for _, e in ipairs(entries) do
		if e.activeCnt and e.activeCnt > 0 then
			sellRow(petScroll, { en = e.en, base = e.base, big = e.big, cnt = e.activeCnt, w = e.w })
		end
	end
	-- ไข่ที่กำลังฟัก (นับถอยหลังจริง)
	anyReady = false
	local okI, incs = pcall(function() return Http:JSONDecode(plr:GetAttribute("IncubJSON") or "[]") end)
	if okI and type(incs) == "table" then
		for _, inc in ipairs(incs) do
			local left = (inc.ready or 0) - os.time()
			local row = Instance.new("Frame"); row.Size = UDim2.new(1, -4, 0, 30)
			row.BackgroundColor3 = left <= 0 and Color3.fromRGB(60, 140, 60) or Color3.fromRGB(30, 60, 110)
			corner(row, 8); row.Parent = petScroll
			local lab = txt(row, UDim2.new(1, -8, 1, 0), UDim2.fromOffset(6, 0), Color3.fromRGB(255, 255, 255))
			if left <= 0 then
				anyReady = true
				lab.Text = LM.petName(inc.p) .. " - " .. LM.tr("ready")
			else
				lab.Text = LM.tr("incub", LM.petName(inc.p), fmtTime(left))
			end
		end
	end
	bagInfo.Text = LM.tr("bag_info", bagN)
	bagScroll:ClearAllChildren()
	local bl2 = Instance.new("UIListLayout"); bl2.Padding = UDim.new(0, 5); bl2.Parent = bagScroll
	for _, e in ipairs(entries) do
		local left = e.cnt - (e.activeCnt or 0)
		if left > 0 then
			sellRow(bagScroll, { en = e.en, base = e.base, big = e.big, cnt = left, w = e.w })
		end
	end
	-- index: ได้แล้ว=ชื่อ · ยังไม่ได้=เงา+คำใบ้ · ??? = ???
	local ok2, idx = pcall(function() return Http:JSONDecode(plr:GetAttribute("IndexJSON") or "{}") end)
	if ok2 and type(idx) == "table" then
		for isl = 2, 5 do
			local info = idxList[isl]
			local arr = idx[tostring(isl)] or idx[isl] or {}
			local disc = {}
			if type(arr) == "table" then for _, id in ipairs(arr) do disc[id] = true end end
			local poolN = 0
			for id, r in pairs(info.rows) do
				poolN = poolN + 1
				local meta = LM.PET_META[id]
				if disc[id] then
					r.chip.BackgroundColor3 = Color3.fromRGB(120, 220, 90)
					r.lab.Text = LM.petName(id) .. " [" .. LM.rarName(meta.r) .. "]"
				elseif meta.r == "mystery" then
					r.chip.BackgroundColor3 = Color3.fromRGB(10, 5, 20)
					r.lab.Text = LM.tr("unknown")
				else
					r.chip.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
					local h = meta.hint and (meta.hint[LM.cur] or meta.hint.en) or ""
					r.lab.Text = LM.tr("unknown") .. " - " .. LM.tr("hint", h)
				end
			end
			local got = 0
			if type(arr) == "table" then got = #arr end
			info.head.Text = "Island " .. isl .. " " .. ISL_NAME[isl] .. " " .. got .. "/" .. poolN .. (got >= poolN and " " .. LM.tr("stick") or "")
		end
	end
	-- fuse list
	fuseInfo.Text = LM.tr("fuse_info")
	fuseScroll:ClearAllChildren()
	local fl2 = Instance.new("UIListLayout"); fl2.Padding = UDim.new(0, 5); fl2.Parent = fuseScroll
	local groups = {}
	for _, e in ipairs(entries) do
		if not e.big then groups[e.base] = (groups[e.base] or 0) + e.cnt end
	end
	for base, cnt in pairs(groups) do
		local row = Instance.new("Frame"); row.Size = UDim2.new(1, -4, 0, 36)
		row.BackgroundColor3 = Color3.fromRGB(34, 40, 60); corner(row, 8); row.Parent = fuseScroll
		local lab = txt(row, UDim2.new(0.55, 0, 1, 0), UDim2.fromOffset(6, 0), Color3.fromRGB(255, 255, 255))
		lab.Text = LM.petName(base) .. " " .. cnt .. "/3"
		local fb = Instance.new("TextButton"); fb.Size = UDim2.new(0.4, -4, 0.8, 0)
		fb.Position = UDim2.new(0.6, 0, 0.1, 0)
		fb.BackgroundColor3 = cnt >= 3 and Color3.fromRGB(88, 200, 60) or Color3.fromRGB(90, 95, 110)
		fb.Font = FONT; fb.TextScaled = true; fb.Text = LM.tr("fuse_btn")
		fb.TextColor3 = Color3.fromRGB(255, 255, 255); corner(fb, 6); fb.Parent = row
		fb.Activated:Connect(function() evAct:FireServer("fuse", base) end)
	end
	-- trail buttons
	for i, t in ipairs(TRAIL_META) do
		trailBtns[i].Text = LM.tr("trail" .. i) .. " x" .. t.mult .. " · $" .. short(t.cost)
	end
	chestBtn.Text = LM.tr("open_chest")
	chestTitle.Text = LM.tr("t_chest")
	-- tutorial auto-advance
	local tutOn = (plr:GetAttribute("Tut") or 0) == 1
	tutBox.Visible = tutOn
	if tutOn then
		if (plr:GetAttribute("OnBoat") or 0) > 0 then tutMax = math.max(tutMax, 2) end
		if (plr:GetAttribute("Carrying") or 0) > 0 then tutMax = math.max(tutMax, 3) end
		if #entries > 0 then tutMax = math.max(tutMax, 4) end
		tutTitle.Text = LM.tr("tut_title") .. " " .. tutMax .. "/4"
		tutTxt.Text = LM.tr("tut" .. tutMax)
		tutSkip.Text = tutMax >= 4 and LM.tr("tut_end") or LM.tr("tut_skip")
	end
end
task.spawn(function() while true do task.wait(0.5) pcall(refresh) end end)
