-- rglx's rocket launcher fire-rate nerfer


-- makes rocket launchers fire slower. this won't increase the damage output despite what the code says as the code has returned a finished result
-- if we want to modify our damage output we can do that separately
rocketNerfFireDelayMultiplier = 2.5 -- mutliply our fire *delay* by this much. higher number, slower gun.
rocketNerfDamageMultiplier = 1.0 -- with the way that rockets are breaking servers at high tech levels presently, letting them be a primary weapon is not my thing. damage will not be changed.

local oldGenerateRocketFunction = WeaponGenerator.generateRocketLauncher
function WeaponGenerator.generateRocketLauncher(rand, ...)

	-- run our stashed function, capturing output
	capturedWeapon = oldGenerateRocketFunction(rand, ...)

	-- make our modifications
	capturedWeapon.fireDelay = capturedWeapon.fireDelay * rocketNerfFireDelayMultiplier
	capturedWeapon.damage = capturedWeapon.damage * rocketNerfDamageMultiplier

	-- and finally, return the finished weaponry
    return capturedWeapon
end