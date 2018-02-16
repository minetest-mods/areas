-- This is inspired by the landrush mod by Bremaweb
local S = areas.intllib

areas.hud = {}

local function tick()
	for _, player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local pos = vector.round(player:getpos())
		local area_text = S("No area(s)").."\n\n"
		local area_owner_name = ""
		local mod_owner = 0
		local mod_open = 0
		local mod_farming = 0
		local area_name = ""
		local nb_areas = 0

		for id, area in pairs(areas:getAreasAtPos(pos)) do
			nb_areas = nb_areas+1
			if areas:isAreaOwner(id, name) then
				mod_owner = 1
			end

			if area.open then
				mod_open = 1
			end
			if area.openfarming then
				mod_farming = 1
			end

			if not area.parent then
				area_owner_name = area.owner
				area_name = area.name
			end
		end

		for i, area in pairs(areas:getExternalHudEntries(pos)) do
			local str = ""
			if area.name then str = area.name .. " " end
			if area.id then str = str.."["..area.id.."] " end
			if area.owner then str = str.."("..area.owner..")" end
			table.insert(areaStrings, str)
		end

		local icon = "areas_not_area.png"
		if nb_areas > 0 then
			local plural = ""
			if nb_areas > 1 then
				plural = "s"
			end
			-- Translators: need to use NS gettext to be more precise
			area_text = (S("%s\nOwner: %s\n%u area") .. plural):format(area_name, area_owner_name, nb_areas)
			icon = ("areas_%u_%u_%u.png"):format(mod_owner, mod_open, mod_farming)
		end
		if not areas.hud[name] then
			areas.hud[name] = {}
			areas.hud[name].icon = player:hud_add({
				hud_elem_type = "image",
				position = {x=0,y=1},
				scale = {x=1,y=1},
				offset = {x=26,y=-60},
				text = icon,
			})

			areas.hud[name].areas_id = player:hud_add({
				hud_elem_type = "text",
				name = "Areas",
				number = 0xFFFFFF,
				position = {x=0, y=1},
				offset = {x=48, y=-40},
				text = area_text,
				scale = {x=1, y=1},
				alignment = {x=1, y=-1},
			})
			areas.hud[name].old_area_text = area_text
			areas.hud[name].old_icon = icon
		else
			if areas.hud[name].old_area_text ~= area_text then
				player:hud_change(areas.hud[name].areas_id, "text", area_text)
				areas.hud[name].old_area_text = area_text
			end
			if areas.hud[name].old_icon ~= icon then
				player:hud_change(areas.hud[name].icon, "text", icon)
				areas.hud[name].old_icon = icon
			end
		end
	end
	minetest.after(1.5, tick)
end

tick()

minetest.register_on_leaveplayer(function(player)
	areas.hud[player:get_player_name()] = nil
end)

