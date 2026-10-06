-- ============================================================
-- EGG RAID · Shared/RPC (ModuleScript → ReplicatedStorage/Shared/RPC)
-- CENTRAL remote channel for all future systems.
-- One RemoteEvent ("RA_RPC") + action routing + middleware:
--   rate limit, argument type checks, permission checks.
-- Server registers handlers; client calls them. Server always decides.
-- No Heartbeat loops; single OnServerEvent connection.
-- ============================================================
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IS_SERVER = RunService:IsServer()

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local RPC = {}
local REMOTE_NAME = Constants.RemoteNames.RPC
local handlers = {}   -- [action] = { args = {...}, perm = fn?, run = fn }
local typeOk = { string = "string", number = "number", boolean = "boolean", table = "table" }

local function getRemote(createIfMissing)
	local f = ReplicatedStorage:FindFirstChild("Remotes")
	local r = f and f:FindFirstChild(REMOTE_NAME)
	if not r and createIfMissing then
		if not f then
			f = Instance.new("Folder"); f.Name = "Remotes"; f.Parent = ReplicatedStorage
		end
		r = Instance.new("RemoteEvent"); r.Name = REMOTE_NAME; r.Parent = f
	end
	return r
end

-- ================= SERVER =================
if IS_SERVER then
	local AntiCheat = require(game:GetService("ServerScriptService"):WaitForChild("Systems"):WaitForChild("AntiCheat"))

	function RPC.Register(action, def)
		assert(type(action) == "string" and not handlers[action], "RPC action exists: " .. tostring(action))
		handlers[action] = {
			args = def.args or {},         -- ordered list of expected types ("nil" = optional)
			perm = def.perm,                 -- fn(plr) -> bool  (e.g. Admin check)
			run  = assert(def.run, "RPC needs run"),
		}
	end

	local function checkArgs(spec, args)
		for i, want in ipairs(spec) do
			local got = args[i]
			if want ~= "nil" then
				if got == nil then return false end
				if typeOk[want] and type(got) ~= want then return false end
			end
		end
		return true
	end

	function RPC.Init()
		local remote = getRemote(true)
		remote.OnServerEvent:Connect(function(plr, action, args)
			if type(action) ~= "string" or type(args) ~= "table" then return end
			local h = handlers[action]
			if not h then return end                      -- unknown action: ignore
			if not AntiCheat.RateCheck(plr.UserId) then return end -- spam drop (silent)
			if h.perm and not h.perm(plr) then return end -- permission denied (silent)
			if #args > 12 or not checkArgs(h.args, args) then return end
			local ok, err = pcall(h.run, plr, table.unpack(args, 1, #args))
			if not ok then warn("[RPC] " .. action .. ": " .. tostring(err)) end
		end)
	end
end

-- ================= CLIENT =================
function RPC.Call(action, ...)
	if IS_SERVER then return end
	local remote = getRemote(false) or ReplicatedStorage:WaitForChild("Remotes", 15):WaitForChild(REMOTE_NAME, 15)
	if remote then remote:FireServer(action, table.pack(...)) end
end

-- Server → client push (notifications etc. use their own remotes via Remotes registry)
function RPC.GetRemote() return getRemote(not IS_SERVER and false or IS_SERVER) end

return RPC
