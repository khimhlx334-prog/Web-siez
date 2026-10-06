-- ============================================================
-- EGG RAID · Systems/AntiCheat (ModuleScript → ServerScriptService/Systems)
-- Server-side remote middleware: per-player rate limiting.
-- Wrap EVERY future gameplay remote handler with Guard().
-- ============================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("GameConfig"))

local AntiCheat = {}
local buckets = {} -- [userId] = {count, resetAt}

local function rateOK(uid)
	local now = os.clock()
	local b = buckets[uid]
	if not b or now >= b.resetAt then
		buckets[uid] = { count = 1, resetAt = now + 1 }
		return true
	end
	b.count += 1
	return b.count <= GameConfig.AntiCheat.RemoteRatePerSec
end

-- Guard(remote): returns a connect helper that drops abusive callers.
-- Usage:  AntiCheat.Guard(remote):Connect(function(plr, ...) ... end)
function AntiCheat.Guard(remote)
	local wrapper = {}
	function wrapper:Connect(fn)
		return remote.OnServerEvent:Connect(function(plr, ...)
			if not rateOK(plr.UserId) then return end -- silent drop
			fn(plr, ...)
		end)
	end
	return wrapper
end

return AntiCheat
