minetest.register_chatcommand("protect", {
	params = "<AreaName>",
	description = "Protect your own area",
	privs = {[areas.self_protection_privilege]=true},
	func = function(name, param)
		if param == "" then
			minetest.chat_send_player(name, 'Invalid usage, see /help protect')
			return
		end
		local pos1, pos2 = {}, {}
		if areas:getPos1(name) and areas:getPos2(name) then
			pos1 = areas:getPos1(name)
			pos2 = areas:getPos2(name)
			pos1, pos2 = areas:sortPos(pos1, pos2)
		else
			minetest.chat_send_player(name, 'You need to select an area first')
			return
		end

		minetest.log("action", "/protect invoked, owner="..name..
				" areaname="..param..
				" startpos="..minetest.pos_to_string(pos1)..
				" endpos="  ..minetest.pos_to_string(pos2))

		local canAdd, errMsg = areas:canPlayerAddArea(pos1, pos2, name)
		if not canAdd then
			minetest.chat_send_player(name,
					"You can't protect that area: "
					..errMsg)
			return
		end

		areas:add(name, param, pos1, pos2, nil)
		areas:save()

		minetest.chat_send_player(name, "Area protected")
end})


minetest.register_chatcommand("set_owner", {
	params = "<PlayerName> <AreaName>",
	description = "Protect an area beetween two positions and give"
		.." a player access to it without setting the parent of the"
		.." area to any existing area",
	privs = {areas=true},
	func = function(name, param)
		local found, _, ownername, areaname = param:find('^([^ ]+) (.+)$')

		if not found then
			minetest.chat_send_player(name, "Incorrect usage, see /help set_owner")
			return
		end

		local pos1, pos2 = {}, {}
		if areas:getPos1(name) and areas:getPos2(name) then
			pos1 = areas:getPos1(name)
			pos2 = areas:getPos2(name)
			pos1, pos2 = areas:sortPos(pos1, pos2)
		else
			minetest.chat_send_player(name, "You need to select an area first")
			return
		end

		if not areas:player_exists(ownername) then
			minetest.chat_send_player(name, "The player \""
					..ownername.."\" does not exist")
			return
		end

		minetest.log("action", name.." runs /set_owner. Owner="..ownername..
				" AreaName="..areaname..
				" StartPos="..minetest.pos_to_string(pos1)..
				" EndPos="  ..minetest.pos_to_string(pos2))

		areas:add(ownername, areaname, pos1, pos2, nil)
		areas:save()
	
		minetest.chat_send_player(ownername,
				"You have been granted control over an area."
				.." Type /list_areas to show your areas.")
		minetest.chat_send_player(name, "Area protected")
end})


minetest.register_chatcommand("add_owner", {
	params = "<ParentID> <Player> <AreaName>",
	description = "Give a player access to a sub-area beetween two"
		.." positions that have already been protected,"
		.." Use set_owner if you don't want the parent to be set.",
	privs = {},
	func = function(name, param)
		local found, _, pid, ownername, areaname
				= param:find('^(%d+) ([^ ]+) (.+)$')

		if not found then
			minetest.chat_send_player(name, "Incorrect usage, see /help set_owner")
			return
		end

		local pos1, pos2 = {}, {}
		if areas:getPos1(name) and areas:getPos2(name) then
			pos1 = areas:getPos1(name)
			pos2 = areas:getPos2(name)
			pos1, pos2 = areas:sortPos(pos1, pos2)
		else
			minetest.chat_send_player(name, 'You need to select an area first')
			return
		end

		if not areas:player_exists(ownername) then
			minetest.chat_send_player(name, 'The player "'
					..ownername..'" does not exist')
			return
		end

		minetest.log("action", name.." runs /add_owner. Owner = "..ownername..
				" AreaName = "..areaname.." ParentID = "..pid..
				" StartPos = "..pos1.x..","..pos1.y..","..pos1.z..
				" EndPos = "  ..pos2.x..","..pos2.y..","..pos2.z)

		-- Check if this new area is inside an area owned by the player
		pid = tonumber(pid)
		if (not areas:isAreaOwner(pid, name)) or
		   (not areas:isSubarea(pos1, pos2, pid)) then
			minetest.chat_send_player(name,
					"You can't protect that area")
			return
		end

		areas:add(ownername, areaname, pos1, pos2, pid)
		areas:save()

		minetest.chat_send_player(ownername,
				"You have been granted control over an area."
				.." Type /list_areas to show your areas.")
		minetest.chat_send_player(name, "Area protected.")
end})


minetest.register_chatcommand("rename_area", {
	params = "<ID> <newName>",
	description = "Rename a area that you own",
	privs = {},
	func = function(name, param)
		local found, _, id, newName = param:find("^(%d+) (.+)$")
		if not found then
			minetest.chat_send_player(name,
					"Invalid usage, see /help rename_area")
			return
		end

		id = tonumber(id)
		index = areas:getIndexById(id)

		if not index then
			minetest.chat_send_player(name, "That area doesn't exist.")
			return
		end

		if not areas:isAreaOwner(id, name) then
			minetest.chat_send_player(name, "You don't own that area.")
			return
		end

		areas.areas[index].name = newName
		areas:save()
		minetest.chat_send_player(name, "Area renamed.")
end})


minetest.register_chatcommand("find_areas", {
	params = "<regexp>",
	description = "Find areas using a Lua regular expression",
	privs = {},
	func = function(name, param)
		if param == "" then
			minetest.chat_send_player(name,
					"A regular expression is required.")
			return
		end
		local found = false
		for _, area in pairs(areas.areas) do
			if areas:isAreaOwner(area.id, name) and
			   areas:toString(area):find(param) then
				minetest.chat_send_player(name, areas:toString(area))
				found = true
			end
		end
		if not found then
			minetest.chat_send_player(name, "No matches found")
		end
end})


minetest.register_chatcommand("list_areas", {
	params = "",
	description = "List your areas, or all areas if you are an admin.",
	privs = {},
	func = function(name, param)
		local admin = minetest.check_player_privs(name, {areas=true})
		if admin then
			minetest.chat_send_player(name,
					"Showing all areas.")
		else
			minetest.chat_send_player(name,
					"Showing your areas.")
		end
		for _, area in pairs(areas.areas) do
			if admin or area.owner == name then
				minetest.chat_send_player(name,
						areas:toString(area))
			end
		end
end})


minetest.register_chatcommand("recursive_remove_areas", {
	params = "<id>",
	description = "Recursively remove areas using an id",
	privs = {},
	func = function(name, param)
		local id = tonumber(param)
		if not id then
			minetest.chat_send_player(name,
					"Invalid usage, see"
					.." /help recursive_remove_areas")
			return
		end

		if areas:isAreaOwner(id, name) then
			areas:remove(id, true)
			areas:sort()
			areas:save()
		else
			minetest.chat_send_player(name, "Area "..id
					.." does not exist or is"
					.." not owned by you.")
			return
		end
		minetest.chat_send_player(name, "Removed area "..id
				.." and it's sub areas.")
end})


minetest.register_chatcommand("remove_area", {
	params = "<id>",
	description = "Remove an area using an id",
	privs = {},
	func = function(name, param)
		local id = tonumber(param)
		if not id then
			minetest.chat_send_player(name,
					"Invalid usage, see /help remove_area")
			return
		end

		if areas:isAreaOwner(id, name) then
			areas:remove(id, false)
			areas:sort()
			areas:save()
		else
			minetest.chat_send_player(name, "Area "..id
					.." does not exist or"
					.." is not owned by you")
			return
		end
		minetest.chat_send_player(name, 'Removed area '..id)
end})


minetest.register_chatcommand("change_owner", {
	params = "<id> <NewOwner>",
	description = "Change the owner of an area using its id",
	privs = {},
	func = function(name, param)
		local found, _, id, new_owner =
				param:find('^(%d+) ([^ ]+)$')

		if not found then
			minetest.chat_send_player(name,
					"Invalid usage,"
					.." see /help change_area_owner")
			return
		end
		
		if not areas:player_exists(new_owner) then
			minetest.chat_send_player(name, 'The player "'
					..new_owner..'" does not exist')
			return
		end

		id = tonumber(id)
		if not areas:isAreaOwner(id, name) then
			minetest.chat_send_player(name,
					"Area "..id.." does not exist"
					.." or is not owned by you.")
			return
		end
		local index = areas:getIndexById(id)
		areas.areas[index].owner = new_owner
		areas:save()
		minetest.chat_send_player(name, 'Owner changed.')
		minetest.chat_send_player(new_owner,
				name..'" has given you control over an area.')
end})

