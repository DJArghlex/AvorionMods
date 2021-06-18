-- bootstraps the turret replicator menu into every turret factory as soon as its loaded and initialized.

local oldTurretFactoryinitialize = TurretFactory.initialize
function TurretFactory.initialize(...)
	-- run existing code
	oldTurretFactoryinitialize(...)
	-- load the turret replicator into every turret factory
	Entity():addScriptOnce("data/scripts/entity/merchants/rglx_ancientturretdecryptor.lua")
end
