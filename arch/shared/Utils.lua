-- ============================================================
-- EGG RAID · Shared/Utils (ModuleScript → ReplicatedStorage/Shared/Utils)
-- Small reusable helpers. Pure functions, no services, no loops.
-- ============================================================
local Utils = {}

function Utils.clamp(v, lo, hi)
	if type(v) ~= "number" then return lo end
	return math.clamp(v, lo, hi)
end

function Utils.round(v)
	return math.floor((v or 0) + 0.5)
end

-- Weighted pick from { {item, weight} } — returns item or nil
function Utils.weightedPick(entries)
	local total = 0
	for _, e in ipairs(entries) do total += e.weight end
	if total <= 0 then return nil end
	local r = math.random() * total
	for _, e in ipairs(entries) do
		r -= e.weight
		if r <= 0 then return e.item end
	end
	return entries[#entries].item
end

function Utils.deepCopy(t)
	if type(t) ~= "table" then return t end
	local out = {}
	for k, v in pairs(t) do out[k] = Utils.deepCopy(v) end
	return out
end

function Utils.distance3(a, b)
	if not a or not b then return math.huge end
	return (a - b).Magnitude
end

function Utils.distanceXZ(a, b)
	if not a or not b then return math.huge end
	local dx = a.X - b.X
	local dz = a.Z - b.Z
	return math.sqrt(dx * dx + dz * dz)
end

function Utils.formatNumber(n)
	n = Utils.round(n or 0)
	if n >= 1e9 then return string.format("%.2fB", n / 1e9) end
	if n >= 1e6 then return string.format("%.2fM", n / 1e6) end
	if n >= 1e3 then return string.format("%.1fK", n / 1e3) end
	return tostring(n)
end

-- Short collision-safe id (no HttpService needed)
function Utils.newId()
	return string.format("%x-%s", os.time(), string.rep("x", 4):gsub("x", function()
		return string.char(97 + math.random(0, 25))
	end))
end

return Utils
