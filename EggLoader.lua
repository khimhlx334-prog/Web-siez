-- EGG ISLE v4 LOADER (plugin) — กดปุ่ม Load EggIsle ในแถบเครื่องมือ
local CORE = [=[
-- ============================================================
-- EGG ISLE v4 · GameCore4 (Script → ServerScriptService)
-- ลูปขโมยไข่: เงิน$ · ไข่มีน้ำหนัก · ถือ=กดค้าง · การ์ด/ฟิวส์/เทรล/หีบ/ลีดเดอร์บอร์ด
-- เซิร์ฟเวอร์ตัดสินทุกอย่าง กันโปร 100%
-- ============================================================
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Http = game:GetService("HttpService")
local WS = game:GetService("Workspace")

local store = DataStoreService:GetDataStore("EggIsleV4")

local function killOld(name) local o = script.Parent:FindFirstChild(name) if o then o:Destroy() end end
killOld("MapBuilder")

-- ---------- สัตว์ 11 ชนิด ----------
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
local WEIGHT = { ["ธรรมดา"] = 10, ["ไม่ธรรมดา"] = 20, ["หายาก"] = 40, ["มหากาพย์"] = 80, ["ตำนาน"] = 150 }
local SELL_VALUE = { ["ธรรมดา"] = 50, ["ไม่ธรรมดา"] = 150, ["หายาก"] = 500, ["มหากาพย์"] = 2000, ["ตำนาน"] = 10000 }
local TRAILS = {
	{ name = "เทรลลมเขียว", mult = 1.5, cost = 2500, color = Color3.fromRGB(80, 220, 90) },
	{ name = "เทรลน้ำแข็ง", mult = 2, cost = 10000, color = Color3.fromRGB(120, 200, 255) },
	{ name = "เทรลเพลิง", mult = 2.5, cost = 40000, color = Color3.fromRGB(255, 120, 50) },
}
local function petById(id) for _, p in ipairs(PETS) do if p.id == id then return p end end end
local function poolOf(isl)
	local t = {}
	for _, p in ipairs(PETS) do if p.isl == isl then table.insert(t, p) end end
	return t
end
local function entryPower(en)
	local base, big = en, false
	if base:sub(1, 3) == "BIG" then big = true; base = base:sub(4) end
	local p = petById(base)
	return p and p.power * (big and 2 or 1) or 0
end
local function entryWeight(en)
	local base, big = en, false
	if base:sub(1, 3) == "BIG" then big = true; base = base:sub(4) end
	local p = petById(base)
	return p and WEIGHT[p.rarity] * (big and 1.5 or 1) or 10
end

-- ---------- เกาะ ----------
local ISLANDS = {
	{ n = 1, pos = Vector3.new(0, 0, 0), r = 90, grass = Color3.fromRGB(95, 190, 60), label = "เกาะเริ่มต้น", rec = 0 },
	{ n = 2, pos = Vector3.new(500, 0, 0), r = 120, grass = Color3.fromRGB(110, 200, 70), label = "เกาะทุ่งหญ้า", rec = 24 },
	{ n = 3, pos = Vector3.new(-500, 0, 300), r = 130, grass = Color3.fromRGB(220, 190, 110), label = "เกาะทะเลทราย", rec = 36 },
	{ n = 4, pos = Vector3.new(300, 0, -700), r = 140, grass = Color3.fromRGB(200, 230, 245), label = "เกาะน้ำแข็ง", rec = 54 },
	{ n = 5, pos = Vector3.new(-400, 0, -1100), r = 150, grass = Color3.fromRGB(110, 85, 150), label = "เกาะอเวจี", rec = 81 },
}
local EGG_COUNT = { [2] = 6, [3] = 5, [4] = 4, [5] = 3 }

-- ---------- รีโมต ----------
local function ev(name) local r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = ReplicatedStorage; return r end
local evNote = ev("Note")     -- (kind, text) kind: "ban","pop","admin"
local evPhase = ev("Phase")
local evBoatIn = ev("BoatIn")
local evAct = ev("Act")
local evPick = ev("Pick")     -- (eggPart) หลังกดค้างครบ
local evIntro = ev("IntroDone")

-- ---------- สถานะ ----------
local DATA = {}
local gardens = {}
local carrying = {} -- [uid] = {model, pet, weight}
local boatOf = {}

local BOAT_COST = { [2] = 1000, [3] = 5000, [4] = 25000, [5] = 100000 }
local GARDEN_COST = { [2] = 500, [3] = 2500, [4] = 10000, [5] = 50000, [6] = 200000 }
local function boatSpeed(lvl) return 16 * math.pow(1.5, lvl - 1) end
local function slotsOf(d) return 2 + d.gardenLvl end
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

local function syncAttrs(plr)
	local d = DATA[plr.UserId] if not d then return end
	plr:SetAttribute("BoatLvl", d.boatLvl)
	plr:SetAttribute("GardenLvl", d.gardenLvl)
	plr:SetAttribute("Slots", slotsOf(d))
	plr:SetAttribute("TrailLvl", d.trail or 0)
	local counts = {}
	for _, en in ipairs(d.pets) do counts[en] = (counts[en] or 0) + 1 end
	plr:SetAttribute("PetsJSON", Http:JSONEncode(counts))
	plr:SetAttribute("IndexJSON", Http:JSONEncode(d.index))
end

Players.PlayerAdded:Connect(function(plr)
	local ls = Instance.new("Folder"); ls.Name = "leaderstats"; ls.Parent = plr
	local cash = Instance.new("IntValue"); cash.Name = "Money"; cash.Value = 0; cash.Parent = ls

	local d = { money = 150, pets = {}, boatLvl = 1, gardenLvl = 1, index = {}, intro = false, trail = 0, trailsOwned = {}, lastGift = 0 }
	local ok, got = pcall(function() return store:GetAsync("u_" .. plr.UserId) end)
	if ok and type(got) == "table" then for k, v in pairs(got) do d[k] = v end end
	d.money = d.money or 150
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
	syncAttrs(plr)
	task.spawn(function() while DATA[plr.UserId] do task.wait(5) d.money = cash.Value save(plr) end end)
	charConnect(plr)
end)

function charConnect(plr)
	plr.CharacterAdded:Connect(function() task.wait(0.1) applyWalk(plr) end)
end

Players.PlayerRemoving:Connect(function(plr)
	save(plr)
	for i = 1, 6 do if gardens[i] == plr.UserId then gardens[i] = nil end end
	local c = carrying[plr.UserId]
	if c then c.model:Destroy() carrying[plr.UserId] = nil end
	DATA[plr.UserId] = nil
end)
game:BindToClose(function() for _, p in ipairs(Players:GetPlayers()) do save(p) end end)

local function money(plr) local ls = plr:FindFirstChild("leaderstats") return ls and ls.Money end

-- ---------- รายได้สวน ----------
task.spawn(function()
	while true do
		task.wait(1)
		for _, plr in ipairs(Players:GetPlayers()) do
			local d = DATA[plr.UserId] if d then
				local pows = {}
				for _, en in ipairs(d.pets) do local pw = entryPower(en) if pw > 0 then table.insert(pows, pw) end end
				table.sort(pows, function(a, b) return a > b end)
				local sum = 0
				for i = 1, math.min(slotsOf(d), #pows) do sum += pows[i] end
				plr:SetAttribute("Income", sum)
				if sum > 0 then local c = money(plr) if c then c.Value += sum end end
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
	local grassTop = cyl(isl.r, 7, isl.pos + Vector3.new(0, 3.4, 0), isl.grass, Enum.Material.Grass)
	spots[isl.n] = {}
	if isl.n == 1 then
		local sp = part(Vector3.new(14, 1, 14), isl.pos + Vector3.new(0, top + 0.4, 20), Color3.fromRGB(255, 220, 120), Enum.Material.Slate)
		sp.Name = "Spawn3"
		-- ลายตารางหญ้าสไตล์ซิม (เกาะเริ่มต้น)
		local cell = 18
		for gx = -4, 4 do for gz = -4, 4 do
			local px, pz = gx * cell, gz * cell
			if math.sqrt(px * px + pz * pz) < isl.r - 8 and (gx + gz) % 2 == 0 then
				part(Vector3.new(cell, 0.15, cell), isl.pos + Vector3.new(px, top + 0.08, pz), Color3.fromRGB(70, 165, 45), Enum.Material.Grass, false)
			end
		end end
		-- สวน 6 แปลง + เครื่องฟัก
		local gpos = { Vector3.new(-30, 0, -20), Vector3.new(0, 0, -20), Vector3.new(30, 0, -20), Vector3.new(-30, 0, -48), Vector3.new(0, 0, -48), Vector3.new(30, 0, -48) }
		for i, gp in ipairs(gpos) do
			local base = part(Vector3.new(14, 0.6, 14), isl.pos + gp + Vector3.new(0, top + 0.2, 0), Color3.fromRGB(120, 90, 60), Enum.Material.Wood)
			base.Name = "Garden" .. i
			sign3d(base, "สวน " .. i, 120, 40)
			local inc = part(Vector3.new(3, 4, 3), isl.pos + gp + Vector3.new(5, top + 2.5, -4), Color3.fromRGB(80, 130, 200), Enum.Material.Metal)
			inc.Name = "Incubator" .. i
			sign3d(inc, "เครื่องฟัก", 110, 36)
		end
		-- หีบฟรี + ป้ายลีดเดอร์บอร์ด (โครง)
		local chest = part(Vector3.new(4, 3, 3), isl.pos + Vector3.new(20, top + 1.5, 20), Color3.fromRGB(255, 200, 60), Enum.Material.Metal)
		chest.Name = "GiftChest"
		sign3d(chest, "หีบฟรี", 100, 40, Color3.fromRGB(255, 240, 150))
		local board = part(Vector3.new(14, 12, 1), isl.pos + Vector3.new(-20, top + 7, 20), Color3.fromRGB(60, 140, 220), Enum.Material.Metal)
		board.Name = "LeaderBoard3D"
		sign3d(board, "เงินมากที่สุด/วินาที", 260, 50, Color3.fromRGB(255, 255, 255))
		-- ท่าเรือ
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
		sign3d(post, "เกาะ " .. isl.n .. " " .. isl.label .. "\nความเร็วแนะนำสำหรับขโมย: x" .. isl.rec, 260, 90, Color3.fromRGB(255, 240, 150))
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
	sign3d(flag, "เรือ " .. i, 90, 40)
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
				b.heading += b.turn * 1.6 * dt
				local fwd = Vector3.new(math.sin(b.heading), 0, math.cos(b.heading))
				b.pos += fwd * sp * b.throttle * dt
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

-- ============================================================
-- กลางวัน/กลางคืน + ไข่
-- ============================================================
local DAY_LEN, NIGHT_LEN, DAWN_WARN = 180, 240, 20
local phase = "day"
local phaseT = DAY_LEN
local liveEggs = {}
local EGG_COLOR = { ["ธรรมดา"] = Color3.fromRGB(245, 245, 240), ["หายาก"] = Color3.fromRGB(120, 180, 255), ["มหากาพย์"] = Color3.fromRGB(190, 120, 255), ["ตำนาน"] = Color3.fromRGB(255, 190, 60) }

local function makeEgg(isl, pos, petId, weight)
	local p = petById(petId)
	local g = Instance.new("Folder"); g.Parent = root
	cyl(2, 1, pos + Vector3.new(0, 0.5, 0), Color3.fromRGB(120, 100, 80), Enum.Material.Slate)
	local e = ball(Vector3.new(3, 4, 3), pos + Vector3.new(0, 2.6, 0), EGG_COLOR[p.rarity], Enum.Material.SmoothPlastic)
	e.Name = "EggLive"
	e.CanTouch = false
	if p.rarity == "ตำนาน" or p.rarity == "มหากาพย์" then
		local li = Instance.new("PointLight"); li.Color = EGG_COLOR[p.rarity]; li.Range = 30; li.Brightness = 3; li.Parent = e
	end
	sign3d(e, weight .. " กก.", 90, 40)
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
				local pet = pool[math.random(1, #pool)]
				makeEgg(isl, s, pet.id, WEIGHT[pet.rarity])
				if isl == 5 then evNote:FireAllClients("ban", "ไข่ตำนานปรากฏที่เกาะ 5 เกาะอเวจี!") end
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
		phaseT -= 1
		if phase == "day" then
			Lighting.ClockTime = math.min(18, 6 + (DAY_LEN - phaseT) / DAY_LEN * 12)
			if phaseT <= 0 then
				phase = "night"; phaseT = NIGHT_LEN
				evNote:FireAllClients("ban", "กลางคืนแล้ว! ไข่แอบซ่อนตามเกาะ ออกเรือเลย!")
				spawnNightEggs()
			end
		else
			Lighting.ClockTime = (18 + (NIGHT_LEN - phaseT) / NIGHT_LEN * 12) % 24
			if phaseT <= 0 then
				phase = "day"; phaseT = DAY_LEN
				evNote:FireAllClients("ban", "เช้าแล้ว! รีไข่ทั้งหมดใน " .. DAWN_WARN .. " วินาที")
				task.wait(DAWN_WARN)
				clearEggs()
			end
		end
		evPhase:FireAllClients({ phase = phase, t = phaseT })
	end
end)

-- ---------- เก็บไข่ (กดค้างฝั่ง client → เรียก Pick) ----------
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
	m.Color = EGG_COLOR[petById(eg.pet).rarity]; m.CanCollide = false; m.Parent = char
	local w = Instance.new("Weld"); w.Part0 = hrp; w.Part1 = m; w.C0 = CFrame.new(0, -0.5, 2); w.Parent = m
	carrying[uid] = { model = m, pet = eg.pet, weight = eg.weight, isl = eg.isl }
	plr:SetAttribute("Carrying", eg.isl)
	plr:SetAttribute("CarryWeight", eg.weight)
	applyWalk(plr)
	evNote:FireClient(plr, "pop", "ถือไข่ " .. eg.weight .. " กก. — กลับไปฟักที่สวนของคุณ!")
end)

local function hatchAt(plr)
	local uid = plr.UserId
	local c = carrying[uid] if not c then return end
	local d = DATA[uid] if not d then return end
	c.model:Destroy(); carrying[uid] = nil
	plr:SetAttribute("Carrying", 0); plr:SetAttribute("CarryWeight", 0)
	applyWalk(plr)
	table.insert(d.pets, c.pet)
	local p = petById(c.pet)
	d.index[p.isl] = d.index[p.isl] or {}
	local seen = false
	for _, id in ipairs(d.index[p.isl]) do if id == c.pet then seen = true end end
	if not seen then table.insert(d.index[p.isl], c.pet) end
	syncAttrs(plr)
	evNote:FireClient(plr, "pop", "ฟักได้ " .. p.name .. " [" .. p.rarity .. "] เข้าสวน!")
	if #d.index[p.isl] >= #poolOf(p.isl) then
		evNote:FireClient(plr, "ban", "ดัชนีเกาะ " .. p.isl .. " ครบ! คุณคู่ควรกับไม้ประจำเกาะ")
	end
end

-- สัมผัสเครื่องฟัก
task.spawn(function()
	while true do
		RunService.Heartbeat:Wait()
		for _, plr in ipairs(Players:GetPlayers()) do
			local d = DATA[plr.UserId]
			local c = carrying[plr.UserId]
			if d and c then
				local char = plr.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					local inc = root:FindFirstChild("Incubator" .. d.slot)
					if inc and (inc.Position - hrp.Position).Magnitude < 7 then hatchAt(plr) end
				end
			end
		end
	end
end)

-- ---------- ขึ้น/ลงเรือ + ร้าน + ฟิวส์ + ขาย + เทรล + หีบ ----------
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
	elseif action == "upboat" then
		local nl = d.boatLvl + 1
		local cost = BOAT_COST[nl]
		if cost and c and c.Value >= cost then
			c.Value -= cost; d.boatLvl = nl
			plr:SetAttribute("BoatLvl", nl)
			evNote:FireClient(plr, "pop", "เรืออัปเป็นความเร็ว x" .. math.floor(boatSpeed(nl)) .. "!")
		end
	elseif action == "upgarden" then
		local nl = d.gardenLvl + 1
		local cost = GARDEN_COST[nl]
		if cost and c and c.Value >= cost then
			c.Value -= cost; d.gardenLvl = nl
			plr:SetAttribute("GardenLvl", nl); plr:SetAttribute("Slots", slotsOf(d))
			evNote:FireClient(plr, "pop", "สวนขยาย! ช่องสัตว์ = " .. slotsOf(d))
		end
	elseif action == "fuse" then
		local id = tostring(arg or "")
		local cnt = 0
		for _, en in ipairs(d.pets) do if en == id then cnt += 1 end end
		if cnt >= 3 and petById(id) then
			local removed = 0; local np = {}
			for _, en in ipairs(d.pets) do
				if en == id and removed < 3 then removed += 1 else table.insert(np, en) end
			end
			d.pets = np
			table.insert(d.pets, "BIG" .. id)
			syncAttrs(plr)
			evNote:FireClient(plr, "pop", "ฟิวส์สำเร็จ! " .. petById(id).name .. " กลายร่างยักษ์ พลัง x2")
		end
	elseif action == "sell" then
		local en = tostring(arg or "")
		for i, x in ipairs(d.pets) do
			if x == en then
				table.remove(d.pets, i)
				local base, big = en, false
				if base:sub(1, 3) == "BIG" then big = true; base = base:sub(4) end
				local p = petById(base)
				local val = SELL_VALUE[p.rarity] * (big and 3 or 1)
				if c then c.Value += val end
				syncAttrs(plr)
				evNote:FireClient(plr, "pop", "ขาย " .. p.name .. (big and "ยักษ์" or "") .. " +$" .. val)
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
				c.Value -= t.cost
				d.trailsOwned = d.trailsOwned or {}
				table.insert(d.trailsOwned, i)
				owned = true
			else
				return
			end
		end
		d.trail = i
		plr:SetAttribute("TrailLvl", i)
		applyWalk(plr)
		evNote:FireClient(plr, "pop", "สวม " .. t.name .. " ความเร็วเดิน x" .. t.mult)
	elseif action == "gift" then
		local now = os.time()
		if now - (d.lastGift or 0) >= 72000 then
			d.lastGift = now
			if c then c.Value += 750 end
			evNote:FireClient(plr, "pop", "เปิดหีบฟรี! +$750")
		else
			evNote:FireClient(plr, "pop", "หีบฟรีอีก " .. math.floor((72000 - (now - d.lastGift)) / 3600) .. " ชม.")
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
		local function fb(t) evNote:FireClient(plr, "admin", t) end
		if cmd == "/money" or cmd == "/coins" then
			local n = math.floor(tonumber(arg) or 100000)
			if c then c.Value = math.clamp(c.Value + n, 0, 9000000000) fb("เติม $" .. n) end
		elseif cmd == "/allpets" then
			local d = DATA[plr.UserId]
			for _, p in ipairs(PETS) do table.insert(d.pets, p.id) end
			syncAttrs(plr); fb("แจกครบ 11 ชนิด")
		elseif cmd == "/egg" then
			-- /egg <id> [น้ำหนัก] เสกไข่ที่ตัวแอดมินให้ผู้เล่นแย่งกัน
			local id, w = arg:match("^(%S+)%s*(%S*)")
			local p = petById(id)
			if p then
				local weight = tonumber(w) or WEIGHT[p.rarity]
				weight = math.clamp(weight, 5, 500)
				local char = plr.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					makeEgg(p.isl, hrp.Position + Vector3.new(3, 0, 3), id, weight)
					evNote:FireAllClients("admin", plr.Name .. " เสกไข่ " .. p.name .. " (" .. weight .. " กก.) — แย่งกัน!")
				end
			else
				fb("ไม่รู้จัก id: " .. tostring(id))
			end
		elseif cmd == "/night" then
			phaseT = 1; fb("ข้ามไปกลางคืน")
		elseif cmd == "/day" then
			phase = "night"; phaseT = 1; fb("ข้ามไปเช้า")
		elseif cmd == "/kick" then
			local t = Players:FindFirstChild(arg)
			if t and t ~= plr then t:Kick("ถูกเตะโดยผู้ดูแล") end
		elseif cmd == "/say" then
			if arg ~= "" then evNote:FireAllClients("admin", arg:sub(1, 120)) end
		elseif cmd == "/reset" then
			local d = DATA[plr.UserId]
			d.pets = {}; d.money = 150; d.boatLvl = 1; d.gardenLvl = 1; d.index = {}; d.trail = 0
			if c then c.Value = 150 end
			syncAttrs(plr); fb("รีเซ็ตเซฟ")
		elseif cmd == "/help" then
			fb("/money n · /egg id [กก.] · /allpets · /night /day · /kick ชื่อ · /say ข้อความ · /reset")
		end
	end)
end
Players.PlayerAdded:Connect(wireAdminChat)
for _, p in ipairs(Players:GetPlayers()) do wireAdminChat(p) end

Lighting.ClockTime = 10
Lighting.Brightness = 1.5
Lighting.FogEnd = 4000
pcall(function() Lighting.Technology = Enum.Technology.Future end)
print("GAMECORE4 READY")
]=]
local GUI = [=[
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
]=]
local INTRO = [=[
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
]=]
local toolbar = plugin:CreateToolbar("EggIsle")
local btn = toolbar:CreateButton("Load EggIsle", "Put latest v4 code into the game", "")
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
	print("EGG ISLE v4 LOADED OK")
end)
