-- ============================================================
-- EGG RAID · Controllers/Notifications (ModuleScript → StarterPlayerScripts/Controllers)
-- Receives server push notifications into a ring buffer.
-- Rendering hooks in with the future UI task (legacy Gui7 toasts
-- stay live until then — no duplicate UI created here).
-- ============================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Notifications = { Name = "Notifications", Enabled = true }

local MAX_KEEP = 20
local buffer = {}
local listeners = {}

local function push(payload)
	table.insert(buffer, payload)
	if #buffer > MAX_KEEP then table.remove(buffer, 1) end
	for _, fn in ipairs(listeners) do
		pcall(fn, payload)
	end
end

function Notifications.Init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
	local remote = remotes:WaitForChild("RA_Notif", 30)
	if remote then
		remote.OnClientEvent:Connect(function(payload)
			if type(payload) == "table" and type(payload.text) == "string" then
				push(payload)
			end
		end)
	end
end

function Notifications.GetRecent(n)
	local out = {}
	local from = math.max(1, #buffer - (n or MAX_KEEP) + 1)
	for i = from, #buffer do table.insert(out, buffer[i]) end
	return out
end

-- Future UI registers a renderer here (keeps this controller UI-free)
function Notifications.OnNotification(fn)
	table.insert(listeners, fn)
end

function Notifications.Destroy()
	table.clear(buffer)
	table.clear(listeners)
end

return Notifications
