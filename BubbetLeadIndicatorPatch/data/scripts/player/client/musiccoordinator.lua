-- shim to load a player-level script on the client without the server's OK

LeadIndicator = {}

if onClient() then

local stashedMusicCoordinator_initialize = MusicCoordinator.initialize
function MusicCoordinator.initialize(...)
	stashedMusicCoordinator_initialize(...)
	print("rglx_LeadIndicatorPatch: shimming musiccoordinator to load...")
	-- load our scripts jankily
	LeadIndicator = include("player/ui/leadindicator") -- include into our array
	LeadIndicator.copyIntoOtherNamespace(MusicCoordinator) -- copy our stuff into the new namespace & reinitialize
end

else
	print("rglx_LeadIndicatorPatch: loaded onto server- this won't do anything")
end