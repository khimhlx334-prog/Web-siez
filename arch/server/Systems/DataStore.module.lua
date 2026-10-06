-- ============================================================
-- EGG RAID · Systems/DataStore (ModuleScript → ServerScriptService/Systems/DataStore)
-- SAFE player-data persistence layer. Queue + throttle; NEVER
-- saves on every value change. Debounced flush, BindToClose final
-- flush. No permanent loops (delay chain only while queue dirty).
-- ============================================================
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local DataStore = {}
local store = DataStoreService:GetDataStore(Constants.DataStores.Profiles)

local FLUSH_INTERVAL = 10      -- seconds between queued saves
local RETRIES = 3
local dirty = {}               -- [key] = writerFn (returns table to save)
local flushing = false

local function keyOf(userId) return "u_" .. userId end

function DataStore.Load(userId)
	local lastErr
	for attempt = 1, RETRIES do
		local ok, data = pcall(function() return store:GetAsync(keyOf(userId)) end)
		if ok then return data end
		lastErr = data
		task.wait(1 + attempt)
	end
	error("DataStore.Load failed: " .. tostring(lastErr))
end

-- Queue a save; writerFn must return the full profile table.
function DataStore.QueueSave(userId, writerFn)
	dirty[keyOf(userId)] = writerFn
	if not flushing then
		flushing = true
		task.delay(FLUSH_INTERVAL, DataStore._flush)
	end
end

function DataStore.SaveNow(userId, writerFn)
	local ok, err = pcall(function() store:SetAsync(keyOf(userId), writerFn()) end)
	if not ok then warn("[DataStore] save fail " .. userId .. ": " .. tostring(err)) end
	return ok
end

function DataStore._flush()
	local hadMore = false
	for key, writerFn in pairs(dirty) do
		local ok, err = pcall(function() store:SetAsync(key, writerFn()) end)
		if ok then dirty[key] = nil else hadMore = true end
	end
	if hadMore or next(dirty) then
		task.delay(FLUSH_INTERVAL, DataStore._flush) -- retry chain, self-terminates
	else
		flushing = false
	end
end

game:BindToClose(function()
	for key, writerFn in pairs(dirty) do
		pcall(function() store:SetAsync(key, writerFn()) end)
		dirty[key] = nil
	end
	flushing = false
end)

return DataStore
