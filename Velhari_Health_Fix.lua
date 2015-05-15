--
-- Correction factor
--
local velhari_health_factor = 1

--
-- Blizzard Frame Hook
--
local _UnitHealth = UnitHealth
local function BlizzardUnitHealth(unit)
	return _UnitHealth(unit) / velhari_health_factor
end

local function BlizzardEnable()
	UnitHealth = BlizzardUnitHealth
end

local function BlizzardDisable()
	UnitHealth = _UnitHealth
end

--
-- Grid Hook
--
local GridRefresh
if Grid then
	local GridFrame = Grid:GetModule("GridFrame")
	local GridStatus = Grid:GetModule("GridStatus")
	local GridStatusHealth = GridStatus:GetModule("GridStatusHealth")

	local function InitializeFrame(self, frame)
		local set_min_max = frame.indicators.bar.SetMinMaxValues
		frame.indicators.bar.SetMinMaxValues = function(self, min, max) 
			set_min_max(self, min, max * velhari_health_factor)
		end
	end

	hooksecurefunc(GridFrame, "InitializeFrame", InitializeFrame)
	
	function GridRefresh()
		GridStatusHealth:UpdateAllUnits()
	end
end

--
-- Control
--
local frame = CreateFrame("Frame")

frame:RegisterEvent("ENCOUNTER_START")
frame:RegisterEvent("ENCOUNTER_END")

local function Refresh()
	GridRefresh()
end

local function Enable()
	velhari_health_factor = 1
	BlizzardEnable()
	Refresh()
end

local function Disable()
	velhari_health_factor = 1
	BlizzardDisable()
	Refresh()
end

frame:SetScript("OnEvent", function(_, event, encounterID)
	if event == "ENCOUNTER_START" then
		Enable()
		print("BEGIN ENCOUNTER: " .. encounterID)
	elseif event == "ENCOUNTER_END" then
		Disable()
	end
end)
