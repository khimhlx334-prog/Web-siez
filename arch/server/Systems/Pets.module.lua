-- ============================================================
-- EGG RAID · Systems/Pets (ModuleScript → ServerScriptService/Systems)
-- Pet inventory ops on modular profiles. Entry format "id@weight".
-- ============================================================
local Pets = {}

local function parse(en)
	local base, big = en, false
	if base:sub(1, 3) == "BIG" then big = true; base = base:sub(4) end
	local i = base:find("@")
	local w = nil
	if i then w = tonumber(base:sub(i + 1)); base = base:sub(1, i - 1) end
	return base, big, w
end

function Pets.Parse(entry) return parse(entry) end

function Pets.Add(profile, petId, weight)
	if type(petId) ~= "string" or petId == "" then return false end
	table.insert(profile.pets, petId .. "@" .. tostring(weight or 0))
	return true
end

-- Remove one EXACT entry (server picks; client may only request by entry)
function Pets.Remove(profile, entry)
	for i, x in ipairs(profile.pets) do
		if x == entry then
			table.remove(profile.pets, i)
			return true
		end
	end
	return false
end

function Pets.CountBase(profile, baseId)
	local n = 0
	for _, en in ipairs(profile.pets) do
		local b, big = parse(en)
		if b == baseId and not big then n += 1 end
	end
	return n
end

function Pets.Owns(profile, baseId)
	for _, en in ipairs(profile.pets) do
		if parse(en) == baseId then return true end
	end
	return false
end

return Pets
