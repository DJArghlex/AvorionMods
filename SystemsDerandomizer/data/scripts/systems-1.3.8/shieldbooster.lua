-- MODIFIES ENTIRE FUNCTION. Removes math.random, getInt, and getFloat functions from most of the code. part of rglx's systemsderandomizer mod.
function getBonuses(seed, rarity, permanent)
	math.randomseed(seed)

	local durability = 5 -- base value, in percent
	-- add flat percentage based on rarity
	durability = durability + (rarity.value + 1) * 15 -- add 0% (worst rarity) to +80% (best rarity)

	-- add randomized percentage, span is based on rarity
	durability = durability + (rarity.value + 1) * 10 -- add random value between 0% (worst rarity) and +60% (best rarity)
	durability = durability * 0.8
	durability = durability / 100

	local recharge = 5 -- base value, in percent
	-- add flat percentage based on rarity
	recharge = recharge + rarity.value * 2 -- add -2% (worst rarity) to +10% (best rarity)

	-- add randomized percentage, span is based on rarity
	recharge = recharge + (rarity.value * 2) -- add random value between -2% (worst rarity) and +10% (best rarity)
	recharge = recharge * 0.8
	recharge = recharge / 100

	-- probability for both of them being used
	-- when rarity.value >= 4, always both
	-- when rarity.value <= 0 always only one
	local probability = math.max(0, rarity.value * 0.25)
	if math.random() > probability then
		-- only 1 will be used
		if math.random() < 0.5 then
			durability = 0
		else
			recharge = 0
		end
	end

	local emergencyRecharge = 0

	if permanent then
		durability = durability * 1.5
		recharge = recharge * 1.5

		if rarity.value >= 2 then
			emergencyRecharge = 1
		end
	end

	return durability, recharge, emergencyRecharge
end