-- turret factory tech level 51+ blueprinting and manufacture enabler code.
-- by rglx
-- allows all turret factories at level 50 to blueprint and manufacture (but not roll!) boss-dropped turrets of tech level 51 & 52

-- leave this here. tells avorion's script-loading engine which part of the game this is.
-- namespace TurretFactory

-- override the window title a little. changed the wording a little.
function TurretFactory.onShowWindow()
	if TurretFactory.getTechLevel() > 49 then
		window.caption = "Turret Factory - Tech Level: 50+"
	else
		window.caption = "Turret Factory - Tech Level: " .. TurretFactory.getTechLevel()
	end

	-- vanilla code continues below.
	if buildTurretsTab.isActiveTab then
		TurretFactory.onBlueprintTypeSelected(blueprintTypeCombo, blueprintTypeCombo.selectedIndex)
		TurretFactory.refreshBuildTurretsUI()
	else
		TurretFactory.refreshMakeBlueprintsUI()
	end
end

-- this function is called in two places: the sanity checks for allowing a turret to be blueprinted, and allowing a turret to be manufactured. this functionally allows players to manufacture copies of boss-drop turrets.
-- since someone got snippy in the comments of the original function of the code saying that this 'hypes up' boss loot, i figured a more clear explanation is needed: nobody wants to sit there and kill the same boss 600 times looking for another additional particular turret. it kills the game for us. so, a workaround is needed.
-- if you feel that yes, a workaround is needed, how about making tech level 51s and 52s blueprintable etc in vanilla, but with a very heavy tax?

function TurretFactory.getTechLevel()
	local tech = Balancing_GetTechLevel(data.x, data.y)
	if tech > 49 then -- if our local tech level is more than lv49, that means its within a radial distance of 20 sectors from the core. allow tech51/52 turrets to be blueprinted.
		return 52
	else
		return tech
	end
end
print("rglx-TL51+BPs: Tech Levels 51+ allowed for vanilla blueprinting and manufacture")