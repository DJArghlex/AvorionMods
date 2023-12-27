-- only do the "return" if we're shim-loaded
if onClient() then
	local scriptPresentInPlayerScripts = nil
	for id,scriptname in ipairs(Player():getScripts()) do
		if scriptname == "data/scripts/player/client/braking_distance_display.lua" then
			scriptPresentInPlayerScripts = true
		end
	end
	if not scriptPresentInPlayerScripts then
		print("rglx_BrakingDisplayClientShim: returning script functions as table...")
		return BrakingDistanceDisplay
	else
		eprint("rglx_BrakingDisplayClientShim: this galaxy is enforcing our parent mod, doing nothing")
	end
end