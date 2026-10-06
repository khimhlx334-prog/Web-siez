-- EGG ISLE v6 LOADER (plugin) — กดปุ่ม Load EggIsle ในแถบเครื่องมือ
local CORE = [=[
-- ============================================================
-- EGG ISLE v6 · GameCore6 (Script → ServerScriptService)
-- Money $ · weight eggs + hold-3s pickup · fuse/trail/chest/sell
-- 8 garden slots + bag · 3 leaderboards · Robux tracking · i18n keys
-- v6: guardians (rarest pet per island) · weight x income · spawn odds · tutorial
-- ============================================================
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Http = game:GetService("HttpService")
local MPS = game:GetService("MarketplaceService")
local WS = game:GetService("Workspace")

local store = DataStoreService:GetDataStore("EggIsleV6")

local function killOld(name) local o = script.Parent:FindFirstChild(name) if o then o:Destroy() end end
killOld("MapBuilder")

-- ---------- pets (canonical rarity ids) ----------
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
}
local WEIGHT = { common = 10, uncommon = 20, rare = 40, epic = 80, legendary = 150 }
local SELL_VALUE = { common = 50, uncommon = 150, rare = 500, epic = 2000, legendary = 10000 }
local TRAILS = {
	{ mult = 1.5, cost = 2500, color = Color3.fromRGB(80, 220, 90) },
	{ mult = 2, cost = 10000, color = Color3.fromRGB(120, 200, 255) },
	{ mult = 2.5, cost = 40000, color = Color3.fromRGB(255, 120, 50) },
}
-- ---------- สมดุล: โอกาสเกิดไข่ต่อระดับ (ปรับได้ที่นี่) ----------
local SPAWN_W = { common = 60, uncommon = 30, rare = 16, epic = 7, legendary = 3 }
-- สัตว์หายากกว่า = เงินเยอะกว่า (power) · น้ำหนักไข่คูณเงินอีก 0.8x-1.6x · ยักษ์ x2
local PET_COLOR = {
	cat = Color3.fromRGB(255, 150, 60), dog = Color3.fromRGB(220, 180, 120), rab = Color3.fromRGB(250, 250, 250),
	pan = Color3.fromRGB(60, 60, 65), cap = Color3.fromRGB(150, 105, 70), ele = Color3.fromRGB(255, 150, 190),
	lio = Color3.fromRGB(255, 200, 80), dra = Color3.fromRGB(140, 220, 255), uni = Color3.fromRGB(255, 255, 255),
	gld = Color3.fromRGB(255, 200, 60), phx = Color3.fromRGB(255, 110, 40),
}
local function petById(id) for _, p in ipairs(PETS) do if p.id == id then return p end end end
local function poolOf(isl)
	local t = {}
	for _, p in ipairs(PETS) do if p.isl == isl then table.insert(t, p) end end
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
-- entry = "id@น้ำหนัก" หรือ "BIGid@น้ำหนัก"
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

-- ---------- islands ----------
local ISLANDS = {
	{ n = 1, pos = Vector3.new(0, 0, 0), r = 90, grass = Color3.fromRGB(95, 190, 60), label = "Start Island", rec = 0 },
	{ n = 2, pos = Vector3.new(500, 0, 0), r = 120, grass = Color3.fromRGB(110, 200, 70), label = "Grass Isle", rec = 24 },
	{ n = 3, pos = Vector3.new(-500, 0, 300), r = 130, grass = Color3.fromRGB(220, 190, 110), label = "Desert Isle", rec = 36 },
	{ n = 4, pos = Vector3.new(300, 0, -700), r = 140, grass = Color3.fromRGB(200, 230, 245), label = "Ice Isle", rec = 54 },
	{ n = 5, pos = Vector3.new(-400, 0, -1100), r = 150, grass = Color3.fromRGB(110, 85, 150), label = "Shadow Isle", rec = 81 },
}
local EGG_COUNT = { [2] = 6, [3] = 5, [4] = 4, [5] = 3 }

-- ---------- remotes ----------
local function ev(name) local r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = ReplicatedStorage; return r end
local evNote = ev("Note")     -- (kind, key, a, b, c)
local evPhase = ev("Phase")
local evBoatIn = ev("BoatIn")
local evAct = ev("Act")
local evPick = ev("Pick")
local evIntro = ev("IntroDone")

-- ---------- state ----------
local DATA = {}
local gardens = {}
local carrying = {}
local boatOf = {}

local BOAT_COST = { [2] = 1000, [3] = 5000, [4] = 25000, [5] = 100000 }
local GARDEN_COST = { [2] = 500, [3] = 2500, [4] = 10000, [5] = 50000, [6] = 200000 }
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
end

local function charConnect(plr)
	plr.CharacterAdded:Connect(function() task.wait(0.1) applyWalk(plr) end)
end

Players.PlayerAdded:Connect(function(plr)
	local ls = Instance.new("Folder"); ls.Name = "leaderstats"; ls.Parent = plr
	local cash = Instance.new("IntValue"); cash.Name = "Money"; cash.Value = 0; cash.Parent = ls

	local d = { money = 150, pets = {}, boatLvl = 1, gardenLvl = 1, index = {}, intro = false, trail = 0, trailsOwned = {}, lastGift = 0, playSec = 0, robuxSpent = 0, tut = false }
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
	DATA[plr.UserId] = nil
end)
game:BindToClose(function() for _, p in ipairs(Players:GetPlayers()) do save(p) end end)

local function money(plr) local ls = plr:FindFirstChild("leaderstats") return ls and ls.Money end

-- ---------- Robux products: track spending + grant money ----------
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

-- ---------- garden income + live board attrs ----------
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
-- world
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
	-- checkered texture tiles on EVERY island (our palette)
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
		local gpos = { Vector3.new(-30, 0, -20), Vector3.new(0, 0, -20), Vector3.new(30, 0, -20), Vector3.new(-30, 0, -48), Vector3.new(0, 0, -48), Vector3.new(30, 0, -48) }
		for i, gp in ipairs(gpos) do
			local base = part(Vector3.new(14, 0.6, 14), isl.pos + gp + Vector3.new(0, top + 0.2, 0), Color3.fromRGB(120, 90, 60), Enum.Material.Wood)
			base.Name = "Garden" .. i
			sign3d(base, "Garden " .. i, 120, 40)
			local inc = part(Vector3.new(3, 4, 3), isl.pos + gp + Vector3.new(5, top + 2.5, -4), Color3.fromRGB(80, 130, 200), Enum.Material.Metal)
			inc.Name = "Incubator" .. i
			sign3d(inc, "Incubator", 110, 36)
		end
		local chest = part(Vector3.new(4, 3, 3), isl.pos + Vector3.new(20, top + 1.5, 20), Color3.fromRGB(255, 200, 60), Enum.Material.Metal)
		chest.Name = "GiftChest"
		sign3d(chest, "Free Chest", 100, 40, Color3.fromRGB(255, 240, 150))
		-- 3 leaderboard boards
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

-- ---------- boats ----------
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

-- ============================================================
-- ผู้พิทักษ์: สัตว์หายากสุดของแต่ละเกาะ ไล่จับคนถือไข่แล้วเอาไข่คืน
-- ============================================================
local RANK = { common = 1, uncommon = 2, rare = 3, epic = 4, legendary = 5 }
local GUARD_PET = {}
for isl = 2, 5 do
	local best = nil
	for _, p in ipairs(PETS) do
		if p.isl == isl and (not best or RANK[p.rarity] > RANK[best.rarity]) then best = p end
	end
	GUARD_PET[isl] = best.id
end
local guardians = {}
local function weldTo(a, b, c0)
	local w = Instance.new("Weld"); w.Part0 = a; w.Part1 = b; w.C0 = c0; w.Parent = a
end
local function buildGuardian(isl)
	local id = GUARD_PET[isl]
	local col = PET_COLOR[id] or Color3.fromRGB(120, 120, 130)
	local islD = ISLANDS[isl]
	local top = 8
	local g0 = Instance.new("Folder"); g0.Name = "Guardian" .. isl; g0.Parent = root
	local body = part(Vector3.new(7, 4, 10), islD.pos + Vector3.new(0, top + 4, 0), col, Enum.Material.SmoothPlastic, false)
	body.Name = "GBody"
	local head = part(Vector3.new(4.5, 4.5, 4.5), islD.pos + Vector3.new(0, top + 6, 6.5), col, Enum.Material.SmoothPlastic, false)
	head.Name = "GHead"
	head:SetAttribute("Pet", id)
	head:SetAttribute("Isle", isl)
	weldTo(body, head, CFrame.new(0, 2, 6.5))
	for _, lp in ipairs({ Vector3.new(-2.5, -2.5, 3.5), Vector3.new(2.5, -2.5, 3.5), Vector3.new(-2.5, -2.5, -3.5), Vector3.new(2.5, -2.5, -3.5) }) do
		local leg = part(Vector3.new(1.6, 3, 1.6), islD.pos + lp + Vector3.new(0, top + 2, 0), col, Enum.Material.SmoothPlastic, false)
		weldTo(body, leg, CFrame.new(lp.X, lp.Y, lp.Z))
	end
	local earL = part(Vector3.new(1, 2, 0.6), islD.pos + Vector3.new(-1.5, top + 8.5, 6.5), col, Enum.Material.SmoothPlastic, false)
	weldTo(body, earL, CFrame.new(-1.5, 4.5, 6.5))
	local earR = part(Vector3.new(1, 2, 0.6), islD.pos + Vector3.new(1.5, top + 8.5, 6.5), col, Enum.Material.SmoothPlastic, false)
	weldTo(body, earR, CFrame.new(1.5, 4.5, 6.5))
	local li = Instance.new("PointLight"); li.Color = col; li.Range = 28; li.Brightness = 2; li.Parent = body
	guardians[isl] = { body = body, pos = Vector3.new(0, 0, 0), heading = 0, patrol = nil, cool = 0 }
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
			-- หาเหยื่อ: คนที่ถือไข่ของเกาะนี้ อยู่ในเกาะ และผู้พิทักษ์มองเห็น
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
				speed = math.min(22, carrySpeed(victimW) + 6) -- ถือไข่หนักยิ่งหนีช้า ผู้พิทักษ์ก็ไล่ทันง่ายขึ้น
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
			g.body.CFrame = CFrame.new(islD.pos + g.pos + Vector3.new(0, top + 4, 0)) * CFrame.Angles(0, g.heading, 0)
			-- จับได้: แย่งไข่คืนรัง
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
					makeEgg(isl, ss[math.random(1, #ss)], c.pet, c.weight) -- ไข่คืนรัง
					g.cool = 6
					g.patrol = nil
				end
			end
		end
	end
end)

-- ============================================================
-- day/night + eggs
-- ============================================================
local DAY_LEN, NIGHT_LEN, DAWN_WARN = 180, 240, 20
local phase = "day"
local phaseT = DAY_LEN
local liveEggs = {}
local EGG_COLOR = { common = Color3.fromRGB(245, 245, 240), rare = Color3.fromRGB(120, 180, 255), epic = Color3.fromRGB(190, 120, 255), legendary = Color3.fromRGB(255, 190, 60) }
local function eggColor(r) return EGG_COLOR[r] or EGG_COLOR.common end

local function makeEgg(isl, pos, petId, weight)
	local p = petById(petId)
	local g = Instance.new("Folder"); g.Parent = root
	cyl(2, 1, pos + Vector3.new(0, 0.5, 0), Color3.fromRGB(120, 100, 80), Enum.Material.Slate)
	local e = ball(Vector3.new(3, 4, 3), pos + Vector3.new(0, 2.6, 0), eggColor(p.rarity), Enum.Material.SmoothPlastic)
	e.Name = "EggLive"
	e.CanTouch = false
	if p.rarity == "legendary" or p.rarity == "epic" then
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
				local pet = pickWeighted(pool) -- ถ่วงน้ำหนักตาม SPAWN_W
				local bw = WEIGHT[pet.rarity]
				local w = math.floor(bw * (0.8 + math.random() * 0.8) * 10) / 10 -- 0.8x-1.6x
				makeEgg(isl, s, pet.id, w)
				if pet.rarity == "legendary" then evNote:FireAllClients("ban", "legend") end
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

-- ---------- pickup (client holds 3s then calls Pick) ----------
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

local function hatchAt(plr)
	local uid = plr.UserId
	local c = carrying[uid] if not c then return end
	local d = DATA[uid] if not d then return end
	c.model:Destroy(); carrying[uid] = nil
	plr:SetAttribute("Carrying", 0); plr:SetAttribute("CarryWeight", 0)
	applyWalk(plr)
	table.insert(d.pets, c.pet .. "@" .. c.weight)
	local p = petById(c.pet)
	d.index[p.isl] = d.index[p.isl] or {}
	local seen = false
	for _, id in ipairs(d.index[p.isl]) do if id == c.pet then seen = true end end
	if not seen then table.insert(d.index[p.isl], c.pet) end
	syncAttrs(plr)
	evNote:FireClient(plr, "pop", "hatch", c.pet, p.rarity)
	if #d.index[p.isl] >= #poolOf(p.isl) then
		evNote:FireClient(plr, "ban", "idx_done", p.isl)
	end
end

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

-- ---------- actions ----------
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
			sumW = math.floor(sumW * 10) / 10
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
				owned = true
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

-- ---------- admin ----------
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
			for _, p in ipairs(PETS) do table.insert(d.pets, p.id) end
			syncAttrs(plr); fb("allpets")
		elseif cmd == "/egg" then
			local id, w = arg:match("^(%S+)%s*(%S*)")
			local p = petById(id)
			if p then
				local weight = math.clamp(tonumber(w) or WEIGHT[p.rarity], 5, 500)
				local char = plr.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					makeEgg(p.isl, hrp.Position + Vector3.new(3, 0, 3), id, weight)
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
			d.pets = {}; d.money = 150; d.boatLvl = 1; d.gardenLvl = 1; d.index = {}; d.trail = 0
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
print("GAMECORE5 READY")
]=]
local LANG = [=[
-- EGG ISLE v5 · EggLang (ModuleScript → ReplicatedStorage)
-- i18n: EN หลัก + TH ES PT ID VI ZH KO JA · ตรวจจับภาษาอัตโนมัติ
local LS = game:GetService("LocalizationService")
local M = {}

M.PET_R = { cat = "common", dog = "common", rab = "common", pan = "uncommon", cap = "uncommon", ele = "rare", lio = "rare", dra = "epic", uni = "epic", gld = "legendary", phx = "legendary" }
M.WEIGHT = { common = 10, uncommon = 20, rare = 40, epic = 80, legendary = 150 }
M.PWR = { cat = 1, dog = 1, rab = 1, pan = 3, cap = 3, ele = 10, lio = 10, dra = 40, uni = 40, gld = 200, phx = 200 }
M.PET_N = {
	en = { cat = "Orange Cat", dog = "Corgi", rab = "White Bunny", pan = "Panda", cap = "Capybara", ele = "Pink Elephant", lio = "Golden Lion", dra = "Ice Dragon", uni = "Rainbow Unicorn", gld = "Golden Dragon", phx = "Cosmic Phoenix" },
	th = { cat = "แมวส้ม", dog = "คอร์กี้", rab = "กระต่ายขาว", pan = "แพนด้า", cap = "คาปิบาร่า", ele = "ช้างชมพู", lio = "สิงโตทอง", dra = "มังกรน้ำแข็ง", uni = "ยูนิคอร์นรุ้ง", gld = "ดราก้อนทอง", phx = "ฟีนิกซ์จักรวาล" },
}
M.RAR = {
	en = { common = "Common", uncommon = "Uncommon", rare = "Rare", epic = "Epic", legendary = "Legendary" },
	th = { common = "ธรรมดา", uncommon = "ไม่ธรรมดา", rare = "หายาก", epic = "มหากาพย์", legendary = "ตำนาน" },
	es = { common = "Común", uncommon = "Infrecuente", rare = "Raro", epic = "Épico", legendary = "Legendario" },
	pt = { common = "Comum", uncommon = "Incomum", rare = "Raro", epic = "Épico", legendary = "Lendário" },
	id = { common = "Biasa", uncommon = "Tak Umum", rare = "Langka", epic = "Epik", legendary = "Legendaris" },
	vi = { common = "Thường", uncommon = "Hiếm Vừa", rare = "Hiếm", epic = "Sử Thi", legendary = "Huyền Thoại" },
	zh = { common = "普通", uncommon = "进阶", rare = "稀有", epic = "史诗", legendary = "传说" },
	ko = { common = "일반", uncommon = "고급", rare = "희귀", epic = "영웅", legendary = "전설" },
	ja = { common = "ノーマル", uncommon = "アンコモン", rare = "レア", epic = "エピック", legendary = "伝説" },
}

M.L = {
	en = {
		day = "DAY", night = "NIGHT", carry = "Carrying egg {1} kg - walk {2}", holdbtn = "HOLD\nTO GRAB",
		admin = "ADMIN", announce = "ANNOUNCEMENT", skip = "Skip",
		m_boat = "BOAT", m_garden = "GARDEN", m_index = "INDEX", m_fuse = "FUSE", m_trail = "TRAIL", m_chest = "CHEST", m_bag = "BAG", m_lang = "LANG",
		t_boat = "My Boat", t_garden = "My Garden", t_index = "Island Index", t_fuse = "Fusion Machine", t_trail = "Trail Shop", t_chest = "Free Chest", t_bag = "Pet Bag", t_lang = "Language",
		board_btn = "Board boat (stand near a boat)", leave_btn = "Leave boat", upboat = "Upgrade boat", upgarden = "Upgrade garden",
		fuse_btn = "FUSE", sell = "Sell", open_chest = "Open chest (+$750 / 20h)", chest_wait = "Chest ready in {1}h",
		fuse_info = "Fuse 3 same pets = BIG form, power x2", stick = "[stick unlocked]",
		boat_spd = "Current boat speed x{1}", slots = "Slots {1} · species {2}",
		bag_info = "In bag (not earning): {1}", active = "Active {1}/{2}",
		b_income = "MOST $/SEC", b_robux = "MOST ROBUX SPENT", b_play = "LONGEST PLAY (HRS)",
		gift_ok = "Chest opened! +$750", hatch = "Hatched {1} [{2}]!", pickup = "Holding {1} kg egg - back to your garden!",
		night_now = "Night! Eggs hidden on the islands - sail out!", dawn = "Morning! Eggs reset in 20s",
		legend = "A LEGENDARY egg appeared on island 5!", idx_done = "Island {1} index complete! Stick unlocked",
		boat_up = "Boat upgraded! speed x{1}", garden_up = "Garden upgraded! slots {1}",
		trail_on = "{1} equipped - walk x{2}", fuse_ok = "Fused! {1} is now BIG (x2)",
		sold = "Sold {1} +${2}", big = "BIG",
		full_boat = "Boat maxed!", full_garden = "Garden maxed!",
		trail1 = "Green Wind Trail", trail2 = "Ice Trail", trail3 = "Fire Trail",
		money_add = "+${1} added", allpets = "All 11 pets granted", reset_ok = "Save reset",
		egg_summon = "{1} summoned {2} ({3} kg) - race to grab it!", robux_thx = "Thanks! +${1} added",
		intro1 = "After a long journey... the Egg Sea lies ahead",
		intro2 = "!? The water shakes... something huge is below us",
		intro3 = "The Guardian of the Shadow Isle!! It remembers intruders!",
		intro4 = "BOOM!! The ship breaks apart-",
		intro5 = "Blub... blub... (everything fades to black)", intro6 = "",
		welcome = "Welcome to Egg Isle! Tonight... sail out for your first egg",
		guard_name = "Guardian {1}", guard_hit = "The guardian snatched your egg back to its nest!",
		tut_title = "HOW TO PLAY", tut1 = "1. At NIGHT eggs appear - board a boat at the dock and sail to an island",
		tut2 = "2. Walk to an egg and HOLD 3s to grab it (heavier = slower but earns more)",
		tut3 = "3. Carry it to YOUR garden Incubator to hatch",
		tut4 = "4. Try the menus: FUSE 3 same pets, TRAIL shop, free CHEST, LANG button",
		tut_skip = "Skip", tut_end = "Finish",
	},
	th = {
		day = "กลางวัน", night = "กลางคืน", carry = "ถือไข่ {1} กก. - เดิน {2}", holdbtn = "กดค้าง\nเก็บไข่",
		admin = "ผู้ดูแล", announce = "ประกาศ", skip = "ข้าม",
		m_boat = "เรือ", m_garden = "สวน", m_index = "ดัชนี", m_fuse = "ฟิวส์", m_trail = "เทรล", m_chest = "หีบ", m_bag = "กระเป๋า", m_lang = "ภาษา",
		t_boat = "เรือของฉัน", t_garden = "สวนของฉัน", t_index = "ดัชนีเกาะ", t_fuse = "เครื่องฟิวส์", t_trail = "ร้านเทรล", t_chest = "หีบฟรี", t_bag = "กระเป๋าเพ็ท", t_lang = "ภาษา",
		board_btn = "ขึ้นเรือ (ยืนใกล้เรือ)", leave_btn = "ลงเรือ", upboat = "อัปเรือ", upgarden = "อัปสวน",
		fuse_btn = "ฟิวส์", sell = "ขาย", open_chest = "เปิดหีบ (+$750 / 20 ชม.)", chest_wait = "หีบพร้อมใน {1} ชม.",
		fuse_info = "ฟิวส์สัตว์เดียวกัน 3 ตัว = ร่างยักษ์ พลัง x2", stick = "[ปลดล็อกไม้]",
		boat_spd = "ความเร็วเรือปัจจุบัน x{1}", slots = "ช่อง {1} · ชนิด {2}",
		bag_info = "ในกระเป๋า (ไม่ผลิต): {1}", active = "ใช้งาน {1}/{2}",
		b_income = "เงิน/วิ มากสุด", b_robux = "จ่ายโรบัคมากสุด", b_play = "เล่นนานสุด (ชม.)",
		gift_ok = "เปิดหีบ! +$750", hatch = "ฟักได้ {1} [{2}]", pickup = "ถือไข่ {1} กก. - กลับสวนของคุณ!",
		night_now = "กลางคืนแล้ว! ไข่ซ่อนตามเกาะ ออกเรือเลย!", dawn = "เช้าแล้ว! รีไข่ใน 20 วิ",
		legend = "ไข่ตำนานโผล่ที่เกาะ 5!", idx_done = "ดัชนีเกาะ {1} ครบ! ปลดล็อกไม้",
		boat_up = "อัปเรือ! ความเร็ว x{1}", garden_up = "อัปสวน! ช่อง {1}",
		trail_on = "สวม {1} - เดิน x{2}", fuse_ok = "ฟิวส์สำเร็จ! {1} กลายเป็นยักษ์ (x2)",
		sold = "ขาย {1} +${2}", big = "ยักษ์",
		full_boat = "เรือเต็มขั้น!", full_garden = "สวนเต็มขั้น!",
		trail1 = "เทรลลมเขียว", trail2 = "เทรลน้ำแข็ง", trail3 = "เทรลเพลิง",
		money_add = "เติม ${1}", allpets = "แจกครบ 11 ชนิด", reset_ok = "รีเซ็ตเซฟ",
		egg_summon = "{1} เสกไข่ {2} ({3} กก.) - แย่งกัน!", robux_thx = "ขอบคุณ! +${1}",
		intro1 = "หลังการเดินทางอันยาวนาน... ทะเลแห่งเกาะไข่อยู่ตรงหน้า",
		intro2 = "!? ผิวน้ำสั่นแรงขึ้น... มีบางอย่างใหญ่โตอยู่ใต้เรา",
		intro3 = "ผู้พิทักษ์แห่งเกาะอเวจี!! มันจำหน้าผู้บุกรุกได้!",
		intro4 = "ตู้ม!! เรือแตกแล้ว-",
		intro5 = "ตุ๊บ... ตุ๊บ... (ทุกอย่างมืดลง)", intro6 = "",
		welcome = "ยินดีต้อนรับสู่ Egg Isle! คืนนี้... ออกเรือไปหาไข่ใบแรก",
		guard_name = "ผู้พิทักษ์ {1}", guard_hit = "ผู้พิทักษ์แย่งไข่คืนรังไปแล้ว!",
		tut_title = "วิธีเล่น", tut1 = "1. กลางคืนไข่จะโผล่ - ขึ้นเรือที่ท่านแล่นไปเกาะ",
		tut2 = "2. เดินใกล้ไข่แล้วกดค้าง 3 วิเพื่อเก็บ (หนัก=ช้าแต่เงินเยอะ)",
		tut3 = "3. ถือไข่กลับเครื่องฟักที่สวนของคุณเพื่อฟัก",
		tut4 = "4. ลองเมนู: ฟิวส์สัตว์เดียวกัน 3 ตัว, ร้านเทรล, หีบฟรี, ปุ่มภาษา",
		tut_skip = "ข้าม", tut_end = "จบการสอน",
	},
	es = {
		day = "DÍA", night = "NOCHE", carry = "Llevas huevo de {1} kg - paso {2}", holdbtn = "MANTEN\nPARA TOMAR",
		admin = "ADMIN", announce = "ANUNCIO", skip = "Saltar",
		m_boat = "BARCO", m_garden = "JARDÍN", m_index = "ÍNDICE", m_fuse = "FUSIÓN", m_trail = "ESTELA", m_chest = "COFRE", m_bag = "BOLSA", m_lang = "IDIOMA",
		t_boat = "Mi Barco", t_garden = "Mi Jardín", t_index = "Índice de Islas", t_fuse = "Máquina de Fusión", t_trail = "Tienda de Estelas", t_chest = "Cofre Gratis", t_bag = "Bolsa de Mascotas", t_lang = "Idioma",
		board_btn = "Subir al barco", leave_btn = "Bajar", upboat = "Mejorar barco", upgarden = "Mejorar jardín",
		fuse_btn = "FUSIONAR", sell = "Vender", open_chest = "Abrir cofre (+$750 / 20h)", chest_wait = "Cofre listo en {1}h",
		fuse_info = "Fusiona 3 mascotas iguales = forma GIGANTE, poder x2", stick = "[palo desbloqueado]",
		boat_spd = "Velocidad de barco x{1}", slots = "Espacios {1} · especies {2}",
		bag_info = "En bolsa (sin producir): {1}", active = "Activas {1}/{2}",
		b_income = "MÁS $/SEG", b_robux = "MÁS ROBUX GASTADO", b_play = "MÁS TIEMPO (HRS)",
		gift_ok = "Cofre abierto! +$750", hatch = "Nació {1} [{2}]!", pickup = "Sostienes huevo de {1} kg - vuelve a tu jardín!",
		night_now = "Noche! Huevos ocultos en las islas - zarpa!", dawn = "Mañana! Huevos se reinician en 20s",
		legend = "Un huevo LEGENDARIO en la isla 5!", idx_done = "Índice de isla {1} completo!",
		boat_up = "Barco mejorado! x{1}", garden_up = "Jardín mejorado! espacios {1}",
		trail_on = "{1} equipada - paso x{2}", fuse_ok = "Fusionado! {1} ahora es GIGANTE (x2)",
		sold = "Vendiste {1} +${2}", big = "GIGANTE",
		full_boat = "Barco al máximo!", full_garden = "Jardín al máximo!",
		trail1 = "Estela Verde", trail2 = "Estela de Hielo", trail3 = "Estela de Fuego",
		money_add = "+${1} añadido", allpets = "11 mascotas dadas", reset_ok = "Guardado reiniciado",
		egg_summon = "{1} invocó {2} ({3} kg) - carrera por tomarlo!", robux_thx = "Gracias! +${1}",
		intro1 = "Tras un largo viaje... el Mar de Huevos está frente a nosotros",
		intro2 = "!? El agua tiembla... algo enorme está abajo",
		intro3 = "El Guardián de la Isla Sombra!! Recuerda a los intrusos!",
		intro4 = "BOOM!! El barco se rompe-",
		intro5 = "Glub... glub... (todo se oscurece)", intro6 = "",
		welcome = "Bienvenido a Egg Isle! Esta noche... zarpa por tu primer huevo",
		guard_name = "Guardián {1}", guard_hit = "El guardián recuperó el huevo!",
		tut_title = "CÓMO JUGAR", tut1 = "1. De NOCHE aparecen huevos - sube al barco y zarpa",
		tut2 = "2. Acércate y MANTEN 3s (más pesado = más lento pero gana más)",
		tut3 = "3. Llévalo a tu Incubadora para eclosionarlo",
		tut4 = "4. Prueba: FUSIÓN, estelas, cofre gratis, idioma",
		tut_skip = "Saltar", tut_end = "Listo",
	},
	pt = {
		day = "DIA", night = "NOITE", carry = "Carregando ovo de {1} kg - passo {2}", holdbtn = "SEGURE\nPARA PEGAR",
		admin = "ADMIN", announce = "ANÚNCIO", skip = "Pular",
		m_boat = "BARCO", m_garden = "JARDIM", m_index = "ÍNDICE", m_fuse = "FUSÃO", m_trail = "RASTRO", m_chest = "BAÚ", m_bag = "BOLSA", m_lang = "IDIOMA",
		t_boat = "Meu Barco", t_garden = "Meu Jardim", t_index = "Índice das Ilhas", t_fuse = "Máquina de Fusão", t_trail = "Loja de Rastros", t_chest = "Baú Grátis", t_bag = "Bolsa de Pets", t_lang = "Idioma",
		board_btn = "Entrar no barco", leave_btn = "Sair do barco", upboat = "Melhorar barco", upgarden = "Melhorar jardim",
		fuse_btn = "FUNDIR", sell = "Vender", open_chest = "Abrir baú (+$750 / 20h)", chest_wait = "Baú pronto em {1}h",
		fuse_info = "Funda 3 pets iguais = forma GIGANTE, poder x2", stick = "[vara desbloqueada]",
		boat_spd = "Velocidade do barco x{1}", slots = "Vagas {1} · espécies {2}",
		bag_info = "Na bolsa (sem render): {1}", active = "Ativos {1}/{2}",
		b_income = "MAIS $/SEG", b_robux = "MAIS ROBUX GASTO", b_play = "MAIS TEMPO (HRS)",
		gift_ok = "Baú aberto! +$750", hatch = "Nasceu {1} [{2}]!", pickup = "Segurando ovo de {1} kg - volte ao jardim!",
		night_now = "Noite! Ovos escondidos nas ilhas - zarpe!", dawn = "Manhã! Ovos reiniciam em 20s",
		legend = "Um ovo LENDÁRIO na ilha 5!", idx_done = "Índice da ilha {1} completo!",
		boat_up = "Barco melhorado! x{1}", garden_up = "Jardim melhorado! vagas {1}",
		trail_on = "{1} equipado - passo x{2}", fuse_ok = "Fundido! {1} agora é GIGANTE (x2)",
		sold = "Vendeu {1} +${2}", big = "GIGANTE",
		full_boat = "Barco no máximo!", full_garden = "Jardim no máximo!",
		trail1 = "Rastro Verde", trail2 = "Rastro de Gelo", trail3 = "Rastro de Fogo",
		money_add = "+${1} adicionado", allpets = "11 pets dados", reset_ok = "Save reiniciado",
		egg_summon = "{1} invocou {2} ({3} kg) - corra para pegar!", robux_thx = "Obrigado! +${1}",
		intro1 = "Após uma longa viagem... o Mar dos Ovos está à frente",
		intro2 = "!? A água treme... algo enorme está embaixo",
		intro3 = "O Guardião da Ilha Sombra!! Ele lembra dos invasores!",
		intro4 = "BOOM!! O navio se parte-",
		intro5 = "Blub... blub... (tudo escurece)", intro6 = "",
		welcome = "Bem-vindo à Egg Isle! Esta noite... zarpe pelo seu primeiro ovo",
		guard_name = "Guardião {1}", guard_hit = "O guardião levou o ovo de volta!",
		tut_title = "COMO JOGAR", tut1 = "1. À NOITE ovos aparecem - entre no barco e zarpe",
		tut2 = "2. Chegue perto e SEGURE 3s (mais pesado = mais lento, rende mais)",
		tut3 = "3. Leve à sua Incubadora para chocar",
		tut4 = "4. Explore: FUSÃO, rastros, baú grátis, idioma",
		tut_skip = "Pular", tut_end = "Concluir",
	},
	id = {
		day = "SIANG", night = "MALAM", carry = "Membawa telur {1} kg - jalan {2}", holdbtn = "TAHAN\nUNTUK AMBIL",
		admin = "ADMIN", announce = "PENGUMUMAN", skip = "Lewati",
		m_boat = "PERAHU", m_garden = "KEBUN", m_index = "INDEKS", m_fuse = "FUSI", m_trail = "JEJAK", m_chest = "PETI", m_bag = "TAS", m_lang = "BAHASA",
		t_boat = "Perahuku", t_garden = "Kebunku", t_index = "Indeks Pulau", t_fuse = "Mesin Fusi", t_trail = "Toko Jejak", t_chest = "Peti Gratis", t_bag = "Tas Hewan", t_lang = "Bahasa",
		board_btn = "Naik perahu", leave_btn = "Turun", upboat = "Tingkatkan perahu", upgarden = "Tingkatkan kebun",
		fuse_btn = "FUSI", sell = "Jual", open_chest = "Buka peti (+$750 / 20j)", chest_wait = "Peti siap dalam {1}j",
		fuse_info = "Fusi 3 hewan sama = bentuk BESAR, daya x2", stick = "[tongkat terbuka]",
		boat_spd = "Kecepatan perahu x{1}", slots = "Slot {1} · spesies {2}",
		bag_info = "Di tas (tidak menghasilkan): {1}", active = "Aktif {1}/{2}",
		b_income = "$/DETIK TERTINGGI", b_robux = "ROBUX TERBANYAK", b_play = "MAIN TERLAMA (JAM)",
		gift_ok = "Peti dibuka! +$750", hatch = "Menetas {1} [{2}]!", pickup = "Membawa telur {1} kg - kembali ke kebunmu!",
		night_now = "Malam! Telur tersembunyi di pulau - berlayar!", dawn = "Pagi! Telur reset dalam 20s",
		legend = "Telur LEGENDARIS muncul di pulau 5!", idx_done = "Indeks pulau {1} lengkap!",
		boat_up = "Perahu ditingkatkan! x{1}", garden_up = "Kebun ditingkatkan! slot {1}",
		trail_on = "{1} dipakai - jalan x{2}", fuse_ok = "Fusi berhasil! {1} kini BESAR (x2)",
		sold = "Menjual {1} +${2}", big = "BESAR",
		full_boat = "Perahu maksimal!", full_garden = "Kebun maksimal!",
		trail1 = "Jejak Hijau", trail2 = "Jejak Es", trail3 = "Jejak Api",
		money_add = "+${1} ditambah", allpets = "11 hewan diberikan", reset_ok = "Save direset",
		egg_summon = "{1} memunculkan {2} ({3} kg) - rebutan!", robux_thx = "Terima kasih! +${1}",
		intro1 = "Setelah perjalanan panjang... Laut Telur terbentang",
		intro2 = "!? Air bergetar... sesuatu yang besar di bawah",
		intro3 = "Penjaga Pulau Bayangan!! Ia ingat penyusup!",
		intro4 = "BOOM!! Kapal hancur-",
		intro5 = "Blub... blub... (semua gelap)", intro6 = "",
		welcome = "Selamat datang di Egg Isle! Malam ini... berlayarlah mencari telur pertamamu",
		guard_name = "Penjaga {1}", guard_hit = "Penjaga merebut kembali telurnya!",
		tut_title = "CARA MAIN", tut1 = "1. MALAM hari telur muncul - naik perahu dan berlayar",
		tut2 = "2. Dekati telur dan TAHAN 3s (berat = lambat tapi hasil besar)",
		tut3 = "3. Bawa ke Inkubator kebunmu untuk menetaskan",
		tut4 = "4. Coba menu: FUSI, jejak, peti gratis, bahasa",
		tut_skip = "Lewati", tut_end = "Selesai",
	},
	vi = {
		day = "NGÀY", night = "ĐÊM", carry = "Đang ôm trứng {1} kg - đi {2}", holdbtn = "GIỮ\nĐỂ NHẶT",
		admin = "ADMIN", announce = "THÔNG BÁO", skip = "Bỏ qua",
		m_boat = "THUYỀN", m_garden = "VƯỜN", m_index = "CHỈ MỤC", m_fuse = "HỢP NHẤT", m_trail = "VẾT", m_chest = "RƯƠNG", m_bag = "TÚI", m_lang = "NGÔN NGỮ",
		t_boat = "Thuyền của tôi", t_garden = "Vườn của tôi", t_index = "Chỉ mục đảo", t_fuse = "Máy hợp nhất", t_trail = "Cửa hàng vết", t_chest = "Rương miễn phí", t_bag = "Túi thú", t_lang = "Ngôn ngữ",
		board_btn = "Lên thuyền", leave_btn = "Xuống thuyền", upboat = "Nâng cấp thuyền", upgarden = "Nâng cấp vườn",
		fuse_btn = "HỢP NHẤT", sell = "Bán", open_chest = "Mở rương (+$750 / 20h)", chest_wait = "Rương sẵn sàng sau {1}h",
		fuse_info = "Hợp nhất 3 thú giống nhau = dạng KHỔNG LỒ, sức x2", stick = "[mở khóa gậy]",
		boat_spd = "Tốc độ thuyền x{1}", slots = "Ô {1} · loài {2}",
		bag_info = "Trong túi (không sinh lợi): {1}", active = "Hoạt động {1}/{2}",
		b_income = "NHIỀU $/GIÂY NHẤT", b_robux = "CHI NHIỀU ROBUX NHẤT", b_play = "CHƠI LÂU NHẤT (GIỜ)",
		gift_ok = "Đã mở rương! +$750", hatch = "Nở ra {1} [{2}]!", pickup = "Đang ôm trứng {1} kg - về vườn của bạn!",
		night_now = "Đêm rồi! Trứng ẩn trên đảo - ra khơi!", dawn = "Sáng rồi! Trứng reset sau 20s",
		legend = "Trứng HUYỀN THOẠI xuất hiện ở đảo 5!", idx_done = "Hoàn thành chỉ mục đảo {1}!",
		boat_up = "Thuyền nâng cấp! x{1}", garden_up = "Vườn nâng cấp! ô {1}",
		trail_on = "Trang bị {1} - đi x{2}", fuse_ok = "Đã hợp nhất! {1} thành KHỔNG LỒ (x2)",
		sold = "Đã bán {1} +${2}", big = "KHỔNG LỒ",
		full_boat = "Thuyền tối đa!", full_garden = "Vườn tối đa!",
		trail1 = "Vết Gió Xanh", trail2 = "Vết Băng", trail3 = "Vết Lửa",
		money_add = "+${1} đã thêm", allpets = "Đã nhận 11 thú", reset_ok = "Đã reset save",
		egg_summon = "{1} triệu hồi {2} ({3} kg) - tranh nhau nhặt!", robux_thx = "Cảm ơn! +${1}",
		intro1 = "Sau hành trình dài... Biển Trứng hiện ra trước mặt",
		intro2 = "!? Mặt nước rung chuyển... thứ gì đó khổng lồ bên dưới",
		intro3 = "Hộ Vệ của Đảo Bóng Đêm!! Nó nhớ kẻ xâm nhập!",
		intro4 = "BOOM!! Thuyền vỡ tan-",
		intro5 = "Ục... ục... (mọi thứ tối sầm)", intro6 = "",
		welcome = "Chào mừng đến Egg Isle! Đêm nay... ra khơi tìm quả trứng đầu tiên",
		guard_name = "Hộ Vệ {1}", guard_hit = "Hộ Vệ đã đoạt lại trứng!",
		tut_title = "CÁCH CHƠI", tut1 = "1. Ban ĐÊM trứng xuất hiện - lên thuyền ra khơi",
		tut2 = "2. Lại gần và GIỮ 3s (nặng = chậm nhưng thu nhiều hơn)",
		tut3 = "3. Mang về máy ấp trong vườn để nở",
		tut4 = "4. Thử menu: HỢP NHẤT, vết, rương miễn phí, ngôn ngữ",
		tut_skip = "Bỏ qua", tut_end = "Xong",
	},
	zh = {
		day = "白天", night = "夜晚", carry = "抱着 {1} kg 蛋 - 移速 {2}", holdbtn = "长按\n拾取",
		admin = "管理员", announce = "公告", skip = "跳过",
		m_boat = "船", m_garden = "花园", m_index = "图鉴", m_fuse = "融合", m_trail = "拖尾", m_chest = "宝箱", m_bag = "背包", m_lang = "语言",
		t_boat = "我的船", t_garden = "我的花园", t_index = "岛屿图鉴", t_fuse = "融合机", t_trail = "拖尾商店", t_chest = "免费宝箱", t_bag = "宠物背包", t_lang = "语言",
		board_btn = "上船", leave_btn = "下船", upboat = "升级船", upgarden = "升级花园",
		fuse_btn = "融合", sell = "出售", open_chest = "开宝箱 (+$750 / 20小时)", chest_wait = "宝箱 {1} 小时后可开",
		fuse_info = "3 只相同宠物融合 = 巨型形态, 力量 x2", stick = "[已解锁木杖]",
		boat_spd = "当前船速 x{1}", slots = "栏位 {1} · 种类 {2}",
		bag_info = "背包中 (不产出): {1}", active = "生效 {1}/{2}",
		b_income = "最高 $/秒", b_robux = "最多 ROBUX 消费", b_play = "最长游玩 (小时)",
		gift_ok = "宝箱已开! +$750", hatch = "孵出 {1} [{2}]!", pickup = "抱着 {1} kg 蛋 - 回你的花园!",
		night_now = "夜晚! 蛋藏在各岛 - 出发!", dawn = "早晨! 蛋 20 秒后重置",
		legend = "传说蛋出现在 5 号岛!", idx_done = "岛屿 {1} 图鉴完成!",
		boat_up = "船已升级! x{1}", garden_up = "花园已升级! 栏位 {1}",
		trail_on = "已装备 {1} - 移速 x{2}", fuse_ok = "融合成功! {1} 变为巨型 (x2)",
		sold = "出售 {1} +${2}", big = "巨型",
		full_boat = "船已满级!", full_garden = "花园已满级!",
		trail1 = "绿风拖尾", trail2 = "冰霜拖尾", trail3 = "烈焰拖尾",
		money_add = "+${1} 已添加", allpets = "已发放 11 种宠物", reset_ok = "存档已重置",
		egg_summon = "{1} 召唤了 {2} ({3} kg) - 快去抢!", robux_thx = "谢谢! +${1}",
		intro1 = "漫长旅途之后... 蛋之海就在眼前",
		intro2 = "!? 水面在震动... 下面有巨大的东西",
		intro3 = "暗影岛的守护者!! 它记得入侵者!",
		intro4 = "轰!! 船碎了-",
		intro5 = "咕嘟... 咕嘟... (一切变黑)", intro6 = "",
		welcome = "欢迎来到 Egg Isle! 今晚... 出发寻找你的第一颗蛋",
		guard_name = "守护者 {1}", guard_hit = "守护者把蛋夺回巢穴了!",
		tut_title = "玩法教学", tut1 = "1. 夜晚蛋会出现 - 上船出航",
		tut2 = "2. 靠近蛋长按 3 秒 (越重越慢但收益更高)",
		tut3 = "3. 抱回你花园的孵化器孵化",
		tut4 = "4. 试试菜单: 融合, 拖尾, 免费宝箱, 语言",
		tut_skip = "跳过", tut_end = "完成",
	},
	ko = {
		day = "낮", night = "밤", carry = "알 {1} kg 드는 중 - 속도 {2}", holdbtn = "길게\n눌러 줍기",
		admin = "관리자", announce = "공지", skip = "건너뛰기",
		m_boat = "배", m_garden = "정원", m_index = "도감", m_fuse = "퓨전", m_trail = "트레일", m_chest = "상자", m_bag = "가방", m_lang = "언어",
		t_boat = "내 배", t_garden = "내 정원", t_index = "섬 도감", t_fuse = "퓨전 머신", t_trail = "트레일 상점", t_chest = "무료 상자", t_bag = "펫 가방", t_lang = "언어",
		board_btn = "배 타기", leave_btn = "배 내리기", upboat = "배 강화", upgarden = "정원 강화",
		fuse_btn = "퓨전", sell = "판매", open_chest = "상자 열기 (+$750 / 20시간)", chest_wait = "상자 {1}시간 후",
		fuse_info = "같은 펫 3마리 퓨전 = 거대 형태, 능력 x2", stick = "[지팡이 해제]",
		boat_spd = "현재 배 속도 x{1}", slots = "슬롯 {1} · 종류 {2}",
		bag_info = "가방 (수익 없음): {1}", active = "활성 {1}/{2}",
		b_income = "최고 $/초", b_robux = "최다 로벅 소비", b_play = "최장 플레이 (시간)",
		gift_ok = "상자 열림! +$750", hatch = "{1} 부화! [{2}]", pickup = "{1} kg 알 드는 중 - 정원으로!",
		night_now = "밤! 섬에 알이 숨겨짐 - 출항!", dawn = "아침! 20초 후 알 초기화",
		legend = "전설 알이 5섬에 등장!", idx_done = "섬 {1} 도감 완료!",
		boat_up = "배 강화! x{1}", garden_up = "정원 강화! 슬롯 {1}",
		trail_on = "{1} 장착 - 속도 x{2}", fuse_ok = "퓨전 성공! {1} 거대화 (x2)",
		sold = "{1} 판매 +${2}", big = "거대",
		full_boat = "배 최대!", full_garden = "정원 최대!",
		trail1 = "초록 바람 트레일", trail2 = "얼음 트레일", trail3 = "화염 트레일",
		money_add = "+${1} 추가", allpets = "11종 지급", reset_ok = "세이브 초기화",
		egg_summon = "{1} 이(가) {2} ({3} kg) 소환 - 빨리 주우세요!", robux_thx = "감사합니다! +${1}",
		intro1 = "긴 여정 끝... 알의 바다가 눈앞에",
		intro2 = "!? 물이 흔들린다... 거대한 무언가가 아래에",
		intro3 = "그림자 섬의 수호자!! 침입자를 기억한다!",
		intro4 = "콰광!! 배가 부서진다-",
		intro5 = "꿀렁... 꿀렁... (모두 어두워진다)", intro6 = "",
		welcome = "Egg Isle에 오신 것을 환영합니다! 오늘 밤... 첫 알을 찾으러 출항하세요",
		guard_name = "수호자 {1}", guard_hit = "수호자가 알을 되가져갔습니다!",
		tut_title = "플레이 방법", tut1 = "1. 밤이 되면 알 등장 - 보트 타고 출항",
		tut2 = "2. 알에 다가가 3초 길게 눌러 줍기 (무거울수록 느리지만 수익 업)",
		tut3 = "3. 정원의 부화기로 가져가 부화",
		tut4 = "4. 메뉴 탐색: 퓨전, 트레일, 무료 상자, 언어",
		tut_skip = "건너뛰기", tut_end = "완료",
	},
	ja = {
		day = "昼", night = "夜", carry = "卵 {1} kg 所持 - 歩速 {2}", holdbtn = "長押しで\n拾う",
		admin = "管理人", announce = "お知らせ", skip = "スキップ",
		m_boat = "ボート", m_garden = "庭", m_index = "図鑑", m_fuse = "融合", m_trail = "トレイル", m_chest = "宝箱", m_bag = "バッグ", m_lang = "言語",
		t_boat = "マイボート", t_garden = "マイ庭", t_index = "島図鑑", t_fuse = "融合マシン", t_trail = "トレイルショップ", t_chest = "無料宝箱", t_bag = "ペットバッグ", t_lang = "言語",
		board_btn = "ボートに乗る", leave_btn = "ボートを降りる", upboat = "ボート強化", upgarden = "庭強化",
		fuse_btn = "融合", sell = "売却", open_chest = "宝箱を開く (+$750 / 20h)", chest_wait = "宝箱あと {1}h",
		fuse_info = "同じペット3体を融合 = BIG形態, 力x2", stick = "[杖解放]",
		boat_spd = "現在のボート速度 x{1}", slots = "スロット {1} · 種類 {2}",
		bag_info = "バッグ内 (生産なし): {1}", active = "稼働 {1}/{2}",
		b_income = "最高 $/秒", b_robux = "最多ロバックス消費", b_play = "最長プレイ (時間)",
		gift_ok = "宝箱を開けた! +$750", hatch = "{1} が孵化! [{2}]", pickup = "{1} kg の卵を所持 - 庭へ戻れ!",
		night_now = "夜! 島に卵が隠れた - 出航!", dawn = "朝! 20秒で卵リセット",
		legend = "伝説の卵が島5に出現!", idx_done = "島 {1} の図鑑完成!",
		boat_up = "ボート強化! x{1}", garden_up = "庭強化! スロット {1}",
		trail_on = "{1} 装備 - 歩速 x{2}", fuse_ok = "融合成功! {1} がBIGに (x2)",
		sold = "{1} を売却 +${2}", big = "BIG",
		full_boat = "ボート最大!", full_garden = "庭最大!",
		trail1 = "緑風のトレイル", trail2 = "氷のトレイル", trail3 = "炎のトレイル",
		money_add = "+${1} 追加", allpets = "11種を付与", reset_ok = "セーブ初期化",
		egg_summon = "{1} が {2} ({3} kg) を召喚 - 取りに行け!", robux_thx = "ありがとう! +${1}",
		intro1 = "長い旅の末... 卵の海が目の前に",
		intro2 = "!? 水面が揺れる... 下に巨大な何かが",
		intro3 = "影の島の守護者!! 侵入者を覚えている!",
		intro4 = "ドカーン!! 船が壊れる-",
		intro5 = "ゴボ... ゴボ... (全てが暗転)", intro6 = "",
		welcome = "Egg Isleへようこそ! 今夜... 最初の卵を探しに出航しよう",
		guard_name = "ガーディアン {1}", guard_hit = "ガーディアンに卵を持ち去られた!",
		tut_title = "あそびかた", tut1 = "1. 夜になると卵が出現 - ボートで出航",
		tut2 = "2. 卵に近づき3秒長押しで拾う (重いほど遅いが収入増)",
		tut3 = "3. 庭の孵化器へ運んで孵化",
		tut4 = "4. メニューを試そう: 融合, トレイル, 無料宝箱, 言語",
		tut_skip = "スキップ", tut_end = "完了",
	},
}

M.cur = "en"
function M.detect()
	local ok, loc = pcall(function() return (LS.RobloxLocaleId or "en-us"):lower() end)
	loc = ok and loc or "en-us"
	for _, code in ipairs({ "th", "es", "pt", "id", "vi", "zh", "ko", "ja" }) do
		if loc:sub(1, 2) == code then return code end
	end
	return "en"
end
function M.set(code)
	if M.L[code] then M.cur = code end
end
function M.tr(key, a, b, c)
	local tbl = M.L[M.cur] or M.L.en
	local t = tbl[key] or M.L.en[key] or key
	if a ~= nil then t = t:gsub("{1}", tostring(a)) end
	if b ~= nil then t = t:gsub("{2}", tostring(b)) end
	if c ~= nil then t = t:gsub("{3}", tostring(c)) end
	return t
end
function M.petName(id)
	local tbl = M.PET_N[M.cur] or M.PET_N.en
	return tbl[id] or M.PET_N.en[id] or id
end
function M.rarName(id)
	local tbl = M.RAR[M.cur] or M.RAR.en
	return tbl[id] or M.RAR.en[id] or id
end
return M
]=]
local GUI = [=[
-- ============================================================
-- EGG ISLE v6 · Gui6 (LocalScript → StarterPlayerScripts)
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
local function stroke(p, c, t) local s = Instance.new("UIStroke"); s.Color = c or Color3.fromRGB(0, 0, 0); s.Thickness = t or 2; s.Parent = p end
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

-- index
local idxPanel, idxBody, idxTitle = makePanel("Index", 300, 290, "t_index")
local il = Instance.new("UIListLayout"); il.Padding = UDim.new(0, 8); il.Parent = idxBody
local idxRows = {}
for isl = 2, 5 do
	local r = Instance.new("TextLabel"); r.Size = UDim2.new(1, 0, 0, 44)
	r.BackgroundColor3 = Color3.fromRGB(60, 64, 84); r.Font = FONT; r.TextScaled = true
	r.TextColor3 = Color3.fromRGB(255, 255, 255); corner(r, 10); stroke(r, Color3.fromRGB(0, 0, 0), 2); r.Parent = idxBody
	idxRows[isl] = r
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
				if d.Name == "GHead" and not done[d] then
					done[d] = true
					local pet = d:GetAttribute("Pet")
					local bb = Instance.new("BillboardGui"); bb.Size = UDim2.new(0, 240, 0, 54); bb.AlwaysOnTop = true; bb.Parent = d
					local t = txt(bb, UDim2.new(1, 0, 1, 0), UDim2.new(), Color3.fromRGB(255, 90, 90), Enum.TextXAlignment.Center)
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
local SELLV = { [1] = 50, [3] = 150, [10] = 500, [40] = 2000, [200] = 10000 }
local function sellRow(parent, entry)
	local val = math.floor((SELLV[LM.PWR[entry.base] or 1] or 50) * wMult(entry.base, entry.w) * (entry.big and 3 or 1))
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
	bagInfo.Text = LM.tr("bag_info", bagN)
	bagScroll:ClearAllChildren()
	local bl2 = Instance.new("UIListLayout"); bl2.Padding = UDim.new(0, 5); bl2.Parent = bagScroll
	for _, e in ipairs(entries) do
		local left = e.cnt - (e.activeCnt or 0)
		if left > 0 then
			sellRow(bagScroll, { en = e.en, base = e.base, big = e.big, cnt = left, w = e.w })
		end
	end
	-- index
	local ok2, idx = pcall(function() return Http:JSONDecode(plr:GetAttribute("IndexJSON") or "{}") end)
	if ok2 and type(idx) == "table" then
		for isl = 2, 5 do
			local got = 0
			local arr = idx[tostring(isl)] or idx[isl]
			if type(arr) == "table" then got = #arr end
			local done = got >= POOL_SIZE[isl]
			idxRows[isl].Text = "Island " .. isl .. " " .. ISL_NAME[isl] .. "  " .. got .. "/" .. POOL_SIZE[isl] .. (done and "  " .. LM.tr("stick") or "")
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
]=]
local INTRO = [=[
-- ============================================================
-- EGG ISLE v5 · Intro5 (LocalScript → StarterPlayerScripts)
-- คัทซีนผู้เล่นใหม่: เรือโดนสัตว์ประหลาดโจมตี → จม → ตื่นบนเกาะ 1 (ข้ามได้)
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local WS = workspace
local plr = Players.LocalPlayer
local evIntro = ReplicatedStorage:WaitForChild("IntroDone")
local LM = require(ReplicatedStorage:WaitForChild("EggLang"))
LM.set(LM.detect())

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
cap.BackgroundTransparency = 1; cap.Font = Enum.Font.FredokaOne; cap.TextScaled = true
cap.TextColor3 = Color3.fromRGB(255, 255, 255); cap.TextStrokeTransparency = 0; cap.TextWrapped = true; cap.Parent = gui
local skip = Instance.new("TextButton"); skip.Size = UDim2.fromOffset(120, 44)
skip.Position = UDim2.new(1, -130, 1, -56); skip.BackgroundColor3 = Color3.fromRGB(40, 44, 60)
skip.Font = Enum.Font.FredokaOne; skip.TextScaled = true; skip.Text = LM.tr("skip")
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
	say(LM.tr("intro1"))
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
	say(LM.tr("intro2"))
	for i = 1, 12 do
		cam.CFrame = cam.CFrame * CFrame.new(math.random() * 0.3 - 0.15, math.random() * 0.3 - 0.15, 0)
		task.wait(0.05)
	end
	if done then return end
	-- 3) สัตว์ประหลาดโผล่
	say(LM.tr("intro3"))
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
	say(LM.tr("intro4"))
	TweenService:Create(hull, TweenInfo.new(0.7), { Position = base + Vector3.new(-6, 0, -4), Rotation = Vector3.new(30, 0, 40) }):Play()
	TweenService:Create(deck, TweenInfo.new(0.7), { Position = base + Vector3.new(5, 1, -2), Rotation = Vector3.new(-20, 0, -35) }):Play()
	TweenService:Create(sail, TweenInfo.new(0.9), { Position = base + Vector3.new(2, 3, -8), Rotation = Vector3.new(60, 20, 0) }):Play()
	for i = 1, 16 do
		cam.CFrame = cam.CFrame * CFrame.new(math.random() * 0.6 - 0.3, math.random() * 0.6 - 0.3, 0)
		task.wait(0.04)
	end
	if done then return end
	-- 5) จม
	say(LM.tr("intro5"))
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
	wel.Text = LM.tr("welcome")
	local g2 = Instance.new("ScreenGui"); g2.Parent = plr.PlayerGui; wel.Parent = g2
	task.delay(5, function() g2:Destroy() end)
end)
]=]
local toolbar = plugin:CreateToolbar("EggIsle")
local btn = toolbar:CreateButton("Load EggIsle", "Put latest v6 code into the game", "")
btn.Click:Connect(function()
	local rs = game:GetService("ReplicatedStorage")
	local m = rs:FindFirstChild("EggLang")
	if not m then m = Instance.new("ModuleScript"); m.Name = "EggLang"; m.Parent = rs end
	m.Source = LANG
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
	print("EGG ISLE v6 LOADED OK")
end)
