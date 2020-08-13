local S = minetest.get_translator("areas")

function areas:player_exists(name)
	return minetest.get_auth_handler().get_auth(name) ~= nil
end

local safe_file_write = minetest.safe_file_write
if safe_file_write == nil then
	function safe_file_write(path, content)
		local file, err = io.open(path, "w")
		if err then
			return err
		end
		file:write(content)
		file:close()
	end
end

-- Save the areas table to a file
function areas:save()
	local datastr = minetest.write_json(self.areas)
	if not datastr then
		minetest.log("error", "[areas] Failed to serialize area data!")
		return
	end
	return safe_file_write(self.config.filename, datastr)
end

-- Load the areas table from the save file
function areas:load()
	local file, err = io.open(self.config.filename, "r")
	if err then
		self.areas = self.areas or {}
		return err
	end
	local data = file:read("*a")
	if data:sub(1, 1) == "[" then
		self.areas, err = minetest.parse_json(data)
	else
		self.areas, err = minetest.deserialize(data)
	end
	if type(self.areas) ~= "table" then
		self.areas = {}
	end
	if err and #data > 10 then
		minetest.log("error", "[areas] Failed to load area data: " ..
			tostring(err))
	end
	file:close()
	self:populateStore()
end

--- Checks an AreaStore ID.
-- Deletes the AreaStore (falling back to the iterative method)
-- and prints an error message if the ID is invalid.
-- @return Whether the ID was valid.
function areas:checkAreaStoreId(sid)
	if not sid then
		minetest.log("error", "AreaStore failed to find an ID for an "
			.."area! Falling back to iterative area checking.")
		self.store = nil
		self.store_ids = nil
	end
	return sid and true or false
end

-- Populates the AreaStore after loading, if needed.
function areas:populateStore()
	if not rawget(_G, "AreaStore") then
		return
	end
	local store = AreaStore()
	local store_ids = {}
	for id, area in pairs(areas.areas) do
		local sid = store:insert_area(area.pos1,
			area.pos2, tostring(id))
		if not self:checkAreaStoreId(sid) then
			return
		end
		store_ids[id] = sid
	end
	self.store = store
	self.store_ids = store_ids
end

-- Finds the first usable index in a table
-- Eg: {[1]=false,[4]=true} -> 2
local function findFirstUnusedIndex(t)
	local i = 0
	repeat i = i + 1
	until t[i] == nil
	return i
end

--- Add a area.
-- @return The new area's ID.
function areas:add(owner, name, pos1, pos2, parent)
	local id = findFirstUnusedIndex(self.areas)
	self.areas[id] = {
		name = name,
		pos1 = pos1,
		pos2 = pos2,
		owner = owner,
		parent = parent
	}

	for i=1, #areas.registered_on_adds do
		areas.registered_on_adds[i](id, self.areas[id])
	end

	-- Add to AreaStore
	if self.store then
		local sid = self.store:insert_area(pos1, pos2, tostring(id))
		if self:checkAreaStoreId(sid) then
			self.store_ids[id] = sid
		end
	end
	return id
end

--- Remove a area, and optionally it's children recursively.
-- If a area is deleted non-recursively the children will
-- have the removed area's parent as their new parent.
function areas:remove(id, recurse)
	if recurse then
		-- Recursively find child entries and remove them
		local cids = self:getChildren(id)
		for _, cid in pairs(cids) do
			self:remove(cid, true)
		end
	else
		-- Update parents
		local parent = self.areas[id].parent
		local children = self:getChildren(id)
		for _, cid in pairs(children) do
			-- The subarea parent will be niled out if the
			-- removed area does not have a parent
			self.areas[cid].parent = parent

		end
	end

	for i=1, #areas.registered_on_removes do
		areas.registered_on_removes[i](id)
	end

	-- Remove main entry
	self.areas[id] = nil

	-- Remove from AreaStore
	if self.store then
		self.store:remove_area(self.store_ids[id])
		self.store_ids[id] = nil
	end
end

--- Move an area.
function areas:move(id, area, pos1, pos2)
	area.pos1 = pos1
	area.pos2 = pos2

	for i=1, #areas.registered_on_moves do
		areas.registered_on_moves[i](id, area, pos1, pos2)
	end

	if self.store then
		self.store:remove_area(areas.store_ids[id])
		local sid = self.store:insert_area(pos1, pos2, tostring(id))
		if self:checkAreaStoreId(sid) then
			self.store_ids[id] = sid
		end
	end
end

-- Checks if a area between two points is entirely contained by another area.
-- Positions must be sorted.
function areas:isSubarea(pos1, pos2, id)
	local area = self.areas[id]
	if not area then
		return false
	end
	local ap1, ap2 = area.pos1, area.pos2
	local ap1x, ap1y, ap1z = ap1.x, ap1.y, ap1.z
	local ap2x, ap2y, ap2z = ap2.x, ap2.y, ap2.z
	local p1x, p1y, p1z = pos1.x, pos1.y, pos1.z
	local p2x, p2y, p2z = pos2.x, pos2.y, pos2.z
	if
			(p1x >= ap1x and p1x <= ap2x) and
			(p2x >= ap1x and p2x <= ap2x) and
			(p1y >= ap1y and p1y <= ap2y) and
			(p2y >= ap1y and p2y <= ap2y) and
			(p1z >= ap1z and p1z <= ap2z) and
			(p2z >= ap1z and p2z <= ap2z) then
		return true
	end
end

-- Returns a table (list) of children of an area given it's identifier
function areas:getChildren(id)
	local children = {}
	for cid, area in pairs(self.areas) do
		if area.parent and area.parent == id then
			table.insert(children, cid)
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
	local privs = minetest.get_player_privs(name)
	if privs.areas then
		return true
	end

	-- Check self protection privilege, if it is enabled,
	-- and if the area is too big.
	if not self.config.self_protection or
			not privs[areas.config.self_protection_privilege] then
		return false, S("Self protection is disabled or you do not have"
				.." the necessary privilege.")
	end

	local max_size = privs.areas_high_limit and
			self.config.self_protection_max_size_high or
			self.config.self_protection_max_size
	if
			(pos2.x - pos1.x) > max_size.x or
			(pos2.y - pos1.y) > max_size.y or
			(pos2.z - pos1.z) > max_size.z then
		return false, S("Area is too big.")
	end

	-- Check number of areas the user has and make sure it not above the max
	local count = 0
	for _, area in pairs(self.areas) do
		if area.owner == name then
			count = count + 1
		end
	end
	local max_areas = privs.areas_high_limit and
			self.config.self_protection_max_areas_high or
			self.config.self_protection_max_areas
	if count >= max_areas then
		return false, S("You have reached the maximum amount of"
				.." areas that you are allowed to protect.")
	end

	-- Check intersecting areas
	local can, id = self:canInteractInArea(pos1, pos2, name)
	if not can then
		local area = self.areas[id]
		return false, S("The area intersects with @1 [@2] (@3).",
				area.name, id, area.owner)
	end

	return true
end

-- Given a id returns a string in the format:
-- "name [id]: owner (x1, y1, z1) (x2, y2, z2) -> children"
function areas:toString(id)
	local area = self.areas[id]
	local message = ("%s [%d]: %s %s %s"):format(
		area.name, id, area.owner,
		minetest.pos_to_string(area.pos1),
		minetest.pos_to_string(area.pos2))

	local children = areas:getChildren(id)
	if #children > 0 then
		message = message.." -> "..table.concat(children, ", ")
	end
	return message
end

-- Re-order areas in table by their identifiers
function areas:sort()
	local sa = {}
	for k, area in pairs(self.areas) do
		if not area.parent then
			table.insert(sa, area)
			local newid = #sa
			for _, subarea in pairs(self.areas) do
				if subarea.parent == k then
					subarea.parent = newid
					table.insert(sa, subarea)
				end
			end
		end
	end
	self.areas = sa
end

-- Checks if a player owns an area or a parent of it
function areas:isAreaOwner(id, name)
	local cur = self.areas[id]
	if cur and minetest.check_player_privs(name, self.adminPrivs) then
		return true
	end
	while cur do
		if cur.owner == name then
			return true
		elseif cur.parent then
			cur = self.areas[cur.parent]
		else
			return false
		end
	end
	return false
end
