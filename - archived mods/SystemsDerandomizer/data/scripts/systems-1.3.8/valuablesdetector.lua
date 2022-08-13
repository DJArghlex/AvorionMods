-- MODIFIES ENTIRE FUNCTION. Removes math.random, getInt, and getFloat functions from most of the code. part of rglx's systemsderandomizer mod.
function getBonuses(seed, rarity, permanent)
	math.randomseed(seed)

	local highlightRange = 0
	if rarity.value >= RarityType.Rare then
		highlightRange = 400 * 200
	end

	if rarity.value >= RarityType.Exceptional then
		highlightRange = 900 * 200
	end

	if rarity.value >= RarityType.Exotic then
		highlightRange = math.huge
	end

	return detections, highlightRange
end