-- MODIFIES ENTIRE FUNCTION. Removes math.random, getInt, and getFloat functions from most of the code. part of rglx's systemsderandomizer mod.
function getBonuses(seed, rarity, permanent)
	math.randomseed(seed)

	local rarityLevel = rarity.value + 2 -- rarity levels start at -1

	local randomEntry = math.random(1, 4)
	weaknessType = weaknessTypes[randomEntry]
	hpBonus = 0
	dmgFactor = 0

	if permanent then
		hpBonus = weaknessBonus[rarityLevel].hpBonus  
		nextLevelHp = weaknessBonus[rarityLevel+1].hpBonus
		hpBonus = round(hpBonus + (nextLevelHp - hpBonus), 2)

		dmgFactor = weaknessBonus[rarityLevel].dmgFactor
		nextLevelDmg = weaknessBonus[rarityLevel+1].dmgFactor
		dmgFactor = round(dmgFactor + (nextLevelDmg - dmgFactor), 2)
	end

	return weaknessType, hpBonus, dmgFactor
end