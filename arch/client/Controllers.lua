-- ============================================================
-- EGG RAID · Controllers index (ModuleScript → StarterPlayerScripts/Controllers)
-- Requires + initializes all client controllers once. Each
-- controller owns one responsibility and cleans up in Destroy().
-- ============================================================
local Controllers = {}
local loaded = {}

local NAMES = { "Notifications", "Settings", "Camera", "Intro" }

function Controllers.Require(name)
	local c = loaded[name]
	if not c then
		c = require(script.Parent:WaitForChild(name))
		loaded[name] = c
	end
	return c
end

function Controllers.InitAll()
	for _, n in ipairs(NAMES) do
		local c = Controllers.Require(n)
		if c.Enabled then
			local ok, err = pcall(c.Init)
			if not ok then warn("[Controllers] " .. n .. " init failed: " .. tostring(err)) end
		end
	end
end

function Controllers.DestroyAll()
	for _, c in pairs(loaded) do
		if c.Destroy then pcall(c.Destroy) end
	end
	table.clear(loaded)
end

return Controllers
