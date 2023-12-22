-- grants server-side immunity to all non-pirate NPC stations.

if onServer() then

	local entity = Entity()

	if entity.type == EntityType.Station then
		-- it's a station!

		if entity.aiOwned then
			-- it's an AI-owned station!

			local entityOwner = Owner(entity.id)

			local s = entityOwner.name
			local suffix = " Pirates" -- don't know how well this will work for localization. may grant immunity on pirate shipyards for non-english servers
			-- check if string ends with another string... performance-wise i don't know how friendly this will be but we'll see.
			b = s:sub(-string.len(suffix)) == suffix

			-- exempt the one station in the Black Market DLC's Family questline
			if s == "Jackson" then
				b = true
			end

			if b ~= true then
				-- okay, so it's not a pirate-owned station. let's make it invincible then.

				entity.invincible = true -- make hull undamageable

				entity.durability = entity.maxDurability -- repair the station as much as we can
				entity.shieldDurability = entity.shieldMaxDurability -- repair shield as well

				entityShield = Shield(entity.id)
				entityShield.invincible = true -- make shielding undamageable
				entityShield.immuneToDeactivation = true -- prevent EMP torpedos (and other similar weapons) from working
				entityShield.impenetrable = true -- prevent phasing weapons (certain torpedoes, pulse cannons, special cannons and other kinetics with ionized projectiles) from bypassing shielding

				entity.crew = entity.idealCrew -- reset crew from pre-2.0 stations because that's why some stations are decaying damage-wise

				entityBoarding = Boarding(entity.id)
				entityBoarding.boardable = false -- prevent boarding, even though hull is already repaired and you can't board undamaged stations

			end
		end
	end
end
