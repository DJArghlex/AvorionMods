local staticSuppressorPlanList = {}

-- add new plans just like this, putting them in data/plans/energysuppressor/<your plan name>.xml
table.insert(staticSuppressorPlanList,"mightybrankor_modular01_satellite") -- satellite made with mightybrankor's modular ship template
table.insert(staticSuppressorPlanList,"rglx_hiigaran_junk_satellite") -- satellite made with a bunch of random hiigaran junk parts i had lying around
table.insert(staticSuppressorPlanList,"sivcorp_junkclan_satellite") -- satellite made with sivcorp's junk clan ship modules

print("rglx-ESSImprovements: loaded into an inventory item!")

-- overwrite existing activate function
function activate(item)
	print("rglx-ESSImprovements: someone activated an improved energy signature suppressor...")
	local craft = Player().craft
	if not craft then return false end

	-- construct an entity from the ground up
	local desc = EntityDescriptor()
	desc:addComponents(
		ComponentType.Plan,
		ComponentType.BspTree,
		ComponentType.Intersection,
		ComponentType.Asleep,
		ComponentType.DamageContributors,
		ComponentType.BoundingSphere,
		ComponentType.BoundingBox,
		ComponentType.Velocity,
		ComponentType.Physics,
		ComponentType.Scripts,
		ComponentType.ScriptCallback,
		ComponentType.Title,
		ComponentType.Owner,
		ComponentType.Durability,
		ComponentType.PlanMaxDurability,
		ComponentType.InteractionText,
		ComponentType.EnergySystem
	)

	local faction = Faction(craft.factionIndex)

	-- old way to load plans - makes 5k block plans that just look like tiny kludge balls
	--local plan = PlanGenerator.makeStationPlan(faction)

	-- pick a plan at supposed random from our list of plans
	local planFilename = "data/plans/energysuppressor/" .. staticSuppressorPlanList[math.random(1, #staticSuppressorPlanList)] .. ".xml"


	print("rglx-ESSImprovements: loading plan ".. planFilename .. " ...")
	-- load our plan
	local plan = LoadPlanFromFile(planFilename)

	if plan == nil then
		-- something went wrong loading our plan- let's bail.
		print("rglx-ESSImprovements: failed to load a plan! bailing!")
		return false
	end
	print("rglx-ESSImprovements: loaded plan ".. planFilename .. " for an energy suppressor - " .. plan.numBlocks .. " total blocks")

	-- force the plan's material type, converting unsupported blocks (like shields and integrity fields) to hull
	plan:forceMaterial(Material(MaterialType.Iron))

	-- scale our existing plant so that it's 15 meters on its longest dimension
	local s = 15 / plan:getBoundingSphere().radius
	plan:scale(vec3(s, s, s)) 

	-- switch it to be a single health pool
	plan.accumulatingHealth = true

	-- set a position for our plan (and thus the entity) to appear
	desc.position = getPositionInFront(craft, 20)

	-- set the plan
	desc:setMovePlan(plan)

	-- make it owned by the faction that owns the ship it's being deployed from
	desc.factionIndex = faction.index

	-- create the entity, attach the script that does the actual energy suppression, and then make sure the entity is dockable.
	local satellite = Sector():createEntity(desc)
	satellite:addScript("entity/energysuppressor.lua")
	satellite.dockable = true

	return true
end
