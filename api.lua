
-- Temporary compatibility function - see minetest PR#1180
if not vector.interpolate then
	vector.interpolate = function(pos1, pos2)
		return {x = pos1.x + (pos2.x - pos1.x) * factor,
		        y = pos1.y + (pos2.y - pos1.y) * factor,
			z = pos1.z + (pos2.z - pos1.z) * factor}
		end
end


-- Returns the nearest area to the given position, optionally checking only
-- areas matching a given pattern (which is a lua regex). The pattern will
-- be amended to make it case-insensitive.
-- Returns nil if nothing could be found, otherwise the area and the
-- distance to it.
-- maxdist is the maximum distance at which to search.
function areas:findNearestArea(pos, pattern, maxdist)

	local nearest, nearestdist
	if pattern then
		-- Make the pattern case-insensitive...
		pattern = pattern:gsub("(%%?)(.)", function(percent, letter)
			if percent ~= "" or not letter:match("%a") then
				return percent .. letter
			else
				return string.format("[%s%s]", letter:lower(), letter:upper())
			end
		end)
	end
	for id, area in pairs(self.areas) do
		if (not pattern) or string.find(area.name, pattern) then
			local centre = vector.interpolate(area.pos1, area.pos2, 0.5)
			local dist = vector.distance(pos, centre)
			if ((not nearestdist) or dist < nearestdist) and ((not maxdist) or dist <= maxdist) then
				nearest = area
				nearestdist = dist
			end
		end
	end
	return nearest, nearestdist
end

-- Returns a list of areas that include the provided position
function areas:getAreasAtPos(pos)
	local a = {}
	local px, py, pz = pos.x, pos.y, pos.z
	for id, area in pairs(self.areas) do
		local ap1, ap2 = area.pos1, area.pos2
		if px >= ap1.x and px <= ap2.x and
		   py >= ap1.y and py <= ap2.y and
		   pz >= ap1.z and pz <= ap2.z then
			a[id] = area
		end
	end
	return a
end

-- Checks if the area is unprotected or owned by you
function areas:canInteract(pos, name)
	if minetest.check_player_privs(name, {areas=true}) then
		return true
	end
	local owned = false
	for _, area in pairs(self:getAreasAtPos(pos)) do
		if area.owner == name or area.open then
			return true
		else
			owned = true
		end
	end
	return not owned
end

-- Returns a table (list) of all players that own an area
function areas:getNodeOwners(pos)
	local owners = {}
	for _, area in pairs(self:getAreasAtPos(pos)) do
		table.insert(owners, area.owner)
	end
	return owners
end

