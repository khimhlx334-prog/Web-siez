-- ============================================================
-- EGG RAID · Systems/Economy (ModuleScript → ServerScriptService/Systems)
-- All money math for modular systems. Clamped, logged, server-only.
-- ============================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("GameConfig"))

local Economy = {}

function Economy.Add(profile, amount)
	if type(amount) ~= "number" or amount ~= amount or amount <= 0 then return profile.money end
	profile.money = math.min(GameConfig.MoneyMax, profile.money + math.floor(amount))
	return profile.money
end

function Economy.TrySpend(profile, amount)
	if type(amount) ~= "number" or amount <= 0 then return false end
	amount = math.floor(amount)
	if profile.money < amount then return false end
	profile.money = profile.money - amount
	return true
end

-- Official Robux → in-game money. Called ONLY from MarketplaceService
-- callbacks (ProcessReceipt / Gamepass purchase server events).
function Economy.GrantFromRobux(profile, robuxSpent)
	if type(robuxSpent) ~= "number" or robuxSpent <= 0 then return 0 end
	local grant = math.floor(robuxSpent * GameConfig.RobuxToMoneyRate)
	return Economy.Add(profile, grant)
end

return Economy
