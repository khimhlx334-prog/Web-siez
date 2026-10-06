-- ============================================================
-- EGG RAID · Systems/Eggs (ModuleScript → ServerScriptService/Systems)
-- Server-side egg validation helpers for the future egg remotes.
-- Pure logic only — spawning/hatching stay with the live system
-- until migration. Nothing here trusts the client.
-- ============================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("GameConfig"))

local Eggs = {}

-- May this player pick up an egg at eggPos right now?
function Eggs.CanPickup(hrpPosition, eggPos, isCarrying)
	if isCarrying then return false end -- one egg at a time
	if not hrpPosition or not eggPos then return false end
	return (eggPos - hrpPosition).Magnitude <= GameConfig.AntiCheat.PickupMaxDistance
end

-- Random weight for a rarity (trash keeps its joke 0.01 kg)
function Eggs.RollWeight(rarity)
	local base = GameConfig.EggBaseWeight[rarity] or 10
	if base < 1 then return base end
	local lo, hi = 0.8, 1.6
	local w = base * (lo + math.random() * (hi - lo))
	return math.max(1, math.floor(w * 10) / 10)
end

-- Weighted rarity roll using SpawnWeight table
function Eggs.RollRarity(pool)
	local total = 0
	for _, p in ipairs(pool) do total += GameConfig.SpawnWeight[p.rarity] or 1 end
	local r = math.random() * total
	for _, p in ipairs(pool) do
		r -= GameConfig.SpawnWeight[p.rarity] or 1
		if r <= 0 then return p end
	end
	return pool[#pool]
end

-- Hatch wait seconds (rarer + heavier = longer, capped 2 days)
function Eggs.HatchWait(rarity, weight)
	local base = GameConfig.HatchWaitBase[rarity] or 60
	local bw = GameConfig.EggBaseWeight[rarity] or 10
	local mult = math.clamp(weight / bw, GameConfig.WeightMultRange[1], GameConfig.WeightMultRange[2])
	return math.min(GameConfig.HatchWaitMax, math.floor(base * mult))
end

-- Walk speed while carrying (heavier = slower)
function Eggs.CarryWalkSpeed(weight)
	return math.clamp(GameConfig.WalkBase - weight * GameConfig.CarrySlowPerKg, GameConfig.WalkMin, GameConfig.WalkBase)
end

return Eggs
