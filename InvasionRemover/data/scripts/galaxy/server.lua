-- rglx's xsotan invasion remover - prevents the invasion from starting, and reverts the wormhole guardian's spawn requirements back to a simple half-hour timer

do -- required because of the particular oddity in the way avorion loads this script

print("rglx-InvasionRemover: loading...")
vanillaUpdateFunction = update

function update(timeStep)
	local server = Server()

	-- this server value contains a delay set on XWG's death that, when it reaches zero, starts the invasion
	local xsotanSwarmSpawnTimer = server:getValue("xsotan_swarm_time")

	if xsotanSwarmSpawnTimer then
		print("rglx-InvasionRemover: an invasion has been pre-empted.")

		-- someone killed XWG and re-started the timer. let's prevent the invasion from occuring

		server:setValue("xsotan_swarm_duration", nil) -- controls length of invasion- just set to nil so nothing thinks its ongoing
		server:setValue("xsotan_swarm_active", false) -- used by a few things to determine if invasion is ongoing or if it 
		server:setValue("xsotan_swarm_time", nil) -- controls invasion respawn delay
		server:setValue("guardian_respawn_time", 30 * 60) -- controls XWG respawn delay (this is the stock value in the game)
		server:setValue("xsotan_swarm_success", false) -- used by a few things to determine the failure or success of invasion (we want to pretend invasion failed)
	end

	-- now, after we've done our work fooling with timers and stuff we can pass the vanilla logic and this won't break anything
	vanillaUpdateFunction(timeStep)
end
print("rglx-InvasionRemover: ready! invasion has been neutralized.")

end -- required because of the particular oddity in the way avorion loads this script