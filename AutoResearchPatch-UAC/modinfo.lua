meta = {
	id = "",
	name = "AutoResearchPatch-UAC",
	title = "Auto Research Patch: Universal Adventuring Companions",
	type = "mod",

	description = "Adds Universal Adventuring Companions to Auto Research's configuration so you don't have to.",
	authors = {"rglx"},

	version = "0.0.1",
	dependencies = {
		{id = "2054946409", exact = "*.*"}, -- UACs
		{id = "1731575231", exact = "*.*"}, -- auto-research
        {id = "Avorion", min = "2.*"}
	},

	serverSideOnly = false,
	clientSideOnly = false,
	saveGameAltering = false,

	contact = "this mod's Steam Workshop page (do not bother Rinart73!)",
}
