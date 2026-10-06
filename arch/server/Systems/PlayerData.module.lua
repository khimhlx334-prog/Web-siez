-- ============================================================
-- EGG RAID · Systems/PlayerData (ModuleScript → ServerScriptService/Systems/PlayerData)
-- Session cache + load/save of the MODULAR profile (EGGRAID_ key).
-- Saves go through the queued DataStore layer — never per-change.
-- Server-authoritative: clients can never write profiles.
-- ============================================================
local Players = game:GetService("Players")

local PlayerData = {}
local DataStore, Constants
local session = {}

local function defaultProfile()
	return {
		money = 0,
		eggs = {},
		pets = {},
		baseLvl = 1,
		quests = {},
		daily = { lastClaim = 0, streak = 0 },
		upgrades = {},
		settings = {},
		stats = { steals = 0, hatches = 0, sells = 0, playSeconds = 0 },
	}
end

-- late binding so require order stays simple
local function deps()
	if not DataStore then
		local ss = game:GetService("ServerScriptService"):WaitForChild("Systems")
		DataStore = require(ss:WaitForChild("DataStore"))
		local rs = game:GetService("ReplicatedStorage")
		Constants = require(rs:WaitForChild("Shared"):WaitForChild("Constants"))
	end
end

function PlayerData.Get(plr)
	local uid = plr.UserId
	local s = session[uid]
	if s then return s.profile end
	deps()
	local loaded = nil
	local ok, data = pcall(DataStore.Load, uid)
	if ok and type(data) == "table" then loaded = data end
	local d = defaultProfile()
	if loaded then
		for _, field in ipairs(Constants.ProfileFields) do
			if loaded[field] ~= nil then d[field] = loaded[field] end
		end
	end
	session[uid] = { profile = d, joinedAt = os.time() }
	return d
end

function PlayerData.MarkDirty(plr)
	local s = session[plr.UserId]
	if not s then return end
	deps()
	DataStore.QueueSave(plr.UserId, function()
		-- playtime folded in at save time
		s.profile.stats = s.profile.stats or {}
		s.profile.stats.playSeconds = (s.profile.stats.playSeconds or 0) + math.floor(os.time() - s.joinedAt)
		s.joinedAt = os.time()
		return s.profile
	end)
end

function PlayerData.SaveNow(plr)
	local s = session[plr.UserId]
	if not s then return end
	deps()
	s.profile.stats = s.profile.stats or {}
	s.profile.stats.playSeconds = (s.profile.stats.playSeconds or 0) + math.floor(os.time() - s.joinedAt)
	s.joinedAt = os.time()
	DataStore.SaveNow(plr.UserId, function() return s.profile end)
end

function PlayerData.Release(plr)
	PlayerData.SaveNow(plr)
	session[plr.UserId] = nil
end

Players.PlayerRemoving:Connect(PlayerData.Release)

return PlayerData
