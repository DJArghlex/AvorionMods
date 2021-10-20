-- MODIFIES ENTIRE FUNCTION. Removes math.random, getInt, and getFloat functions from most of the code. part of rglx's systemsderandomizer mod.
function getBonuses(seed, rarity, permanent)
	math.randomseed(seed)

	local perc = 10 -- base value, in percent
	-- add flat percentage based on rarity
	perc = perc + rarity.value * 4 -- add -4% (worst rarity) to +20% (best rarity)

	-- add randomized percentage, span is based on rarity
	perc = perc + (rarity.value * 4) -- add random value between -4% (worst rarity) and +20% (best rarity)
	perc = perc * 0.8
	perc = perc / 100
	if permanent then perc = perc * 1.5 end

	local flat = 20 -- base value
	-- add flat value based on rarity
	flat = flat + (rarity.value + 1) * 50 -- add +0 (worst rarity) to +300 (best rarity)

	-- add randomized value, span is based on rarity
	flat = flat + ((rarity.value + 1) * 50) -- add random value between +0 (worst rarity) and +300 (best rarity)
	flat = flat * 0.8
	if permanent then flat = flat * 1.5 end
	flat = round(flat)

	if math.random() < 0.5 then
		perc = 0
	else
		flat = 0
	end

	return perc, flat
end