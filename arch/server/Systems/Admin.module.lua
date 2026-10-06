-- ============================================================
-- EGG RAID · Systems/Admin (ModuleScript → ServerScriptService/Systems)
-- Server-side permission checks. Clients can never grant admin.
-- ============================================================
local Admin = {}

-- Put real UserIds here (or rely on place ownership). Never client-set.
Admin.OwnerIds = {}

function Admin.IsAdmin(plr)
	if not plr then return false end
	if plr.UserId == 0 then return true end -- Studio solo test
	if game.CreatorType == Enum.CreatorType.User and plr.UserId == game.CreatorId then return true end
	for _, id in ipairs(Admin.OwnerIds) do
		if id == plr.UserId then return true end
	end
	return false
end

return Admin
