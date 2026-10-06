-- ============================================================
-- EGG RAID · Systems/Rewards (ModuleScript → ServerScriptService/Systems)
-- Daily reward claim — server-timestamped, 20h cooldown.
-- ============================================================
local Rewards = {}

local COOLDOWN = 72000 -- 20 hours
local AMOUNT = 750

function Rewards.DailyStatus(profile)
	local left = COOLDOWN - (os.time() - (profile.lastDaily or 0))
	if left <= 0 then return true, 0 end
	return false, math.max(1, math.floor(left / 3600))
end

-- Returns granted amount or 0
function Rewards.ClaimDaily(profile)
	local ready = Rewards.DailyStatus(profile)
	if not ready then return 0 end
	profile.lastDaily = os.time()
	return AMOUNT
end

return Rewards
