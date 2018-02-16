local S = areas.intllib

minetest.register_chatcommand("protect", {
	params = "<AreaName>",
	description = S("Protect your own area"),
	privs = {[areas.config.self_protection_privilege]=true},
	func = function(name, param)
		if param == "" then
			return false, S("Invalid usage, see /help protect.")
		end
		local pos1, pos2 = areas:getPos(name)
		if not (pos1 and pos2) then
			return false, S("You need to select an area first.")
		end

		minetest.log("action", S("/protect invoked, Owner =")..name..
				" AreaName="..param..
				" StartPos="..minetest.pos_to_string(pos1)..
				" EndPos="  ..minetest.pos_to_string(pos2))

		local canAdd, errMsg = areas:canPlayerAddArea(pos1, pos2, name)
		if not canAdd then
			return false, S("You can't protect that area: ")..errMsg
		end

		local id = areas:add(name, param, pos1, pos2, nil)
		areas:save()

		return true, S("Area protected. ID: ")..id
	end
})


minetest.register_chatcommand("set_owner", {
	params = "<PlayerName> <AreaName>",
	description = S("Protect an area beetween two positions and give"
		.." a player access to it without setting the parent of the"
		.." area to any existing area"),
	privs = areas.adminPrivs,
	func = function(name, param)
		local ownerName, areaName = param:match('^(%S+)%s(.+)$')

		if not ownerName then
			return false, S("Incorrect usage, see /help set_owner.")
		end

		local pos1, pos2 = areas:getPos(name)
		if not (pos1 and pos2) then
			return false, S("You need to select an area first.")
		end

		if not areas:player_exists(ownerName) then
			return false, S("The player \"@1\" does not exist.", ownerName)
		end

		minetest.log("action", name..S(" runs /set_owner. Owner = ")..ownerName..
				" AreaName = "..areaName..
				" StartPos = "..minetest.pos_to_string(pos1)..
				" EndPos = "  ..minetest.pos_to_string(pos2))

		local id = areas:add(ownerName, areaName, pos1, pos2, nil)
		areas:save()
	
		minetest.chat_send_player(ownerName,
				S("You have been granted control over area #@1. Type /list_areas to show your areas.", id))
		return true, S("Area protected. ID: ")..id
	end
})


minetest.register_chatcommand("add_owner", {
	params = "<ParentID> <Player> <AreaName>",
	description = S("Give a player access to a sub-area beetween two"
		.." positions that have already been protected,"
		.." Use set_owner if you don't want the parent to be set."),
	func = function(name, param)
		local pid, ownerName, areaName
				= param:match('^(%d+) ([^ ]+) (.+)$')

		if not pid then
			minetest.chat_send_player(name, S("Incorrect usage, see /help add_owner"))
			return
		end

		local pos1, pos2 = areas:getPos(name)
		if not (pos1 and pos2) then
			return false, S("You need to select an area first.")
		end

		if not areas:player_exists(ownerName) then
			return false, S("The player \"@1\" does not exist.", ownerName)
		end

		minetest.log("action", name..S(" runs /add_owner. Owner = ")..ownerName..
				" AreaName = "..areaName.." ParentID = "..pid..
				" StartPos = "..pos1.x..","..pos1.y..","..pos1.z..
				" EndPos = "  ..pos2.x..","..pos2.y..","..pos2.z)

		-- Check if this new area is inside an area owned by the player
		pid = tonumber(pid)
		if (not areas:isAreaOwner(pid, name)) or
		   (not areas:isSubarea(pos1, pos2, pid)) then
			return false, S("You can't protect that area.")
		end

		local id = areas:add(ownerName, areaName, pos1, pos2, pid)
		areas:save()

		minetest.chat_send_player(ownerName,
				S("You have been granted control over area #@1. Type /list_areas to show your areas.", id))
		return true, S("Area protected. ID: ")..id
	end
})


minetest.register_chatcommand("rename_area", {
	params = "<ID> <newName>",
	description = S("Rename a area that you own"),
	func = function(name, param)
		local id, newName = param:match("^(%d+)%s(.+)$")
		if not id then
			return false, S("Invalid usage, see /help rename_area.")
		end

		id = tonumber(id)
		if not id then
			return false, S("That area doesn't exist.")
		end

		if not areas:isAreaOwner(id, name) then
			return true, S("You don't own that area.")
		end

		areas.areas[id].name = newName
		areas:save()
		return true, S("Area renamed.")
	end
})


minetest.register_chatcommand("find_areas", {
	params = "<regexp>",
	description = S("Find areas using a Lua regular expression"),,
	privs = areas.adminPrivs,
	func = function(name, param)
		if param == "" then
			return false, S("A regular expression is required.")
		end

		-- Check expression for validity
		local function testRegExp()
			("Test [1]: Player (0,0,0) (0,0,0)"):find(param)
		end
		if not pcall(testRegExp) then
			return false, S("Invalid regular expression.")
		end

		local matches = {}
		for id, area in pairs(areas.areas) do
			local str = areas:toString(id)
			if str:find(param) then
				table.insert(matches, str)
			end
		end
		if #matches > 0 then
			return true, table.concat(matches, "\n")
		else
			return true, S("No matches found.")
		end
	end
})


minetest.register_chatcommand("list_areas", {
	description = S("List your areas, or all areas if you are an admin."),
	func = function(name, param)
		local admin = minetest.check_player_privs(name, areas.adminPrivs)
		local areaStrings = {}
		for id, area in pairs(areas.areas) do
			if admin or areas:isAreaOwner(id, name) then
				table.insert(areaStrings, areas:toString(id))
			end
		end
		if #areaStrings == 0 then
			return true, S("No visible areas.")
		end
		return true, table.concat(areaStrings, "\n")
	end
})


minetest.register_chatcommand("recursive_remove_areas", {
	params = "<id>",
	description = S("Recursively remove areas using an id"),
	func = function(name, param)
		local id = tonumber(param)
		if not id then
			return false, S("Invalid usage, see"
					.." /help recursive_remove_areas")
		end

		if not areas:isAreaOwner(id, name) then
			return false, S("Area @1 does not exist or is"
					.." not owned by you.", id)
		end

		areas:remove(id, true)
		areas:save()
		return true, S("Removed area @1 and it's sub areas.", id)
	end
})


minetest.register_chatcommand("remove_area", {
	params = "<id>",
	description = S("Remove an area using an id"),
	func = function(name, param)
		local id = tonumber(param)
		if not id then
			return false, S("Invalid usage, see /help remove_area")
		end

		if not areas:isAreaOwner(id, name) then
			return false, S("Area @1 does not exist or"
					.." is not owned by you.", id)
		end

		areas:remove(id)
		areas:save()
		return true, S("Removed area @1", id)
	end
})


minetest.register_chatcommand("change_owner", {
	params = "<ID> <NewOwner>",
	description = S("Change the owner of an area using it's ID"),
	func = function(name, param)
		local id, newOwner = param:match("^(%d+)%s(%S+)$")
		if not id then
			return false, S("Invalid usage, see"
					.." /help change_owner.")
		end

		if not areas:player_exists(newOwner) then
			return false, S("The player \"@1\" does not exist.", newOwner)
		end

		id = tonumber(id)
		if not areas:isAreaOwner(id, name) then
			return false, S("Area @1 does not exist"
					.." or is not owned by you.", id)
		end
		areas.areas[id].owner = newOwner
		areas:save()
		minetest.chat_send_player(newOwner,
			S("@1 has given you control over the area @2 (ID @3).",name, areas.areas[id].name, id))
		return true, S("Owner changed.")
	end
})


minetest.register_chatcommand("area_open", {
	params = "<ID>",
	description = S("Toggle an area open (anyone can interact) or closed"),
	func = function(name, param)
		local id = tonumber(param)
		if not id then
			return false, S("Invalid usage, see /help area_open.")
		end

		if not areas:isAreaOwner(id, name) then
			return false, S("Area @1 does not exist"
					.." or is not owned by you.", id)
		end
		local open = not areas.areas[id].open
		local open_msg = open and S("opened") or S("closed")
		-- Save false as nil to avoid inflating the DB.
		areas.areas[id].open = open or nil
		areas:save()
		-- Translators: @1 is one of the previous 'opened' or 'closed'
		return true, S("Area @1.", open_msg)
	end
})

minetest.register_chatcommand("area_openfarming", {
	params = "<ID>",
	description = S("Toggle an area open (anyone can interact farming) or closed"),
	func = function(name, param)
		local id = tonumber(param)
		if not id then
			return false, S("Invalid usage, see /help area_openfarming.")
		end

		if not areas:isAreaOwner(id, name) then
			return false, S("Area @1 does not exist"
					.." or is not owned by you.", id)
		end
		local openfarming = not areas.areas[id].openfarming
		local openfarming_msg = openfarming and S("opened") or S("closed")
		-- Save false as nil to avoid inflating the DB.
		areas.areas[id].openfarming = openfarming or nil
		areas:save()
		-- Translators: @1 is one of the previous 'opened' or 'closed'
+		return true, S("Area @1 to farming.", openfarming_msg)
	end
})

minetest.register_chatcommand("move_area", {
	params = "<ID>",
	description = S("Move (or resize) an area to the current positions."),
	privs = areas.adminPrivs,
	func = function(name, param)
		local id = tonumber(param)
		if not id then
			return false, S("Invalid usage, see /help move_area.")
		end

		local area = areas.areas[id]
		if not area then
			return false, S("Area does not exist.")
		end

		local pos1, pos2 = areas:getPos(name)
		if not pos1 then
			return false, S("You need to select an area first.")
		end

		areas:move(id, area, pos1, pos2)
		areas:save()

		return true, S("Area successfully moved.")
	end,
})


minetest.register_chatcommand("area_info", {
	description = S("Get information about area configuration and usage."),
	func = function(name, param)
		local lines = {}
		local privs = minetest.get_player_privs(name)

		-- Short (and fast to access) names
		local cfg = areas.config
		local self_prot  = cfg.self_protection
		local prot_priv  = cfg.self_protection_privilege
		local limit      = cfg.self_protection_max_areas
		local limit_high = cfg.self_protection_max_areas_high
		local size_limit = cfg.self_protection_max_size
		local size_limit_high = cfg.self_protection_max_size_high

		local has_high_limit = privs.areas_high_limit
		local has_prot_priv = not prot_priv or privs[prot_priv]
		local can_prot = privs.areas or (self_prot and has_prot_priv)
		local max_count = can_prot and
			(has_high_limit and limit_high or limit) or 0
		local max_size = has_high_limit and
			size_limit_high or size_limit

		-- Privilege information
		local self_prot_msg = self_prot and S("enabled") or S("disabled")
		-- Translators: @1 is one of the previous 'enabled' or 'disabled'
		local self_prot_line = S("Self protection is @1 ", self_prot_msg)
		if self_prot and prot_priv then
			local has_prot_priv_msg = has_prot_priv and S("and you") or S("but you don't")
			-- Translators: @1 is one of the previous 'and you' or 'but you don't'
			self_prot_line = self_prot_line..
				S(" @1 have the neccessary privilege (@2).", has_prot_priv_msg, prot_priv)
		else
			self_prot_line = self_prot_line.."."
		end
		table.insert(lines, self_prot_line)
		if privs.areas then
			table.insert(lines, S("You are an area"..
				" administrator (\"areas\" privilege)."))
		elseif has_high_limit then
			table.insert(lines,
				S("You have extended area protection"..
				" limits (\"areas_high_limit\" privilege)."))
		end

		-- Area count
		local area_num = 0
		for id, area in pairs(areas.areas) do
			if area.owner == name then
				area_num = area_num + 1
			end
		end
		-- Translators: need to use NS gettext to be more precise
		local count_line = S("You have @1 area@2", area_num, area_num == 1 and "" or "s")
		if privs.areas then
			count_line = count_line..
				S(" and have no area protection limits.")
		elseif can_prot then
			count_line = count_line..S(", out of a maximum of @1.", max_count)
		end
		table.insert(lines, count_line)

		-- Area size limits
		local function size_info(str, size)
			table.insert(lines, (S("%s spanning up to %dx%dx%d."))
				:format(str, size.x, size.y, size.z))
		end
		local function priv_limit_info(priv, max_count, max_size)
			size_info((S("Players with the %q privilege"
				.." can protect up to %d areas")):format(
					priv, max_count), max_size)
		end
		if self_prot then
			if privs.areas then
				priv_limit_info(prot_priv,
					limit, size_limit)
				priv_limit_info("areas_high_limit",
					limit_high, size_limit_high)
			elseif has_prot_priv then
				size_info(S("You can protect areas"), max_size)
			end
		end

		return true, table.concat(lines, "\n")
	end,
})

--MFF DEBUT crabman(17/09/2015 ) respawn player at in special area(event) if a spawn is set.
+minetest.register_chatcommand("area_addspawn", {
	params = "<ID>",
		privs = areas.adminPrivs,
	description = S("Define special spawn for area"),
	func = function(name, param)
		local id = param:match("^(%d+)")
		if not id then
			return false, S("Invalid usage, see /help area_addspawn.")
		end

		id = tonumber(id)
		if not id then
			return false, S("Error, Param id must be int.")
		end

		local player = minetest.get_player_by_name(name)
		if not player then
			return false, S("Error, there is not such player")
		end
		local pos = player:getpos()
		if not pos then
			return false, S("Error, there is not pos.")
		end

		if not areas.areas[id] then
			return false, S("Area @1 does not exist.", id)
		end
		areas.areas[id].spawn = pos
		areas:save()
		return true, S("spawn of area @1 defined.", id)
	end
})

minetest.register_chatcommand("area_delspawn", {
	params = "<ID>",
		privs = areas.adminPrivs,
	description = S("Delete special spawn of area"),
	func = function(name, param)
		local id = param:match("^(%d+)")
		if not id then
			return false, S("Invalid usage, see /help area_delspawn.")
		end

		id = tonumber(id)
		if not id then
			return false, S("Error, Param id must be int.")
		end

		if not areas.areas[id] then
			return false, S("Area @1 does not exist.", id)
		end
		areas.areas[id].spawn = nil
		areas:save()
		return true, S("spawn of area @1 deleted.", id)
	end
})
