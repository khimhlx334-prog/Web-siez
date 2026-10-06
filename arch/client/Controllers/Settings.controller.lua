-- ============================================================
-- EGG RAID · Controllers/Settings (ModuleScript → StarterPlayerScripts/Controllers)
-- Client-side settings cache. Writes go through the central RPC;
-- the server validates + persists. Values travel string-encoded.
-- ============================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Settings = { Name = "Settings", Enabled = true }
local cache = {
	language = "en",
	music = true,
	sfx = true,
	quality = "medium",
	showHints = true,
}
local listeners = {}

local function getRPC()
	return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RPC"))
end

function Settings.Get(key) return cache[key] end

function Settings.SetLocal(key, value) -- immediate optimistic update
	cache[key] = value
	for _, fn in ipairs(listeners) do pcall(fn, key, value) end
end

-- Send to server (server rejects invalid keys/values silently)
function Settings.Set(key, value)
	Settings.SetLocal(key, value)
	getRPC().Call("Settings.Set", key, tostring(value))
end

function Settings.OnChanged(fn) table.insert(listeners, fn) end

function Settings.Init()
	-- restore persisted settings from server on demand (no polling)
	getRPC().Call("Settings.Get")
end

function Settings.Destroy() table.clear(listeners) end

return Settings
