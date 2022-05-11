
local vanillaInitializeSmugglerRep = initialize

function initialize()
	vanillaInitializeSmugglerRep()

	local entity = Entity()
	entity.invincible = true -- make hull undamageable

	local entityBoarding = Boarding(entity.id)
	entityBoarding.boardable = false -- prevent boarding
end

