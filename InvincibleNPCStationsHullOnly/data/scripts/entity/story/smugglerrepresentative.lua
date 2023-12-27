
local vanillaInitializeSmugglerRep = initialize

function initialize()
	vanillaInitializeSmugglerRep()

	local entityDurability = Durability(entity.id)
	entityDurability.invincibility = 0.15 -- make hull undamageable

	local entityBoarding = Boarding(entity.id)
	entityBoarding.boardable = false -- prevent boarding
end

