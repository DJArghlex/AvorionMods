-- rglx's simply gate compasses mod, v0.2.2
-- purely clientsided now, and with support for ancient gates :)

-- namespace Gate

if onClient() then -- only do icon stuff on the clientside

	package.path = package.path .. ";data/scripts/?.lua"
	local SectorSpecifics = include ("sectorspecifics")

	vanillaGateInitialize = Gate.initialize
	function Gate.initialize(...)
		vanillaGateInitialize(...)

		--print("rglx-SimplyGateCompasses: modifying a regular gate")

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

		local entity = Entity()

		entity.title = "${dir} Gate to ${sector}"%_t % {dir = dirString, sector = specs.name}
		--print("rglx-SimplyGateCompasses: gate renamed in " .. thissectorspecs.name )

		local iconPath = "data/textures/icons/pixel/rglx_simplygatecompass/gate_Unknown.png"
		if dirString ~= "" then
			--print("rglx-SimplyGateCompasses: found a directional to set on a regular gate")
			iconPath = "data/textures/icons/pixel/rglx_simplygatecompass/gate_Direction" .. dirString .. ".png"
		end
		if onClient() then
			EntityIcon(entity.index).icon = iconPath
		end
		--print("rglx-SimplyGateCompasses: set an icon on a gate")
		print("rglx-SimplyGateCompasses: successfully modified a regular gate & its icon in " .. thissectorspecs.name)
	end
end
