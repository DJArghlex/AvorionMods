-- rglx's xsotan invasion remover - prevents the invasion from starting, and reverts the wormhole guardian's spawn requirements back to a simple half-hour timer

-- for game versions UP TO 2.1.0, and no further! the way the invasion works in 2.2 onwards currently makes this mod meaningless, as we can now, in vanilla server.ini configurations, disable the invasion completely, without impacting XWG's spawn cycle.

do -- required because of the particular oddity in the way avorion loads this script

print("rglx-InvasionRemover: loading...")
vanillaUpdateFunction = update

function update(timeStep)
	local server = Server()

	-- this server value contains a delay set on XWG's death that, when it reaches zero, starts the invasion
	local xsotanSwarmSpawnTimer = server:getValue("xsotan_swarm_time")

	if xsotanSwarmSpawnTimer then
		-- someone killed XWG and re-started the timer. let's prevent the invasion from occuring

		server:setValue("xsotan_swarm_duration", nil) -- controls length of invasion- just set to nil so nothing thinks its ongoing
		server:setValue("xsotan_swarm_active", false) -- used by a few things to determine if invasion is ongoing or if it 
		server:setValue("xsotan_swarm_time", nil) -- controls invasion respawn delay
		server:setValue("xsotan_swarm_success", false) -- used by a few things to determine the failure or success of invasion (we want to pretend invasion failed)

		-- as of 2.2.0 and onwards this is no longer necessary due to the changes made to invasion and XWG.
		-- if converting upwards from an older galaxy where the invasion was in progress or repelled already and hasn't spawned a guardian, this will not be set properly.
		server:setValue("guardian_respawn_time", 30 * 60) -- controls XWG respawn delay (this is the stock value in the game)
		
		print("rglx-InvasionRemover: an invasion has been pre-empted.")
	end

	-- now, after we've done our work fooling with timers and stuff we can pass the vanilla logic and this won't break anything
	vanillaUpdateFunction(timeStep)
end
print("rglx-InvasionRemover: ready! invasion has been neutralized.")

end -- required because of the particular oddity in the way avorion loads this script