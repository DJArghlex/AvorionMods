-- MODIFIES ENTIRE FUNCTION. Removes math.random, getInt, and getFloat functions from most of the code. part of rglx's systemsderandomizer mod.
function getNumDefenseWeapons(seed, rarity, permanent)
	math.randomseed(seed)

	if permanent then
		if rarity.value <= 2 then
			return (rarity.value + 2) * 5 + 3
		else
			return rarity.value * 10 + 8
		end
	end

	return 0
end
