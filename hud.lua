-- This is inspired by the landrush mod by Bremaweb
local S = minetest.get_translator("areas")
areas.hud = {}
areas.hud.refresh = 0

minetest.register_globalstep(function(dtime)
	areas.hud.refresh = areas.hud.refresh + dtime
	if areas.hud.refresh > areas.config["tick"] then
		areas.hud.refresh = 0
	else
		return
	end

	for _, player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local pos = vector.round(player:get_pos())
		pos = vector.apply(pos, function(p)
			return math.max(math.min(p, 2147483), -2147483)
		end)
		local areaStrings = {}

		for id, area in pairs(areas:getAreasAtPos(pos)) do
			local faction_info
			if area.faction_open and areas.factions_available then
				-- Gather and clean up disbanded factions
				local changed = false
				for i, fac_name in ipairs(area.faction_open) do
					if not factions.get_owner(fac_name) then
						table.remove(area.faction_open, i)
						changed = true
					end
				end
				if #area.faction_open == 0 then
					-- Prevent DB clutter, remove value
					area.faction_open = nil
				else
					faction_info = table.concat(area.faction_open, ", ")
				end

				if changed then
					areas:save()
				end
			end

			table.insert(areaStrings, ("%s [%u] (%s%s%s)")
					:format(area.name, id, area.owner,
					area.open and S(":open") or "",
					faction_info and ": "..faction_info or ""))
		end

		for i, area in pairs(areas:getExternalHudEntries(pos)) do
			local str = ""
			if area.name then str = area.name .. " " end
			if area.id then str = str.."["..area.id.."] " end
			if area.owner then str = str.."("..area.owner..")" end
			table.insert(areaStrings, str)
		end

		local areaString = S("Areas:")
		if #areaStrings > 0 then
			areaString = areaString.."\n"..
				table.concat(areaStrings, "\n")
		end
		local hud = areas.hud[name]
		if not hud then
			hud = {}
			areas.hud[name] = hud
			hud.areasId = player:hud_add({
				hud_elem_type = "text",
				name = "Areas",
				number = 0xFFFFFF,
				position = {x=0, y=1},
				offset = {x=8, y=-8},
				text = areaString,
				scale = {x=200, y=60},
				alignment = {x=1, y=-1},
			})
			hud.oldAreas = areaString
			return
		elseif hud.oldAreas ~= areaString then
			player:hud_change(hud.areasId, "text", areaString)
			hud.oldAreas = areaString
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	areas.hud[player:get_player_name()] = nil
end)
