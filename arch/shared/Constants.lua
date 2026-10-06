-- ============================================================
-- EGG RAID · Shared/Constants (ModuleScript → ReplicatedStorage/Shared/Constants)
-- Central names/limits shared by server + client. No logic here.
-- ============================================================
local Constants = {
	RemoteNames = {
		RPC          = "RA_RPC",   -- central client→server request channel
		Notification = "RA_Notif", -- server→client notifications
		Settings     = "RA_Settings", -- client→server settings push
	},
	DataStores = {
		Profiles = "EGGRAID_Profiles_v1",
	},
	Limits = {
		MaxMoney       = 1e12,
		MaxEggsStorage = 200,
		MaxPets        = 500,
		MaxCarryEggs   = 1,
	},
	Defaults = {
		StartMoney = 150,
		BaseLvl    = 1,
	},
	ProfileFields = { "money", "eggs", "pets", "baseLvl", "quests", "daily", "upgrades", "settings", "stats" },
}

return Constants
