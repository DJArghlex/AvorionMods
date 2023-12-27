-- rglx's weird patch for bubbet's lead indicator mod
-- it functions exactly the same
-- the only thing that's changed is how it is being loaded, but even then that's pretty much just the same

-- namespace LeadIndicator
-- this line i think is probably unneccessary since we're shim-loading, not using :addScript() anywhere
LeadIndicator = {}
local self = LeadIndicator

-- slightly modified, removes dependency on UIelements for its shim-loading method
function LeadIndicator.initialize()
	self.player = Player() -- stash player someplace we can mess with it
	self.player:registerCallback("onPostRenderHud","onPostRenderHud") -- technically a client callback but it's in the player object anyway
end

-- unchanged from bubbet's original code
function LeadIndicator.onPostRenderHud(state) -- called each frame, after the HUD has been rendered
	if state == PlayerStateType.Fly then -- only work while a player is physically flying the ship
		-- https://en.wikipedia.org/wiki/3D_projection#Mathematical_formula
		local color = ColorHSV(1,1,1) -- default color for a glow is white
		local entity = Entity(self.player.selectedObject) -- get the entity we're looking at
		self.target = entity or self.target -- if that entity is nil, then get the ship's current target (typically set by autopilot)
		if self.target then
			if not self.player.craft then return end -- don't calculate lead indicators if we're not actually in a craft
			local vel = Velocity(self.target) -- get velocity object for target
			if not vel then return end
			local evel = Velocity(self.player.craft) -- get velocity object for us
			if not self.player.craft or not evel then return end -- bail if our craft or the enemy's velocity is nil
			if not valid(self.player.craft) or not valid(self.target) then return end -- bail if the craft we're in or the craft we're targetting are invalid
			local dist = distance(self.player.craft.translationf, self.target.translationf) -- determine the distance between us and them
			if not dist then return end
			local sector = Sector()
			local size = dist/100 -- we want to scale our lead indicator dynamically with our distance, to prevent a really distant target from having a tiny dot we can't really see
			--print('vel', length(vel.velocityf)) -- prints velocity in decimeters per second to the client console
			local turrets = {self.player.craft:getTurrets()} -- get a list of all the turrets we have on the ship
			local turrets_objects = {}
			for k, v in pairs(turrets) do -- for each one, we want to cast each turret as both a turret object AND its turret template object, and store them for later use
				table.insert(turrets_objects, {entity = v, turret = Turret(v), template = CreateTemplateFromTurret(v)})
			end
			table.sort(turrets_objects, function(a, b) return a.template.dps < b.template.dps end) -- sort it by each turret's DPS, with higher DPS turrets being given a different color than lower DPS ones
			for k, v in ipairs(turrets_objects) do
				if v.template.reach > dist and v.turret:hasEnergyForShot(1) then -- check if the turret has the energy for a single shotand if it's in range
				-- presently we have no way to (without a great deal of trouble) determine what turrets are shut off in the hotbar or if they're under the AI's control
					local color = ColorRGB(1-k/#turrets, k/#turrets, 0) -- turrets will get assigned a colored dot for each one, with higher DPS turrets being given a greener dot, and the lower DPS ones a redder dot
					local speed = v.template.shotSpeed
					local v3 = self.target.translationf + vel.velocityf * (dist) / (speed) - evel.velocityf * (dist) / (speed) -- calculate a shot's landing location between our two ships
					for i=1, 2 do
						sector:createGlow(v3, size, color) -- add the dots in that location- these will get cleared after each frame
					end
				end
			end
		end
	end
end

-- we're only ever loaded via shimming musiccoordinator with this script, so a lot of stuff can be skipped outright
-- only do the "return" if we're shim-loaded
if onClient() then
--	local scriptPresentInPlayerScripts = nil
--	for id,scriptname in ipairs(Player():getScripts()) do
--		if scriptname == "ui/leadindicator" then
--			scriptPresentInPlayerScripts = true
--		end
--	end
--	if not scriptPresentInPlayerScripts then
		return LeadIndicator
--	end
end