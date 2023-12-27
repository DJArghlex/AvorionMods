-- shim to load a player-level script on the client without the server's OK

BrakingDistanceDisplay = {}

if onClient() then

local stashedMusicCoordinator_initialize = MusicCoordinator.initialize
function MusicCoordinator.initialize(...)
	stashedMusicCoordinator_initialize(...)
	print("rglx_BrakingDisplayClientShim: shimming musiccoordinator to load...")
	-- load our scripts jankily

	-- don't do anything if the server's already loaded the script onto us
	for id,scriptname in ipairs(Player():getScripts()) do
		if scriptname == "data/scripts/player/client/braking_distance_display.lua" then
			return
		end
	end

	-- read and execute our script- it should return its functions and variables
	BrakingDistanceDisplay = include("player/client/braking_distance_display") -- include into our array

	-- stash a function if existing
	if MusicCoordinator.onPreRenderHud then
		if BrakingDistanceDisplay.onPreRenderHud then
			print("rglx_BrakingDisplayClientShim: shimming onPreRenderHud()...")
			BrakingDistanceDisplay.stash_onPreRenderHud = MusicCoordinator.onPreRenderHud -- stash extant code 
			MusicCoordinator.onPreRenderHud = function(...) BrakingDistanceDisplay.stash_onPreRenderHud(...); BrakingDistanceDisplay.onPreRenderHud(...); end -- clobber with a new function that runs the old code and our new code
		end
	else
		print("rglx_BrakingDisplayClientShim: clobber onPreRenderHud()...")
		MusicCoordinator.onPreRenderHud = BrakingDistanceDisplay.onPreRenderHud -- no existing code is present, we can simply just add our code.
	end
	
	-- shim onToggleAlertSound since it's used in a callback
	-- stash a function if existing
	if MusicCoordinator.onToggleAlertSound then
		if BrakingDistanceDisplay.onToggleAlertSound then
			print("rglx_BrakingDisplayClientShim: shimming onToggleAlertSound()...")
			BrakingDistanceDisplay.stash_onToggleAlertSound = MusicCoordinator.onToggleAlertSound -- stash extant code 
			MusicCoordinator.onToggleAlertSound = function(...) BrakingDistanceDisplay.stash_onToggleAlertSound(...); BrakingDistanceDisplay.onToggleAlertSound(...); end -- clobber with a new function that runs the old code and our new code
		end
	else
		print("rglx_BrakingDisplayClientShim: clobber onToggleAlertSound()...")
		MusicCoordinator.onToggleAlertSound = BrakingDistanceDisplay.onToggleAlertSound -- no existing code is present, we can simply just add our code.
	end

	BrakingDistanceDisplay.initialize(...) -- run our initialization function

end

end