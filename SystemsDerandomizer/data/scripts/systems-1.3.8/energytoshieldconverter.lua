-- MODIFIES ENTIRE FUNCTION. Removes math.random, getInt, and getFloat functions from most of the code. part of rglx's systemsderandomizer mod.
function getBonuses(seed, rarity, permanent)
	math.randomseed(seed)

	local amplification = 20
	-- add flat percentage based on rarity
	amplification = amplification + (rarity.value + 1) * 15 -- add 0% (worst rarity) to +120% (best rarity)

	-- add randomized percentage, span is based on rarity
	amplification = amplification + (rarity.value + 1) * 10 -- add random value between 0% (worst rarity) and +60% (best rarity)
	amplification = amplification / 100

	energy = -amplification * 0.4 / (1.1 ^ rarity.value) -- note the minus

	amplification = amplification * 0.8
	if permanent then
		amplification = amplification * 1.4
	end

	return amplification, energy
end