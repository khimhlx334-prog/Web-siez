-- ============================================================
-- EGG RAID · Systems/PlayerData (ModuleScript → ServerScriptService/Systems)
-- NEW profile store for modular systems (key prefix EGGRAID_).
-- The legacy monolith keeps its own store until migrated.
-- Server-authoritative. Clients never write profiles.
-- ============================================================
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("DataStoreService") and game:GetService("Players")

local PlayerData = {}
local store = DataStoreService:GetDataStore("EGGRAID_Profiles_v1")
local session = {}

local function defaultProfile()
	return {
		money = 0,
		eggs = {},        -- stored eggs {pet, weight, readyAt}
		pets = {},        -- pet entries "id@weight" / "BIGid@weight"
		baseLvl = 1,
		quests = {},      -- [questId] = progress
		lastDaily = 0,
		stats = { steals = 0, hatches = 0, sells = 0 },
	}
end

function PlayerData.Get(plr)
	local uid = plr.UserId
	if session[uid] then return session[uid] end
	local ok, got = pcall(function() return store:GetAsync("u_" .. uid) end)
	local d = defaultProfile()
	if ok and type(got) == "table" then
		for k, v in pairs(got) do d[k] = v end
	end
	d.stats = d.stats or defaultProfile().stats
	session[uid] = d
	return d
end

function PlayerData.Save(plr)
	local d = session[plr.UserId]
	if not d then return end
	pcall(function() store:SetAsync("u_" .. plr.UserId, d) end)
end

function PlayerData.Release(plr)
	PlayerData.Save(plr)
	session[plr.UserId] = nil
end

Players.PlayerRemoving:Connect(PlayerData.Release)
game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do PlayerData.Save(p) end
end)

return PlayerData
