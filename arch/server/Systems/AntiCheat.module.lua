-- ============================================================
-- EGG RAID · Systems/AntiCheat (ModuleScript → ServerScriptService/Systems/AntiCheat)
-- Server-side validation layer. Interfaces + rate limiting today;
-- movement detectors hook in later (no permanent loops by design —
-- detectors run on demand / on remote requests).
-- ============================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("GameConfig"))

local AntiCheat = {}

-- Detection categories (future systems feed these)
AntiCheat.Detections = {
	SpeedHack      = false, -- future: position sampling vs walkspeed
	Fly            = false, -- future: airborne duration check
	NoClip         = false, -- future: collision sanity on teleport requests
	TeleportAbuse  = false, -- future: max distance per action window
	RemoteSpam     = true,  -- LIVE: token bucket below
	FakeRewards    = false, -- future: rewards only granted by server flows
	FakeItems      = false, -- future: inventory writes server-only
	DuplicateItems = false, -- future: exact-entry dedupe on write
	UnauthorizedAdmin = false, -- future: Admin.IsAdmin gate on admin RPCs
}

AntiCheat.OnFlag = nil -- optional fn(plr, category, detail) set by Main

-- ---------- rate limiting (token bucket, per player) ----------
local buckets = {} -- [userId] = { count, resetAt }

function AntiCheat.RateCheck(userId, limit)
	local now = os.clock()
	local max = limit or GameConfig.AntiCheat.RemoteRatePerSec
	local b = buckets[userId]
	if not b or now >= b.resetAt then
		buckets[userId] = { count = 1, resetAt = now + 1 }
		return true
	end
	b.count += 1
	return b.count <= max
end

function AntiCheat.Flag(plr, category, detail)
	if not plr then return end
	if AntiCheat.OnFlag then
		pcall(AntiCheat.OnFlag, plr, category, detail or "")
	end
end

-- ---------- movement sampling interface (no loops) ----------
-- Future hooks call Sample(player, position) when the player performs
-- a server-checked action; we validate distance/time since last sample.
local lastPos = {} -- [userId] = { pos, t }
function AntiCheat.Sample(plr, position)
	if not plr or not position then return true end
	local rec = lastPos[plr.UserId]
	local now = os.clock()
	if rec then
		local dt = now - rec.t
		if dt > 0.2 then
			local maxTravel = (GameConfig.WalkBase * 1.9) * dt + 4 -- 90% margin + lag grace
			if (position - rec.pos).Magnitude > maxTravel then
				AntiCheat.Flag(plr, "SpeedHack", "dist=" .. math.floor((position - rec.pos).Magnitude))
				lastPos[plr.UserId] = { pos = position, t = now }
				return false
			end
		end
	end
	lastPos[plr.UserId] = { pos = position, t = now }
	return true
end

-- Wrap a RemoteEvent handler with rate limiting (legacy helper kept)
function AntiCheat.Guard(remote)
	local wrapper = {}
	function wrapper:Connect(fn)
		return remote.OnServerEvent:Connect(function(plr, ...)
			if not AntiCheat.RateCheck(plr.UserId) then return end
			fn(plr, ...)
		end)
	end
	return wrapper
end

game:GetService("Players").PlayerRemoving:Connect(function(plr)
	buckets[plr.UserId] = nil
	lastPos[plr.UserId] = nil
end)

return AntiCheat
