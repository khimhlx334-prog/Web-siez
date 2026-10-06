-- ============================================================
-- EGG RAID · Systems/Leaderboards (ModuleScript → ServerScriptService/Systems)
-- Session leaderboards from player Attributes (set by live systems).
-- Keys map to attributes so no client can forge a rank.
-- ============================================================
local Players = game:GetService("Players")

local Leaderboards = {}

Leaderboards.Keys = {
	income  = "Income",      -- $/sec
	robux   = "RobuxSpent",  -- official Robux spent (MarketplaceService only)
	play    = "PlayHours",   -- hours played
	money   = "Money",       -- via leaderstats
}

function Leaderboards.Top(key, n)
	local attr = Leaderboards.Keys[key]
	if not attr then return {} end
	local rows = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local v = 0
		if key == "money" then
			local ls = p:FindFirstChild("leaderstats")
			v = ls and ls:FindFirstChild("Money") and ls.Money.Value or 0
		else
			v = p:GetAttribute(attr) or 0
		end
		table.insert(rows, { name = p.Name, userId = p.UserId, value = v })
	end
	table.sort(rows, function(a, b) return a.value > b.value end)
	local out = {}
	for i = 1, math.min(n or 5, #rows) do table.insert(out, rows[i]) end
	return out
end

return Leaderboards
