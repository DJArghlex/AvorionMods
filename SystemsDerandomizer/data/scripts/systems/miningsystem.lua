-- MODIFIES ENTIRE FUNCTION. Removes math.random, getInt, and getFloat functions from most of the code. part of rglx's systemsderandomizer mod.
function getBonuses(seed, rarity, permanent)
	math.randomseed(seed)

	local range = 200 -- base value
	-- add flat range based on rarity
	range = range + (rarity.value + 1) * 80 -- add 0 (worst rarity) to +480 (best rarity)
	-- add randomized range, span is based on rarity
	range = range + ((rarity.value + 1) * 20) -- add random value between 0 (worst rarity) and 120 (best rarity)

	local material = rarity.value + 1
	if math.random() < 0.25 then
		material = material + 1
	end

	local amount = 3
	-- add flat amount based on rarity
	amount = amount + (rarity.value + 1) * 2 -- add 0 (worst rarity) to +120 (best rarity)
	-- add randomized amount, span is based on rarity
	amount = amount + ((rarity.value + 1) * 5) -- add random value between 0 (worst rarity) and 60 (best rarity)

	if permanent then
		range = range * 1.5
		amount = amount * 1.5
		material = material + 1
	end

	return material, range, amount
end
