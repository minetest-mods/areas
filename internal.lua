function areas:player_exists(name)
	return minetest.auth_table[name] ~= nil
end

-- Save the areas table to a file
function areas:save()
	file, err = io.open(self.filename, "w")
	if err then
		return err
	end
	file:write(minetest.serialize(self.areas))
	file:close()
end

-- Load the areas table from the save file
function areas:load()
	file, err = io.open(self.filename, "r")
	if err then
		self.areas = self.areas or {}
		return err
	end
	self.areas = minetest.deserialize(file:read("*a"))
	if type(self.areas) ~= "table" then self.areas = {} end
	file:close()
end

-- Shorter than the table function
function areas:add(owner, name, pos1, pos2, parent)
	table.insert(areas.areas, {id=table.maxn(self.areas)+1, name=name,
			pos1=pos1, pos2=pos2, owner=owner, parent=parent})
end

-- Remove a area, and optionally it's children recursively.
-- If a area is deleted non-recursively the children will
-- have the removed area's parent as their new parent.
function areas:remove(id, recurse)
	if recurse then
		-- Recursively find child entries and remove them
		local cids = self:getChildren(id)
		for _, cid in pairs(cids) do
			self:removeArea(cid, true)
		end
	else
		-- Update parents
		local parent = self:getAreaById(id).parent
		local children = self:getChildren(id)
		for _, child in pairs(children) do
			-- The subarea parent will be niled out if the
			-- removed area does not have a parent
			areas.areas[self:getIndexById(child)].parent = parent

		end
	end

	-- Remove main entry
	table.remove(self.areas, self:getIndexById(id))
end

-- Checks if a area between two points is entirely contained by another area
function areas:isSubarea(pos1, pos2, id)
	local area = areas:getAreaById(id)
	if not area then
		return false
	end
	p1, p2 = area.pos1, area.pos2
	if (pos1.x >= p1.x and pos1.x <= p2.x) and
	   (pos2.x >= p1.x and pos2.x <= p2.x) and
	   (pos1.y >= p1.y and pos1.y <= p2.y) and
	   (pos2.y >= p1.y and pos2.y <= p2.y) and
	   (pos1.z >= p1.z and pos1.z <= p2.z) and
	   (pos2.z >= p1.z and pos2.z <= p2.z) then
		return true
	end
end

-- Returns a table (list) of children of an area given it's identifier
function areas:getChildren(id)
	local children = {}
	for _, area in pairs(self.areas) do
		if area.parent and area.parent == id then
			table.insert(children, area.id)
		end
	end
	return children
end

-- Checks if the user has sufficient privileges.
-- If the player is not a administrator it also checks
-- if the area intersects other areas that they do not own.
-- Also checks the size of the area and if the user already
-- has more than max_areas.
function areas:canPlayerAddArea(pos1, pos2, name)
	if minetest.check_player_privs(name, {areas=true}) then
		return true
	end

	-- Check self protection privilege, if it is enabled,
	-- and if the area is too big.
	if (not self.self_protection) or 
	   (not minetest.check_player_privs(name,
	   		{[areas.self_protection_privilege]=true})) then
		return false, "Self protection is disabled or you do not have"
				.." the necessary privilege."
	end

	if (pos2.x - pos1.x) > self.self_protection_max_size.x or
	   (pos2.y - pos1.y) > self.self_protection_max_size.y or
	   (pos2.z - pos1.z) > self.self_protection_max_size.z then
		return false, "Area is too big."
	end

	-- Check number of areas the user has and make sure it not above the max
	if self.self_protection then
		local count = 0
		for _, area in pairs(self.areas) do
			if area.owner == name then
				count = count + 1
			end
		end
		if count > self.self_protection_max_areas then
			return false, "You have reached the maximum amount"
					.." of areas that you are allowed to"
					.." protect."
		end
	end

	-- Check intersecting areas
	for _, area in pairs(self.areas) do
		if (area.pos1.x <= pos2.x and area.pos2.x >= pos1.x) and
		   (area.pos1.y <= pos2.y and area.pos2.y >= pos1.y) and
		   (area.pos1.z <= pos2.z and area.pos2.z >= pos1.z) then
			--Found an area intersecting with the suplied area
			if area.owner ~= name then
				return false, "The area intersects with an"
						.." area that you do not own."
			end
		end
	end

	return true, ""
end

-- Given a area returns a string in the format:
-- "name [id]: owner (x1, y1, z1) (x2, y2, z2) -> children"
function areas:toString(area)
	local message = area.name..
		" ["..area.id.."]: "..area.owner.." "..
		minetest.pos_to_string(area.pos1).." "..
		minetest.pos_to_string(area.pos2)

	local children = areas:getChildren(id)
	if #children > 0 then
		message = message..
		" -> "..table.concat(children, ", ")
	end
	return message		
end

-- Returns a area given it's identifier
function areas:getAreaById(id)
	for _, area in pairs(self.areas) do
		if area.id == id then return area end
	end
end

-- Returns a table index for an area given it's identifier
function areas:getIndexById(id)
	for i, area in pairs(self.areas) do
		if area.id == id then return i end
	end
end

-- Re-order areas in table by their identifiers
function areas:sort()
	for k, area in pairs(self.areas) do
		if area.id ~= k then
			for _, subarea in pairs(self.areas) do
				if subarea.parent == area.id then
					subarea.parent = k
				end
			end
			area.id = k
		end
	end
end

-- Checks if a player owns an area or a parent of it
function areas:isAreaOwner(id, name)
	local cur = self:getAreaById(id)
	if cur and minetest.check_player_privs(name, {areas=true}) then
		return true
	end
	while cur do
		if cur.owner == name then
			return true
		elseif cur.parent then
			cur = self:getAreaById(cur.parent)
		else
			return false
		end
	end
	return false
end

