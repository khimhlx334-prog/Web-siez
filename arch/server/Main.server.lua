-- ============================================================
-- EGG RAID · Main (Script → ServerScriptService/Main)
-- Server bootstrap: folder skeleton + system wiring.
-- The legacy monolith (Script "Script") keeps running the live
-- game untouched until systems migrate (Task 2+). No loops here.
-- ============================================================
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local function folderAt(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

-- ReplicatedStorage skeleton
local shared = folderAt(ReplicatedStorage, "Shared")
folderAt(shared, "Config")
folderAt(ReplicatedStorage, "Remotes")
folderAt(ReplicatedStorage, "Assets")

-- Workspace skeleton (folders only — no parts)
for _, n in ipairs({ "Map", "Bases", "EggAreas", "EggSpawns", "GamepassShop", "Spawn" }) do
	folderAt(Workspace, n)
end

-- StarterGui home for the future modular UI
folderAt(StarterGui, "MainUI")

-- Load systems (single require per module; Lua caches automatically)
local systemsRoot = ServerScriptService:WaitForChild("Systems")
local function sys(name) return require(systemsRoot:WaitForChild(name)) end

local RPC          = require(shared:WaitForChild("RPC"))
local PlayerData   = sys("PlayerData")
local DataStore    = sys("DataStore")
local Economy      = sys("Economy")
local Eggs         = sys("Eggs")
local Bases        = sys("Bases")
local Pets         = sys("Pets")
local Zones        = sys("Zones")
local Quests       = sys("Quests")
local Rewards      = sys("Rewards")
local Leaderboards = sys("Leaderboards")
local Gamepasses   = sys("Gamepasses")
local Admin        = sys("Admin")
local AntiCheat    = sys("AntiCheat")
local Notifications = sys("Notifications")
local SettingsSvc  = sys("SettingsSvc")
local EventSystem  = sys("EventSystem")

-- Wire central RPC channel (creates RA_RPC once, single connection)
RPC.Init()

-- Admin actions must pass permission checks (used by future RPCs)
local function isAdmin(plr) return Admin.IsAdmin(plr) end

-- Settings actions (real wiring; persisted in modular profile)
SettingsSvc.Init(function(plr) return PlayerData.Get(plr) end, function(plr) PlayerData.MarkDirty(plr) end)

-- Gamepasses official prompt + ownership caching
Gamepasses.Init()

-- Central registry for future server scripts
RA_REGISTRY = {
	PlayerData = PlayerData, DataStore = DataStore, Economy = Economy,
	Eggs = Eggs, Bases = Bases, Pets = Pets, Zones = Zones,
	Quests = Quests, Rewards = Rewards, Leaderboards = Leaderboards,
	Gamepasses = Gamepasses, Admin = Admin, AntiCheat = AntiCheat,
	Notifications = Notifications, SettingsSvc = SettingsSvc,
	EventSystem = EventSystem, RPC = RPC, isAdmin = isAdmin,
}

print("EGG RAID ARCHITECTURE READY · " .. "17 systems wired")
