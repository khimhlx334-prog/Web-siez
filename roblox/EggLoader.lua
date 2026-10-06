local CORE = [=[ 
-- ============================================================
-- 🥚 EGG ISLE v3 · GameCore3 (Script → ServerScriptService)
-- ลูปขโมยไข่: เกาะใหญ่ · กลางวัน/คืน · ไข่ซ่อน · เรือ · สวน · กันโปรเซิร์ฟตัดสิน
-- ============================================================
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local WS = game:GetService("Workspace")

local store = DataStoreService:GetDataStore("EggIsleV3")

-- ปิดสคริปต์ชุดเก่ากันทำงานซ้อน
local function killOld(name)
	local o = script.Parent:FindFirstChild(name)
	if o then o:Destroy() end
end
killOld("MapBuilder")

-- ---------- ข้อมูลสัตว์ ----------
local PETS = {
	{ id = "cat", name = "แมวส้ม", rarity = "ธรรมดา", power = 1, isl = 2 },
	{ id = "dog", name = "คอร์กี้", rarity = "ธรรมดา", power = 1, isl = 2 },
	{ id = "rab", name = "กระต่ายขาว", rarity = "ธรรมดา", power = 1, isl = 2 },
	{ id = "pan", name = "แพนด้า", rarity = "ไม่ธรรมดา", power = 3, isl = 2 },
	{ id = "cap", name = "คาปิบาร่า", rarity = "ไม่ธรรมดา", power = 3, isl = 3 },
	{ id = "ele", name = "ช้างชมพู", rarity = "หายาก", power = 10, isl = 3 },
	{ id = "lio", name = "สิงโตทอง", rarity = "หายาก", power = 10, isl = 3 },
	{ id = "dra", name = "มังกรน้ำแข็ง", rarity = "มหากาพย์", power = 40, isl = 4 },
	{ id = "uni", name = "ยูนิคอร์นรุ้ง", rarity = "มหากาพย์", power = 40, isl = 4 },
	{ id = "gld", name = "ดราก้อนทอง", rarity = "ตำนาน", power = 200, isl = 5 },
	{ id = "phx", name = "ฟีนิกซ์จักรวาล", rarity = "ตำนาน", power = 200, isl = 5 },
}
local function petById(id) for _, p in ipairs(PETS) do if p.id == id then return p end end end
local function poolOf(isl)
	local t = {}
	for _, p in ipairs(PETS) do if p.isl == isl then table.insert(t, p) end end
	return t
end

-- ---------- เกาะ ----------
local ISLANDS = {
	{ n = 1, pos = Vector3.new(0, 0, 0), r = 90, grass = Color3.fromRGB(95, 175, 85), label = "เกาะเริ่มต้น", rec = 0 },
	{ n = 2, pos = Vector3.new(500, 0, 0), r = 120, grass = Color3.fromRGB(110, 190, 90), label = "เกาะทุ่งหญ้า", rec = 24 },
	{ n = 3, pos = Vector3.new(-500, 0, 300), r = 130, grass = Color3.fromRGB(220, 190, 110), label = "เกาะทะเลทราย", rec = 36 },
	{ n = 4, pos = Vector3.new(300, 0, -700), r = 140, grass = Color3.fromRGB(200, 230, 245), label = "เกาะน้ำแข็ง", rec = 54 },
	{ n = 5, pos = Vector3.new(-400, 0, -1100), r = 150, grass = Color3.fromRGB(90, 70, 130), label = "เกาะอเวจี", rec = 81 },
}
local EGG_COUNT = { [2] = 6, [3] = 5, [4] = 4, [5] = 3 }

-- ---------- รีโมต ----------
local function ev(name)
	local r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = ReplicatedStorage; return r
end
local evNote = ev("Note")       -- (kind, text) kind: "ban" | "pop"
local evPhase = ev("Phase")     -- {phase, t}
local evBoatIn = ev("BoatIn")   -- (throttle, turn)
local evAct = ev("Act")         -- (action, arg)
local evIntro = ev("IntroDone")
local evAdmin = ev("Admin")

-- ---------- ข้อมูลผู้เล่น ----------
local DATA = {}
local gardens = {} -- [1..6] = userId
local carrying = {} -- [userId] = {isl, tier, eggModel}
local boatOf = {} -- [userId] = boatIdx

local BOAT_COST = { [2] = 1000, [3] = 5000, [4] = 25000, [5] = 100000 }
local GARDEN_COST = { [2] = 500, [3] = 2500, [4] = 10000, [5] = 50000, [6] = 200000 }
local function boatSpeed(lvl) return 16 * math.pow(1.5, lvl - 1) end
local function slotsOf(d) return 2 + d.gardenLvl end

local function save(plr)
	local d = DATA[plr.UserId] if not d then return end
	pcall(function()
		store:SetAsync("u_" .. plr.UserId, d)
	end)
end

Players.PlayerAdded:Connect(function(plr)
	local ls = Instance.new("Folder"); ls.Name = "leaderstats"; ls.Parent = plr
	local cash = Instance.new("IntValue"); cash.Name = "Coins"; cash.Value = 0; cash.Parent = ls

	local d = { coins = 150, pets = {}, boatLvl = 1, gardenLvl = 1, index = {}, intro = false }
	local ok, got = pcall(function() return store:GetAsync("u_" .. plr.UserId) end)
	if ok and type(got) == "table" then
		for k, v in pairs(got) do d[k] = v end
	end
	d.coins = d.coins or 150
	cash.Value = d.coins
	DATA[plr.UserId] = d

	-- สุ่มสวนว่าง
	local free = {}
	for i = 1, 6 do if not gardens[i] then table.insert(free, i) end end
	local slot = free[math.random(1, #free)] or 1
	gardens[slot] = plr.UserId
	d.slot = slot
	plr:SetAttribute("Slot", slot)
	plr:SetAttribute("BoatLvl", d.boatLvl)
	plr:SetAttribute("GardenLvl", d.gardenLvl)
	plr:SetAttribute("NeedIntro", not d.intro)

	-- ลำดับแรก: เงินตั้งต้นไม่ต้อง (มีอยู่แล้ว) sync
	task.spawn(function() while DATA[plr.UserId] do task.wait(5) d.coins = cash.Value save(plr) end end)
end)
Players.PlayerRemoving:Connect(function(plr)
	save(plr)
	for i = 1, 6 do if gardens[i] == plr.UserId then gardens[i] = nil end end
	if carrying[plr.UserId] then
		local c = carrying[plr.UserId]
		if c.model then c.model:Destroy() end
		carrying[plr.UserId] = nil
	end
	DATA[plr.UserId] = nil
end)
game:BindToClose(function() for _, p in ipairs(Players:GetPlayers()) do save(p) end end)

local function coins(plr) local ls = plr:FindFirstChild("leaderstats") return ls and ls.Coins end
local function syncAttrs(plr)
	local d = DATA[plr.UserId] if not d then return end
	plr:SetAttribute("BoatLvl", d.boatLvl)
	plr:SetAttribute("GardenLvl", d.gardenLvl)
	plr:SetAttribute("Slots", slotsOf(d))
	local counts = {}
	for _, id in ipairs(d.pets) do counts[id] = (counts[id] or 0) + 1 end
	plr:SetAttribute("PetsJSON", game:GetService("HttpService"):JSONEncode(counts))
	plr:SetAttribute("IndexJSON", game:GetService("HttpService"):JSONEncode(d.index))
end

-- ---------- รายได้สวน (top-N พาวเวอร์) ----------
task.spawn(function()
	while true do
		task.wait(1)
		for _, plr in ipairs(Players:GetPlayers()) do
			local d = DATA[plr.UserId] if d then
				local pows = {}
				for _, id in ipairs(d.pets) do local p = petById(id) if p then table.insert(pows, p.power) end end
				table.sort(pows, function(a, b) return a > b end)
				local sum = 0
				for i = 1, math.min(slotsOf(d), #pows) do sum += pows[i] end
				if sum > 0 then
					local c = coins(plr) if c then c.Value += sum end
				end
			end
		end
	end
end)

-- ============================================================
-- สร้างโลก
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
	t.Font = Enum.Font.GothamBlack; t.TextScaled = true; t.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	t.TextStrokeTransparency = 0; t.Text = text; t.Parent = b; return b
end

-- ทะเล
local bp = WS:FindFirstChild("Baseplate")
if bp then bp.Material = Enum.Material.Water; bp.Color = Color3.fromRGB(25, 80, 150); bp.Size = Vector3.new(6000, 8, 6000); bp.Position = Vector3.new(0, -4, 0) end
for _, v in ipairs(WS:GetChildren()) do if v:IsA("SpawnLocation") and v.Name ~= "Spawn3" then v:Destroy() end end

local spots = {} -- [islandN] = {Vector3...} จุดซ่อนไข่
for _, isl in ipairs(ISLANDS) do
	local top = isl.n == 1 and 7 or 8
	cyl(isl.r + 12, 5, isl.pos + Vector3.new(0, 2, 0), Color3.fromRGB(235, 210, 150), Enum.Material.Sand)
	cyl(isl.r, 7, isl.pos + Vector3.new(0, 3.4, 0), isl.grass, Enum.Material.Grass)
	spots[isl.n] = {}
	if isl.n == 1 then
		local sp = part(Vector3.new(14, 1, 14), isl.pos + Vector3.new(0, top + 0.4, 20), Color3.fromRGB(255, 220, 120), Enum.Material.Slate)
		sp.Name = "Spawn3"
		-- สวน 6 แปลง
		local gpos = { Vector3.new(-30, 0, -20), Vector3.new(0, 0, -20), Vector3.new(30, 0, -20), Vector3.new(-30, 0, -48), Vector3.new(0, 0, -48), Vector3.new(30, 0, -48) }
		for i, gp in ipairs(gpos) do
			local base = part(Vector3.new(14, 0.6, 14), isl.pos + gp + Vector3.new(0, top + 0.2, 0), Color3.fromRGB(120, 90, 60), Enum.Material.Wood)
			base.Name = "Garden" .. i
			sign3d(base, "🏡 สวน " .. i, 120, 40)
			local inc = part(Vector3.new(3, 4, 3), isl.pos + gp + Vector3.new(5, top + 2.5, -4), Color3.fromRGB(80, 130, 200), Enum.Material.Metal)
			inc.Name = "Incubator" .. i
			sign3d(inc, " เครื่องฟัก", 110, 36)
		end
		-- ท่าเรือ
		part(Vector3.new(10, 1, 40), isl.pos + Vector3.new(0, 2.5, isl.r + 16), Color3.fromRGB(140, 100, 60), Enum.Material.Wood)
	else
		-- จุดซ่อนไข่ + ที่กำบัง (หิน/พุ่ม)
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
		-- ป้ายความเร็วแนะนำ
		local post = part(Vector3.new(2, 8, 2), isl.pos + Vector3.new(0, top + 4, isl.r - 14), Color3.fromRGB(140, 100, 60), Enum.Material.Wood)
		sign3d(post, "⛵ เกาะ " .. isl.n .. " " .. isl.label .. "\nความเร็วแนะนำสำหรับขโมย: x" .. isl.rec, 260, 90, Color3.fromRGB(255, 240, 150))
		-- ท่าเรือเล็ก
		local dir = (Vector3.new(0, 0, 0) - isl.pos); dir = Vector3.new(dir.X, 0, dir.Z).Unit
		part(Vector3.new(8, 1, 30), isl.pos + dir * (isl.r + 10) + Vector3.new(0, 2.5, 0), Color3.fromRGB(140, 100, 60), Enum.Material.Wood)
	end
end

-- ---------- เรือ 6 ลำ ----------
local boats = {} -- [i] = {model, cf=CFrame, heading, throttle, turn, rider}
local function buildBoat(i, pos)
	local m = Instance.new("Folder"); m.Parent = root
	local hull = part(Vector3.new(8, 2, 14), pos + Vector3.new(0, 1.2, 0), Color3.fromRGB(180, 80, 50), Enum.Material.Wood)
	hull.Name = "BoatHull" .. i
	part(Vector3.new(6.5, 0.5, 12), pos + Vector3.new(0, 2.5, 0), Color3.fromRGB(220, 180, 120), Enum.Material.Wood)
	part(Vector3.new(6.5, 1.5, 1), pos + Vector3.new(0, 3.2, -6), Color3.fromRGB(180, 80, 50), Enum.Material.Wood)
	local flag = part(Vector3.new(0.3, 5, 0.3), pos + Vector3.new(0, 5, -6), Color3.fromRGB(90, 60, 40), Enum.Material.Wood)
	sign3d(flag, "⛵ " .. i, 70, 40)
	boats[i] = { hull = hull, pos = pos + Vector3.new(0, 0, 0), heading = 0, throttle = 0, turn = 0, rider = nil, cf = CFrame.new(pos) }
end
for i = 1, 6 do
	local a = math.rad(20 + i * 20)
	buildBoat(i, Vector3.new(math.cos(a) * 120, 1, math.sin(a) * 120 + 110))
end

-- ลูปฟิสิกส์เรือ (เซิร์ฟเวอร์)
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
				b.heading += b.turn * 1.6 * dt
				local fwd = Vector3.new(math.sin(b.heading), 0, math.cos(b.heading))
				b.pos += fwd * sp * b.throttle * dt
				b.pos = Vector3.new(math.clamp(b.pos.X, -2900, 2900), 1, math.clamp(b.pos.Z, -2900, 2900))
				-- กันชนเกาะ
				for _, isl in ipairs(ISLANDS) do
					local d2 = Vector3.new(b.pos.X - isl.pos.X, 0, b.pos.Z - isl.pos.Z)
					local L = d2.Magnitude
					if L < isl.r + 8 and L > 0.01 then
						b.pos = isl.pos + d2.Unit * (isl.r + 8) + Vector3.new(0, 1, 0)
					end
				end
				b.cf = CFrame.new(b.pos) * CFrame.Angles(0, b.heading, 0)
				b.hull.CFrame = b.cf
				-- คนขี่ตามเรือ
				if plr and plr.Character then
					local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
					if hrp then
						hrp.CFrame = b.cf * CFrame.new(0, 2.6, 0)
					end
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

-- ============================================================
-- กลางวัน/กลางคืน + ไข่
-- ============================================================
local DAY_LEN, NIGHT_LEN, DAWN_WARN = 180, 240, 20
local phase = "day"
local phaseT = DAY_LEN
local liveEggs = {} -- {model, isl, spot, tier}

local TIER_OF_ISL = { [2] = "ธรรมดา", [3] = "หายาก", [4] = "มหากาพย์", [5] = "ตำนาน" }
local EGG_COLOR = { ["ธรรมดา"] = Color3.fromRGB(245, 245, 240), ["หายาก"] = Color3.fromRGB(120, 180, 255), ["มหากาพย์"] = Color3.fromRGB(190, 120, 255), ["ตำนาน"] = Color3.fromRGB(255, 190, 60) }

local function spawnEgg(isl, spot)
	local tier = TIER_OF_ISL[isl]
	local g = Instance.new("Folder"); g.Parent = root
	local base = cyl(2, 1, spot + Vector3.new(0, 0.5, 0), Color3.fromRGB(120, 100, 80), Enum.Material.Slate)
	local e = ball(Vector3.new(3, 4, 3), spot + Vector3.new(0, 2.6, 0), EGG_COLOR[tier], Enum.Material.SmoothPlastic)
	e.Name = "Egg_" .. isl
	e.CanTouch = true; e.CanCollide = false
	if tier == "ตำนาน" or tier == "มหากาพย์" then
		local li = Instance.new("PointLight"); li.Color = EGG_COLOR[tier]; li.Range = 30; li.Brightness = 3; li.Parent = e
	end
	local tag = Instance.new("StringValue"); tag.Name = "isl"; tag.Value = tostring(isl); tag.Parent = e
	sign3d(e, "🥚", 60, 60)
	table.insert(liveEggs, { model = g, egg = e, isl = isl, spot = spot })
	return e
end

local function spawnNightEggs()
	for isl = 2, 5 do
		local ss = spots[isl]
		local n = EGG_COUNT[isl]
		local picked = {}
		for _ = 1, n do
			local s = ss[math.random(1, #ss)]
			if not picked[s] then
				picked[s] = true
				local e = spawnEgg(isl, s)
				if isl == 5 then
					evNote:FireAllClients("ban", "🌟 ไข่ตำนานเกิดที่เกาะ 5 เกาะอเวจี!")
				end
			end
		end
	end
end
local function clearEggs()
	for _, eg in ipairs(liveEggs) do eg.model:Destroy() end
	liveEggs = {}
	for uid, c in pairs(carrying) do
		if c.model then c.model:Destroy() end
		carrying[uid] = nil
		local plr = Players:GetPlayerFromUserId(uid)
		if plr then plr:SetAttribute("Carrying", 0) end
	end
end

task.spawn(function()
	while true do
		task.wait(1)
		phaseT -= 1
		if phase == "day" then
			Lighting.ClockTime = math.min(18, 6 + (DAY_LEN - phaseT) / DAY_LEN * 12)
			if phaseT == DAWN_WARN then
			end
			if phaseT <= 0 then
				phase = "night"; phaseT = NIGHT_LEN
				evNote:FireAllClients("ban", "🌙 กลางคืนแล้ว! ไข่แอบซ่อนตามเกาะ ออกเรือเลย!")
				spawnNightEggs()
			end
		else
			Lighting.ClockTime = math.max(0, 18 + (NIGHT_LEN - phaseT) / NIGHT_LEN * 12) % 24
			if phaseT <= 0 then
				phase = "day"; phaseT = DAY_LEN
				evNote:FireAllClients("ban", "🌅 เช้าแล้ว! รีไข่ใน " .. DAWN_WARN .. " วิ")
				task.wait(DAWN_WARN)
				clearEggs()
			end
		end
		evPhase:FireAllClients({ phase = phase, t = phaseT })
	end
end)

-- ---------- เก็บ/ถือ/ฟักไข่ ----------
local function tryPickup(plr, eggPart)
	local uid = plr.UserId
	if carrying[uid] then return end
	-- หาใน liveEggs
	local found
	for i, eg in ipairs(liveEggs) do
		if eg.egg == eggPart then found = i break end
	end
	if not found then return end
	local eg = liveEggs[found]
	table.remove(liveEggs, found)
	eg.model:Destroy()
	-- สร้างไข่ติดตัว
	local char = plr.Character if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") if not hrp then return end
	local m = Instance.new("Part"); m.Shape = Enum.PartType.Ball; m.Size = Vector3.new(2.4, 3, 2.4)
	m.Color = EGG_COLOR[TIER_OF_ISL[eg.isl]]; m.Anchored = false; m.CanCollide = false; m.Parent = char
	local w = Instance.new("Weld"); w.Part0 = hrp; w.Part1 = m; w.C0 = CFrame.new(0, -0.5, 2); w.Parent = m
	carrying[uid] = { isl = eg.isl, model = m }
	plr:SetAttribute("Carrying", eg.isl)
	local hum = char:FindFirstChild("Humanoid") if hum then hum.WalkSpeed = 14 end
	evNote:FireClient(plr, "pop", "🥚 เก็บไข่เกาะ " .. eg.isl .. "! เอาไปฟักที่สวนของคุณ")
end

local function hatchAt(plr)
	local uid = plr.UserId
	local c = carrying[uid] if not c then return end
	local d = DATA[uid] if not d then return end
	c.model:Destroy()
	carrying[uid] = nil
	plr:SetAttribute("Carrying", 0)
	local char = plr.Character
	local hum = char and char:FindFirstChild("Humanoid")
	if hum then hum.WalkSpeed = 16 end
	-- สุ่มสัตว์จากเกาะของไข่
	local pool = poolOf(c.isl)
	local got = pool[math.random(1, #pool)]
	table.insert(d.pets, got.id)
	d.index[c.isl] = d.index[c.isl] or {}
	local seen = 0
	for _, id in ipairs(d.index[c.isl]) do if id == got.id then seen += 1 end end
	if seen == 0 then table.insert(d.index[c.isl], got.id) end
	syncAttrs(plr)
	evNote:FireClient(plr, "pop", "🎉 ฟักได้ " .. got.name .. " [" .. got.rarity .. "] เข้าสวน!")
	-- เช็กดัชนีครบ → แจ้งไม้ (เฟส P3 ใช้)
	local need = #poolOf(c.isl)
	if #d.index[c.isl] >= need then
		plr:SetAttribute("Stick" .. c.isl, true)
		evNote:FireClient(plr, "ban", "🪵 ดัชนีเกาะ " .. c.isl .. " ครบ! คุณคู่ควรกับไม้ประจำเกาะ")
	end
end

-- สัมผัสไข่/เครื่องฟัก
task.spawn(function()
	while true do
		RunService.Heartbeat:Wait()
		for _, plr in ipairs(Players:GetPlayers()) do
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local p = hrp.Position
				-- ไข่สด
				if not carrying[plr.UserId] then
					for _, eg in ipairs(liveEggs) do
						if (eg.egg.Position - p).Magnitude < 6 then
							tryPickup(plr, eg.egg)
							break
						end
					end
				end
				-- เครื่องฟักประจำสวน
				local d = DATA[plr.UserId]
				if d and carrying[plr.UserId] then
					local inc = root:FindFirstChild("Incubator" .. d.slot)
					if inc and (inc.Position - p).Magnitude < 7 then
						hatchAt(plr)
					end
				end
			end
		end
	end
end)

-- ---------- ขึ้น/ลงเรือ + อัปเกรด ----------
evAct.OnServerEvent:Connect(function(plr, action)
	local uid = plr.UserId
	local d = DATA[uid] if not d then return end
	local c = coins(plr)
	if action == "board" then
		if boatOf[uid] then return end
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") if not hrp then return end
		for i, b in ipairs(boats) do
			if (b.pos - hrp.Position).Magnitude < 14 and not b.rider then
				b.rider = uid
				boatOf[uid] = i
				plr:SetAttribute("OnBoat", i)
				break
			end
		end
	elseif action == "leave" then
		local bi = boatOf[uid] if not bi then return end
		local b = boats[bi]
		b.rider = nil; b.throttle = 0; b.turn = 0
		boatOf[uid] = nil
		plr:SetAttribute("OnBoat", 0)
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then hrp.CFrame = b.cf * CFrame.new(6, 3, 0) end
	elseif action == "upboat" then
		local nl = d.boatLvl + 1
		local cost = BOAT_COST[nl]
		if cost and c and c.Value >= cost then
			c.Value -= cost; d.boatLvl = nl; d.coins = c.Value
			plr:SetAttribute("BoatLvl", nl)
			evNote:FireClient(plr, "pop", "⛵ เรืออัปเป็น x" .. math.floor(boatSpeed(nl)) .. "!")
		end
	elseif action == "upgarden" then
		local nl = d.gardenLvl + 1
		local cost = GARDEN_COST[nl]
		if cost and c and c.Value >= cost then
			c.Value -= cost; d.gardenLvl = nl; d.coins = c.Value
			plr:SetAttribute("GardenLvl", nl); plr:SetAttribute("Slots", slotsOf(d))
			evNote:FireClient(plr, "pop", "🏡 สวนขยาย! ช่องสัตว์ = " .. slotsOf(d))
		end
	end
end)

evIntro.OnServerEvent:Connect(function(plr)
	local d = DATA[plr.UserId] if not d then return end
	d.intro = true
	plr:SetAttribute("NeedIntro", false)
	save(plr)
end)

-- ---------- แอดมินแชท ----------
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
		local c = coins(plr)
		local function fb(t) evNote:FireClient(plr, "ban", "🛠️ " .. t) end
		if cmd == "/coins" then
			local n = math.floor(tonumber(arg) or 100000)
			if c then c.Value = math.clamp(c.Value + n, 0, 9000000000) fb("+" .. n) end
		elseif cmd == "/allpets" then
			local d = DATA[plr.UserId]
			for _, p in ipairs(PETS) do table.insert(d.pets, p.id) end
			syncAttrs(plr); fb("แจกครบ 11")
		elseif cmd == "/night" then
			phaseT = 1; fb("ข้ามไปกลางคืน")
		elseif cmd == "/day" then
			phase = "night"; phaseT = 1; fb("ข้ามไปเช้า")
		elseif cmd == "/kick" then
			local t = Players:FindFirstChild(arg)
			if t and t ~= plr then t:Kick("🛠️") end
		elseif cmd == "/say" then
			if arg ~= "" then evNote:FireAllClients("ban", arg:sub(1, 120)) end
		elseif cmd == "/reset" then
			local d = DATA[plr.UserId]
			d.pets = {}; d.coins = 150; d.boatLvl = 1; d.gardenLvl = 1; d.index = {}
			if c then c.Value = 150 end
			syncAttrs(plr); fb("รีเซ็ต")
		elseif cmd == "/help" then
			fb("/coins n · /allpets · /night · /day · /kick ชื่อ · /say ข้อความ · /reset")
		end
	end)
end
Players.PlayerAdded:Connect(wireAdminChat)
for _, p in ipairs(Players:GetPlayers()) do wireAdminChat(p) end

Lighting.ClockTime = 10
Lighting.Brightness = 1.5
Lighting.FogEnd = 4000
pcall(function() Lighting.Technology = Enum.Technology.Future end)
print("GAMECORE3 READY")
]=]
local GUI = [=[ 
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
]=]
local INTRO = [=[ 
-- ============================================================
-- ⛵ EGG ISLE v3 · Intro3 (LocalScript → StarterPlayerScripts)
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
skip.Font = Enum.Font.GothamBlack; skip.TextScaled = true; skip.Text = "ข้าม ⏭️"
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
	say("🌊 หลังการเดินทางอันยาวนาน... ทะเลแห่งเกาะไข่ก็อยู่ตรงหน้า")
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
	say("🐲 ผู้พิทักษ์แห่งเกาะอเวจี!! มันจำหน้าผู้บุกรุกได้แม่นยำ!")
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
	say("💥 ตู้ม!! เรือแตกแล้ว—!")
	TweenService:Create(hull, TweenInfo.new(0.7), { Position = base + Vector3.new(-6, 0, -4), Rotation = Vector3.new(30, 0, 40) }):Play()
	TweenService:Create(deck, TweenInfo.new(0.7), { Position = base + Vector3.new(5, 1, -2), Rotation = Vector3.new(-20, 0, -35) }):Play()
	TweenService:Create(sail, TweenInfo.new(0.9), { Position = base + Vector3.new(2, 3, -8), Rotation = Vector3.new(60, 20, 0) }):Play()
	for i = 1, 16 do
		cam.CFrame = cam.CFrame * CFrame.new(math.random() * 0.6 - 0.3, math.random() * 0.6 - 0.3, 0)
		task.wait(0.04)
	end
	if done then return end
	-- 5) จม
	say("🫧 ตุ๊บ... ตุ๊บ... (ทุกอย่างมืดลง)")
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
	wel.Text = "🥚 ยินดีต้อนรับสู่ Egg Isle! กลางคืนนี้... ออกเรือไปหาไข่ใบแรกของคุณเถอะ"
	local g2 = Instance.new("ScreenGui"); g2.Parent = plr.PlayerGui; wel.Parent = g2
	task.delay(5, function() g2:Destroy() end)
end)
]=]
local toolbar = plugin:CreateToolbar("EggIsle")
local btn = toolbar:CreateButton("Load EggIsle", "Put latest v3 code into the game", "")
btn.Click:Connect(function()
	local ss = game:GetService("ServerScriptService")
	local s = ss:FindFirstChild("Script")
	if not s then s = Instance.new("Script"); s.Name = "Script"; s.Parent = ss end
	s.Source = CORE
	local sp = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
	local l = sp:FindFirstChild("LocalScript")
	if not l then l = Instance.new("LocalScript"); l.Name = "LocalScript"; l.Parent = sp end
	l.Source = GUI
	local it = sp:FindFirstChild("Intro")
	if not it then it = Instance.new("LocalScript"); it.Name = "Intro"; it.Parent = sp end
	it.Source = INTRO
	local mb = ss:FindFirstChild("MapBuilder") if mb then mb:Destroy() end
	local ag = sp:FindFirstChild("AdminGui") if ag then ag:Destroy() end
	print("EGG ISLE v3 LOADED OK")
end)
