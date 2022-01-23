
local vanillaInitializeSmugglerRep = initialize -- stash our existing initialization function

function initialize()
	-- first run our vanilla function - then we can mess with our stats to make sure we don't get killed
	vanillaInitializeSmugglerRep()

	-- now let's make it invincible so we don't have any problems

	local entity = Entity()

	entity.invincible = true -- make hull undamageable

	entity.durability = entity.maxDurability -- repair the station as much as we can
	entity.shieldDurability = entity.shieldMaxDurability -- repair shield as well

	local entityShield = Shield(entity.id)
	entityShield.invincible = true -- make shielding undamageable
	entityShield.immuneToDeactivation = true -- prevent EMP torpedos (and other similar weapons) from working
	entityShield.impenetrable = true -- prevent phasing weapons (certain torpedoes, pulse cannons, special cannons and other kinetics with ionized projectiles) from bypassing shielding

	entity.crew = entity.idealCrew -- reset crew from pre-2.0 stations because that's why some stations are decaying damage-wise

	local entityBoarding = Boarding(entity.id)
	entityBoarding.boardable = false -- prevent boarding, even though hull is already repaired and you can't board undamaged stations

end

