-- ============================================================
-- EGG RAID · Client (LocalScript → StarterPlayerScripts/Client)
-- Client bootstrap. Controllers live in StarterPlayerScripts/
-- Controllers. The client only ever REQUESTS; the server decides.
-- The legacy UI (LocalScript) and intro (Intro) keep running —
-- nothing here duplicates them.
-- ============================================================
local Controllers = require(script.Parent:WaitForChild("Controllers"):WaitForChild("Init"))

Controllers.InitAll()

local Client = {
	Controllers = Controllers,
	Player = game:GetService("Players").LocalPlayer,
}

-- Request helpers (all go through the central RPC channel)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RPC = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RPC"))
Client.Request = RPC.Call

local GPConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("GamepassConfig"))
function Client.PromptGamepass(key)
	if not GPConfig.Get(key) then return end
	RPC.Call("PromptGamepass", key)
end

_G.EGGRAID_CLIENT = Client
print("EGG RAID CLIENT READY")
