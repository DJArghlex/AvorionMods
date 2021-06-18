meta = {
	id = "2483780833",
	name = "NoRegrowDocksForPlayerStations",
	title = "No regrowdocks.lua for Player Stations",
	type = "mod",
	description = "Prevents regrowdocks.lua from actually doing anything on player stations. Useful for a lot of stations that're close together that you only want to have one (or zero) working docks on.",

	authors = {"rglx"},
	version = "0.1",
	
	dependencies = {
		{id = "Avorion", min = "1.3.*", max = "1.3.8"}
	},

	serverSideOnly = false,
	clientSideOnly = false,
	saveGameAltering = false,
	
	contact = "Steam Workshop page",
}
