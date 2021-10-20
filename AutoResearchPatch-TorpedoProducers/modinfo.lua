meta = {
	id = "",
	name = "AutoResearchPatch-TorpedoProducers",
	title = "Auto Research Patch: Torpedo Producers",
	type = "mod",

	description = "Adds Torpedo Producer systems to Auto Research's configuration so you don't have to.",
	authors = {"rglx"},

	version = "0.0.1",
	dependencies = {
		{id = "2053583501", exact = "*.*"}, -- torpedo producers
		{id = "1731575231", exact = "*.*"}, -- auto-research
        {id = "Avorion", min = "2.*", max = "2.0.7"}
	},

	serverSideOnly = false,
	clientSideOnly = false,
	saveGameAltering = false,

	contact = "this mod's Steam Workshop page (do not bother Rinart73!)",
}
