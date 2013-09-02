-- This file contains functions to convert from
-- the old areas format and other compatability code.

minetest.register_chatcommand("legacy_load_areas", {
	params = "",
	description = "Loads, converts, and saves the areas from a legacy save file.",
	privs = {areas=true, server=true},
	func = function(name, param)
		minetest.chat_send_player(name, "Converting areas...")
		local startTime = os.clock()

		err = areas:legacy_load()
		if err then
			minetest.chat_send_player(name, "Error loading legacy file: "..err)
			return
		end
		minetest.chat_send_player(name, "Legacy file loaded.")

		for k, area in pairs(areas.areas) do
			--New position format
			areas.areas[k].pos1 = {x=area.x1, y=area.y1, z=area.z1}
			areas.areas[k].pos2 = {x=area.x2, y=area.y2, z=area.z2}

			areas.areas[k].x1, areas.areas[k].y1,
			areas.areas[k].z1, areas.areas[k].x2,
			areas.areas[k].y2, areas.areas[k].z2 =
				nil, nil, nil, nil, nil, nil

			--Area positions sorting
			areas.areas[k].pos1, areas.areas[k].pos2 =
				areas:sortPos(areas.areas[k].pos1, areas.areas[k].pos2)

			--Add name
			areas.areas[k].name = "unnamed"
		end
		minetest.chat_send_player(name, "Table format updated.")

		areas:save()
		minetest.chat_send_player(name, "Converted areas saved.")
		minetest.chat_send_player(name, "Finished in "..tostring(os.clock() - startTime).."s.")
end})

-- The old load function from node_ownership (with minor modifications)
function areas:legacy_load()
	local filename = minetest.get_worldpath().."/owners.tbl"
	tables, err = loadfile(filename)
	if err then
		return err
	end

	tables = tables()
	for idx = 1, #tables do
		local tolinkv, tolinki = {}, {}
		for i, v in pairs(tables[idx]) do
			if type(v) == "table" and tables[v[1]] then
				table.insert(tolinkv, {i, tables[v[1]]})
			end
			if type(i) == "table" and tables[i[1]] then
				table.insert(tolinki, {i, tables[i[1]]})
			end
		end
		-- link values, first due to possible changes of indices
		for _, v in ipairs(tolinkv) do
			tables[idx][v[1]] = v[2]
		end
		-- link indices
		for _, v in ipairs(tolinki) do
			tables[idx][v[2]], tables[idx][v[1]] =  tables[idx][v[1]], nil
		end
	end
	self.areas = tables[1]
end

-- Returns the name of the first player that owns an area
function areas.getNodeOwnerName(pos)
	for _, area in pairs(areas.areas) do
		p1, p2 = area.pos1, area.pos2
		if pos.x >= p1.x and pos.x <= p2.x and
		   pos.y >= p1.y and pos.y <= p2.y and
		   pos.z >= p1.z and pos.z <= p2.z then
			if area.owner ~= nil then
				return area.owner
			end
		end
	end
	return false
end

-- Checks if a node is owned by you
function areas.isNodeOwner(pos, name)
	if minetest.check_player_privs(name, {areas=true}) then
		return true
	end
	for _, area in pairs(areas.areas) do
		p1, p2 = area.pos1, area.pos2
		if pos.x >= p1.x and pos.x <= p2.x and
		   pos.y >= p1.y and pos.y <= p2.y and
		   pos.z >= p1.z and pos.z <= p2.z then
			if name == area.owner then
				return true
			end
		end
	end
	return false
end

IsPlayerNodeOwner = areas.isNodeOwner
GetNodeOwnerName  = areas.getNodeOwnerName
HasOwner          = areas.hasOwner

if areas.legacy_table then
	owner_defs = {}
	setmetatable(owner_defs, {
		__index = function(table, key)
			local a = rawget(areas.areas, key)
			if a then
				a.x1 = a.pos1.x
				a.y1 = a.pos1.y
				a.z1 = a.pos1.z
				a.x2 = a.pos2.x
				a.y2 = a.pos2.y
				a.z2 = a.pos2.z
				a.pos1, a.pos2 = nil, nil
			end
			return a
		end,
		__newindex = function(table, key, value)
			if rawget(areas.areas, key) ~= nil then
				local a = value
				a.pos1, a.pos2 = {}, {}
				a.pos1.x = a.x1
				a.pos1.y = a.y1
				a.pos1.z = a.z1
				a.pos2.x = a.x2
				a.pos2.y = a.y2
				a.pos2.z = a.z2
				a.x1, a.y1, a.z1, a.x2, a.y2, a.z2
				= nil, nil, nil, nil, nil, nil
				a.name = a.name or "unnamed"
				return rawset(areas.areas, key, a);
			end
		end
	})
end

