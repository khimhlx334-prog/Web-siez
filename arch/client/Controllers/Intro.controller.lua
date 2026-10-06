-- ============================================================
-- EGG RAID · Controllers/Intro (ModuleScript → StarterPlayerScripts/Controllers)
-- Intro cinematic STATE MACHINE skeleton for the future remake.
-- Legacy Intro5 remains the live implementation; this controller
-- is passive (Enabled = false) and only defines the contract:
-- join → fade → sea/boat cinematic → cartoon attack → island
-- sweep → wake → banner → control returned. No violence visuals.
-- ============================================================
local Intro = { Name = "Intro", Enabled = false }

Intro.States = {
	None = 0, FadeIn = 1, BoatCinematic = 2, Attack = 3,
	Fall = 4, IslandSweep = 5, Wake = 6, Banner = 7, Done = 8,
}

Intro.state = Intro.States.None
local listeners = {}

-- Future server flow drives transitions; client never self-advances
function Intro.SetState(nextState)
	if type(nextState) ~= "number" then return end
	Intro.state = nextState
	for _, fn in ipairs(listeners) do pcall(fn, nextState) end
end

function Intro.OnStateChanged(fn) table.insert(listeners, fn) end

function Intro.IsPlaying()
	return Intro.state > Intro.States.None and Intro.state < Intro.States.Done
end

function Intro.Init() end -- wired by future task; keeps zero footprint now
function Intro.Destroy() table.clear(listeners) end

return Intro
