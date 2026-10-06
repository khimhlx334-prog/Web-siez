-- ============================================================
-- EGG RAID · Main (Script → ServerScriptService)
-- Architecture bootstrap: creates the folder skeleton, wires the
-- modular systems. Does NOT touch the legacy monolith (it keeps
-- running the live game until systems are migrated, Task 2+).
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

-- Systems live as sibling ModuleScripts
local systemsRoot = ServerScriptService:WaitForChild("Systems")
local function sys(name)
	return require(systemsRoot:WaitForChild(name))
end

local PlayerData   = sys("PlayerData")
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

-- Wire systems that need remotes/events at boot
Gamepasses.Init()

-- Expose the system registry to future server scripts (Task 2+):
-- they can read this Script's globals via require-free access pattern,
-- or simply require the System ModuleScripts directly (recommended).
RA_REGISTRY = {
	PlayerData = PlayerData, Economy = Economy, Eggs = Eggs, Bases = Bases,
	Pets = Pets, Zones = Zones, Quests = Quests, Rewards = Rewards,
	Leaderboards = Leaderboards, Gamepasses = Gamepasses, Admin = Admin,
	AntiCheat = AntiCheat,
}

print("EGG RAID ARCHITECTURE READY · 12 systems wired")
