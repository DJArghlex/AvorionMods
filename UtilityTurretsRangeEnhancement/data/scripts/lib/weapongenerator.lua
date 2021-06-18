-- rglx's utlity turrets range enhancement mod
-- raises the base ranges on some turrets to be better for larger scale ships and balancing repair and force guns to maybe have some combat potential
-- v0.0.1

--print("rglx-UtilityTurretsRangeEnhancement: loading...")

-- range weighting! uses randomext's getInt()
refinedHarvestersRangeMin = 1500 -- in decameters!
refinedHarvestersRangeMax = 2000 -- in decameters!
rawHarvestersRangeMin = refinedHarvestersRangeMin -- in decameters!
rawHarvestersRangeMax = refinedHarvestersRangeMax -- in decameters!
repairBeamsRangeMin = 2000 -- in decameters!
repairBeamsRangeMax = 2500 -- in decameters!
forceGunsRangeMin = repairBeamsRangeMin -- in decameters!
forceGunsRangeMax = repairBeamsRangeMax -- in decameters!
-- keep in mind these are only suggestions to the turret generator that modifies stats after this. in my singleplayer world, turrets in the core can sometimes add 40-80% more range onto these default settings, so please use your best judgment with them. too much range and they're too powerful or cut through too many asteroids and create lots of little orphanned fragments that crunch up your universe with little two-block plans everywhere

-- preserve the vanilla function someplace safe momentarily
local oldGenerateFunctionMining = WeaponGenerator.generateMiningLaser
-- overwrite ours, making sure we pass all arguments we're given down to the below one
-- but we also need the random seed for our range modifications, so let's make sure we get that.
function WeaponGenerator.generateMiningLaser(rand, ...)
	-- run existing code and capture its output
	returnedWeapon = oldGenerateFunctionMining(rand, ...)
	-- make our changes
	returnedWeapon.reach = rand:getInt(refinedHarvestersRangeMin,refinedHarvestersRangeMax)
	-- then return it back to whoever called us to begin with.
	return returnedWeapon
end


local oldGenerateFunctionSalvaging = WeaponGenerator.generateSalvagingLaser
function WeaponGenerator.generateSalvagingLaser(rand, ...)
	returnedWeapon = oldGenerateFunctionSalvaging(rand, ...)
	returnedWeapon.reach = rand:getInt(refinedHarvestersRangeMin,refinedHarvestersRangeMax)
	return returnedWeapon
end


local oldGenerateFunctionRMining = WeaponGenerator.generateRawMiningLaser
function WeaponGenerator.generateRawMiningLaser(rand, ...)
	returnedWeapon = oldGenerateFunctionRMining(rand, ...)
	returnedWeapon.reach = rand:getInt(rawHarvestersRangeMin,rawHarvestersRangeMax)
	return returnedWeapon
end


local oldGenerateFunctionRSalvaging = WeaponGenerator.generateRawSalvagingLaser
function WeaponGenerator.generateRawSalvagingLaser(rand, ...)
	returnedWeapon = oldGenerateFunctionRSalvaging(rand, ...)
	returnedWeapon.reach = rand:getInt(rawHarvestersRangeMin,rawHarvestersRangeMax)
	return returnedWeapon
end


local oldGenerateFunctionRepair = WeaponGenerator.generateRepairBeamEmitter
function WeaponGenerator.generateRepairBeamEmitter(rand, ...)
	returnedWeapon = oldGenerateFunctionRepair(rand, ...)
	returnedWeapon.reach = rand:getInt(repairBeamsRangeMin,repairBeamsRangeMax)
	return returnedWeapon
end


local oldGenerateFunctionForce = WeaponGenerator.generateForceGun
function WeaponGenerator.generateForceGun(rand, ...)
	returnedWeapon = oldGenerateFunctionForce(rand, ...)
	returnedWeapon.reach = rand:getInt(forceGunsRangeMin,forceGunsRangeMax)
	return returnedWeapon
end
--print("rglx-UtilityTurretsRangeEnhancement: done loading")