-- load our stuff
if onServer() then
	local sector = Sector()
	sector:addScriptOnce("sector/rglx_serverlib_logstationdestructions.lua")
end