
-- Checks if the area is unprotected or owned by you
function areas:canInteract(pos, name)
	if minetest.check_player_privs(name, {areas=true}) then
		return true
	end
	local owned = false
	for _, area in pairs(self.areas) do
		p1, p2 = area.pos1, area.pos2
		if pos.x >= p1.x and pos.x <= p2.x and
		   pos.y >= p1.y and pos.y <= p2.y and
		   pos.z >= p1.z and pos.z <= p2.z then
			if area.owner == name then
				return true
			else
				owned = true
			end
		end
	end
	return not owned
end

-- Returns a table (list) of all players that own an area
function areas:getNodeOwners(pos)
	local owners = {}
	for _, area in pairs(self.areas) do
		if pos.x >= area.pos1.x and pos.x <= area.pos2.x and
		   pos.y >= area.pos1.y and pos.y <= area.pos2.y and
		   pos.z >= area.pos1.z and pos.z <= area.pos2.z then
			table.insert(owners, area.owner)
		end
	end
	return owners
end

