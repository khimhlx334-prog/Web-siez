-- ============================================================
-- EGG RAID · Shared/Localization (ModuleScript → ReplicatedStorage/Shared/Localization)
-- Facade over the legacy EggLang module (ReplicatedStorage.EggLang).
-- Single entry point for ALL future UI text. Never inline strings.
-- ============================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Localization = {}
local langModule = ReplicatedStorage:WaitForChild("EggLang", 15)
local dict = langModule and require(langModule) or nil

Localization.Default = "en"
Localization.Current = "en"

function Localization.SetLanguage(code)
	if dict and dict[code] then
		Localization.Current = code
		return true
	end
	return false
end

-- T(key) or T(code, key) — returns translated text, falls back to en, then key
function Localization.T(a, b)
	local code, key
	if b == nil then code, key = Localization.Current, a else code, key = a, b end
	if not dict then return tostring(key) end
	local pack = dict[code] or dict[Localization.Default]
	if pack and pack[key] ~= nil then return pack[key] end
	if dict[Localization.Default] and dict[Localization.Default][key] ~= nil then
		return dict[Localization.Default][key]
	end
	return tostring(key)
end

function Localization.Available()
	local out = {}
	if dict then for k in pairs(dict) do table.insert(out, k) end end
	table.sort(out)
	return out
end

return Localization
