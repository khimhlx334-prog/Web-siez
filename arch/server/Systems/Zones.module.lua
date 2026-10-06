-- ============================================================
-- EGG RAID · Systems/Zones (ModuleScript → ServerScriptService/Systems)
-- Circular island zones from GameConfig. Pure server math.
-- ============================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("GameConfig"))

local Zones = {}

function Zones.All() return GameConfig.Islands end

function Zones.At(point)
	if not point then return nil end
	for _, z in ipairs(GameConfig.Islands) do
		local dx = point.X - z.pos[1]
		local dz = point.Z - z.pos[3]
		if math.sqrt(dx * dx + dz * dz) <= z.r then return z end
	end
	return nil
end

function Zones.Contains(zoneId, point)
	local z = Zones.At(point)
	return z ~= nil and z.id == zoneId
end

return Zones
