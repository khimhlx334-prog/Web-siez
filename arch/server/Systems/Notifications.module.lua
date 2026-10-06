-- ============================================================
-- EGG RAID · Systems/Notifications (ModuleScript → ServerScriptService/Systems/Notifications)
-- Server → client push channel (single RemoteEvent via registry).
-- Payload: { text = string, kind = "info"|"success"|"warning"|"error", duration = number? }
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local Notifications = {}
local remote

local function ensure()
	if not remote then remote = Remotes.Event(Constants.RemoteNames.Notification, true) end
	return remote
end

local function clean(payload)
	if type(payload) ~= "table" or type(payload.text) ~= "string" then return nil end
	local kind = payload.kind
	if kind ~= "info" and kind ~= "success" and kind ~= "warning" and kind ~= "error" then kind = "info" end
	return { text = payload.text:sub(1, 200), kind = kind, duration = tonumber(payload.duration) or 4 }
end

function Notifications.Send(plr, payload)
	local p = clean(payload)
	if p then ensure():FireClient(plr, p) end
end

function Notifications.Broadcast(payload)
	local p = clean(payload)
	if p then ensure():FireAllClients(p) end
end

-- Convenience: send translated key (Localization lives on client side;
-- server sends keys, client translates — keeps language per-player)
function Notifications.SendKey(plr, key, kind)
	Notifications.Send(plr, { text = key, kind = kind or "info" })
end

return Notifications
