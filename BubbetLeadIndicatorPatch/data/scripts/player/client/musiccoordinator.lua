-- shim to load a player-level script on the client without the server's OK

LeadIndicator = {}

if onClient() then

local stashedMusicCoordinator_initialize = MusicCoordinator.initialize
function MusicCoordinator.initialize(...)
	stashedMusicCoordinator_initialize(...)
	print("rglx_BrakingDisplayClientShim: shimming musiccoordinator to load...")
	-- load our scripts jankily

	-- don't do anything if the server's already loaded the script onto us
	for id,scriptname in ipairs(Player():getScripts()) do
		if scriptname == "data/scripts/player/ui/leadindicator.lua" then
			return
		end
	end

	-- read and execute our script- it should return its functions and variables
	LeadIndicator = include("player/client/braking_distance_display") -- include into our array

	-- stash a function if existing
	if MusicCoordinator.onPostRenderHud then
		if LeadIndicator.onPostRenderHud then
			print("rglx_BrakingDisplayClientShim: shimming onPostRenderHud()...")
			LeadIndicator.stash_onPostRenderHud = MusicCoordinator.onPostRenderHud -- stash extant code 
			MusicCoordinator.onPostRenderHud = function(...) LeadIndicator.stash_onPostRenderHud(...); LeadIndicator.onPostRenderHud(...); end -- clobber with a new function that runs the old code and our new code
		end
	else
		print("rglx_BrakingDisplayClientShim: clobber onPostRenderHud()...")
		MusicCoordinator.onPostRenderHud = LeadIndicator.onPostRenderHud -- no existing code is present, we can simply just add our code.
	end

	LeadIndicator.initialize(...) -- run our initialization function

end

end