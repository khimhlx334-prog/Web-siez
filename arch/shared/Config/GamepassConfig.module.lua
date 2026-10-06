-- ============================================================
-- EGG RAID · GamepassConfig (ModuleScript → ReplicatedStorage/Shared/Config)
-- Interface for the FUTURE official Gamepass shop.
--
-- SECURITY CONTRACT:
--  * GamepassId = 0  →  NOT configured → benefit is NEVER granted.
--  * Ownership is ONLY checked on the server via MarketplaceService.
--  * The client may only REQUEST a purchase prompt; it never grants.
--  * No fake Robux currency, no fake purchase confirmation, ever.
-- ============================================================
local GamepassConfig = {}

GamepassConfig.Catalog = {
	-- key            = internal id used by all systems
	-- GamepassId     = real Roblox game pass id (set in Creator Dashboard; 0 = off)
	-- PriceRobux     = reference price for the future shop UI
	{ key = "money2x",   GamepassId = 0, PriceRobux = 399,  NameKey = "gp_money2x" },
	{ key = "luck2x",    GamepassId = 0, PriceRobux = 499,  NameKey = "gp_luck2x" },
	{ key = "speed2x",   GamepassId = 0, PriceRobux = 299,  NameKey = "gp_speed2x" },
	{ key = "vip",       GamepassId = 0, PriceRobux = 799,  NameKey = "gp_vip" },
	{ key = "biggerbag", GamepassId = 0, PriceRobux = 249,  NameKey = "gp_biggerbag" },
}

GamepassConfig.DeveloperProducts = {
	-- One-time consumables (official Developer Products, ProcessReceipt on server)
	{ key = "coins_small", ProductId = 0, PriceRobux = 49,  GrantMoney = 10000 },
	{ key = "coins_big",   ProductId = 0, PriceRobux = 399, GrantMoney = 1000000 },
}

function GamepassConfig.Get(key)
	for _, g in ipairs(GamepassConfig.Catalog) do
		if g.key == key then return g end
	end
	return nil
end

function GamepassConfig.IsConfigured(key)
	local g = GamepassConfig.Get(key)
	return g ~= nil and g.GamepassId > 0
end

return GamepassConfig
