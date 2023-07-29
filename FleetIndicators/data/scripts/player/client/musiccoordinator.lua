-- shim to load a player-level script on the client without the server's OK

FleetIndicatorsCraftStatus = {}
FleetIndicatorsBlockDamage = {}

local stashedMusicCoordinator_initialize = MusicCoordinator.initialize
function MusicCoordinator.initialize(...)
    stashedMusicCoordinator_initialize(...)

    for _, path in pairs(Player():getScripts()) do
        -- dig through all the loaded playerscripts
        if string.find(path, "data/scripts/player/ui/rglx_fleetindicators_blockdamage.lua") or string.find(path, "data/scripts/player/ui/rglx_fleetindicators_craftstatus.lua") then
            return -- server enforcing mod onto clients- which means we don't need to do anything in musiccoordinator. bail out.
        end
    end

    print("rglx_fleetindicators_clientsideloader: server not enforcing this mod. moving to shim method for loading...")
    -- load our scripts jankily
    FleetIndicatorsCraftStatus = include("player/ui/rglx_fleetindicators_craftstatus")
    FleetIndicatorsCraftStatus.copyIntoOtherNamespace(MusicCoordinator)
    FleetIndicatorsBlockDamage = include("player/ui/rglx_fleetindicators_blockdamage")
    FleetIndicatorsBlockDamage.copyIntoOtherNamespace(MusicCoordinator)
end