-- ============================================================
-- EGG RAID · Systems/Quests (ModuleScript → ServerScriptService/Systems)
-- Quest definitions + progress API on modular profiles.
-- Progress is ONLY added by server systems (steal/hatch/sell hooks).
-- ============================================================
local Quests = {}

Quests.Definitions = {
	{ id = "q_steal3",  goal = 3,  rewardMoney = 500,   NameKey = "quest_steal3",  stat = "steals" },
	{ id = "q_hatch1",  goal = 1,  rewardMoney = 300,   NameKey = "quest_hatch1",  stat = "hatches" },
	{ id = "q_sell2",   goal = 2,  rewardMoney = 400,   NameKey = "quest_sell2",   stat = "sells" },
	{ id = "q_steal10", goal = 10, rewardMoney = 2500,  NameKey = "quest_steal10", stat = "steals" },
}

function Quests.Get(id)
	for _, q in ipairs(Quests.Definitions) do
		if q.id == id then return q end
	end
	return nil
end

function Quests.Progress(profile, id)
	return profile.quests[id] or 0
end

-- Server hook: add progress; returns rewardMoney when completed NOW
function Quests.AddProgress(profile, id, n)
	local q = Quests.Get(id)
	if not q then return 0 end
	local before = profile.quests[id] or 0
	if before >= q.goal then return 0 end
	local after = math.min(q.goal, before + (n or 1))
	profile.quests[id] = after
	if after >= q.goal and before < q.goal then return q.rewardMoney end
	return 0
end

return Quests
