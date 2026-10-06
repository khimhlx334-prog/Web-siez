-- ============================================================
-- EGG RAID · Systems/EventSystem (ModuleScript → ServerScriptService/Systems/EventSystem)
-- Scheduled in-game events, computed from os.time() on demand.
-- NO permanent loops and NO polling: future systems ask
-- EventSystem.IsActive(name) at the moment they need it.
-- ============================================================
local EventSystem = {}

-- Definitions (tunable later via GameConfig)
EventSystem.Definitions = {
	doubleMoney = { kind = "double_money", cadenceMin = 60 }, -- 1h window every 6h
	dailyBonus  = { kind = "daily" },
}

local DAILY_RESET_HOUR_UTC = 0

-- next start timestamp for a cadence-based event
local function nextCadenceStart(cadenceMin, now)
	local period = cadenceMin * 60 * 4 -- active 25% of the cycle
	local cycle = cadenceMin * 60 * 4
	local anchor = math.floor(now / (cycle * 4)) * (cycle * 4)
	return anchor
end

function EventSystem.IsActive(name, now)
	now = now or os.time()
	local def = EventSystem.Definitions[name]
	if not def then return false end
	if def.kind == "daily" then
		local t = os.date("!*t", now)
		return t.hour >= DAILY_RESET_HOUR_UTC -- daily window open after reset hour
	end
	if def.kind == "double_money" then
		local cycle = def.cadenceMin * 60 * 4 -- 4h cycle: 1h active
		local phase = now % cycle
		return phase < def.cadenceMin * 60
	end
	return false
end

-- Seconds until next start (for countdown UI)
function EventSystem.SecondsUntilStart(name, now)
	now = now or os.time()
	local def = EventSystem.Definitions[name]
	if not def or def.kind ~= "double_money" then return nil end
	local cycle = def.cadenceMin * 60 * 4
	local phase = now % cycle
	if phase < def.cadenceMin * 60 then return 0 end -- active now
	return cycle - phase
end

-- Multiplier helper future economy code will call
function EventSystem.MoneyMultiplier(now)
	return EventSystem.IsActive("doubleMoney", now) and 2 or 1
end

return EventSystem
