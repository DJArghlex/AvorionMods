-- rglx's scrapyard founding hook script - allows players to found their own (slightly limited) scrapyards

table.insert(StationFounder.stations, 
    {
        name = "Scrapyard"%_t,
        tooltip = "Recycles turrets and ships into wrecks. Does not claim wreckages in a sector."%_t .. "\n\n" ..
                  "The population on this station buys and consumes a range of technological goods. These goods can be picked up for free by the owner of the station. Attracts NPC traders."%_t,
        scripts = {
            {script = "data/scripts/entity/merchants/scrapyard.lua"},
            {script = "data/scripts/entity/merchants/consumer.lua", args = {"Scrapyard"%_t, unpack(ConsumerGoods.EquipmentDock())}},
        },
        getPrice = function()
            return 20000000 +
                StationFounder.calculateConsumerValue({"Scrapyard"%_t, unpack(ConsumerGoods.EquipmentDock())})
        end
    },)
print("rglx-FoundableScrapyards: loaded scrapyard station founder entry data into a ship!")