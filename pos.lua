local S = minetest.get_translator("areas")

-- I could depend on WorldEdit for this, but you need to have the 'worldedit'
-- permission to use those commands and you don't have
-- /area_pos{1,2} [X Y Z|X,Y,Z].
-- Since this is mostly copied from WorldEdit it is mostly
-- licensed under the AGPL. (select_area is an exception)

areas.set_pos = {}
areas.pos1 = {}
areas.pos2 = {}

local LIMIT = 30992 -- this is due to MAPBLOCK_SIZE=16!

local function posLimit(pos)
	return {
		x = math.max(math.min(pos.x, LIMIT), -LIMIT),
		y = math.max(math.min(pos.y, LIMIT), -LIMIT),
		z = math.max(math.min(pos.z, LIMIT), -LIMIT)
	}
end

local parse_relative_pos

if minetest.parse_relative_number then
	parse_relative_pos = function(x_str, y_str, z_str, pos)

		local x = pos and minetest.parse_relative_number(x_str, pos.x)
			or tonumber(x_str)
		local y = pos and minetest.parse_relative_number(y_str, pos.y)
			or tonumber(y_str)
		local z = pos and minetest.parse_relative_number(z_str, pos.z)
			or tonumber(z_str)
		if x and y and z then
			return vector.new(x, y, z)
		end
	end
else
	parse_relative_pos = function(x_str, y_str, z_str, pos)
		local x = tonumber(x_str)
		local y = tonumber(y_str)
		local z = tonumber(z_str)
		if x and y and z then
			return vector.new(x, y, z)
		elseif string.sub(x_str, 1, 1) == "~"
			or string.sub(y_str, 1, 1) == "~"
			or string.sub(z_str, 1, 1) == "~" then
			return nil, S("Relative coordinates is not supported on this server. " ..
				"Please upgrade Minetest to 5.7.0 or newer versions.")
		end
	end
end

minetest.register_chatcommand("select_area", {
	params = S("<ID>"),
	description = S("Select an area by ID."),
	func = function(name, param)
		local id = tonumber(param)
		if not id then
			return false, S("Invalid usage, see /help @1.", "select_area")
		end
		if not areas.areas[id] then
			return false, S("The area @1 does not exist.", id)
		end

		areas:setPos1(name, areas.areas[id].pos1)
		areas:setPos2(name, areas.areas[id].pos2)
		return true, S("Area @1 selected.", id)
	end,
})

minetest.register_chatcommand("area_pos1", {
	params = "[X Y Z|X,Y,Z]",
	description = S("Set area protection region position @1 to your"
		.." location or the one specified", "1"),
	privs = {},
	func = function(name, param)
		local pos
		local player = minetest.get_player_by_name(name)
		if player then
			pos = vector.round(player:get_pos())
		end
		local found, _, x_str, y_str, z_str = param:find(
			"^(~?-?%d*)[, ](~?-?%d*)[, ](~?-?%d*)$")
		if found then
			local get_pos, reason = parse_relative_pos(x_str, y_str, z_str, pos)
			if get_pos then
				pos = get_pos
			elseif not get_pos and reason then
				return false, reason
			end
		elseif param ~= "" then
			return false, S("Invalid usage, see /help @1.", "area_pos1")
		end
		if not pos then
			return false, S("Unable to get position.")
		end
		pos = posLimit(vector.round(pos))
		areas:setPos1(name, pos)
		return true, S("Area position @1 set to @2", "1",
				minetest.pos_to_string(pos))
	end,
})

minetest.register_chatcommand("area_pos2", {
	params = "[X Y Z|X,Y,Z]",
	description = S("Set area protection region position @1 to your"
		.." location or the one specified", "2"),
	func = function(name, param)
		local pos
		local player = minetest.get_player_by_name(name)
		if player then
			pos = vector.round(player:get_pos())
		end
		local found, _, x_str, y_str, z_str = param:find(
			"^(~?-?%d*)[, ](~?-?%d*)[, ](~?-?%d*)$")
		if found then
			local get_pos, reason = parse_relative_pos(x_str, y_str, z_str, pos)
			if get_pos then
				pos = get_pos
			elseif not get_pos and reason then
				return false, reason
			end
		elseif param ~= "" then
			return false, S("Invalid usage, see /help @1.", "area_pos2")
		end
		if not pos then
			return false, S("Unable to get position.")
		end
		pos = posLimit(vector.round(pos))
		areas:setPos2(name, pos)
		return true, S("Area position @1 set to @2", "2",
			minetest.pos_to_string(pos))
	end,
})


minetest.register_chatcommand("area_pos", {
	params = "set/set1/set2/get",
	description = S("Set area protection region, position 1, or position 2"
		.." by punching nodes, or display the region"),
	func = function(name, param)
		if param == "set" then -- Set both area positions
			areas.set_pos[name] = "pos1"
			return true, S("Select positions by punching two nodes.")
		elseif param == "set1" then -- Set area position 1
			areas.set_pos[name] = "pos1only"
			return true, S("Select position @1 by punching a node.", "1")
		elseif param == "set2" then -- Set area position 2
			areas.set_pos[name] = "pos2"
			return true, S("Select position @1 by punching a node.", "2")
		elseif param == "get" then -- Display current area positions
			local pos1str, pos2str = S("Position @1:", " 1"), S("Position @1:", " 2")
			if areas.pos1[name] then
				pos1str = pos1str..minetest.pos_to_string(areas.pos1[name])
			else
				pos1str = pos1str..S("<not set>")
			end
			if areas.pos2[name] then
				pos2str = pos2str..minetest.pos_to_string(areas.pos2[name])
			else
				pos2str = pos2str..S("<not set>")
			end
			return true, pos1str.."\n"..pos2str
		else
			return false, S("Unknown subcommand: @1", param)
		end
	end,
})

function areas:getPos(playerName)
	local pos1, pos2 = areas.pos1[playerName], areas.pos2[playerName]
	if not (pos1 and pos2) then
		return nil
	end
	-- Copy positions so that the area table doesn't contain multiple
	-- references to the same position.
	pos1, pos2 = vector.new(pos1), vector.new(pos2)
	return areas:sortPos(pos1, pos2)
end

function areas:setPos1(name, pos)
	local old_pos = areas.pos1[name]
	pos = posLimit(pos)
	areas.pos1[name] = pos

	if old_pos then
		-- TODO: use `core.objects_inside_radius` after Luanti 5.10.0 is well established.
		for _, object in ipairs(core.get_objects_inside_radius(old_pos, 0.01)) do
			local luaentity = object:get_luaentity()
			if luaentity and luaentity.name == "areas:pos1" and luaentity.player == name then
				object:remove()
			end
		end
	end

	local entity = core.add_entity(pos, "areas:pos1")
	if entity then
		local luaentity = entity:get_luaentity()
		if luaentity then
			luaentity.player = name
		end
	end
end

function areas:setPos2(name, pos)
	local old_pos = areas.pos2[name]
	pos = posLimit(pos)
	areas.pos2[name] = pos

	if old_pos then
		-- TODO: use `core.objects_inside_radius` after Luanti 5.10.0 is well established.
		for _, object in ipairs(core.get_objects_inside_radius(old_pos, 0.01)) do
			local luaentity = object:get_luaentity()
			if luaentity and luaentity.name == "areas:pos2" and luaentity.player == name then
				object:remove()
			end
		end
	end

	local entity = core.add_entity(pos, "areas:pos2")
	if entity then
		local luaentity = entity:get_luaentity()
		if luaentity then
			luaentity.player = name
		end
	end
end

minetest.register_on_punchnode(function(pos, node, puncher)
	local name = puncher:get_player_name()
	-- Currently setting position
	if name ~= "" and areas.set_pos[name] then
		if areas.set_pos[name] == "pos2" then
			areas:setPos2(name, pos)
			areas.set_pos[name] = nil
			minetest.chat_send_player(name,
					S("Position @1 set to @2", "2",
					minetest.pos_to_string(pos)))
		else
			areas:setPos1(name, pos)
			areas.set_pos[name] = areas.set_pos[name] == "pos1" and "pos2" or nil
			minetest.chat_send_player(name,
					S("Position @1 set to @2", "1",
					minetest.pos_to_string(pos)))
		end
	end
end)

-- Modifies positions `pos1` and `pos2` so that each component of `pos1`
-- is less than or equal to its corresponding component of `pos2`,
-- returning the two positions.
function areas:sortPos(pos1, pos2)
	if pos1.x > pos2.x then
		pos2.x, pos1.x = pos1.x, pos2.x
	end
	if pos1.y > pos2.y then
		pos2.y, pos1.y = pos1.y, pos2.y
	end
	if pos1.z > pos2.z then
		pos2.z, pos1.z = pos1.z, pos2.z
	end
	return pos1, pos2
end

minetest.register_entity("areas:pos1", {
	initial_properties = {
		visual = "cube",
		visual_size = {x=1.1, y=1.1},
		textures = {"areas_pos1.png", "areas_pos1.png",
		            "areas_pos1.png", "areas_pos1.png",
		            "areas_pos1.png", "areas_pos1.png"},
		collisionbox = {-0.55, -0.55, -0.55, 0.55, 0.55, 0.55},
		hp_max = 1,
		armor_groups = {fleshy=100},
		static_save = false,
	},
})

minetest.register_entity("areas:pos2", {
	initial_properties = {
		visual = "cube",
		visual_size = {x=1.1, y=1.1},
		textures = {"areas_pos2.png", "areas_pos2.png",
		            "areas_pos2.png", "areas_pos2.png",
		            "areas_pos2.png", "areas_pos2.png"},
		collisionbox = {-0.55, -0.55, -0.55, 0.55, 0.55, 0.55},
		hp_max = 1,
		armor_groups = {fleshy=100},
		static_save = false,
	},
})
