-- can only addScriptOnce() from the server, meaning this particular part of the script will only work if the server loads the mod.
-- the methods using scripts/player/client/musiccoordinator.lua and a modified series of shim functions in each script were developed by (as best i can tell) rinart73.
-- which will load the mod on the clientside if the server only allows the mod, not enforces it like most singleplayer galaxies.

if onServer() then
	Player():addScriptOnce("ui/rglx_fleetindicators_blockdamage.lua")
	Player():addScriptOnce("ui/rglx_fleetindicators_craftstatus.lua")
end