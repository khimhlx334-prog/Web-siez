-- ============================================================
-- EGG RAID · Systems/Gamepasses (ModuleScript → ServerScriptService/Systems)
-- OFFICIAL Roblox gamepass integration. SERVER-AUTHORITATIVE.
--  * HasPass()   → MarketplaceService:UserOwnsGamePassAsync (cached)
--  * Prompt()    → server asks client to show the OFFICIAL prompt only
--  * Unconfigured ids (0) NEVER grant benefits.
-- ============================================================
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GamepassConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("GamepassConfig"))

local Gamepasses = {}
local cache = {} -- [userId][key] = bool

function Gamepasses.HasPass(plr, key)
	local g = GamepassConfig.Get(key)
	if not g or g.GamepassId <= 0 then return false end -- not configured = never granted
	cache[plr.UserId] = cache[plr.UserId] or {}
	local c = cache[plr.UserId][key]
	if c ~= nil then return c end
	local ok, own = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(plr.UserId, g.GamepassId) end)
	local v = (ok and own) == true
	cache[plr.UserId][key] = v
	return v
end

-- Client requested a purchase prompt (only allowed action for clients)
local function onPrompt(plr, key)
	local g = GamepassConfig.Get(key)
	if not g or g.GamepassId <= 0 then return end
	MarketplaceService:PromptGamePassPurchase(plr, g.GamepassId)
end

function Gamepasses.Init()
	-- routed via the CENTRAL RPC channel (no dedicated remote)
	local RPC = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RPC"))
	RPC.Register("PromptGamepass", {
		args = { "string" },
		run = function(plr, key) onPrompt(plr, key) end,
	})
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, id, purchased)
		if purchased then
			for _, g in ipairs(GamepassConfig.Catalog) do
				if g.GamepassId == id then
					cache[plr.UserId] = cache[plr.UserId] or {}
					cache[plr.UserId][g.key] = true
				end
			end
		end
	end)
end

Players.PlayerRemoving:Connect(function(plr) cache[plr.UserId] = nil end)

return Gamepasses
