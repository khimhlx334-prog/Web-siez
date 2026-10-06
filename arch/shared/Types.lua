-- ============================================================
-- EGG RAID · Shared/Types (ModuleScript → ReplicatedStorage/Shared/Types)
-- Shared type definitions for every future system (documentation
-- contracts; Luau type checking picks these up automatically).
-- ============================================================
local Types = {}

--[[
	type EggId = string
	type PetEntry = string          -- "<petId>@<weightKg>" | "BIG<petId>@<weightKg>"
	type RarityId = "common" | "uncommon" | "rare" | "epic" | "legendary"
		| "mythic" | "secret" | "divine" | "mystery" | "trash"

	type EggInstance = {
		rarity: RarityId,
		weightKg: number,           -- server-rolled only
		spawnPos: Vector3,
		spawnedAt: number,          -- os.time()
		islandId: string,
		carriedBy: number?,         -- UserId or nil
	}

	type PetInstance = {
		petId: string,
		rarity: RarityId,
		level: number,
		weightKg: number,
		isBig: boolean,
	}

	type PlayerProfile = {
		money: number,
		eggs: { EggInstance },      -- storage (base), server-owned
		pets: { PetEntry },
		baseLvl: number,
		quests: { [string]: number },
		daily: { lastClaim: number, streak: number },
		upgrades: { [string]: number },
		settings: { [string]: string | number | boolean },
		stats: { steals: number, hatches: number, sells: number, playSeconds: number },
	}

	type QuestDef = {
		id: string,
		goal: number,
		rewardMoney: number,
		nameKey: string,
		stat: string,
	}

	type ZoneDef = {
		id: string,
		n: number,
		pos: { number },            -- {x, y, z} center
		r: number,                  -- radius studs
		unlock: number,             -- unlock cost / requirement tag
	}

	type GamepassDef = {
		key: string,
		GamepassId: number,         -- 0 = not configured, never grants
		PriceRobux: number,
		NameKey: string,
	}

	type DeveloperProductDef = {
		key: string,
		ProductId: number,          -- 0 = not configured
		PriceRobux: number,
		GrantMoney: number,
	}

	type ScheduledEventDef = {
		name: string,
		kind: string,               -- "daily" | "double_money"
		cadenceMin: number,
	}

	type NotificationPayload = {
		text: string,               -- plain text (UI colors it; no emoji)
		kind: string?,              -- "info" | "success" | "warning" | "error"
		duration: number?,
	}
]]

Types.VERSION = 1
return Types
