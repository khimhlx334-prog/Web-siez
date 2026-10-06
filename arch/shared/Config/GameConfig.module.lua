-- ============================================================
-- EGG RAID · GameConfig (ModuleScript → ReplicatedStorage/Shared/Config)
-- Central tunables for ALL future systems. Server + client may read.
-- NOTE: the legacy monolith (GameCore7) still keeps its own copy of
-- these values until it is migrated system-by-system (Task 2+).
-- ============================================================
local GameConfig = {}

GameConfig.GameName = "EGG RAID: Island Heist"

-- Islands / Zones (circular zones; pos = center, r = radius)
GameConfig.Islands = {
	{ id = "start",  n = 1, pos = { 0, 0, 0 },        r = 90,  unlock = 0 },
	{ id = "grass",  n = 2, pos = { 500, 0, 0 },      r = 120, unlock = 0 },
	{ id = "desert", n = 3, pos = { -500, 0, 300 },   r = 130, unlock = 0 },
	{ id = "ice",    n = 4, pos = { 300, 0, -700 },   r = 140, unlock = 0 },
	{ id = "shadow", n = 5, pos = { -400, 0, -1100 }, r = 150, unlock = 0 },
}

-- Rarity ladder (order matters)
GameConfig.RarityOrder = { "common", "uncommon", "rare", "epic", "legendary", "mythic", "secret", "divine", "mystery", "trash" }
GameConfig.RarityPower = { common = 1, uncommon = 3, rare = 10, epic = 40, legendary = 200, mythic = 1000, secret = 5000, divine = 25000, mystery = 100000, trash = 1000 }
GameConfig.RaritySell  = { common = 50, uncommon = 150, rare = 500, epic = 2000, legendary = 10000, mythic = 50000, secret = 250000, divine = 1000000, mystery = 10000000, trash = 1 }
GameConfig.EggBaseWeight = { common = 10, uncommon = 20, rare = 40, epic = 80, legendary = 150, mythic = 300, secret = 600, divine = 1200, mystery = 2500, trash = 0.01 }
GameConfig.SpawnWeight = { common = 60, uncommon = 30, rare = 16, epic = 7, legendary = 3, mythic = 1.2, secret = 0.45, divine = 0.12, mystery = 0.03, trash = 0.1 }
GameConfig.HatchWaitBase = { common = 10, uncommon = 30, rare = 120, epic = 600, legendary = 3600, mythic = 21600, secret = 43200, divine = 86400, mystery = 172800, trash = 300 }
GameConfig.HatchWaitMax = 172800 -- 2 days
GameConfig.WeightMultRange = { 0.5, 2 }

-- Economy
GameConfig.MoneyMax = 1e12
GameConfig.StartMoney = 150
GameConfig.RobuxToMoneyRate = 500 -- official purchases only (MarketplaceService)
GameConfig.GardenSlotsBase = 8
GameConfig.GardenSlotsPerLevel = 4

-- Carrying
GameConfig.WalkBase = 16
GameConfig.WalkMin = 6
GameConfig.CarrySlowPerKg = 0.06

-- Anti-cheat
GameConfig.AntiCheat = {
	RemoteRatePerSec = 20,   -- max remote calls/sec per player
	PickupMaxDistance = 9,   -- studs
	ActMaxDistance = 30,
}

-- Localization supported codes (full UI lives in legacy EggLang until migrated)
GameConfig.Languages = { "en", "th", "es", "pt", "id", "vi", "zh", "ko", "ja" }
GameConfig.DefaultLanguage = "en"

return GameConfig
