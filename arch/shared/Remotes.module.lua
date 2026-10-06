-- ============================================================
-- EGG RAID · Remotes (ModuleScript → ReplicatedStorage/Shared)
-- Single registry for every RemoteEvent/RemoteFunction.
-- Legacy monolith remotes live at ReplicatedStorage root; new
-- systems live in ReplicatedStorage/Remotes. Get() bridges both
-- so there is never a duplicate remote with the same name.
-- ============================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = {}

local function folder()
	local f = ReplicatedStorage:FindFirstChild("Remotes")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Remotes"
		f.Parent = ReplicatedStorage
	end
	return f
end

-- Get-or-create a RemoteEvent by name (server creates; client waits)
function Remotes.Event(name, isServer)
	local f = folder()
	local r = f:FindFirstChild(name) or ReplicatedStorage:FindFirstChild(name)
	if not r and isServer then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = f
	end
	if not r and not isServer then
		r = ReplicatedStorage:WaitForChild(name, 10) or f:WaitForChild(name, 10)
	end
	return r
end

function Remotes.Function(name, isServer)
	local f = folder()
	local r = f:FindFirstChild(name) or ReplicatedStorage:FindFirstChild(name)
	if not r and isServer then
		r = Instance.new("RemoteFunction")
		r.Name = name
		r.Parent = f
	end
	if not r and not isServer then
		r = f:WaitForChild(name, 10)
	end
	return r
end

-- Names reserved for the future modular systems (Task 2+)
Remotes.Names = {
	RequestAction   = "RA_Action",    -- client requests; server validates (AntiCheat-wrapped)
	RequestPickup   = "RA_Pickup",
	RequestHatch    = "RA_Hatch",
	RequestSell     = "RA_Sell",
	RequestQuest    = "RA_Quest",
	RequestDaily    = "RA_Daily",
	RequestPromptGP = "RA_PromptGP",  -- client asks for an official purchase prompt only
	StateUpdate     = "RA_State",     -- server → client profile snapshots
	ShopCatalog     = "RA_Shop",      -- server → client official catalog
}

return Remotes
