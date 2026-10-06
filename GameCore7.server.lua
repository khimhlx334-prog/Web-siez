-- ============================================================
-- EGG ISLE v7 · GameCore7 (Script → ServerScriptService)
-- v7: rarity Mythic/Secret/Divine/??? + Trash · ทุกเกาะมีทุกระดับ
-- ฟักไข่แบบวางรอเวลา (สูงสุด 2 วัน) · โมเดลสัตว์ 3D ทุกตัว · ดัชนีเงา
-- ============================================================
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Http = game:GetService("HttpService")
local MPS = game:GetService("MarketplaceService")
local WS = game:GetService("Workspace")

local store = DataStoreService:GetDataStore("EggIsleV7")

local function killOld(name) local o = script.Parent:FindFirstChild(name) if o then o:Destroy() end end
killOld("MapBuilder")

-- ---------- สัตว์ 22 ชนิด (isl="all" = โผล่ทุกเกาะ) ----------
local PETS = {
	{ id = "cat", rarity = "common", power = 1, isl = 2 },
	{ id = "dog", rarity = "common", power = 1, isl = 2 },
	{ id = "rab", rarity = "common", power = 1, isl = 2 },
	{ id = "pan", rarity = "uncommon", power = 3, isl = 2 },
	{ id = "cap", rarity = "uncommon", power = 3, isl = 3 },
	{ id = "ele", rarity = "rare", power = 10, isl = 3 },
	{ id = "lio", rarity = "rare", power = 10, isl = 3 },
	{ id = "dra", rarity = "epic", power = 40, isl = 4 },
	{ id = "uni", rarity = "epic", power = 40, isl = 4 },
	{ id = "gld", rarity = "legendary", power = 200, isl = 5 },
	{ id = "phx", rarity = "legendary", power = 200, isl = 5 },
	{ id = "bull", rarity = "mythic", power = 1000, isl = 2 },
	{ id = "scor", rarity = "mythic", power = 1000, isl = 3 },
	{ id = "bear", rarity = "mythic", power = 1000, isl = 4 },
	{ id = "bat", rarity = "mythic", power = 1000, isl = 5 },
	{ id = "sheep", rarity = "secret", power = 5000, isl = 2 },
	{ id = "sphinx", rarity = "secret", power = 5000, isl = 3 },
	{ id = "wraith", rarity = "secret", power = 5000, isl = 4 },
	{ id = "shd", rarity = "secret", power = 5000, isl = 5 },
	{ id = "seraph", rarity = "divine", power = 25000, isl = "all" },
	{ id = "void", rarity = "mystery", power = 100000, isl = "all" },
	{ id = "sloth", rarity = "trash", power = 1000, isl = "all" },
}
local WEIGHT = { common = 10, uncommon = 20, rare = 40, epic = 80, legendary = 150, mythic = 300, secret = 600, divine = 1200, mystery = 2500, trash = 0.01 }
local SELL_VALUE = { common = 50, uncommon = 150, rare = 500, epic = 2000, legendary = 10000, mythic = 50000, secret = 250000, divine = 1000000, mystery = 10000000, trash = 1 }
-- โอกาสเกิดไข่ (ปรับสมดุลที่นี่) · secret ออกยาก ~2.5x กว่า mythic · ??? แทบไม่โผล่
local SPAWN_W = { common = 60, uncommon = 30, rare = 16, epic = 7, legendary = 3, mythic = 1.2, secret = 0.45, divine = 0.12, mystery = 0.03, trash = 0.1 }
-- เวลารอฟักพื้นฐาน (วินาที) x ตัวคูณน้ำหนัก(0.5-2) · เพดาน 2 วัน
local WAIT_BASE = { common = 10, uncommon = 30, rare = 120, epic = 600, legendary = 3600, mythic = 21600, secret = 43200, divine = 86400, mystery = 172800, trash = 300 }
local MAX_WAIT = 172800
local TRAILS = {
	{ mult = 1.5, cost = 2500, color = Color3.fromRGB(80, 220, 90) },
	{ mult = 2, cost = 10000, color = Color3.fromRGB(120, 200, 255) },
	{ mult = 2.5, cost = 40000, color = Color3.fromRGB(255, 120, 50) },
}
local RANK = { common = 1, uncommon = 2, rare = 3, epic = 4, legendary = 5, mythic = 6, secret = 7, divine = 8, mystery = 9, trash = 0 }
local SINGLE = { divine = true, mystery = true } -- ถือได้ตัวเดียว
local PET_COLOR = {
	cat = Color3.fromRGB(255, 150, 60), dog = Color3.fromRGB(220, 180, 120), rab = Color3.fromRGB(250, 250, 250),
	pan = Color3.fromRGB(60, 60, 65), cap = Color3.fromRGB(150, 105, 70), ele = Color3.fromRGB(255, 150, 190),
	lio = Color3.fromRGB(255, 200, 80), dra = Color3.fromRGB(140, 220, 255), uni = Color3.fromRGB(255, 255, 255),
	gld = Color3.fromRGB(255, 200, 60), phx = Color3.fromRGB(255, 110, 40),
	bull = Color3.fromRGB(255, 215, 90), scor = Color3.fromRGB(200, 160, 60), bear = Color3.fromRGB(240, 248, 255),
	bat = Color3.fromRGB(160, 30, 40), sheep = Color3.fromRGB(245, 245, 255), sphinx = Color3.fromRGB(230, 190, 110),
	wraith = Color3.fromRGB(180, 230, 255), shd = Color3.fromRGB(40, 30, 60), seraph = Color3.fromRGB(255, 250, 220),
	void = Color3.fromRGB(25, 10, 40), sloth = Color3.fromRGB(140, 120, 90),
}
local function petById(id) for _, p in ipairs(PETS) do if p.id == id then return p end end end
local function poolOf(isl)
	local t = {}
	for _, p in ipairs(PETS) do if p.isl == isl or p.isl == "all" then table.insert(t, p) end end
	return t
end
local function pickWeighted(pool)
	local total = 0
	for _, p in ipairs(pool) do total = total + (SPAWN_W[p.rarity] or 1) end
	local r = math.random() * total
	for _, p in ipairs(pool) do
		r = r - (SPAWN_W[p.rarity] or 1)
		if r <= 0 then return p end
	end
	return pool[#pool]
end
local function parseEntry(en)
	local base, big = en, false
	if base:sub(1, 3) == "BIG" then big = true; base = base:sub(4) end
	local i = base:find("@")
	local w = nil
	if i then w = tonumber(base:sub(i + 1)); base = base:sub(1, i - 1) end
	return base, big, w
end
local function wMult(base, w)
	local p = petById(base)
	if not p or not w then return 1 end
	return math.clamp(w / WEIGHT[p.rarity], 0.5, 2)
end
local function entryPower(en)
	local base, big, w = parseEntry(en)
	local p = petById(base)
	if not p then return 0 end
	return p.power * wMult(base, w) * (big and 2 or 1)
end
local function sellValue(en)
	local base, big, w = parseEntry(en)
	local p = petById(base)
	if not p then return 0 end
	return math.floor(SELL_VALUE[p.rarity] * wMult(base, w) * (big and 3 or 1))
end

-- ---------- โมเดลสัตว์บล็อกกี้ ----------
local function buildPet(id, scale, pos, heading)
	scale = scale or 1
	local col = PET_COLOR[id] or Color3.fromRGB(150, 150, 150)
	local f = Instance.new("Folder"); f.Name = "Pet_" .. id
	local function mk(size, off, color, collide)
		local p = Instance.new("Part"); p.Size = Vector3.new(size[1], size[2], size[3]) * scale
		p.Color = color or col; p.Anchored = true; p.CanCollide = collide or false
		p.Material = Enum.Material.SmoothPlastic; p.Parent = f
		return p
	end
	local body, head
	local biped = (id == "seraph" or id == "void")
	if biped then
		body = mk({ 3, 4, 2 }, { 0, 3, 0 })
		head = mk({ 2, 2, 2 }, { 0, 5.8, 0 })
		mk({ 1, 3, 1 }, { -2, 3, 0 }); mk({ 1, 3, 1 }, { 2, 3, 0 })
		mk({ 1.2, 2, 1.2 }, { -1, 0.9, 0 }); mk({ 1.2, 2, 1.2 }, { 1, 0.9, 0 })
	else
		body = mk({ 3, 2.4, 4.4 }, { 0, 2.4, 0 })
		head = mk({ 2, 2, 2 }, { 0, 3.4, 2.8 })
		mk({ 0.8, 1.6, 0.8 }, { -1.1, 0.8, 1.4 }); mk({ 0.8, 1.6, 0.8 }, { 1.1, 0.8, 1.4 })
		mk({ 0.8, 1.6, 0.8 }, { -1.1, 0.8, -1.4 }); mk({ 0.8, 1.6, 0.8 }, { 1.1, 0.8, -1.4 })
	end
	local function weld(a, b, c0) local w = Instance.new("Weld"); w.Part0 = a; w.Part1 = b; w.C0 = c0 * 1 and CFrame.new(c0.X * scale, c0.Y * scale, c0.Z * scale) or c0; w.Parent = a end
	local ears = { cat = "point", dog = "flop", rab = "long", pan = "round", cap = "round", ele = "fan", lio = "round", bear = "round", bat = "point", sheep = "round", sloth = "round", bull = "horn", scor = nil, sphinx = "round" }
	local e = ears[id]
	if e == "point" then weld(body, mk({ 0.5, 1, 0.3 }, { 0, 0, 0 }), Vector3.new(-0.7, 4.6, 2.8)); weld(body, mk({ 0.5, 1, 0.3 }, { 0, 0, 0 }), Vector3.new(0.7, 4.6, 2.8)) end
	if e == "long" then weld(body, mk({ 0.5, 2.2, 0.4 }, { 0, 0, 0 }), Vector3.new(-0.6, 5.2, 2.8)); weld(body, mk({ 0.5, 2.2, 0.4 }, { 0, 0, 0 }), Vector3.new(0.6, 5.2, 2.8)) end
	if e == "flop" then weld(body, mk({ 0.5, 1.2, 0.4 }, { 0, 0, 0 }, col:Lerp(Color3.new(0, 0, 0), 0.25)), Vector3.new(-1.1, 3.6, 2.8)); weld(body, mk({ 0.5, 1.2, 0.4 }, { 0, 0, 0 }, col:Lerp(Color3.new(0, 0, 0), 0.25)), Vector3.new(1.1, 3.6, 2.8)) end
	if e == "round" then weld(body, mk({ 0.6, 0.6, 0.3 }, { 0, 0, 0 }), Vector3.new(-0.7, 4.5, 2.8)); weld(body, mk({ 0.6, 0.6, 0.3 }, { 0, 0, 0 }), Vector3.new(0.7, 4.5, 2.8)) end
	if e == "fan" then weld(body, mk({ 1.4, 1.6, 0.3 }, { 0, 0, 0 }), Vector3.new(-1.3, 3.6, 2.6)); weld(body, mk({ 1.4, 1.6, 0.3 }, { 0, 0, 0 }), Vector3.new(1.3, 3.6, 2.6)) end
	if e == "horn" then weld(body, mk({ 0.4, 1.6, 0.4 }, { 0, 0, 0 }, Color3.fromRGB(240, 240, 230)), Vector3.new(-0.9, 4.6, 2.8)); weld(body, mk({ 0.4, 1.6, 0.4 }, { 0, 0, 0 }, Color3.fromRGB(240, 240, 230)), Vector3.new(0.9, 4.6, 2.8)) end
	if id == "ele" then weld(body, mk({ 0.7, 2.4, 0.7 }, { 0, 0, 0 }), Vector3.new(0, 2.6, 4)) end
	if id == "uni" then weld(body, mk({ 0.3, 1.6, 0.3 }, { 0, 0, 0 }, Color3.fromRGB(255, 220, 120)), Vector3.new(0, 5, 2.8)) end
	if id == "lio" or id == "sphinx" then weld(body, mk({ 2.8, 2.8, 0.6 }, { 0, 0, 0 }, Color3.fromRGB(180, 110, 40)), Vector3.new(0, 3.4, 2)) end
	if id == "scor" then weld(body, mk({ 0.6, 0.6, 2.4 }, { 0, 0, 0 }), Vector3.new(0, 3.2, -2.8)); weld(body, mk({ 1, 1, 1 }, { 0, 0, 0 }, Color3.fromRGB(120, 40, 40)), Vector3.new(0, 3.8, -4)) end
	if id == "sloth" then weld(body, mk({ 0.4, 1.4, 0.4 }, { 0, 0, 0 }, Color3.fromRGB(90, 75, 55)), Vector3.new(-1.2, 2.6, 2.6)); weld(body, mk({ 0.4, 1.4, 0.4 }, { 0, 0, 0 }, Color3.fromRGB(90, 75, 55)), Vector3.new(1.2, 2.6, 2.6)) end
	local wings = { dra = true, gld = true, phx = true, bat = true, sphinx = true, shd = true, seraph = true, void = true, uni = false }
	if wings[id] then
		local wc = id == "shd" and Color3.fromRGB(30, 20, 50) or id == "void" and Color3.fromRGB(60, 20, 100) or col:Lerp(Color3.new(1, 1, 1), 0.3)
		local wy = biped and 4 or 3.4
		weld(body, mk({ 3.4, 2.2, 0.3 }, { 0, 0, 0 }, wc), Vector3.new(-2.6, wy, -1))
		weld(body, mk({ 3.4, 2.2, 0.3 }, { 0, 0, 0 }, wc), Vector3.new(2.6, wy, -1))
	end
	if id == "seraph" then weld(body, mk({ 1.6, 0.3, 1.6 }, { 0, 0, 0 }, Color3.fromRGB(255, 240, 150)), Vector3.new(0, 7.2, 0)) end
	if id == "void" then
		local li = Instance.new("PointLight"); li.Color = Color3.fromRGB(160, 60, 255); li.Range = 20; li.Brightness = 2; li.Parent = head
	end
	if RANK[petById(id).rarity] >= 6 then
		local li = Instance.new("PointLight"); li.Color = col; li.Range = 18; li.Brightness = 1.5; li.Parent = body
	end
	-- ตา
	local eyeC = Color3.fromRGB(20, 20, 25)
	if biped then
		weld(body, mk({ 0.3, 0.3, 0.1 }, { 0, 0, 0 }, eyeC), Vector3.new(-0.5, 6, 1)); weld(body, mk({ 0.3, 0.3, 0.1 }, { 0, 0, 0 }, eyeC), Vector3.new(0.5, 6, 1))
	else
		weld(body, mk({ 0.3, 0.3, 0.1 }, { 0, 0, 0 }, eyeC), Vector3.new(-0.5, 3.6, 3.8)); weld(body, mk({ 0.3, 0.3, 0.1 }, { 0, 0, 0 }, eyeC), Vector3.new(0.5, 3.6, 3.8))
	end
	f.Parent = WS:FindFirstChild("World3") or WS
	local root0 = body
	root0.CFrame = CFrame.new(pos) * CFrame.Angles(0, heading or 0, 0)
	return f, root0
end

-- ---------- เกาะ ----------
local ISLANDS = {
	{ n = 1, pos = Vector3.new(0, 0, 0), r = 90, grass = Color3.fromRGB(95, 190, 60), label = "Start Island", rec = 0 },
	{ n = 2, pos = Vector3.new(500, 0, 0), r = 120, grass = Color3.fromRGB(110, 200, 70), label = "Grass Isle", rec = 24 },
	{ n = 3, pos = Vector3.new(-500, 0, 300), r = 130, grass = Color3.fromRGB(220, 190, 110), label = "Desert Isle", rec = 36 },
	{ n = 4, pos = Vector3.new(300, 0, -700), r = 140, grass = Color3.fromRGB(200, 230, 245), label = "Ice Isle", rec = 54 },
	{ n = 5, pos = Vector3.new(-400, 0, -1100), r = 150, grass = Color3.fromRGB(110, 85, 150), label = "Shadow Isle", rec = 81 },
}
local EGG_COUNT = { [2] = 8, [3] = 7, [4] = 6, [5] = 5 }

-- ---------- รีโมต ----------
local function ev(name) local r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = ReplicatedStorage; return r end
local evNote = ev("Note")
local evPhase = ev("Phase")
local evBoatIn = ev("BoatIn")
local evAct = ev("Act")
local evPick = ev("Pick")
local evIntro = ev("IntroDone")

-- ---------- สถานะ ----------
local DATA = {}
local gardens = {}
local carrying = {}
local boatOf = {}

local BOAT_COST = { [2] = 1000, [3] = 5000, [4] = 25000, [5] = 100000 }
local GARDEN_COST = { [2] = 500, [3] = 2500, [4] = 10000, [5] = 50000, [6] = 200000 }
local GPOS = { Vector3.new(-30, 0, -20), Vector3.new(0, 0, -20), Vector3.new(30, 0, -20), Vector3.new(-30, 0, -48), Vector3.new(0, 0, -48), Vector3.new(30, 0, -48) }
local function boatSpeed(lvl) return 16 * math.pow(1.5, lvl - 1) end
local function slotsOf(d) return 8 + (d.gardenLvl - 1) * 4 end
local function carrySpeed(w) return math.clamp(16 - w * 0.06, 6, 16) end

local function save(plr)
	local d = DATA[plr.UserId] if not d then return end
	pcall(function() store:SetAsync("u_" .. plr.UserId, d) end)
end

local function applyWalk(plr)
	local char = plr.Character; local hum = char and char:FindFirstChild("Humanoid")
	if not hum then return end
	local c = carrying[plr.UserId]
	if c then hum.WalkSpeed = carrySpeed(c.weight) return end
	local d = DATA[plr.UserId]
	local mult = 1
	if d and d.trail and d.trail > 0 and TRAILS[d.trail] then mult = TRAILS[d.trail].mult end
	hum.WalkSpeed = 16 * mult
end

local function topActive(d)
	local list = {}
	for _, en in ipairs(d.pets) do table.insert(list, { en = en, pw = entryPower(en) }) end
	table.sort(list, function(a, b) return a.pw > b.pw end)
	local out = {}
	for i = 1, math.min(slotsOf(d), #list) do table.insert(out, list[i].en) end
	return out
end

-- แสดงโมเดลสัตว์ที่สวน + ไข่ที่กำลังฟัก
local function refreshGardenVis(plr)
	local d = DATA[plr.UserId] if not d then return end
	local rt = WS:FindFirstChild("World3") if not rt then return end
	local old = rt:FindFirstChild("Vis" .. plr.UserId)
	if old then old:Destroy() end
	local holder = Instance.new("Folder"); holder.Name = "Vis" .. plr.UserId; holder.Parent = rt
	local gp = GPOS[d.slot] + Vector3.new(0, 7, 0)
	local act = topActive(d)
	for i, en in ipairs(act) do
		local base = parseEntry(en)
		local a = (i / math.max(1, #act)) * math.pi * 2
		local m = buildPet(base, 0.8, gp + Vector3.new(math.cos(a) * 5, 0, math.sin(a) * 5), a + math.pi / 2)
		m.Parent = holder
	end
	for i, inc in ipairs(d.incub or {}) do
		if i <= 8 then
			local p = petById(inc.p)
			local e = Instance.new("Part"); e.Shape = Enum.PartType.Ball; e.Size = Vector3.new(2, 2.6, 2)
			e.Color = EGG_COLOR[p.rarity] or Color3.fromRGB(245, 245, 240)
			e.Anchored = true; e.CanCollide = false; e.Parent = holder
			e.Position = gp + Vector3.new(-5 + (i - 1) * 1.6, 1.4, -5)
			e.Name = (os.time() >= inc.ready) and "IncubReady" or "IncubWait"
			if os.time() >= inc.ready then
				local li = Instance.new("PointLight"); li.Color = Color3.fromRGB(255, 255, 150); li.Range = 12; li.Brightness = 2; li.Parent = e
			end
		end
	end
end

local function syncAttrs(plr)
	local d = DATA[plr.UserId] if not d then return end
	plr:SetAttribute("BoatLvl", d.boatLvl)
	plr:SetAttribute("GardenLvl", d.gardenLvl)
	plr:SetAttribute("Slots", slotsOf(d))
	plr:SetAttribute("TrailLvl", d.trail or 0)
	local counts = {}
	for _, en in ipairs(d.pets) do counts[en] = (counts[en] or 0) + 1 end
	plr:SetAttribute("PetsJSON", Http:JSONEncode(counts))
	local idx = {}
	for k, v in pairs(d.index) do idx[tostring(k)] = v end
	plr:SetAttribute("IndexJSON", Http:JSONEncode(idx))
	plr:SetAttribute("RobuxSpent", d.robuxSpent or 0)
	plr:SetAttribute("IncubJSON", Http:JSONEncode(d.incub or {}))
	refreshGardenVis(plr)
end

local function charConnect(plr)
	plr.CharacterAdded:Connect(function() task.wait(0.1) applyWalk(plr) end)
end

Players.PlayerAdded:Connect(function(plr)
	local ls = Instance.new("Folder"); ls.Name = "leaderstats"; ls.Parent = plr
	local cash = Instance.new("IntValue"); cash.Name = "Money"; cash.Value = 0; cash.Parent = ls

	local d = { money = 150, pets = {}, boatLvl = 1, gardenLvl = 1, index = {}, intro = false, trail = 0, trailsOwned = {}, lastGift = 0, playSec = 0, robuxSpent = 0, tut = false, incub = {} }
	local ok, got = pcall(function() return store:GetAsync("u_" .. plr.UserId) end)
	if ok and type(got) == "table" then for k, v in pairs(got) do d[k] = v end end
	d.money = d.money or 150
	d.incub = d.incub or {}
	cash.Value = d.money
	DATA[plr.UserId] = d

	local free = {}
	for i = 1, 6 do if not gardens[i] then table.insert(free, i) end end
	local slot = 1
	if #free > 0 then slot = free[math.random(1, #free)] end
	gardens[slot] = plr.UserId
	d.slot = slot
	plr:SetAttribute("Slot", slot)
	plr:SetAttribute("NeedIntro", not d.intro)
	plr:SetAttribute("Tut", d.tut and 0 or 1)
	syncAttrs(plr)
	task.spawn(function()
		while DATA[plr.UserId] do
			task.wait(5)
			d.money = cash.Value
			d.playSec = (d.playSec or 0) + 5
			save(plr)
		end
	end)
	charConnect(plr)
end)

Players.PlayerRemoving:Connect(function(plr)
	save(plr)
	for i = 1, 6 do if gardens[i] == plr.UserId then gardens[i] = nil end end
	local c = carrying[plr.UserId]
	if c then c.model:Destroy() carrying[plr.UserId] = nil end
	local v = root:FindFirstChild("Vis" .. plr.UserId) if v then v:Destroy() end
	DATA[plr.UserId] = nil
end)
game:BindToClose(function() for _, p in ipairs(Players:GetPlayers()) do save(p) end end)

local function money(plr) local ls = plr:FindFirstChild("leaderstats") return ls and ls.Money end

MPS.ProcessReceipt = function(receipt)
	local plr = Players:GetPlayerByUserId(receipt.PlayerId)
	if plr and DATA[plr.UserId] then
		local d = DATA[plr.UserId]
		local spent = receipt.CurrencySpent or 0
		d.robuxSpent = (d.robuxSpent or 0) + spent
		local c = money(plr)
		if c then c.Value = c.Value + spent * 500 end
		syncAttrs(plr)
		evNote:FireClient(plr, "pop", "robux_thx", spent)
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- ---------- รายได้สวน ----------
task.spawn(function()
	while true do
		task.wait(1)
		for _, plr in ipairs(Players:GetPlayers()) do
			local d = DATA[plr.UserId]
			if d then
				local pows = {}
				for _, en in ipairs(d.pets) do local pw = entryPower(en) if pw > 0 then table.insert(pows, pw) end end
				table.sort(pows, function(a, b) return a > b end)
				local sum = 0
				for i = 1, math.min(slotsOf(d), #pows) do sum = sum + pows[i] end
				plr:SetAttribute("Income", sum)
				if sum > 0 then local c = money(plr) if c then c.Value = c.Value + sum end end
				plr:SetAttribute("PlayHours", math.floor(((d.playSec or 0) / 3600) * 10) / 10)
			end
		end
	end
end)

-- ============================================================
-- โลก
-- ============================================================
local old = WS:FindFirstChild("World3") if old then old:Destroy() end
local md = WS:FindFirstChild("MapDecor") if md then md:Destroy() end
local root = Instance.new("Folder"); root.Name = "World3"; root.Parent = WS

local function part(size, pos, color, mat, collide)
	local p = Instance.new("Part"); p.Size = size; p.Position = pos; p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic; p.Anchored = true
	p.CanCollide = collide ~= false; p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = root; return p
end
local function cyl(r, h, pos, color, mat)
	local p = Instance.new("Part"); p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(h, r * 2, r * 2); p.Orientation = Vector3.new(0, 0, 90)
	p.Position = pos; p.Color = color; p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true; p.Parent = root; return p
end
local function ball(size, pos, color, mat)
	local p = Instance.new("Part"); p.Shape = Enum.PartType.Ball; p.Size = size; p.Position = pos
	p.Color = color; p.Material = mat or Enum.Material.SmoothPlastic; p.Anchored = true; p.CanCollide = false; p.Parent = root; return p
end
local function sign3d(parent, text, w, h, color)
	local b = Instance.new("BillboardGui"); b.Size = UDim2.new(0, w, 0, h); b.AlwaysOnTop = true; b.Parent = parent
	local t = Instance.new("TextLabel"); t.Size = UDim2.new(1, 0, 1, 0); t.BackgroundTransparency = 1
	t.Font = Enum.Font.FredokaOne; t.TextScaled = true; t.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	t.TextStrokeTransparency = 0; t.Text = text; t.Parent = b; return b
end

local bp = WS:FindFirstChild("Baseplate")
if bp then bp.Material = Enum.Material.Water; bp.Color = Color3.fromRGB(25, 80, 150); bp.Size = Vector3.new(6000, 8, 6000); bp.Position = Vector3.new(0, -4, 0) end
for _, v in ipairs(WS:GetChildren()) do if v:IsA("SpawnLocation") and v.Name ~= "Spawn3" then v:Destroy() end end

local spots = {}
for _, isl in ipairs(ISLANDS) do
	local top = isl.n == 1 and 7 or 8
	cyl(isl.r + 12, 5, isl.pos + Vector3.new(0, 2, 0), Color3.fromRGB(235, 210, 150), Enum.Material.Sand)
	cyl(isl.r, 7, isl.pos + Vector3.new(0, 3.4, 0), isl.grass, Enum.Material.Grass)
	spots[isl.n] = {}
	local cell = 18
	local n = math.ceil((isl.r - 8) / cell)
	local dark = Color3.new(isl.grass.R * 0.82, isl.grass.G * 0.82, isl.grass.B * 0.82)
	for gx = -n, n do for gz = -n, n do
		local px, pz = gx * cell, gz * cell
		if math.sqrt(px * px + pz * pz) < isl.r - 8 and (gx + gz) % 2 == 0 then
			part(Vector3.new(cell, 0.15, cell), isl.pos + Vector3.new(px, top + 0.08, pz), dark, Enum.Material.Grass, false)
		end
	end end
	if isl.n == 1 then
		local sp = part(Vector3.new(14, 1, 14), isl.pos + Vector3.new(0, top + 0.4, 20), Color3.fromRGB(255, 220, 120), Enum.Material.Slate)
		sp.Name = "Spawn3"
		for i, gp in ipairs(GPOS) do
			local base = part(Vector3.new(14, 0.6, 14), isl.pos + gp + Vector3.new(0, top + 0.2, 0), Color3.fromRGB(120, 90, 60), Enum.Material.Wood)
			base.Name = "Garden" .. i
			sign3d(base, "Garden " .. i, 120, 40)
		end
		local chest = part(Vector3.new(4, 3, 3), isl.pos + Vector3.new(20, top + 1.5, 20), Color3.fromRGB(255, 200, 60), Enum.Material.Metal)
		chest.Name = "GiftChest"
		sign3d(chest, "Free Chest", 100, 40, Color3.fromRGB(255, 240, 150))
		local bdefs = { { "BoardA", -26, 8 }, { "BoardB", -26, 26 }, { "BoardC", -26, 44 } }
		for _, bd in ipairs(bdefs) do
			local b = part(Vector3.new(12, 14, 1), isl.pos + Vector3.new(bd[2], top + 8, bd[3]), Color3.fromRGB(60, 140, 220), Enum.Material.Metal)
			b.Name = bd[1]
		end
		part(Vector3.new(10, 1, 40), isl.pos + Vector3.new(0, 2.5, isl.r + 16), Color3.fromRGB(140, 100, 60), Enum.Material.Wood)
	else
		math.randomseed(isl.n * 999)
		local hide = isl.n == 4 and Enum.Material.Ice or Enum.Material.Rock
		for i = 1, 10 do
			local a = math.rad(i * 36 + isl.n * 10)
			local rr = isl.r * (0.35 + 0.5 * ((i * 37) % 10) / 10)
			local p = isl.pos + Vector3.new(math.cos(a) * rr, top, math.sin(a) * rr)
			table.insert(spots[isl.n], p)
			if i % 2 == 0 then
				ball(Vector3.new(6, 5, 6), p + Vector3.new(3, 2, 0), Color3.fromRGB(140, 140, 150), hide)
			else
				ball(Vector3.new(5, 4, 5), p + Vector3.new(-3, 1.5, 0), Color3.fromRGB(60, 150, 60), Enum.Material.Grass)
			end
		end
		local post = part(Vector3.new(2, 8, 2), isl.pos + Vector3.new(0, top + 4, isl.r - 14), Color3.fromRGB(140, 100, 60), Enum.Material.Wood)
		sign3d(post, "Island " .. isl.n .. " " .. isl.label .. "\nsteal speed rec x" .. isl.rec, 260, 90, Color3.fromRGB(255, 240, 150))
		local dir = (Vector3.new(0, 0, 0) - isl.pos); dir = Vector3.new(dir.X, 0, dir.Z).Unit
		part(Vector3.new(8, 1, 30), isl.pos + dir * (isl.r + 10) + Vector3.new(0, 2.5, 0), Color3.fromRGB(140, 100, 60), Enum.Material.Wood)
	end
end

-- ---------- เรือ ----------
local boats = {}
local function buildBoat(i, pos)
	local hull = part(Vector3.new(8, 2, 14), pos + Vector3.new(0, 1.2, 0), Color3.fromRGB(180, 80, 50), Enum.Material.Wood)
	hull.Name = "BoatHull" .. i
	part(Vector3.new(6.5, 0.5, 12), pos + Vector3.new(0, 2.5, 0), Color3.fromRGB(220, 180, 120), Enum.Material.Wood)
	part(Vector3.new(6.5, 1.5, 1), pos + Vector3.new(0, 3.2, -6), Color3.fromRGB(180, 80, 50), Enum.Material.Wood)
	local flag = part(Vector3.new(0.3, 5, 0.3), pos + Vector3.new(0, 5, -6), Color3.fromRGB(90, 60, 40), Enum.Material.Wood)
	sign3d(flag, "Boat " .. i, 90, 40)
	boats[i] = { hull = hull, pos = pos, heading = 0, throttle = 0, turn = 0, rider = nil, cf = CFrame.new(pos) }
end
for i = 1, 6 do
	local a = math.rad(20 + i * 20)
	buildBoat(i, Vector3.new(math.cos(a) * 120, 1, math.sin(a) * 120 + 110))
end
task.spawn(function()
	local dt = 1 / 30
	while true do
		task.wait(dt)
		for i, b in ipairs(boats) do
			if b.rider then
				local plr = Players:GetPlayerFromUserId(b.rider)
				local lvl = 1
				if plr and DATA[plr.UserId] then lvl = DATA[plr.UserId].boatLvl end
				local sp = boatSpeed(lvl)
				b.heading = b.heading + b.turn * 1.6 * dt
				local fwd = Vector3.new(math.sin(b.heading), 0, math.cos(b.heading))
				b.pos = b.pos + fwd * sp * b.throttle * dt
				b.pos = Vector3.new(math.clamp(b.pos.X, -2900, 2900), 1, math.clamp(b.pos.Z, -2900, 2900))
				for _, isl in ipairs(ISLANDS) do
					local d2 = Vector3.new(b.pos.X - isl.pos.X, 0, b.pos.Z - isl.pos.Z)
					local L = d2.Magnitude
					if L < isl.r + 8 and L > 0.01 then b.pos = isl.pos + d2.Unit * (isl.r + 8) + Vector3.new(0, 1, 0) end
				end
				b.cf = CFrame.new(b.pos) * CFrame.Angles(0, b.heading, 0)
				b.hull.CFrame = b.cf
				if plr and plr.Character then
					local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
					if hrp then hrp.CFrame = b.cf * CFrame.new(0, 2.6, 0) end
				end
			end
		end
	end
end)
evBoatIn.OnServerEvent:Connect(function(plr, th, tu)
	local bi = boatOf[plr.UserId] if not bi then return end
	local b = boats[bi] if not b or b.rider ~= plr.UserId then return end
	b.throttle = math.clamp(tonumber(th) or 0, -0.4, 1)
	b.turn = math.clamp(tonumber(tu) or 0, -1, 1)
end)

-- ---------- ผู้พิทักษ์ = Secret ประจำเกาะ ----------
local GUARD_PET = {}
for isl = 2, 5 do
	local best = nil
	for _, p in ipairs(PETS) do
		if p.isl == isl and RANK[p.rarity] >= 2 and RANK[p.rarity] <= 7 and (not best or RANK[p.rarity] > RANK[best.rarity]) then best = p end
	end
	GUARD_PET[isl] = best.id
end
local guardians = {}
local function buildGuardian(isl)
	local id = GUARD_PET[isl]
	local islD = ISLANDS[isl]
	local m, bodyPart = buildPet(id, 2.6, islD.pos + Vector3.new(0, 8, 0), 0)
	m.Name = "Guardian" .. isl
	local head = m:FindFirstChildOfClass("Part")
	for _, p in ipairs(m:GetChildren()) do
		if p:IsA("Part") then p.Parent = m end
	end
	local ghead = nil
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("Part") and p.Size.Y < 3 then ghead = p break end
	end
	if bodyPart then
		bodyPart.Name = "GBody"
		bodyPart:SetAttribute("Pet", id)
		local bb = Instance.new("BillboardGui"); bb.Size = UDim2.new(0, 240, 0, 54); bb.AlwaysOnTop = true; bb.Parent = bodyPart
		local t = Instance.new("TextLabel"); t.Size = UDim2.new(1, 0, 1, 0); t.BackgroundTransparency = 1
		t.Font = Enum.Font.FredokaOne; t.TextScaled = true; t.TextColor3 = Color3.fromRGB(255, 90, 90)
		t.TextStrokeTransparency = 0; t.Name = "GTitle"; t.Parent = bb
	end
	guardians[isl] = { model = m, body = bodyPart, pos = Vector3.new(0, 0, 0), heading = 0, patrol = nil, cool = 0 }
end
for isl = 2, 5 do buildGuardian(isl) end

task.spawn(function()
	local dt = 1 / 20
	while true do
		task.wait(dt)
		for isl, g in pairs(guardians) do
			local islD = ISLANDS[isl]
			local top = 8
			g.cool = math.max(0, g.cool - dt)
			local victimUid, victimHrp, victimW = nil, nil, 0
			if g.cool <= 0 then
				for uid, c in pairs(carrying) do
					if c.isl == isl then
						local plr = Players:GetPlayerFromUserId(uid)
						local hrp = plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
						if hrp then
							local d2 = hrp.Position - islD.pos
							local inIsle = Vector3.new(d2.X, 0, d2.Z).Magnitude < islD.r + 25
							local near = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(islD.pos.X + g.pos.X, 0, islD.pos.Z + g.pos.Z)).Magnitude < 60
							if inIsle and near then
								victimUid, victimHrp, victimW = uid, hrp, c.weight
								break
							end
						end
					end
				end
			end
			local speed, dest = 9, nil
			if victimHrp then
				dest = victimHrp.Position - islD.pos
				speed = math.min(22, carrySpeed(victimW) + 6)
			else
				if not g.patrol or (Vector3.new(g.pos.X, 0, g.pos.Z) - g.patrol).Magnitude < 5 then
					local a = math.random() * math.pi * 2
					local rr = math.random() * math.max(10, islD.r - 30)
					g.patrol = Vector3.new(math.cos(a) * rr, 0, math.sin(a) * rr)
				end
				dest = g.patrol
			end
			local dir = dest - g.pos
			dir = Vector3.new(dir.X, 0, dir.Z)
			local L = dir.Magnitude
			if L > 0.5 then
				dir = dir.Unit
				g.pos = g.pos + dir * math.min(speed * dt, L)
				g.heading = math.atan2(dir.X, dir.Z)
			end
			if g.body then
				g.body.CFrame = CFrame.new(islD.pos + g.pos + Vector3.new(0, top + 2, 0)) * CFrame.Angles(0, g.heading, 0)
			end
			if victimUid and (victimHrp.Position - (islD.pos + g.pos + Vector3.new(0, top, 0))).Magnitude < 6 then
				local c = carrying[victimUid]
				if c then
					c.model:Destroy()
					carrying[victimUid] = nil
					local plr = Players:GetPlayerFromUserId(victimUid)
					if plr then
						plr:SetAttribute("Carrying", 0); plr:SetAttribute("CarryWeight", 0)
						applyWalk(plr)
						evNote:FireClient(plr, "pop", "guard_hit")
					end
					local ss = spots[isl]
					makeEgg(isl, ss[math.random(1, #ss)], c.pet, c.weight)
					g.cool = 6
					g.patrol = nil
				end
			end
		end
	end
end)

-- ============================================================
-- กลางวัน/กลางคืน + ไข่
-- ============================================================
local DAY_LEN, NIGHT_LEN, DAWN_WARN = 180, 240, 20
local phase = "day"
local phaseT = DAY_LEN
local liveEggs = {}
EGG_COLOR = {
	common = Color3.fromRGB(245, 245, 240), rare = Color3.fromRGB(120, 180, 255), epic = Color3.fromRGB(190, 120, 255),
	legendary = Color3.fromRGB(255, 190, 60), mythic = Color3.fromRGB(255, 80, 60), secret = Color3.fromRGB(60, 30, 90),
	divine = Color3.fromRGB(255, 250, 210), mystery = Color3.fromRGB(15, 5, 25), trash = Color3.fromRGB(120, 110, 90),
}
local function eggColor(r) return EGG_COLOR[r] or EGG_COLOR.common end

function makeEgg(isl, pos, petId, weight)
	local p = petById(petId)
	local g = Instance.new("Folder"); g.Parent = root
	cyl(2, 1, pos + Vector3.new(0, 0.5, 0), Color3.fromRGB(120, 100, 80), Enum.Material.Slate)
	local e = ball(Vector3.new(3, 4, 3), pos + Vector3.new(0, 2.6, 0), eggColor(p.rarity), Enum.Material.SmoothPlastic)
	e.Name = "EggLive"
	e.CanTouch = false
	if RANK[p.rarity] >= 4 then
		local li = Instance.new("PointLight"); li.Color = eggColor(p.rarity); li.Range = 30; li.Brightness = 3; li.Parent = e
	end
	sign3d(e, weight .. " kg", 90, 40)
	table.insert(liveEggs, { model = g, egg = e, isl = isl, pet = petId, weight = weight })
end
local function spawnNightEggs()
	for isl = 2, 5 do
		local ss = spots[isl]
		local picked = {}
		for _ = 1, EGG_COUNT[isl] do
			local s = ss[math.random(1, #ss)]
			if not picked[s] then
				picked[s] = true
				local pool = poolOf(isl)
				local pet = pickWeighted(pool)
				local bw = WEIGHT[pet.rarity]
				local w
				if bw < 1 then w = bw else w = math.max(1, math.floor(bw * (0.8 + math.random() * 0.8) * 10) / 10) end
				makeEgg(isl, s, pet.id, w)
				if pet.rarity == "legendary" then evNote:FireAllClients("ban", "legend") end
				if pet.rarity == "mystery" then evNote:FireAllClients("ban", "mystery_egg") end
			end
		end
	end
end
local function clearEggs()
	for _, eg in ipairs(liveEggs) do eg.model:Destroy() end
	liveEggs = {}
	for uid, c in pairs(carrying) do
		c.model:Destroy(); carrying[uid] = nil
		local plr = Players:GetPlayerFromUserId(uid)
		if plr then plr:SetAttribute("Carrying", 0); applyWalk(plr) end
	end
end

task.spawn(function()
	while true do
		task.wait(1)
		phaseT = phaseT - 1
		if phase == "day" then
			Lighting.ClockTime = math.min(18, 6 + (DAY_LEN - phaseT) / DAY_LEN * 12)
			if phaseT <= 0 then
				phase = "night"; phaseT = NIGHT_LEN
				evNote:FireAllClients("ban", "night_now")
				spawnNightEggs()
			end
		else
			Lighting.ClockTime = (18 + (NIGHT_LEN - phaseT) / NIGHT_LEN * 12) % 24
			if phaseT <= 0 then
				phase = "day"; phaseT = DAY_LEN
				evNote:FireAllClients("ban", "dawn")
				task.wait(DAWN_WARN)
				clearEggs()
			end
		end
		evPhase:FireAllClients({ phase = phase, t = phaseT })
	end
end)

-- ---------- เก็บไข่ ----------
evPick.OnServerEvent:Connect(function(plr, eggPart)
	local uid = plr.UserId
	if carrying[uid] then return end
	local idx
	for i, eg in ipairs(liveEggs) do if eg.egg == eggPart then idx = i break end end
	if not idx then return end
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or (liveEggs[idx].egg.Position - hrp.Position).Magnitude > 9 then return end
	local eg = table.remove(liveEggs, idx)
	eg.model:Destroy()
	local m = Instance.new("Part"); m.Shape = Enum.PartType.Ball; m.Size = Vector3.new(2.4, 3, 2.4)
	m.Color = eggColor(petById(eg.pet).rarity); m.CanCollide = false; m.Parent = char
	local w = Instance.new("Weld"); w.Part0 = hrp; w.Part1 = m; w.C0 = CFrame.new(0, -0.5, 2); w.Parent = m
	carrying[uid] = { model = m, pet = eg.pet, weight = eg.weight, isl = eg.isl }
	plr:SetAttribute("Carrying", eg.isl)
	plr:SetAttribute("CarryWeight", eg.weight)
	applyWalk(plr)
	evNote:FireClient(plr, "pop", "pickup", eg.weight)
end)

local function ownBase(d, id)
	for _, en in ipairs(d.pets) do
		local b = parseEntry(en)
		if b == id then return true end
	end
	return false
end
local function grantPet(plr, d, petId, weight)
	local p = petById(petId)
	if SINGLE[p.rarity] and ownBase(d, petId) then
		local val = sellValue(petId .. "@" .. weight)
		local c = money(plr)
		if c then c.Value = c.Value + val end
		evNote:FireClient(plr, "pop", "dup_convert", val)
		return
	end
	table.insert(d.pets, petId .. "@" .. weight)
	d.index[p.isl == "all" and 2 or p.isl] = d.index[p.isl == "all" and 2 or p.isl] or {}
	for isl = 2, 5 do
		if p.isl == isl or p.isl == "all" then
			d.index[isl] = d.index[isl] or {}
			local seen = false
			for _, id in ipairs(d.index[isl]) do if id == petId then seen = true end end
			if not seen then table.insert(d.index[isl], petId) end
			if #d.index[isl] >= #poolOf(isl) then evNote:FireClient(plr, "ban", "idx_done", isl) end
		end
	end
	if p.rarity == "mystery" then
		evNote:FireClient(plr, "reveal", petId)
	else
		evNote:FireClient(plr, "pop", "hatch", petId, p.rarity)
	end
	syncAttrs(plr)
end

-- ---------- แอ็กชัน ----------
evAct.OnServerEvent:Connect(function(plr, action, arg)
	local uid = plr.UserId
	local d = DATA[uid] if not d then return end
	local c = money(plr)
	if action == "board" then
		if boatOf[uid] then return end
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") if not hrp then return end
		for i, b in ipairs(boats) do
			if (b.pos - hrp.Position).Magnitude < 14 and not b.rider then
				b.rider = uid; boatOf[uid] = i; plr:SetAttribute("OnBoat", i); break
			end
		end
	elseif action == "leave" then
		local bi = boatOf[uid] if not bi then return end
		local b = boats[bi]
		b.rider = nil; b.throttle = 0; b.turn = 0; boatOf[uid] = nil
		plr:SetAttribute("OnBoat", 0)
		local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		if hrp then hrp.CFrame = b.cf * CFrame.new(6, 3, 0) end
	elseif action == "place" then
		-- วางไข่ที่สวน → เริ่มนับเวลาฟัก
		local cc = carrying[uid] if not cc then return end
		local p = petById(cc.pet)
		local mult = wMult(cc.pet, cc.weight)
		local wait = math.min(MAX_WAIT, math.floor(WAIT_BASE[p.rarity] * mult))
		cc.model:Destroy(); carrying[uid] = nil
		plr:SetAttribute("Carrying", 0); plr:SetAttribute("CarryWeight", 0)
		applyWalk(plr)
		table.insert(d.incub, { p = cc.pet, w = cc.weight, ready = os.time() + wait })
		syncAttrs(plr)
		evNote:FireClient(plr, "pop", "placed", math.floor(wait / 60))
	elseif action == "hatch" then
		-- ฟักไข่ที่ครบเวลา
		for i, inc in ipairs(d.incub) do
			if os.time() >= inc.ready then
				table.remove(d.incub, i)
				grantPet(plr, d, inc.p, inc.w)
				return
			end
		end
	elseif action == "upboat" then
		local nl = d.boatLvl + 1
		local cost = BOAT_COST[nl]
		if cost and c and c.Value >= cost then
			c.Value = c.Value - cost; d.boatLvl = nl
			plr:SetAttribute("BoatLvl", nl)
			evNote:FireClient(plr, "pop", "boat_up", math.floor(boatSpeed(nl)))
		end
	elseif action == "upgarden" then
		local nl = d.gardenLvl + 1
		local cost = GARDEN_COST[nl]
		if cost and c and c.Value >= cost then
			c.Value = c.Value - cost; d.gardenLvl = nl
			plr:SetAttribute("GardenLvl", nl); plr:SetAttribute("Slots", slotsOf(d))
			syncAttrs(plr)
			evNote:FireClient(plr, "pop", "garden_up", slotsOf(d))
		end
	elseif action == "fuse" then
		local id = tostring(arg or "")
		local cnt = 0
		for _, en in ipairs(d.pets) do
			local b, bg = parseEntry(en)
			if b == id and not bg then cnt = cnt + 1 end
		end
		if cnt >= 3 and petById(id) then
			local removed = 0; local np = {}; local sumW = 0
			for _, en in ipairs(d.pets) do
				local b, bg, w = parseEntry(en)
				if b == id and not bg and removed < 3 then
					removed = removed + 1
					sumW = sumW + (w or WEIGHT[petById(id).rarity])
				else
					table.insert(np, en)
				end
			end
			d.pets = np
			sumW = math.floor(sumW * 100) / 100
			table.insert(d.pets, "BIG" .. id .. "@" .. sumW)
			syncAttrs(plr)
			evNote:FireClient(plr, "pop", "fuse_ok", id)
		end
	elseif action == "sell" then
		local en = tostring(arg or "")
		for i, x in ipairs(d.pets) do
			if x == en then
				table.remove(d.pets, i)
				local base, big = parseEntry(en)
				local val = sellValue(en)
				if c then c.Value = c.Value + val end
				syncAttrs(plr)
				evNote:FireClient(plr, "pop", "sold", base, big and 1 or 0, val)
				break
			end
		end
	elseif action == "trail" then
		local i = tonumber(arg) or 1
		local t = TRAILS[i] if not t then return end
		local owned = false
		for _, o in ipairs(d.trailsOwned or {}) do if o == i then owned = true end end
		if not owned then
			if c and c.Value >= t.cost then
				c.Value = c.Value - t.cost
				d.trailsOwned = d.trailsOwned or {}
				table.insert(d.trailsOwned, i)
			else
				return
			end
		end
		d.trail = i
		plr:SetAttribute("TrailLvl", i)
		applyWalk(plr)
		evNote:FireClient(plr, "pop", "trail_on", i, t.mult)
	elseif action == "tutdone" then
		d.tut = true
		plr:SetAttribute("Tut", 0)
	elseif action == "gift" then
		local now = os.time()
		if now - (d.lastGift or 0) >= 72000 then
			d.lastGift = now
			if c then c.Value = c.Value + 750 end
			evNote:FireClient(plr, "pop", "gift_ok")
		else
			evNote:FireClient(plr, "pop", "chest_wait", math.max(1, math.floor((72000 - (now - d.lastGift)) / 3600)))
		end
	end
end)

evIntro.OnServerEvent:Connect(function(plr)
	local d = DATA[plr.UserId] if not d then return end
	d.intro = true
	plr:SetAttribute("NeedIntro", false)
	save(plr)
end)

-- ---------- แอดมิน ----------
local OWNERS = {}
local function isAdmin(plr)
	if plr.UserId == 0 then return true end
	if game.CreatorId > 0 and plr.UserId == game.CreatorId then return true end
	return table.find(OWNERS, plr.UserId) ~= nil
end
local function wireAdminChat(plr)
	plr.Chatted:Connect(function(msg)
		if not isAdmin(plr) then return end
		local cmd, arg = msg:match("^(/%S+)%s*(.*)$")
		if not cmd then return end
		cmd = cmd:lower()
		local c = money(plr)
		local function fb(key, a) evNote:FireClient(plr, "admin", key, a) end
		if cmd == "/money" or cmd == "/coins" then
			local n = math.floor(tonumber(arg) or 100000)
			if c then c.Value = math.clamp(c.Value + n, 0, 9000000000) fb("money_add", n) end
		elseif cmd == "/allpets" then
			local d = DATA[plr.UserId]
			for _, p in ipairs(PETS) do
				if not SINGLE[p.rarity] or not ownBase(d, p.id) then table.insert(d.pets, p.id .. "@" .. WEIGHT[p.rarity]) end
			end
			syncAttrs(plr); fb("allpets")
		elseif cmd == "/egg" then
			local id, w = arg:match("^(%S+)%s*(%S*)")
			local p = petById(id)
			if p then
				local weight = math.clamp(tonumber(w) or WEIGHT[p.rarity], 0.01, 5000)
				local char = plr.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					makeEgg(p.isl == "all" and 1 or p.isl, hrp.Position + Vector3.new(3, 0, 3), id, weight)
					evNote:FireAllClients("admin", "egg_summon", plr.Name, id, weight)
				end
			else
				fb("__raw", "unknown id: " .. tostring(id))
			end
		elseif cmd == "/night" then
			phaseT = 1; fb("__raw", "-> night")
		elseif cmd == "/day" then
			phase = "night"; phaseT = 1; fb("__raw", "-> day")
		elseif cmd == "/kick" then
			local t = Players:FindFirstChild(arg)
			if t and t ~= plr then t:Kick("Kicked by admin") end
		elseif cmd == "/say" then
			if arg ~= "" then evNote:FireAllClients("admin", "__raw", arg:sub(1, 120)) end
		elseif cmd == "/reset" then
			local d = DATA[plr.UserId]
			d.pets = {}; d.money = 150; d.boatLvl = 1; d.gardenLvl = 1; d.index = {}; d.trail = 0; d.incub = {}
			if c then c.Value = 150 end
			syncAttrs(plr); fb("reset_ok")
		elseif cmd == "/help" then
			fb("__raw", "/money n | /egg id [kg] | /allpets | /night /day | /kick name | /say text | /reset")
		end
	end)
end
Players.PlayerAdded:Connect(wireAdminChat)
for _, p in ipairs(Players:GetPlayers()) do wireAdminChat(p) end

Lighting.ClockTime = 10
Lighting.Brightness = 1.5
Lighting.FogEnd = 4000
pcall(function() Lighting.Technology = Enum.Technology.Future end)
print("GAMECORE7 READY")
