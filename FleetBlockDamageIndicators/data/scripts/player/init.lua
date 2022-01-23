if onClient() then
	local player = Player()
	print("rglx-FleetBlockDamageIndicators: attempting to load script onto ".. player.name .. "'s client")
	player:addScriptOnce("ui/enemystrengthindicators.lua")
end