-- rglx's utlity turrets range enhancement mod
-- raises the base ranges on some turrets to be better for larger scale ships and balancing repair and force guns to maybe have some combat potential
-- v0.0.1


-- range adjustments. multiplies by the multiplier, then adds 5 kilometers onto the result.
purifyingHarvesterRangeMultiplier = 2.5
rawHarvesterRangeMultiplier = 2.5
repairBeamRangeMultiplier = 2.5
forceGunRangeMultiplier = 2.5
baseRangeAddition = 500.0

-- preserve the vanilla function someplace safe momentarily
local oldGenerateFunctionMining = WeaponGenerator.generateMiningLaser
-- overwrite ours, making sure we pass all arguments we're given down to the below one
-- but we also need the random seed for our range modifications, so let's make sure we get that.
function WeaponGenerator.generateMiningLaser(rand, ...)
	-- run existing code and capture its output
	returnedWeapon = oldGenerateFunctionMining(rand, ...)
	-- make our changes
	returnedWeapon.reach = baseRangeAddition + math.abs( returnedWeapon.reach * purifyingHarvesterRangeMultiplier )
	-- then return it back to whoever called us to begin with.
	return returnedWeapon
end


local oldGenerateFunctionSalvaging = WeaponGenerator.generateSalvagingLaser
function WeaponGenerator.generateSalvagingLaser(rand, ...)
	returnedWeapon = oldGenerateFunctionSalvaging(rand, ...)
	returnedWeapon.reach = baseRangeAddition + math.abs( returnedWeapon.reach * purifyingHarvesterRangeMultiplier )
	return returnedWeapon
end


local oldGenerateFunctionRMining = WeaponGenerator.generateRawMiningLaser
function WeaponGenerator.generateRawMiningLaser(rand, ...)
	returnedWeapon = oldGenerateFunctionRMining(rand, ...)
	returnedWeapon.reach = baseRangeAddition + math.abs( returnedWeapon.reach * rawHarvesterRangeMultiplier )
	return returnedWeapon
end


local oldGenerateFunctionRSalvaging = WeaponGenerator.generateRawSalvagingLaser
function WeaponGenerator.generateRawSalvagingLaser(rand, ...)
	returnedWeapon = oldGenerateFunctionRSalvaging(rand, ...)
	returnedWeapon.reach = baseRangeAddition + math.abs( returnedWeapon.reach * rawHarvesterRangeMultiplier )
	return returnedWeapon
end


local oldGenerateFunctionRepair = WeaponGenerator.generateRepairBeamEmitter
function WeaponGenerator.generateRepairBeamEmitter(rand, ...)
	returnedWeapon = oldGenerateFunctionRepair(rand, ...)
	returnedWeapon.reach = baseRangeAddition + math.abs( returnedWeapon.reach * repairBeamRangeMultiplier )
	return returnedWeapon
end


local oldGenerateFunctionForce = WeaponGenerator.generateForceGun
function WeaponGenerator.generateForceGun(rand, ...)
	returnedWeapon = oldGenerateFunctionForce(rand, ...)
	returnedWeapon.reach = baseRangeAddition + math.abs( returnedWeapon.reach * forceGunRangeMultiplier )
	return returnedWeapon
end