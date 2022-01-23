--[[

	DS9 Utilities - Welcome Email
	-----------------------------
	Sends off an email to a newly joined player using either the defaults
	provided below, or via a WelcomeEmail.txt file located in the Server
	root directory. Also optionally (and by default) adds one or more
	turrets of your spefication to the email as an attachment.

	License: WTFPL
	Info: https://en.wikipedia.org/wiki/WTFPL

]]

do
	local __old_path = package.path
	local vanilla_initialize = initialize
	local vanilla_onPlayerCreated = onPlayerCreated

	package.path = package.path .. ";data/scripts/lib/?.lua"
	package.path = package.path .. ";data/scripts/lib/?.lua"
	package.path = package.path .. ";data/scripts/?.lua"
	
	include("utility")
	include("stringutility")
	include("weapontype")

	local __d = {
		-- Mod Init
		turret     = nil,

		-- Default Message Information
		m_sender   = "void catgirl rglx",
		m_header   = "welcome to the server!",
		m_text     = "sample text. please put something in WelcomeEmail.txt in your server's data folder.",
		m_file     = Server().folder .. "/WelcomeEmail.txt",

		-- Resources
		r_money    = 50000000,
		r_iron     = 10000000,
		r_titanium = 10000000,
		r_naonite  = 100000,
		r_trinium  = 0,
		r_xanion   = 0,
		r_ogonite  = 0,
		r_avorion  = 0,

		-- Turret Data
		t_num      = 10,
		t_mat      = Material(MaterialType.Naonite),
		t_rarity   = Rarity(5),
		t_type     = WeaponType.RawMiningLaser,
		t_sec_x    = 0,
		t_sec_y    = 20,
		t_sec_o    = 0,

		-- building knowledge to include
		k_iron = false, -- included in vanilla storyline at start
		k_titanium = false, -- granted when the player obtains titanium (or shortly thereafter)
		k_naonite = true, -- have to scavenge for the rest - or be granted them with this mail :)
		k_trinium = false,
		k_xanion = false,
		k_ogonite = false,
		k_avorion = false,

	}

	-- https://stackoverflow.com/questions/4990990/check-if-a-file-exists-with-lua
	local function __does_file_exist(name)
		local f=io.open(name,"r")
		if f~=nil then io.close(f) return true else return false end
	end

	-- Returns a newly generated turret using the data provided
	local function __make_turret(__d)
		local __stg = include("sectorturretgenerator")
		return __stg(SectorSeed(__d.t_sec_x, __d.t_sec_y)):generate(
			__d.t_sec_x,
			__d.t_sec_y,
			__d.t_sec_o,
			__d.t_rarity,
			__d.t_type,
			__d.t_mat
		)
	end

	-- Initial turret generation; __d.turret is mostly used as a safeguard
	-- in case turret generation breaks again.
	function initialize()
		vanilla_initialize()
		__d.turret = __make_turret(__d)
		if type(__d.turret) == "nil" then 
			print("Generated turret is nil! Skipping turret email addition.")
		else
			print("Generated turret is of type <${t_type}>."%_T % {t_type=type(__d.turret)} )
		end

		print("Mail text file location is: ${m_file}"%_T % {m_file=__d.m_file})
	end

	function onPlayerCreated (index)
		vanilla_onPlayerCreated(index)

		local __player = Player(index)
		local __mail = Mail()
		local __msgfooter = "Used default text body."
		local __turret, __mailfile = false, false

		-- Adapted from DirtyRedzServer Manager. Override the default message if
		-- a file called WelcomeEmail.txt is present in the server directory and is
		-- readable. We load this on demand so that we dont need to restart the
		-- whole server to update our email
		__mail.sender = __d.m_sender
		__mail.header = __d.m_header
		__mail.text   = __d.m_text
		if __does_file_exist(__d.m_file) then
			local FILE = assert(io.open(__d.m_file, "r"))
			__mail.text = FILE:read("*all")
			FILE:close()
			FILE = nil

			__mailfile = true
		end

		-- Resources
		__mail.money  = __d.r_money
		__mail:setResources(
			__d.r_iron,
			__d.r_titanium,
			__d.r_naonite,
			__d.r_trinium,
			__d.r_xanion,
			__d.r_ogonite,
			__d.r_avorion
		)

		-- Make sure we **actually** generated the initial turret,
		-- and then make sure that the number set to be given is
		-- greater than 0 before adding it to the player.
		if type(__d.turret) == "userdata" and __d.t_num > 0 then
			__mail:addTurret(__d.turret)
			
			-- If the number mentioned is set higher than 1, generate
			-- even more turrets and attach them to the email.
			if __d.t_num > 1 then
				for i=2, __d.t_num, 1 do
					__mail:addTurret(__make_turret(__d))
				end
			end

			__turret = true
		else
			print("Skipped adding turret to player mail. Datatype is incorrect: <%{t_type}>"%_T % {t_type=type(__d.turret)} )
		end
		
		-- yeah i'm just gonna do this dirty

		-- for each material grade we can attach these building knowledges so that the player can have them upon login.
		if __d.k_iron == true then
			__mail:addItem(UsableInventoryItem("buildingknowledge.lua", Rarity(RarityType.Exotic), Material(MaterialType.Iron), __player.index))
			print("attached building knowledge for iron to " .. __player.name .. "'s (#" .. __player.index .. ") welcome mail")
		end

		if __d.k_titanium == true then
			__mail:addItem(UsableInventoryItem("buildingknowledge.lua", Rarity(RarityType.Exotic), Material(MaterialType.Titanium), __player.index))
			print("attached building knowledge for titanium to " .. __player.name .. "'s (#" .. __player.index .. ") welcome mail")
		end

		if __d.k_naonite == true then
			__mail:addItem(UsableInventoryItem("buildingknowledge.lua", Rarity(RarityType.Exotic), Material(MaterialType.Naonite), __player.index))
			print("attached building knowledge for naonite to " .. __player.name .. "'s (#" .. __player.index .. ") welcome mail")
		end

		if __d.k_trinium == true then
			__mail:addItem(UsableInventoryItem("buildingknowledge.lua", Rarity(RarityType.Exotic), Material(MaterialType.Trinium), __player.index))
			print("attached building knowledge for trinium to " .. __player.name .. "'s (#" .. __player.index .. ") welcome mail")
		end

		if __d.k_xanion == true then
			__mail:addItem(UsableInventoryItem("buildingknowledge.lua", Rarity(RarityType.Exotic), Material(MaterialType.Xanion), __player.index))
			print("attached building knowledge for xanion to " .. __player.name .. "'s (#" .. __player.index .. ") welcome mail")
		end

		if __d.k_ogonite == true then
			__mail:addItem(UsableInventoryItem("buildingknowledge.lua", Rarity(RarityType.Exotic), Material(MaterialType.Ogonite), __player.index))
			print("attached building knowledge for ogonite to " .. __player.name .. "'s (#" .. __player.index .. ") welcome mail")
		end

		if __d.k_avorion == true then
			__mail:addItem(UsableInventoryItem("buildingknowledge.lua", Rarity(RarityType.Exotic), Material(MaterialType.Avorion), __player.index))
			print("attached building knowledge for avorion to " .. __player.name .. "'s (#" .. __player.index .. ") welcome mail")
		end

		if __mailfile then
			__msgfooter = "Used <"..__d.m_file.."> for mail text."
		end

		if __turret then
			__msgfooter = __msgfooter.." Attached "..__d.t_num.." turret[s]"
		end

		__player:addMail(__mail)
		print("Sent welcome email to <${pname}>. ${footer}"%_T % {pname=__player.name,footer=__msgfooter} )
	end

	package.path = __old_path
end

