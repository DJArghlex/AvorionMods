local commandName = "/giveVetPackage"
local commandDescription = "Grants the specified player their choice of their veteran's package. Keep in mind there is NO UNDO!"
local commandHelp = "<player ID> <credits/harvesters/bottans/systems>"

package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("weapontype")


function getDescription()
	return commandDescription
end

function getHelp()
	return commandDescription .. " Usage: " .. commandName .. " " .. commandHelp
end

local function has_value (tab, val) -- https://stackoverflow.com/a/33511182
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

-- from http://lua-users.org/wiki/FormattingNumbers, by a sam_lie there
local function comma_value(amount)
  local formatted = amount
  while true do  
	formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
	if (k==0) then
	  break
	end
  end
  return formatted
end

function execute(sender, commandName, ...)

	-- CONFIGURATION
	-- the reason this isn't at the top of the file is i don't think it will re-read the config when the command is run, but i could be wrong

	local packageCreditsAmount = 5000000 -- credits package amount

	-- harvesting turrets package- both will be generated in the 'harvesters' package unless one of these is set to 0
	local packageMinersQuantity = 4
	local packageSalvagersQuantity = 4

	-- sets tech level and generation seed - use a radial distance calculator or the below excel formula to make it make sense:
	--   =MAX(ROUND((-0.104*(SQRT(X-coordinate^2+Y-coordinate^2))) + 51.84),1)
	-- in short, ( -0.104 * radial distance ) + 51.84
	-- rnglayer is just a sort of secondary control that you can fool with if you don't like the turrets it generates.
	local packageHarvestersTurretX = 155 -- obviously, whole numbers only
	local packageHarvestersTurretY = 0 -- obviously, whole numbers only
	local packageHarvestersRNGLayer = 0 -- obviously, whole numbers only

	 -- look at the enums documentation in the game files for all of these possible values
	local packageHarvestersMaterial = Material(MaterialType.Trinium)
	local packageHarvestersRarity = Rarity(RarityType.Legendary)

	-- number of bottan chips in bottans package
	local packageBottansCount = 5

	-- same thing here, !PLAYER replaced with player's current name, but won't update.
	local packageMailSender = "Tree Cafe Administration Team"
	local packageMailSubject = "Tree Cafe Veterans' Package"
	local packageMailText = "Dearest !PLAYER,\n\n\tThanks for playing on Tree Cafe's second-ever iteration! As recognition of your hardest work, here's a small gift to get your journey restarted in our new galaxy.\n\nHave fun!\n~ "..packageMailSender

	local packageHarvestersFlavorText = "Thank you, !PLAYER, for playing on Tree Cafe!"

	-- systemchip package changes require reading and changing code down near the bottom
	-- i would do some testing on legacy with spawning specific-seeded chips then testing again with seeds set in this file on yourself before using it on someone else.
	-- or just wing it, i think that's probably sane.


	-- END CONFIGURATION




	-- initial object collection & variable setups
	local args = {...}
	local returnValue = nil
	local player = Player() -- currently running player
	local galaxy = Galaxy() -- currently running galaxy
	local server = Server() -- currently running server

	-- just in case
	if not server:hasAdminPrivileges(player) then
		returnValue = commandName .. ": You don't have permission."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	-- check if our first argument is a player ID
	--- first check if it even exists
	if args[1] == nil then
		returnValue = commandName .. ": No player ID or package specification supplied."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	--- ... and cast to a number
	local targetPlayerId = tonumber(args[1])

	if targetPlayerId == nil then
		returnValue = commandName .. ": Invalid playerID specified. Use /playerinfo to get their player ID."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	--- ok so looks like a player ID. let's give it a shot via Faction()
	local targetPlayer = Faction(targetPlayerId)

	--- nonexistent faction IDs will return as nil
	if targetPlayer == nil then
		returnValue = commandName .. ": Target playerID did not resolve to a player properly. Sure you got it right?"
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	--- check that this faction isn't an NPC faction or alliance
	if not targetPlayer.isPlayer then
		returnValue = commandName .. ": Target faction is NOT a player. Sure you got it right?"
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	-- it's confirmably a player. let's overwrite and see about the next argument
	local targetPlayer = Player(targetPlayerId)

	-- check if our second argument is not nil
	if args[2] == nil then
		returnValue = commandName .. ": No package specification supplied."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end
	
	-- set up our mail
	local mailToBeAdded = Mail()
	mailToBeAdded.header = packageMailSubject:gsub("!PLAYER",targetPlayer.name)
	mailToBeAdded.sender = packageMailSender:gsub("!PLAYER",targetPlayer.name)
	mailToBeAdded.text = packageMailText:gsub("!PLAYER",targetPlayer.name)



	-- ok now for logic loops
	if args[2] == "credits" then
		mailToBeAdded.money = packageCreditsAmount

	elseif args[2] == "harvesters" then
		local sectorTurretGenerator = include("sectorturretgenerator")
		-- generate our turrets, ensuring our sector seeds are identical for each one
		local sectorSeed = SectorSeed( packageHarvestersTurretX, packageHarvestersTurretY )
		local generatedMiningTurret = sectorTurretGenerator( sectorSeed ):generate( packageHarvestersTurretX, packageHarvestersTurretY, packageHarvestersRNGLayer, packageHarvestersRarity, WeaponType.RawMiningLaser, packageHarvestersMaterial )
		local generatedSalvagingTurret = sectorTurretGenerator( sectorSeed ):generate( packageHarvestersTurretX, packageHarvestersTurretY, packageHarvestersRNGLayer, packageHarvestersRarity, WeaponType.RawSalvagingLaser, packageHarvestersMaterial )
		
		generatedMiningTurret.flavorText = packageHarvestersFlavorText:gsub("!PLAYER",targetPlayer.name)
		generatedSalvagingTurret.flavorText = packageHarvestersFlavorText:gsub("!PLAYER",targetPlayer.name)

		generatedSalvagingTurret.favorite = true
		generatedMiningTurret.favorite = true

		if packageMinersQuantity > 1 then
			for i=1, packageMinersQuantity, 1 do
				mailToBeAdded:addTurret(generatedMiningTurret)
			end
		elseif packageMinersQuantity == 1 then
			mailToBeAdded:addTurret(generatedMiningTurret)
		end

		if packageSalvagersQuantity > 1 then
			for i=1, packageSalvagersQuantity, 1 do
				mailToBeAdded:addTurret(generatedSalvagingTurret)
			end
		elseif packageSalvagersQuantity == 1 then
			mailToBeAdded:addTurret(generatedSalvagingTurret)
		end

	elseif args[2] == "systems" then
		-- obviously you can generate whatever you like here just as long as it has a script
		-- changing the seed as you need it will also help you pick specific upgrades to give out, but will need testing.

		local system = SystemUpgradeTemplate("data/scripts/systems/militarytcs.lua", Rarity(RarityType.Legendary), Seed(256384128))
		system.favorite = true 
		mailToBeAdded:addItem(system)

		-- you can also add more repeated sections
		local system = SystemUpgradeTemplate("data/scripts/systems/militarytcs.lua", Rarity(RarityType.Legendary), Seed(13131313))
		system.favorite = true 
		mailToBeAdded:addItem(system)

		local system = SystemUpgradeTemplate("data/scripts/systems/civiltcs.lua", Rarity(RarityType.Legendary), Seed(1))
		system.favorite = true 
		mailToBeAdded:addItem(system)

		local system = SystemUpgradeTemplate("data/scripts/systems/civiltcs.lua", Rarity(RarityType.Legendary), Seed(1))
		system.favorite = true 
		mailToBeAdded:addItem(system)

		-- so on and so forth - exodus key's pretty rad earlygame if you can manage to find a gate, good for moving around the edges of the galaxy, but not so much getting closer than trinium. gates kinda die out after that.
		local system = SystemUpgradeTemplate("data/scripts/systems/teleporterkey1.lua", Rarity(RarityType.Legendary), Seed(1))
		system.favorite = true 
		mailToBeAdded:addItem(system)

	elseif args[2] == "bottans" then
		local bottanChip = SystemUpgradeTemplate("data/scripts/systems/teleporterkey8.lua", Rarity(RarityType.Legendary), Seed(1))
		bottanChip.favorite = true

		if packageBottansCount > 1 then
			for i=1, packageBottansCount, 1 do
				mailToBeAdded:addItem(bottanChip)
			end
		elseif packageBottansCount == 1 then
			mailToBeAdded:addItem(bottanChip)
		end
		
	else
		returnValue = commandName .. ": Invalid package selection. use /help givevetpackage for a list."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end




	targetPlayer:addMail(mailToBeAdded)

	returnValue = commandName .. ": gave " .. targetPlayer.name .. " their " .. args[2] .. " veterans' package."
	print( player.name .. " ran " .. returnValue )
	return 0, returnValue, returnValue
end