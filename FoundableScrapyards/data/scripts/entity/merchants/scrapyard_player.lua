--namespace ScrapyardPlayer
ScrapyardPlayer = {}

function ScrapyardPlayer.initialize()
	-- just load regular scrapyard
	local entity = Entity()
	entity:addScriptOnce("data/scripts/entity/merchants/scrapyard.lua")
	entity:removeScript("data/scripts/entity/merchants/scrapyard_player.lua")
	print("rglx-FoundableScrapyards: converted an old player-scrapyard back to the common script")
end