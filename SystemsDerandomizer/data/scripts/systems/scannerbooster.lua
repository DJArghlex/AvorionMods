-- MODIFIES ENTIRE FUNCTION. Removes math.random, getInt, and getFloat functions from most of the code. part of rglx's systemsderandomizer mod.
function getBonuses(seed, rarity, permanent)
	math.randomseed(seed)

	local scanner = 1

	scanner = 5 -- base value, in percent
	-- add flat percentage based on rarity
	scanner = scanner + (rarity.value + 2) * 15 -- add +15% (worst rarity) to +105% (best rarity)

	-- add randomized percentage, span is based on rarity
	scanner = scanner + ((rarity.value + 1) * 15) -- add random value between +0% (worst rarity) and +90% (best rarity)
	scanner = scanner / 100

	if permanent then
		scanner = scanner * 2
	end

	return scanner
end
