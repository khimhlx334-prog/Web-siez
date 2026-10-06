-- ============================================================
-- 🥚 EGG ISLE · EggCore v3 (Script → ServerScriptService)
-- ฟักไข่สุ่มสัตว์ · สัตว์ผลิตเหรียญ · กันฟาร์ม/กันโปร + ระบบแอดมิน
-- ============================================================
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local store = DataStoreService:GetDataStore("EggIsleV1")

-- ⚠️ สร้าง Game Pass ในเว็บ Roblox แล้วเอา ID มาใส่ (0 = ปิดไว้ก่อน)
local PASS_LUCK  = 0 -- 🍀 โชค x2 ตลอดไป
local PASS_SLOT  = 0 -- 🐾 ช่องสัตว์ +2
local PASS_FAST  = 0 -- ⚡ ฟักไม่มีคูลดาวน์

-- ---------- ข้อมูลสัตว์ (ออริจินัลของเรา) ----------
local PETS = {
	{ id = "cat", name = "แมวส้ม",        emoji = "🐱", rarity = "ธรรมดา",    power = 1 },
	{ id = "dog", name = "คอร์กี้",        emoji = "🐶", rarity = "ธรรมดา",    power = 1 },
	{ id = "rab", name = "กระต่ายขาว",    emoji = "🐰", rarity = "ธรรมดา",    power = 1 },
	{ id = "pan", name = "แพนด้า",        emoji = "🐼", rarity = "ไม่ธรรมดา", power = 3 },
	{ id = "cap", name = "คาปิบาร่า",     emoji = "🦫", rarity = "ไม่ธรรมดา", power = 3 },
	{ id = "ele", name = "ช้างชมพู",      emoji = "🐘", rarity = "หายาก",     power = 10 },
	{ id = "lio", name = "สิงโตทอง",      emoji = "🦁", rarity = "หายาก",     power = 10 },
	{ id = "dra", name = "มังกรน้ำแข็ง",  emoji = "🐉", rarity = "มหากาพย์",   power = 40 },
	{ id = "uni", name = "ยูนิคอร์นรุ้ง",  emoji = "🦄", rarity = "มหากาพย์",   power = 40 },
	{ id = "gld", name = "ดราก้อนทอง",    emoji = "🐲", rarity = "ตำนาน",     power = 200 },
	{ id = "phx", name = "ฟีนิกซ์จักรวาล", emoji = "🌟", rarity = "ตำนาน",     power = 200 },
}
local BASE_W = { ["ธรรมดา"] = 60, ["ไม่ธรรมดา"] = 25, ["หายาก"] = 10, ["มหากาพย์"] = 4, ["ตำนาน"] = 1 }
local EGGS = {
	{ id = "basic", name = "ไข่ธรรมดา", cost = 100 },
	{ id = "rare",  name = "ไข่หายาก",  cost = 1500,  w = { ["ธรรมดา"] = 30, ["ไม่ธรรมดา"] = 35, ["หายาก"] = 22, ["มหากาพย์"] = 9, ["ตำนาน"] = 4 } },
	{ id = "leg",   name = "ไข่ตำนาน", cost = 30000, w = { ["ไม่ธรรมดา"] = 20, ["หายาก"] = 40, ["มหากาพย์"] = 28, ["ตำนาน"] = 12 } },
}

local Http = game:GetService("HttpService")
local evHatch = Instance.new("RemoteEvent"); evHatch.Name = "Hatch"; evHatch.Parent = ReplicatedStorage
local evAdmin = Instance.new("RemoteEvent"); evAdmin.Name = "Admin"; evAdmin.Parent = ReplicatedStorage
local evAnn = Instance.new("RemoteEvent"); evAnn.Name = "Announce"; evAnn.Parent = ReplicatedStorage

local function petById(id) for _, p in ipairs(PETS) do if p.id == id then return p end end end

local DATA = {} -- [userId] = { pets = {id,...} }
local lastHatch = {}
local daily = {} -- [userId] = { date = "d", earned = n }

local function hasPass(plr, passId)
	if passId == 0 then return false end
	local ok, own = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(plr.UserId, passId) end)
	return ok and own
end

local function activePower(plr)
	local d = DATA[plr.UserId] if not d then return 0 end
	local slots = 3 + (hasPass(plr, PASS_SLOT) and 2 or 0)
	local pows = {}
	for _, id in ipairs(d.pets) do local p = petById(id) if p then table.insert(pows, p.power) end end
	table.sort(pows, function(a, b) return a > b end)
	local sum = 0
	for i = 1, math.min(slots, #pows) do sum += pows[i] end
	return sum
end

local function syncUI(plr)
	local d = DATA[plr.UserId] if not d then return end
	plr:SetAttribute("Power", activePower(plr))
	local counts = {}
	for _, id in ipairs(d.pets) do counts[id] = (counts[id] or 0) + 1 end
	plr:SetAttribute("PetsJSON", Http:JSONEncode(counts))
end

local function luckOf(plr)
	local l = 1
	if hasPass(plr, PASS_LUCK) then l *= 2 end
	return l
end

Players.PlayerAdded:Connect(function(plr)
	local ls = Instance.new("Folder"); ls.Name = "leaderstats"; ls.Parent = plr
	local cash = Instance.new("IntValue"); cash.Name = "Coins"; cash.Value = 0; cash.Parent = ls

	local d = { pets = {} }
	local ok, data = pcall(function() return store:GetAsync("u_" .. plr.UserId) end)
	if ok and type(data) == "table" then
		d.pets = type(data.pets) == "table" and data.pets or {}
		cash.Value = data.coins or 0
	else
		cash.Value = 150 -- เหรียญตั้งต้นให้ฟักไข่ใบแรกได้
	end
	DATA[plr.UserId] = d
	lastHatch[plr.UserId] = 0
	daily[plr.UserId] = { date = os.date("%Y-%m-%d"), earned = 0 }
	syncUI(plr)
end)

local function save(plr)
	local d = DATA[plr.UserId] if not d then return end
	local ls = plr:FindFirstChild("leaderstats")
	pcall(function()
		store:SetAsync("u_" .. plr.UserId, { pets = d.pets, coins = ls and ls.Coins.Value or 0 })
	end)
end
Players.PlayerRemoving:Connect(function(plr) save(plr) DATA[plr.UserId] = nil end)
game:BindToClose(function() for _, plr in ipairs(Players:GetPlayers()) do save(plr) end end)
task.spawn(function() while true do task.wait(60) for _, plr in ipairs(Players:GetPlayers()) do save(plr) end end end)

-- ---------- ลูปรายได้ (เวลาเซิร์ฟเวอร์เท่านั้น กันสปีดแฮก) ----------
task.spawn(function()
	while true do
		task.wait(1)
		local today = os.date("%Y-%m-%d")
		for _, plr in ipairs(Players:GetPlayers()) do
			local d = DATA[plr.UserId] if d then
				local ls = plr:FindFirstChild("leaderstats")
				if ls then
					local dy = daily[plr.UserId]
					if dy.date ~= today then daily[plr.UserId] = { date = today, earned = 0 }; dy = daily[plr.UserId] end
					local gain = activePower(plr)
					if gain > 0 then
						-- soft cap รายวัน: กันฟาร์ม AFK ระยะยาว (เกินโควตา = ครึ่งเดียว)
						if dy.earned > 50000 then gain *= 0.5 end
						dy.earned += gain
						ls.Coins.Value += math.floor(gain)
					end
				end
			end
		end
	end
end)

-- ---------- ฟักไข่ ----------
evHatch.OnServerEvent:Connect(function(plr, eggId)
	local d = DATA[plr.UserId] if not d then return end
	local now = os.clock()
	local cd = hasPass(plr, PASS_FAST) and 0.1 or 0.5
	if now - (lastHatch[plr.UserId] or 0) < cd then return end
	lastHatch[plr.UserId] = now

	local egg
	for _, e in ipairs(EGGS) do if e.id == eggId then egg = e end end
	if not egg then return end

	local ls = plr:FindFirstChild("leaderstats") if not ls then return end
	if ls.Coins.Value < egg.cost then return end
	ls.Coins.Value -= egg.cost

	-- สุ่มระดับ (luck คูณโอกาสมหากาพย์/ตำนาน)
	local luck = luckOf(plr)
	local w = {}
	local total = 0
	for _, r in ipairs({ "ธรรมดา", "ไม่ธรรมดา", "หายาก", "มหากาพย์", "ตำนาน" }) do
		local base = (egg.w and egg.w[r]) or BASE_W[r] or 0
		if base > 0 then
			if r == "มหากาพย์" or r == "ตำนาน" then base *= luck end
			w[r] = base; total += base
		end
	end
	local roll = math.random() * total
	local rarity = "ธรรมดา"
	for _, r in ipairs({ "ธรรมดา", "ไม่ธรรมดา", "หายาก", "มหากาพย์", "ตำนาน" }) do
		if w[r] then roll -= w[r] if roll <= 0 then rarity = r break end end
	end
	-- สุ่มตัวในระดับ
	local pool = {}
	for _, p in ipairs(PETS) do if p.rarity == rarity then table.insert(pool, p) end end
	local got = pool[math.random(1, #pool)]
	table.insert(d.pets, got.id)
	syncUI(plr)
	evHatch:FireClient(plr, { emoji = got.emoji, name = got.name, rarity = got.rarity, power = got.power })
end)

-- ---------- 🛠️ ระบบแอดมิน (เซิร์ฟเวอร์เช็กสิทธิ์ทุกครั้ง — โปรปลอมไม่ได้) ----------
local OWNERS = {} -- ใส่ UserId เพิ่มได้ เช่น { 12345678 }
local function isAdmin(plr)
	if plr.UserId == 0 then return true end -- เทสต์ใน Studio
	if game.CreatorId > 0 and plr.UserId == game.CreatorId then return true end -- เจ้าของเกม
	return table.find(OWNERS, plr.UserId) ~= nil
end

local function givePet(plr, id)
	local d = DATA[plr.UserId] if not d then return end
	local p = petById(id) if not p then return end
	table.insert(d.pets, id)
	syncUI(plr)
	evHatch:FireClient(plr, { emoji = p.emoji, name = p.name, rarity = p.rarity, power = p.power })
end

evAdmin.OnServerEvent:Connect(function(plr, action, arg)
	if not isAdmin(plr) then return end -- ❌ ไม่ใช่แอดมิน = ไม่ทำอะไรเลย
	action = tostring(action)
	if action == "coins" then
		local ls = plr:FindFirstChild("leaderstats") if not ls then return end
		local n = math.floor(tonumber(arg) or 1000000)
		ls.Coins.Value = math.clamp(ls.Coins.Value + n, 0, 9000000000)
	elseif action == "pet" then
		givePet(plr, tostring(arg))
	elseif action == "randomleg" then
		local pool = {}
		for _, p in ipairs(PETS) do if p.rarity == "มหากาพย์" or p.rarity == "ตำนาน" then table.insert(pool, p) end end
		givePet(plr, pool[math.random(1, #pool)].id)
	elseif action == "allpets" then
		for _, p in ipairs(PETS) do givePet(plr, p.id) end
	elseif action == "reset" then
		local d = DATA[plr.UserId]
		if d then d.pets = {} end
		local ls = plr:FindFirstChild("leaderstats")
		if ls then ls.Coins.Value = 150 end
		syncUI(plr)
	elseif action == "kick" then
		local t = Players:FindFirstChild(tostring(arg))
		if t and t ~= plr then t:Kick("🛠️ ถูกเตะโดยแอดมิน") end
	elseif action == "announce" then
		local msg = tostring(arg):sub(1, 120)
		if msg ~= "" then evAnn:FireAllClients(msg) end
	end
end)

-- ---------- 💬 คำสั่งแอดมินแบบแชท (พิมพ์ในแชท เกมมือถือก็ใช้ได้) ----------
local function wireAdminChat(plr)
	plr.Chatted:Connect(function(msg)
		if not isAdmin(plr) then return end
		local cmd, arg = msg:match("^(/%S+)%s*(.*)$")
		if not cmd then return end
		cmd = cmd:lower()
		local ls = plr:FindFirstChild("leaderstats")
		local function fb(t) evAnn:FireClient(plr, "🛠️ " .. t) end
		if cmd == "/coins" then
			local n = math.floor(tonumber(arg) or 1000000)
			if ls then
				ls.Coins.Value = math.clamp(ls.Coins.Value + n, 0, 9000000000)
				fb("เติม " .. n .. " เหรียญแล้ว")
			end
		elseif cmd == "/leg" then
			local pool = {}
			for _, p in ipairs(PETS) do if p.rarity == "มหากาพย์" or p.rarity == "ตำนาน" then table.insert(pool, p) end end
			givePet(plr, pool[math.random(1, #pool)].id)
			fb("สุ่มตัวเทพให้แล้ว")
		elseif cmd == "/allpets" then
			for _, p in ipairs(PETS) do givePet(plr, p.id) end
			fb("แจกครบ 11 ชนิดแล้ว")
		elseif cmd == "/pet" then
			if petById(arg) then givePet(plr, arg) fb("ให้ " .. arg .. " แล้ว") else fb("ไม่รู้จัก id: " .. arg) end
		elseif cmd == "/reset" then
			local d = DATA[plr.UserId]
			if d then d.pets = {} end
			if ls then ls.Coins.Value = 150 end
			syncUI(plr)
			fb("รีเซ็ตเซฟแล้ว")
		elseif cmd == "/kick" then
			local t = Players:FindFirstChild(arg)
			if t and t ~= plr then t:Kick("🛠️ ถูกเตะโดยแอดมิน") fb("เตะ " .. arg .. " แล้ว") end
		elseif cmd == "/say" or cmd == "/announce" then
			if arg ~= "" then evAnn:FireAllClients(arg:sub(1, 120)) fb("ประกาศแล้ว") end
		elseif cmd == "/help" then
			fb("/coins จำนวน · /leg · /allpets · /pet id · /kick ชื่อ · /say ข้อความ · /reset")
		end
	end)
end
Players.PlayerAdded:Connect(wireAdminChat)
for _, p in ipairs(Players:GetPlayers()) do wireAdminChat(p) end
