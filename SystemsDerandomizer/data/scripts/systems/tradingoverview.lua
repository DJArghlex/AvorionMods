-- MODIFIES ENTIRE FUNCTION. Removes math.random, getInt, and getFloat functions from most of the code. part of rglx's systemsderandomizer mod.
function getHistorySize(seed, rarity)

	if rarity.value == 2 then
		return 1
	elseif rarity.value >= 3 then
		math.randomseed(seed)

		if rarity.value == 5 then
			return 15
		elseif rarity.value == 4 then
			return 6
		elseif rarity.value == 3 then
			return 3
		end
	end

	return 0
end