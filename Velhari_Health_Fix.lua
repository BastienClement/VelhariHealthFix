--
-- Correction factor
--
local velhari_health_factor = 1
local velhari_encounter_active = false
local AURA_OF_CONTEMPT = GetSpellInfo(179986)

--
-- Blizzard Frame Hook
--
local _UnitHealth = UnitHealth
local function BlizzardUnitHealth(unit)
	if UnitIsFriend("player", unit) then
		return _UnitHealth(unit) / velhari_health_factor
	else
		return _UnitHealth(unit)
	end
end

local function BlizzardEnable()
	UnitHealth = BlizzardUnitHealth
end

local function BlizzardDisable()
	UnitHealth = _UnitHealth
end

--
-- VuhDo Hook
--
local hasVuhDo = _G["VUHDO_CONFIG"] and true or false

local _UnitHealthMax = UnitHealthMax
local function VuhDoUnitHealthMax(unit)
	if UnitIsFriend("player", unit) then
		return _UnitHealthMax(unit) * velhari_health_factor
	else
		return _UnitHealthMax(unit)
	end
end

local function VuhDoEnable()
	UnitHealthMax = VuhDoUnitHealthMax
end

local function VuhDoDisable()
	UnitHealthMax = _UnitHealthMax
end

local function VuhDoRefresh()
	for unit, _ in pairs(VUHDO_RAID) do
		VUHDO_updateHealth(unit, 3)
	end
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
	if GridRefresh then GridRefresh() end

	if hasVuhDo then VuhDoRefresh() end
end

local function Disable()
	velhari_health_factor = 1
	velhari_encounter_active = false
	BlizzardDisable()

	if hasVuhDo then VuhDoDisable() end
	
	Refresh()
end

local function Scan()
	if not velhari_encounter_active then return end
	local max_percentage = select(15, UnitAura("boss1", AURA_OF_CONTEMPT))
	if max_percentage then
		velhari_health_factor = max_percentage / 100
		Refresh()
	else
		velhari_health_factor = 1
		if not UnitExists("boss1") then
			Disable()
			return
		end
	end
	C_Timer.After(1, Scan)
end

local function Enable()
	if velhari_encounter_active then return end
	
	velhari_health_factor = 1
	velhari_encounter_active = true
	
	BlizzardEnable()

	if hasVuhDo then VuhDoEnable() end

	Refresh()
	
	C_Timer.After(1, Scan)
end

frame:SetScript("OnEvent", function(_, event, encounterID)
	if event == "ENCOUNTER_START" and encounterID == 1784 then
		Enable()
	elseif event == "ENCOUNTER_END" then
		Disable()
	end
end)
