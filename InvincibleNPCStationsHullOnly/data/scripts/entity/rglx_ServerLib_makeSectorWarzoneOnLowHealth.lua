-- makes entities this is attached to call out hazard zones when below 50% hull

-- namespace makeSectorWarzoneOnLowHealth
makeSectorWarzoneOnLowHealth = {}
self = makeSectorWarzoneOnLowHealth

if onServer() then

	self.callWarzoneAtHealth = 0.50 -- float of health percentage to call out the warzone.
	self.entity = nil

	function makeSectorWarzoneOnLowHealth.initialize()

		--entity
		self.entity = Entity()

		-- hook our callbacks
		self.entity:registerCallback("onDamaged","checkHealth")
		self.entity:registerCallback("onDestroyed", "makeWarzone")

	end

	function makeSectorWarzoneOnLowHealth.makeWarzone()

		if not self.entity then
			eprint("rglx_ServerLib_makeSectorWarzoneOnLowHealth: script was attached to nil entity? (#2)")
			return
		end

		local sector = Sector()
		if not sector then
			eprint("rglx_ServerLib_makeSectorWarzoneOnLowHealth: sector is nil?")
		end

		-- game calls hazard zones "warzones" for some reason.
		local warzoneValue = sector:getValues("war_zone") -- get hazard zone's current value: if it's anything but true it's not a hazard zone.
		if warzoneValue ~= true then
			-- hazard zone wasn't already in place, so let's have the hazard zone script do the work of setting it.
			sector:invokeFunction("background/warzonecheck","declareWarZone")
		end

	end

	function makeSectorWarzoneOnLowHealth.checkHealth()

		if not self.entity then
			eprint("rglx_ServerLib_makeSectorWarzoneOnLowHealth: script was attached to nil entity? (#1)")
			return
		end

		local durability = Durability(self.entity.id)

		if not durability then
			eprint("rglx_ServerLib_makeSectorWarzoneOnLowHealth: durability is nil? bailing.")
			return
		end

		if durability.filledPercentage <= self.callWarzoneAtHealth then
			-- we're below our hull percentage, so let's make the sector a warzone
			makeSectorWarzoneOnLowHealth.makeWarzone()
			-- heal ourself
			durability.durability = durability.maximum
		end
	end
end