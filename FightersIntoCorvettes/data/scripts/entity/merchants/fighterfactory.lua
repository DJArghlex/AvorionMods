-- rglx's fighter factory modification to stack fighters together into big-ass corvettes and hopefully make them look like it too.
-- v0.0.1

fighterEquivalency = 12 -- we'll start here for now.

function FighterFactory.makeFighter(type, plan, turret, sizePoints, durabilityPoints, turningSpeedPoints, velocityPoints)
	local material = Material(1)
	local rarity = Rarity(1)

	-- make sure the fighter's material and rarity get copied in
	if turret then
		material = turret.material
		rarity = turret.rarity
	end

	-- retrieve our stats modifiers from the player's selections on where their points are going
	local diameter, durability, turningSpeed, maxVelocity = FighterFactory.getStats(rarity, material, sizePoints, durabilityPoints, turningSpeedPoints, velocityPoints)

	local fighter = FighterTemplate() -- construct our fighter template
	fighter.type = type -- cargo, boarding shuttle, or weapon-using, doesn't matter. they all need this copied in.

	if turret then
		local corvetteFactor = fighterEquivalency * turret.slots
		-- base stats definitions - factoring in big-ness and now accounting for the slot count on the turrets.
		fighter.crew = corvetteFactor	
		fighter.diameter = diameter * ( corvetteFactor ^ (1/3) ) -- cube root of our corvette factor, maybe that'll do something
		fighter.durability = durability * material.strengthFactor * corvetteFactor * 50 -- hull strength
		if material.value > 1 then
			fighter.shield = fighter.durability * 1.8
		else
			fighter.shield = 0
		end

		 -- honestly this is just random variable adding i have no idea how to balance these reasonably
		fighter.turningSpeed = turningSpeed / 2
		fighter.maxVelocity = maxVelocity * 2


		 --scale to a uniform size first
		local scale = 1.5 + lerp(1.5, fighter.minFighterDiameter, fighter.maxFighterDiameter, 0, 1.5)
		scale = scale / (plan.radius * 2)
		plan:scale(vec3(scale, scale, scale))

		-- then scale up.
		local corvetteScaling = 1/3 * fighterEquivalency -- don't scale this to turret slots or big coax turret-based corvettes won't be useful because they'll just keep trying to dock and failing miserably. also, dont scale it to their hangar size or they'll just be... worthlessly enormous
		plan:scale(vec3(corvetteScaling,corvetteScaling,corvetteScaling))

		fighter.plan = plan

		-- gun stuff
		-- determine if this gun is an overheater/capacitored weapon or not, and factor that into the rate of fire
		local fireRateFactor = 1.0
		if turret.coolingType == 0 and turret.heatPerShot > 0 and tostring(turret.shootingTime) ~= "inf" then
			fireRateFactor = turret.shootingTime / (turret.shootingTime + turret.coolingTime)
		end

		-- then copy in the turret's weapons, adjusting damage to scale with how many fighters this is replacing
		for _, weapon in pairs({turret:getWeapons()}) do
			weapon.damage = weapon.damage * 0.3 / turret.slots
			weapon.damage = weapon.damage * fighterEquivalency -- scale it
			weapon.fireRate = weapon.fireRate * fireRateFactor
			if turret.slots > 3 then -- if we used a big turret for the corvette make sure we say something about it.
				weapon.prefix = "Heavy "..weapon.prefix
			end
			weapon.prefix = weapon.prefix .. " Corvette\n\n\nNot a"
			fighter:addWeapon(weapon)
		end

		-- aaaaand the descriptions as well
		for desc, value in pairs(turret:getDescriptions()) do
			fighter:addDescription(desc, value)
		end

		-- then add our own description
		fighter:addDescription("Corvette - Stats multiplied.","")
		fighter:addDescription("Make more at a corvette factory!","")

	else -- unarmed fighters e.g. cargo and crew transports
		fighter.crew = 1
		fighter.diameter = diameter
		fighter.durability = durability * material.strengthFactor
		fighter.turningSpeed = turningSpeed
		fighter.maxVelocity = maxVelocity


		local scale = diameter + lerp(diameter, fighter.minFighterDiameter, fighter.maxFighterDiameter, 0, 1.5)
		scale = scale / (plan.radius * 2)
		plan:scale(vec3(scale, scale, scale))
		fighter.plan = plan
	end

	return fighter
end

-- make armed corvettes dirt cheap since they're fucking expensive. balances them so the only way to really get more quickly is by shoveling turrets into a factory vs just making them on a massive manufacturing array.
function FighterFactory.getPriceAndTax(fighter, stationFaction, buyerFaction)
	local price = fighter:getPrice()
	price = price / ( fighterEquivalency * 10000 )
	if price < 180000 then -- generic minimum base price for a fighter.
		price = 180000
	end
	local tax = price * FighterFactory.tax

	if stationFaction.index == buyerFaction.index then
		price = price - tax
		-- don't pay out for the second time
		tax = 0
	end

	return price, tax
end


function FighterFactory.initialize()
	if onServer() then
		local station = Entity()
		if station.title == "" then
			station.title = "Corvette Factory"
		end
		if station.title == "Fighter Factory" then
			station.title = "Corvette Factory"
		end        
	end

	if onClient() and EntityIcon().icon == "" then
		EntityIcon().icon = "data/textures/icons/pixel/fighter.png"
		InteractionText().text = Dialog.generateStationInteractionText(Entity(), random())
	end
end

-- vanilla. overwriting the existing function to add our own
function FighterFactory.initializationFinished()
	if onClient() then
		local ok, r = Sector():invokeFunction("radiochatter", "addSpecificLines", Entity().id.string,
		{
			"Don't fancy the standard? We build corvettes individually according to your specifications.",
			"We build gunships for everybody who can pay.",
			"We heavily discourage building support crafts on your own ship and emphasize the quality of those you get from a professional.",
			"Make your own corvettes! Only bring us the parts, turrets, select a configuration and it's yours!.",
			"Massive assembly stations not required.",
			"Corvette crews not included.",
			"Fighters? Naaaah! Get some corvettes instead. ".. fighterEquivalency .. " times the power, ".. fighterEquivalency .. " times the fun.",
		})
	end
end