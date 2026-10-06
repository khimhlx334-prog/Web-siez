-- ============================================================
-- EGG RAID · Systems/SettingsSvc (ModuleScript → ServerScriptService/Systems/SettingsSvc)
-- Per-player settings: whitelist + type checks + RPC action.
-- Persisted inside the modular profile (profile.settings).
-- ============================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RPC = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RPC"))

local SettingsSvc = {}

-- Whitelist: key -> allowed lua type + constraint
SettingsSvc.Schema = {
	language  = { t = "string",  oneOf = { "en", "th", "es", "pt", "id", "vi", "zh", "ko", "ja" } },
	music     = { t = "boolean" },
	sfx       = { t = "boolean" },
	quality   = { t = "string",  oneOf = { "low", "medium", "high" } },
	showHints = { t = "boolean" },
}

function SettingsSvc.Validate(key, value)
	local s = SettingsSvc.Schema[key]
	if not s or type(value) ~= s.t then return false end
	if s.oneOf then
		for _, v in ipairs(s.oneOf) do
			if v == value then return true end
		end
		return false
	end
	return true
end

function SettingsSvc.Get(profile, key)
	if not SettingsSvc.Schema[key] then return nil end
	profile.settings = profile.settings or {}
	return profile.settings[key]
end

function SettingsSvc.Set(profile, key, value)
	if not SettingsSvc.Validate(key, value) then return false end
	profile.settings = profile.settings or {}
	profile.settings[key] = value
	return true
end

-- Wire the RPC action once at boot (called from Main)
function SettingsSvc.Init(getProfile, markDirty)
	RPC.Register("Settings.Set", {
		args = { "string", "string" },
		run = function(plr, key, valueRaw)
			-- values arrive string-encoded from the client
			local profile = getProfile(plr)
			if not profile then return end
			local s = SettingsSvc.Schema[key]
			if not s then return end
			local value
			if s.t == "boolean" then
				if valueRaw == "true" then value = true elseif valueRaw == "false" then value = false end
			elseif s.t == "number" then
				value = tonumber(valueRaw)
			else
				value = valueRaw
			end
			if value == nil then return end
			if SettingsSvc.Set(profile, key, value) then markDirty(plr) end
		end,
	})
	RPC.Register("Settings.Get", {
		args = {},
		run = function(plr)
			_ = getProfile(plr) -- profile auto-loads; client reads its own cache
		end,
	})
end

return SettingsSvc
