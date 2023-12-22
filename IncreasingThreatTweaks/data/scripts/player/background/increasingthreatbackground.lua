-- rglx's shim for increasing threat to only hook callbacks for hatred/notoriety increases inside the core.
-- a note: this will NOT prevent spawns on players who have been into the core to increase their notoriety, then later leave

-- namespace ITBackground

-- stash existing function
local oldITBinitialize = ITBackground.initialize
function ITBackground.initialize(...)
	-- check and see if we're inside the galactic barrier as defined by the balancing system
	local sectorX, sectorY = Sector():getCoordinates()
	if Balancing_InsideRing(sectorX,sectorY) then
		oldITBinitialize(...)
	else
		ITBackground.Log("init","Not registering callbacks (outside barrier!)")
	end
end

-- stash existing function
local oldITBonSectorArrivalConfirmed = ITBackground.onSectorArrivalConfirmed
function ITBackground.onSectorArrivalConfirmed(...)
	-- check and see if we're inside the galactic barrier as defined by the balancing system
	local sectorX, sectorY = Sector():getCoordinates()
	if Balancing_InsideRing(sectorX,sectorY) then
		oldITBonSectorArrivalConfirmed(...)
	else
		ITBackground.Log("oSAC","Not registering callbacks (outside barrier!)")
	end
end

ITBackground.Log("IT-CoreOnly","Shimmed initialization functions.")