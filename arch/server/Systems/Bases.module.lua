-- ============================================================
-- EGG RAID · Systems/Bases (ModuleScript → ServerScriptService/Systems)
-- Base (home plot) ownership + level data on modular profiles.
-- Physical base building arrives with the migration tasks.
-- ============================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("GameConfig"))

local Bases = {}

function Bases.Slots(profile)
	return GameConfig.GardenSlotsBase + (profile.baseLvl - 1) * GameConfig.GardenSlotsPerLevel
end

function Bases.CanUpgrade(profile, costTable)
	local nextLvl = profile.baseLvl + 1
	local cost = costTable and costTable[nextLvl]
	if not cost then return false, nil end
	return profile.money >= cost, cost
end

function Bases.Upgrade(profile, costTable)
	local ok, cost = Bases.CanUpgrade(profile, costTable)
	if not ok then return false end
	profile.money = profile.money - cost
	profile.baseLvl = profile.baseLvl + 1
	return true
end

return Bases
