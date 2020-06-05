-- This file contains functions to convert from
-- the old areas format and other compatability code.
local S = minetest.get_translator("areas")

minetest.register_chatcommand("legacy_load_areas", {
	params = S("<version>"),
	description = S("Loads, converts, and saves the areas from"
		.." a legacy save file."),
	privs = {areas=true, server=true},
	func = function(name, param)
		minetest.chat_send_player(name, S("Converting areas…"))
		local version = tonumber(param)
		if version == 0 then
			local err = areas:node_ownership_load()
			if err then
				minetest.chat_send_player(name, S("Error loading legacy file: @1", err))
				return
			end
		else
			minetest.chat_send_player(name, S("Invalid version number. (0 allowed)"))
			return
		end
		minetest.chat_send_player(name, S("Legacy file loaded."))

		for k, area in pairs(areas.areas) do
			-- New position format
			area.pos1 = {x=area.x1, y=area.y1, z=area.z1}
			area.pos2 = {x=area.x2, y=area.y2, z=area.z2}

			area.x1, area.y1, area.z1,
			area.x2, area.y2, area.z2 =
				nil, nil, nil, nil, nil, nil

			-- Area positions sorting
			areas:sortPos(area.pos1, area.pos2)

			-- Add name
			area.name = S("unnamed")

			-- Remove ID
			area.id = nil
		end
		minetest.chat_send_player(name, S("Table format updated."))

		areas:save()
		minetest.chat_send_player(name, S("Converted areas saved. Done."))
	end
})

function areas:node_ownership_load()
	local filename = minetest.get_worldpath().."/owners.tbl"
	local tables, err
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
	for id, area in pairs(areas:getAreasAtPos(pos)) do
		return area.owner
	end
	return false
end

-- Checks if a node is owned by you
function areas.isNodeOwner(pos, name)
	if minetest.check_player_privs(name, areas.adminPrivs) then
		return true
	end
	for id, area in pairs(areas:getAreasAtPos(pos)) do
		if name == area.owner then
			return true
		end
	end
	return false
end

-- Checks if an area has an owner
function areas.hasOwner(pos)
	for id, area in pairs(areas:getAreasAtPos(pos)) do
		return true
	end
	return false
end
