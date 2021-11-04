# rglx's repository of mods for avorion

basically just off-site storage for the sources

pull requests welcome via the issues page.


## planned mods
- upgraded headquarters.lua for players/alliances
	- owner-toggleable/pricable ability for other players to pay for max reputation
	- owner-toggleable/pricable ability for other players to pay for allied status
	- owner-toggleable/pricable ability for other players to pay for ceasefire status
	- allow for setting the 'home sector' setting for the alliance so that it's shown
- ancient gate network changes (one of these will be implemented)
	- gates won't ever close themselves once opened by a key somehow
	- gates will all open galaxy-wide for all players once the exodus mission is completed
	- gates will open for that player at all times as long as they have a key in their INVENTORY (instead of on their ships)
- consumer.lua & tradingpost.lua changes
	- custom good trading settings (or just a panel that reloads/unloads them with the correct arguments)
	- limiting quantities to 25k of each good unless transferred in by the operator of the station
- silencing alliance log output for economy stuff
	- to better show expenditures and vault accesses by players themselves versus just being useless
	- also make it log as comma/tab-separated values for econ tracking?
- sector regenerator - possible methods
	- out-of-band system
		- reads sector files and faction databases to determine what entities are owned by which faction (and wether it's safe to delete the sector or not)
		- dead pending either a) response from boxelware with some simple insights into the format of the file or b) response 
	- command that does the following [possible? may need research]
		- locks a sector (forbids players entering it)
		- kicks all player/alliance crafts out of it
		- unloads the sector completely, then deletes its file from the galaxy (or just moves it)
	- attaching deleteentityonplayersleft.lua to everything in the galaxy that isn't a player/alliance/story craft [probably a bad idea]
- equipment/goods trading windows: disable buy/sell button if button was pressed more times than items to buy/sell
- energy signature suppressor changes
	- use a predefined plan instead of random stations
	- have them self-destruct when empty
	- allow recharging or stacking additional ones on top of them
	- server admin menu for making them permanent
- neutral zone beacon
	- same as energy signature suppressor, but with more ... neutral-ness?