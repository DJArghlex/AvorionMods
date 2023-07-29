package.path = package.path .. ";data/scripts/lib/?.lua"

local CaptainGenerator = include("captaingenerator")
local CaptainUtility = include("captainutility")

local commandName = "/addProCrew"
local commandDescription = "Adds a fully professional crew to a ship, with Tier 3, Level 5"
local commandHelp = "[str: captain primary class] [str: captain secondary class]"

function getDescription()
	return commandDescription
end

function getHelp()
	return commandDescription .. " Usage: " .. commandName .. " " .. commandHelp
end

local function pickCaptainClassFromName(className)
	if className == "None" then
		return CaptainUtility.ClassType.None

	elseif className == "Commodore" then
		return CaptainUtility.ClassType.Commodore

	elseif className == "Smuggler" then
		return CaptainUtility.ClassType.Smuggler

	elseif className == "Merchant" then
		return CaptainUtility.ClassType.Merchant

	elseif className == "Miner" then
		return CaptainUtility.ClassType.Miner

	elseif className == "Scavenger" then
		return CaptainUtility.ClassType.Scavenger

	elseif className == "Explorer" then
		return CaptainUtility.ClassType.Explorer

	elseif className == "Daredevil" then
		return CaptainUtility.ClassType.Daredevil

	elseif className == "Scientist" then
		return CaptainUtility.ClassType.Scientist

	elseif className == "Hunter" then
		return CaptainUtility.ClassType.Hunter

	else
		return nil

	end
end

function execute(sender, commandName, ...)
	local args = {...}
	local player = Player()
	local returnValue = nil

	if onClient() then
		returnValue = "Execution on client forbidden."
		return 1, returnValue, returnValue
	end
	
	if not player then
		returnValue = commandName .. ": Player isn't present?"
		return 1, returnValue, returnValue
	end

	local self = player.craft
	if not self then
		returnValue = commandName .. ": Drones don't need crew. Did you forget to select a target?"
		return 1, returnValue, returnValue
	end

	local craft = self.selectedObject or self

	if not craft.crew then
		returnValue = commandName .. ": This craft doesn't need a crew."
		return 1, returnValue, returnValue
	end

	local idealCrew = craft.idealCrew
	local newCrew = Crew()

	local crewMembersTable = idealCrew:getWorkforce()
	for crewJob in pairs(crewMembersTable) do

		local workforceNeeded = crewMembersTable[crewJob]

		if crewJob.value == CrewProfessionType.Engine then
			local maxPossibleWorkforce = 3.00
			local maxLevelWorkforceProvided = 2.50
			local professionalsNeeded = maxPossibleWorkforce * math.ceil( workforceNeeded / maxLevelWorkforceProvided )
			print (crewJob:name(workforceNeeded),"|",professionalsNeeded,"needed")
			newCrew:add(professionalsNeeded,CrewMan(crewJob,true,3))

		elseif crewJob.value == CrewProfessionType.Gunner then
			local maxPossibleWorkforce = 1.00
			local maxLevelWorkforceProvided = 2.50
			local professionalsNeeded = maxPossibleWorkforce * math.ceil( workforceNeeded / maxLevelWorkforceProvided )
			print (crewJob:name(workforceNeeded),"|",professionalsNeeded,"needed")
			newCrew:add(professionalsNeeded,CrewMan(crewJob,true,3))

		elseif crewJob.value == CrewProfessionType.Miner then
			local maxPossibleWorkforce = 1.00
			local maxLevelWorkforceProvided = 2.50
			local professionalsNeeded = maxPossibleWorkforce * math.ceil( workforceNeeded / maxLevelWorkforceProvided )
			print (crewJob:name(workforceNeeded),"|",professionalsNeeded,"needed")
			newCrew:add(professionalsNeeded,CrewMan(crewJob,true,3))

		elseif crewJob.value == CrewProfessionType.Repair then
			local maxPossibleWorkforce = 3.00
			local maxLevelWorkforceProvided = 2.50
			local professionalsNeeded = maxPossibleWorkforce * math.ceil( workforceNeeded / maxLevelWorkforceProvided )
			print (crewJob:name(workforceNeeded),"|",professionalsNeeded,"needed")
			newCrew:add(professionalsNeeded,CrewMan(crewJob,true,3))

		elseif crewJob.value == CrewProfessionType.Pilot then
			local maxPossibleWorkforce = 1.00
			local maxLevelWorkforceProvided = 1.00
			local professionalsNeeded = maxPossibleWorkforce * math.ceil( workforceNeeded / maxLevelWorkforceProvided )
			print (crewJob:name(workforceNeeded),"|",professionalsNeeded,"needed")
			newCrew:add(professionalsNeeded,CrewMan(crewJob,true,3))

		elseif crewJob.value == CrewProfessionType.Security then
			local maxPossibleWorkforce = 1.00
			local maxLevelWorkforceProvided = 1.00
			local professionalsNeeded = maxPossibleWorkforce * math.ceil( workforceNeeded / maxLevelWorkforceProvided )
			print (crewJob:name(workforceNeeded),"|",professionalsNeeded,"needed")
			newCrew:add(professionalsNeeded,CrewMan(crewJob,true,3))

		elseif crewJob.value == CrewProfessionType.Attacker then
			local maxPossibleWorkforce = 1.00
			local maxLevelWorkforceProvided = 1.00
			local professionalsNeeded = maxPossibleWorkforce * math.ceil( workforceNeeded / maxLevelWorkforceProvided )
			print (crewJob:name(workforceNeeded),"|",professionalsNeeded,"needed")
			newCrew:add(professionalsNeeded,CrewMan(crewJob,true,3))

		end

	end


	local primaryClass = nil
	local secondaryClass = nil
	if args[1] ~= nil and args[2] ~= nil then
		primaryClass = pickCaptainClassFromName(args[1])
		secondaryClass = pickCaptainClassFromName(args[2])
	end
	if primaryClass ~= nil and secondaryClass ~= nil then
		print("custom captain classes specified:",args[1],args[2])
		newCrew:setCaptain(CaptainGenerator():generate(3,5,primaryClass,secondaryClass))
	else
		print("generating random T3 Lv5 Dual-class Captain")
		newCrew:setCaptain(CaptainGenerator():generate(3,5))
	end


	-- preserve our existing boarders and security
	print( "Adding security:", craft.crew.security ) 
	newCrew:add(craft.crew.security,CrewMan(CrewProfession(CrewProfessionType.Security),true,3))
	print( "Adding boarders:", craft.crew.security ) 
	newCrew:add(craft.crew.attackers,CrewMan(CrewProfession(CrewProfessionType.Attacker),true,3))
	
	-- add our extra pilots
	print ("Adding extra pilots:",craft.crew.pilots)
	if (craft.crew.pilots > newCrew.pilots) then -- we only want to add whatever we had as extra pilots
		newCrew:add(craft.crew.pilots,CrewMan(CrewProfession(CrewProfessionType.Pilot),true,3))
	end

	-- add some free-floating crewmembers in case we need more gunners or something
	-- newCrew:add( math.floor( newCrew.size / 10 ) ,CrewMan(CrewProfession(CrewProfessionType.None),false,0))

	craft.crew = newCrew

	returnValue = commandName .. ": Re-crewed " .. craft.title .. " '" .. craft.name .."' owned by " .. Owner(craft).name
	print( player.name .. " ran " .. returnValue )
	return 0, returnValue, returnValue
end
