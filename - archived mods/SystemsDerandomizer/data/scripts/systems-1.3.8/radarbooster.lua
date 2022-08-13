-- MODIFIES ENTIRE FUNCTION. Removes math.random, getInt, and getFloat functions from most of the code. part of rglx's systemsderandomizer mod.
function getBonuses(seed, rarity, permanent)
	math.randomseed(seed)

	local radar = 0
	local hiddenRadar = 0

	radar = math.max(0, rarity.value * 2.0) + 1
	hiddenRadar = math.max(0, rarity.value * 1.5) + 1

	-- probability for both of them being used
	-- when rarity.value >= 4, always both
	-- when rarity.value <= 0 always only one
	local probability = math.max(0, rarity.value * 0.25)
	if math.random() > probability then
		-- only 1 will be used
		if math.random() < 0.5 then
			radar = 0
		else
			hiddenRadar = 0
		end
	end

	if permanent then
		radar = radar * 1.5
		hiddenRadar = hiddenRadar * 2
	end

	return round(radar), round(hiddenRadar)
end