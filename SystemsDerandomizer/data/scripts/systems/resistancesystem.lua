-- MODIFIES ENTIRE FUNCTION. Removes math.random, getInt, and getFloat functions from most of the code. part of rglx's systemsderandomizer mod.
function getBonuses(seed, rarity, permanent)
	math.randomseed(seed)

	local rarityLevel = rarity.value + 2 -- rarity levels start at -1

	local randomEntry = math.random(1, 4)
	resistanceType = resistanceTypes[randomEntry]
	dmgFactor = 0

	if permanent then
		dmgFactor = resistanceBonus[rarityLevel].dmgFactor
		nextLevel = resistanceBonus[rarityLevel+1].dmgFactor
		dmgFactor = dmgFactor + (nextLevel - dmgFactor - 0.01)
	end

	return resistanceType, dmgFactor
end
