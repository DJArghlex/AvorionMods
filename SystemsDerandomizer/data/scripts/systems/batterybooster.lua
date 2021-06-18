-- MODIFIES ENTIRE FUNCTION. Removes math.random, getInt, and getFloat functions from most of the code. part of rglx's systemsderandomizer mod.
function getBonuses(seed, rarity, permanent)
	math.randomseed(seed)

	local energy = 15 -- base value, in percent
	-- add flat percentage based on rarity
	energy = energy + (rarity.value + 1) * 15 -- add 0% (worst rarity) to +80% (best rarity)

	-- add randomized percentage, span is based on rarity
	energy = energy + ((rarity.value + 1) * 10) -- add random value between 0% (worst rarity) and +60% (best rarity)
	energy = energy * 0.8
	energy = energy / 100

	local charge = 15 -- base value, in percent
	-- add flat percentage based on rarity
	charge = charge + (rarity.value + 1) * 4 -- add 0% (worst rarity) to +24% (best rarity)

	-- add randomized percentage, span is based on rarity
	charge = charge + ((rarity.value + 1) * 4) -- add random value between 0% (worst rarity) and +24% (best rarity)
	charge = charge * 0.8
	charge = charge / 100

	if permanent then
		charge = charge * 1.5
		energy = energy * 1.5
	end

	-- probability for both of them being used
	-- when rarity.value >= 4, always both
	-- when rarity.value <= 0 always only one
	local probability = math.max(0, rarity.value * 0.25)
	if math.random() > probability then
		-- only 1 will be used
		if math.random() < 0.5 then
			energy = 0
		else
			charge = 0
		end
	end

	return energy, charge
end