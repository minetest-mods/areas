local hudHandlers = {}

--- Adds a function as a HUD handler, it will be able to add items to the Areas HUD element.
function areas:registerHudHandler(handler)
	table.insert(hudHandlers, handler)
end


function areas:getExternalHudEntries(pos)
	local areas = {}
	for _, func in pairs(hudHandlers) do
		func(pos, areas)
	end
	return areas
end

--plants to place in openfarming
local plants = { ["farming:blueberries"]="air", ["farming:carrot"]="air", ["farming:coffee_beans"]="air", ["farming:corn"]="air", ["farming:cucumber"]="air",
				["farming:melon_slice"]="air", ["farming:potato"]="air", ["farming:pumpkin_slice"]="air", ["farming:raspberries"]="air", ["farming:rhubarb"]="air",
				 ["farming:tomato"]="air", ["farming:seed_cotton"]="air", ["farming:seed_wheat"]="air",["default:papyrus"]="air", ["farming:trellis"]="air",
				 ["farming:grapes"]="farming:trellis", ["farming:beanpole"]="air", ["farming:beans"]="farming:beanpole",
				}

--- Returns a list of areas that include the provided position.
function areas:getAreasAtPos(pos)
	local res = {}

	if self.store then
		local a = self.store:get_areas_for_pos(pos, false, true)
		for store_id, store_area in pairs(a) do
			local id = tonumber(store_area.data)
			res[id] = self.areas[id]
		end
	else
		local px, py, pz = pos.x, pos.y, pos.z
		for id, area in pairs(self.areas) do
			local ap1, ap2 = area.pos1, area.pos2
			if
				(px >= ap1.x and px <= ap2.x) and
				(py >= ap1.y and py <= ap2.y) and
				(pz >= ap1.z and pz <= ap2.z) then
				res[id] = area
			end
		end
	end
	return res
end

--- Returns areas that intersect with the passed area.
function areas:getAreasIntersectingArea(pos1, pos2)
	local res = {}
	if self.store then
		local a = self.store:get_areas_in_area(pos1, pos2,
				true, false, true)
		for store_id, store_area in pairs(a) do
			local id = tonumber(store_area.data)
			res[id] = self.areas[id]
		end
	else
		self:sortPos(pos1, pos2)
		local p1x, p1y, p1z = pos1.x, pos1.y, pos1.z
		local p2x, p2y, p2z = pos2.x, pos2.y, pos2.z
		for id, area in pairs(self.areas) do
			local ap1, ap2 = area.pos1, area.pos2
			if
					(ap1.x <= p2x and ap2.x >= p1x) and
					(ap1.y <= p2y and ap2.y >= p1y) and
					(ap1.z <= p2z and ap2.z >= p1z) then
				-- Found an intersecting area.
				res[id] = area
			end
		end
	end
	return res
end

-- Checks if the area is unprotected or owned by you
function areas:canInteract(pos, name)
	if minetest.check_player_privs(name, self.adminPrivs) then
		return true
	end
	local owned = false
	
	-- to avoid crash with water lily
	if pos == nil  then
		return not owned
	end
	
	for _, area in pairs(self:getAreasAtPos(pos)) do
		if area.owner == name or area.open then
			return true
		
		elseif area.openfarming then
			-- if area is openfarming
			local node = minetest.get_node(pos).name
			if not minetest.registered_nodes[node] then
				return false
			end
			local player = minetest.get_player_by_name(name)
			if not player then
				return false
			end
			local wstack = player:get_wielded_item():get_name()
			if wstack == "" then
				wstack = "hand"
			end

			--on_dig
			if minetest.get_item_group(node, "plant") == 1 and (wstack == "hand" or minetest.registered_tools[wstack]) then
				return true
			end

			--on_place
			if plants[wstack] ~= nil and plants[wstack] == node then
				return true
			end

			owned = true
		else
			owned = true
		end
	end
	return not owned
end

function areas:canMakeArea(pos1, pos2, name) --MFF crabman(25/02/2016) fix areas in areas
	if name and minetest.check_player_privs(name, self.adminPrivs) then
		return true
	end
	areas:sortPos(pos1, pos2)

	local id_areas_intersect = {}
	local areas = self:getAreasIntersectingArea(pos1, pos2)

	if not areas then return true end

	for id, area in pairs(areas) do
		if area.owner == name and self:isSubarea(pos1, pos2, id) then
			return true
		end
		if not area.open and not self:isAreaOwner(id, name) then
			table.insert(id_areas_intersect, id)
		end
	end

	if #id_areas_intersect > 0 then
		return false, id_areas_intersect[1]
	end

	return true
end


--MFF crabman(5/03/2016 ) return special area pos if a spawn is set.
--1 party (2 party in beds mod)
function areas:getSpawn(pos)
	for _, area in pairs(areas:getAreasAtPos(pos)) do
		if area.spawn and area.spawn.x then
			return area.spawn
		end
	end
	return nil
end

--MFF DEBUT crabman(17/09/2015 ) respawn player in special area(event) if a spawn is set.
--1 party (2 party in beds mod)
local dead_players = {}
minetest.register_on_dieplayer(function(player)
	local player_name = player:get_player_name()
	if not player_name then return end
	local pos = player:getpos()
	if pos then
		dead_players[player_name] = pos
	end
end)


function areas:onRespawn(player)
	local player_name = player:get_player_name()
	if not player_name or not dead_players[player_name] then return false end
	local pos = dead_players[player_name]
	dead_players[player_name] = nil
	if pos then
		for _, area in pairs(areas:getAreasAtPos(pos)) do
			if area.spawn then
				player:setpos(area.spawn)
				return true
			end
		end
	end
	return false
end

-- Returns a table (list) of all players that own an area
function areas:getNodeOwners(pos)
	local owners = {}
	for _, area in pairs(self:getAreasAtPos(pos)) do
		table.insert(owners, area.owner)
	end
	return owners
end

--- Checks if the area intersects with an area that the player can't interact in.
-- Note that this fails and returns false when the specified area is fully
-- owned by the player, but with multiple protection zones, none of which
-- cover the entire checked area.
-- @param name (optional) Player name.  If not specified checks for any intersecting areas.
-- @param allow_open Whether open areas should be counted as if they didn't exist.
-- @return Boolean indicating whether the player can interact in that area.
-- @return Un-owned intersecting area ID, if found.
function areas:canInteractInArea(pos1, pos2, name, allow_open)
	if name and minetest.check_player_privs(name, self.adminPrivs) then
		return true
	end
	self:sortPos(pos1, pos2)

	-- Intersecting non-owned area ID, if found.
	local blocking_area = nil

	local areas = self:getAreasIntersectingArea(pos1, pos2)
	for id, area in pairs(areas) do
		-- First check for a fully enclosing owned area.
		-- A little optimization: isAreaOwner isn't necessary
		-- here since we're iterating over all relevant areas.
		if area.owner == name and
				self:isSubarea(pos1, pos2, id) then
			return true
		end

		-- Then check for intersecting non-owned (blocking) areas.
		-- We don't bother with this check if we've already found a
		-- blocking area, as the check is somewhat expensive.
		-- The area blocks if the area is closed or open areas aren't
		-- acceptable to the caller, and the area isn't owned.
		-- Note: We can't return directly here, because there might be
		-- an exclosing owned area that we haven't gotten to yet.
		if not blocking_area and
				(not allow_open or not area.open) and
				(not name or not self:isAreaOwner(id, name)) then
			blocking_area = id
		end
	end

	if blocking_area then
		return false, blocking_area
	end

	-- There are no intersecting areas or they are only partially
	-- intersecting areas and they are all owned by the player.
	return true
end

