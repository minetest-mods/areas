-- This is inspired by the landrush mod by Bremaweb

areas.hud = {}
local xOffset = 8
local yOffset = -16
-- Approximate the text height
local textHeight = (tonumber(minetest.setting_get("font_size")) or 13) * 1.16

minetest.register_globalstep(function(dtime)
	for _, player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local pos = vector.round(player:getpos())
		local areaStrings = {}
		for id, area in pairs(areas:getAreasAtPos(pos)) do
			table.insert(areaStrings, ("%s [%u] (%s%s)")
					:format(area.name, id, area.owner,
					area.open and ":open" or ""))
		end
		local areaString = table.concat(areaStrings, "\n")
		local hud = areas.hud[name]
		if not hud then
			hud = {}
			areas.hud[name] = hud
			hud.areasId = player:hud_add({
				hud_elem_type = "text",
				name = "Areas",
				number = 0xFFFFFF,
				position = {x=0, y=1},
				offset = {x=xOffset, y=yOffset - ((#areaStrings + 1) * textHeight)},
				direction = 0,
				text = "Areas:\n"..areaString,
				scale = {x=200, y=60},
				alignment = {x=1, y=1},
			})
			hud.oldAreas = areaString
			return
		elseif hud.oldAreas ~= areaString then
			player:hud_change(hud.areasId, "offset",
				{x=xOffset, y=yOffset - ((#areaStrings + 1) * textHeight)})
			player:hud_change(hud.areasId, "text",
					"Areas:\n"..areaString)
			hud.oldAreas = areaString
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	areas.hud[player:get_player_name()] = nil
end)

