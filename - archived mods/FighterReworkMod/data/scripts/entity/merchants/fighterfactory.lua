-- rglx's fighter factory modification to stack fighters together into single fighters.
-- v0.0.1

fightersPerWing = 4 -- multiplies the final damage output (and size, production effort, etc) of a single fighter to this. Divide your galaxy's active fighter limit by this number in your universe configuration. IS NOT RETROACTIVE.

oldFactoryMakeFighter = FighterFactory.makeFighter
function FighterFactory.makeFighter(type, plan, turret, ...)
	generatedFighter = oldFactoryMakeFighter(type, plan, turret, ...)

	-- only change armed fighters
	if turret then
		-- change crew, size, and durability to make sense
		--generatedFighter.crew = generatedFighter.crew * fightersPerWing
		generatedFighter.diameter = generatedFighter.diameter * math.pow(fightersPerWing,(1/2)) -- this one is kinda weird. i think it's being exponentified somehow but we'll work with it by bullshitting in something else.
		generatedFighter.durability = generatedFighter.durability * fightersPerWing
		weaponsToModify = {}
		-- yes, i know, iterating twice over the same table is bad... only way to modify them currently.
		for _, weapon in pairs({generatedFighter:getWeapons()}) do
			--- modify and store to a table safely
			weapon.damage = weapon.damage * fightersPerWing
			weapon.prefix = "Wing of " .. fightersPerWing .. " - " .. weapon.prefix
			table.insert(weaponsToModify,weapon)
		end
		generatedFighter:clearWeapons() -- clear all weapons off the fighter...
		for _, weapon in pairs(weaponsToModify) do
			-- and then re-add them.
			generatedFighter:addWeapon(weapon)
		end
		generatedFighter:addDescription("Fighter Wing - Stats multiplied.","")
		generatedFighter:addDescription("Fighters in Wing: " .. fightersPerWing,"")
	end
	return generatedFighter
end