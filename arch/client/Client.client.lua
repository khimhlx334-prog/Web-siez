-- ============================================================
-- EGG RAID · Client (LocalScript → StarterPlayerScripts)
-- Thin client bootstrap for the modular systems.
--  * May only REQUEST actions via Remotes (server validates).
--  * Never trusts or stores authoritative state.
-- The legacy UI (Gui7) stays live until the UI migration task.
-- ============================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local plr = Players.LocalPlayer

local shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(shared:WaitForChild("Remotes"))
local GamepassConfig = require(shared:WaitForChild("Config"):WaitForChild("GamepassConfig"))

local Client = {}

-- Ask the server to show the OFFICIAL gamepass purchase prompt.
-- This is the ONLY gamepass-related thing a client may do.
function Client.PromptGamepass(key)
	if not GamepassConfig.Get(key) then return end
	local r = Remotes.Event(Remotes.Names.RequestPromptGP, false)
	if r then r:FireServer(key) end
end

-- Generic request helper for future systems (server-validated)
function Client.Request(name, ...)
	local r = Remotes.Event(name, false)
	if r then r:FireServer(...) end
end

Client.Player = plr
_G.EGGRAID_CLIENT = Client -- temporary handle for the future UI layer

print("EGG RAID CLIENT READY")
