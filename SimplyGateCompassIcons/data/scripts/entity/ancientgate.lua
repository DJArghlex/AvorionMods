-- rglx's simply gate compasses mod, v0.2.1
-- more clientsided now, and with support for ancient gates :)

-- namespace AncientGate


vanillaAncientGateInitialize = AncientGate.initialize
function AncientGate.initialize(...)
	vanillaAncientGateInitialize(...)
	print("rglx-SimplyGateCompasses: modifying an ancient gate ....")

	local dirs = { -- from vanilla gate.lua
		{name = "E /*direction*/"%_t,    angle = math.pi * 2 * 0 / 16},
		{name = "ENE /*direction*/"%_t,  angle = math.pi * 2 * 1 / 16},
		{name = "NE /*direction*/"%_t,   angle = math.pi * 2 * 2 / 16},
		{name = "NNE /*direction*/"%_t,  angle = math.pi * 2 * 3 / 16},
		{name = "N /*direction*/"%_t,    angle = math.pi * 2 * 4 / 16},
		{name = "NNW /*direction*/"%_t,  angle = math.pi * 2 * 5 / 16},
		{name = "NW /*direction*/"%_t,   angle = math.pi * 2 * 6 / 16},
		{name = "WNW /*direction*/"%_t,  angle = math.pi * 2 * 7 / 16},
		{name = "W /*direction*/"%_t,    angle = math.pi * 2 * 8 / 16},
		{name = "WSW /*direction*/"%_t,  angle = math.pi * 2 * 9 / 16},
		{name = "SW /*direction*/"%_t,   angle = math.pi * 2 * 10 / 16},
		{name = "SSW /*direction*/"%_t,  angle = math.pi * 2 * 11 / 16},
		{name = "S /*direction*/"%_t,    angle = math.pi * 2 * 12 / 16},
		{name = "SSE /*direction*/"%_t,  angle = math.pi * 2 * 13 / 16},
		{name = "SE /*direction*/"%_t,   angle = math.pi * 2 * 14 / 16},
		{name = "ESE /*direction*/"%_t,  angle = math.pi * 2 * 15 / 16},
		{name = "E /*direction*/"%_t,    angle = math.pi * 2 * 16 / 16}
	}
	local x, y = Sector():getCoordinates()
	local tx, ty = WormHole():getTargetCoordinates()

	local specs = SectorSpecifics(tx, ty, GameSeed())
	local thissectorspecs = SectorSpecifics(x, y, GameSeed())

	-- find "sky" direction to name the gate
	local ownAngle = math.atan2(ty - y, tx - x) + math.pi * 2
	if ownAngle > math.pi * 2 then ownAngle = ownAngle - math.pi * 2 end
	if ownAngle < 0 then ownAngle = ownAngle + math.pi * 2 end

	local dirString = ""
	local min = 3.0
	for _, dir in pairs(dirs) do

		local d = math.abs(ownAngle - dir.angle)
		if d < min then
			min = d
			dirString = dir.name
		end
	end

	Entity().title = "${dir} Ancient Gate to ${sector}"%_t % {dir = dirString, sector = specs.name}
	print("rglx-SimplyGateCompasses: gate renamed in " .. thissectorspecs.name )

	-- ok, now for icon stuff. clientside only.

	if onClient() then -- only do icon stuff on the clientside
		local iconPath = "data/textures/icons/pixel/rglx_simplygatecompass/ancient/gate_Unknown.png"
		if dirString ~= nil then
			print("rglx-SimplyGateCompasses: found a directional to set on an ancient gate")
			iconPath = "data/textures/icons/pixel/rglx_simplygatecompass/ancient/gate_Direction" .. dirString .. ".png"
		end
		EntityIcon().icon = iconPath
		print("rglx-SimplyGateCompasses: icon set on ancient gate")
	end
end
