-- rglx's scrapyard founding hook script - allows players to found their own (slightly limited) scrapyards

table.insert(StationFounder.stations, {
	name = "Scrapyard",
	tooltip = "Allows players to recycle old turrets and ships. Note: Does NOT claim salvageable wreckages in a sector. Will also collect and consume some goods.",
		scripts = {
			{script = "data/scripts/entity/merchants/scrapyard.lua"},
			{script = "data/scripts/entity/merchants/consumer.lua", args = {"Scrapyard"%_t, unpack(ConsumerGoods.EquipmentDock())}},
		},
		price = 25000000
	})
print("rglx-FoundableScrapyards: loaded scrapyard station founder entry data into a ship!")