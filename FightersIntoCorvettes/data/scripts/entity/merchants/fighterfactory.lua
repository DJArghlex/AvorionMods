-- rglx's fighter factory modification to stack fighters together into big-ass corvettes and hopefully make them look like it too.
-- v0.0.1

fighterEquivalency = 12 -- we'll start here for now.

oldFactoryMakeFighter = FighterFactory.makeFighter
function FighterFactory.makeFighter(type, plan, turret, sizePoints, durabilityPoints, turningSpeedPoints, velocityPoints)
	-- only change armed fighters
	if turret then
		newFighter = FighterTemplate()
		rarity = turret.rarity
		material = turret.material
		tech = turret.averageTech
		-- plan scaling stuff

		-- first, to uniform size
		local scale = 1.5 + lerp(1.5, newFighter.minFighterDiameter, newFighter.maxFighterDiameter, 0, 1.5)
		scale = scale / (plan.radius * 2)
		plan:scale(vec3(scale, scale, scale))

		-- then scale up.
		local corvetteScaling = 12000
		plan:scale(vec3(corvetteScaling,corvetteScaling,corvetteScaling))

		generatedFighter = oldFactoryMakeFighter(type, plan, turret, sizePoints, durabilityPoints, turningSpeedPoints, velocityPoints)

		-- size & blockplan
		newFighter.diameter = 6 -- cubed to get the hangar space consumption
		newFighter.plan = plan

		-- types
        newFighter.type = type

        -- maneuverability
		newFighter.turningSpeed = generatedFighter.turningSpeed * 0.8
		newFighter.maxVelocity = generatedFighter.maxVelocity * 0.8

		-- defenses
		newFighter.durability = generatedFighter.durability * material.strengthFactor * ( fighterEquivalency * turret.slots ) * 50
		if turret.material.value > 1 then -- add shields if this is a naonite or higher turret
			print("shielded fighter")
			newFighter.shield = newFighter.durability * 1.8
		end

		weaponsToModify = {}
		for _, weapon in pairs({generatedFighter:getWeapons()}) do
			--- modify and store to a table safely
			weapon.damage = weapon.damage * fighterEquivalency
			if turret.slots > 3 then -- if we used a big turret for the corvette make sure we say something about it.
				print("heavy turret!")
				weapon.prefix = "Heavy "..weapon.prefix
			end
			weapon.prefix = weapon.prefix .. " Corvette\n\n\nNot a"
			table.insert(weaponsToModify,weapon)
		end
		newFighter:clearWeapons(weapon)
		for _, weapon in pairs(weaponsToModify) do
			-- and then re-add them.
			newFighter:addWeapon(weapon)
		end
		newFighter:addDescription("Corvette - Really tiny but very potent fighter.","")
		newFighter:addDescription("Make more at a Corvette Factory!","")
		return newFighter
	else
		-- unarmed fighter. don't mess around too much, just make the new fighter and return it
		return oldFactoryMakeFighter(type, plan, turret, sizePoints, durabilityPoints, turningSpeedPoints, velocityPoints)
	end
end

-- make armed corvettes dirt cheap since they're fucking expensive. balances them so the only way to really get more quickly is by shoveling turrets into a factory vs just making them on a massive manufacturing array.
function FighterFactory.getPriceAndTax(fighter, stationFaction, buyerFaction)
	local price = fighter:getPrice()
	price = price / ( fighterEquivalency * 100 )
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
			"Fighters? Naaaah! Get some corvettes instead. Many times the power, many times the fun.",
        })
    end
end