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

			if b ~= true then
				-- okay, so it's not a pirate-owned station. let's make it invincible then.

				entity.invincible = true -- make hull undamageable


				entityBoarding = Boarding(entity.id)
				entityBoarding.boardable = false -- prevent boarding

			end
		end
	end
end
