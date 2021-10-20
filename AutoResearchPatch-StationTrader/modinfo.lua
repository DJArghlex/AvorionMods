meta = {
	id = "",
	name = "AutoResearchPatch-StationTrader",
	title = "Auto Research Patch: Station Traders",
	type = "mod",

	description = "Adds Station Trader systems to Auto Research's configuration so you don't have to.",
	authors = {"rglx"},

	version = "0.0.1",
	dependencies = {
		{id = "2099635425", exact = "*.*"}, -- station traders
		{id = "1731575231", exact = "*.*"}, -- auto-research
        {id = "Avorion", min = "2.*", max = "2.0.7"}
	},

	serverSideOnly = false,
	clientSideOnly = false,
	saveGameAltering = false,

	contact = "this mod's Steam Workshop page (do not bother Rinart73!)",
}
