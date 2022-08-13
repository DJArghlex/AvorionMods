-- MODIFIES ENTIRE FUNCTION. Removes math.random, getInt, and getFloat functions from most of the code. part of rglx's systemsderandomizer mod.
function getBonuses(seed, rarity, permanent)
	math.randomseed(seed)

	local reach = 0
	local cdfactor = 0
	local efactor = 0
	local radar = 0

	-- probability for both of them being used
	local numBonuses = 1

	if rarity.value >= 4 then numBonuses = 3
	elseif rarity.value == 3 then numBonuses = 3
	elseif rarity.value == 2 then numBonuses = 3
	elseif rarity.value == 1 then numBonuses = 2
	end

	-- pick bonuses
	local bonuses = {}
	bonuses[StatsBonuses.HyperspaceReach] = 1.5
	bonuses[StatsBonuses.HyperspaceCooldown] = 1
	bonuses[StatsBonuses.HyperspaceRechargeEnergy] = 1
	bonuses[StatsBonuses.RadarReach] = 0.25

	local enabled = {}

	for i = 1, numBonuses do
		local bonus = selectByWeight(random(), bonuses)
		enabled[bonus] = 1
		bonuses[bonus] = nil -- remove from list so it wont be picked again
	end

	if enabled[StatsBonuses.HyperspaceReach] then
		reach = math.max(1, rarity.value + 1)
	end

	if enabled[StatsBonuses.HyperspaceCooldown] then
		cdfactor = 5 -- base value, in percent
		-- add flat percentage based on rarity
		cdfactor = cdfactor + (rarity.value + 1) * 2.5 -- add 0% (worst rarity) to +15% (best rarity)

		-- add randomized percentage, span is based on rarity
		cdfactor = cdfactor + ((rarity.value + 1) * 2.5) -- add random value between 0% (worst rarity) and +15% (best rarity)
		cdfactor = -cdfactor / 100
	end

	if enabled[StatsBonuses.HyperspaceRechargeEnergy] then
		efactor = 5 -- base value, in percent
		-- add flat percentage based on rarity
		efactor = efactor + (rarity.value + 1) * 3 -- add 0% (worst rarity) to +18% (best rarity)

		-- add randomized percentage, span is based on rarity
		efactor = efactor + ((rarity.value + 1) * 4) -- add random value between 0% (worst rarity) and +24% (best rarity)
		efactor = -efactor / 100
	end

	if enabled[StatsBonuses.RadarReach] then
		radar = math.max(0, rarity.value * 2.0) + 1
	end

	if permanent then
		reach = reach * 2.5 + rarity.value
		radar = radar * 1.5
	else
		cdfactor = 0
	end

	return round(reach), cdfactor, efactor, round(radar)
end