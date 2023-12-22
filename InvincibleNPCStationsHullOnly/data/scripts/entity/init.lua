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
			local b = s:sub(-string.len(suffix)) == suffix

			-- exempt the one station in the Black Market DLC's Family questline
			if s == "Jackson" then
				b = true
			end

			local entityDurability = Durability(entity.id)
			entity.invincibility = 0.15 -- make hull undamageable

			local entityBoarding = Boarding(entity.id)
			entityBoarding.boardable = false -- prevent boarding

			-- add our script to cause a sector with a heavily damaged station to call itself out as a warzone
			entity:addScriptOnce("rglx_ServerLib_makeSectorWarzoneOnLowHealth")

		end
	end
end
