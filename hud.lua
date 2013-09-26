-- This is inspired by the landrush mod by Bremaweb

areas.hud = {}

minetest.register_globalstep(function(dtime)
	for _, player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local pos = vector.round(player:getpos())
		local owners = areas:getNodeOwners(pos)
		local ownerString = table.concat(owners, ", ")
		if not areas.hud[name] then
			areas.hud[name] = {}
			areas.hud[name].ownersId = player:hud_add({
				hud_elem_type = "text",
				name = "AreaOwners",
				number = 0xFFFFFF,
				position = {x=0, y=1},
				offset = {x=5, y=-40},
				direction = 0,
				text = "Area owners: "..ownerString,
				scale = {x=200, y=40},
				alignment = {x=1, y=1},
			})
			areas.hud[name].oldOwners = ownerString
			return
		end
		if areas.hud[name].oldOwners ~= ownerString then
			player:hud_change(areas.hud[name].ownersId, "text",
					"Area owners: "..ownerString)
			areas.hud[name].oldOwners = ownerString
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	areas.hud[player:get_player_name()] = nil
end)

