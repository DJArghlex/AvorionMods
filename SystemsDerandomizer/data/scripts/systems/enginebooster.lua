-- MODIFIES ENTIRE FUNCTION. Removes math.random, getInt, and getFloat functions from most of the code. part of rglx's systemsderandomizer mod.
function getBonuses(seed, rarity, permanent)
	math.randomseed(seed)

	local vfactor = 3 -- base value, in percent
	-- add flat percentage based on rarity
	vfactor = vfactor + (rarity.value + 1) * 3 -- add 0% (worst rarity) to +18% (best rarity)

	-- add randomized percentage, span is based on rarity
	vfactor = vfactor + ((rarity.value + 1) * 4) -- add random value between 0% (worst rarity) and +24% (best rarity)
	vfactor = vfactor * 0.8
	vfactor = vfactor / 100

	local afactor = 6 -- base value, in percent
	-- add flat percentage based on rarity
	afactor = afactor + (rarity.value + 1) * 5 -- add 0% (worst rarity) to +30% (best rarity)

	-- add randomized percentage, span is based on rarity
	afactor = afactor + ((rarity.value + 1) * 4) -- add random value between 0% (worst rarity) and +24% (best rarity)
	afactor = afactor * 0.8
	afactor = afactor / 100

	if permanent then
		vfactor = vfactor * 1.5
		afactor = afactor * 1.5
	end

	-- probability for both of them being used
	-- when rarity.value >= 4, always both
	-- when rarity.value <= 0 always only one
	local probability = math.max(0, rarity.value * 0.25)
	if math.random() > probability then
		-- only 1 will be used
		if math.random() < 0.5 then
			vfactor = 0
		else
			afactor = 0
		end
	end

	return vfactor, afactor
end
