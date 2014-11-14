local worldpath = minetest.get_worldpath()

local function setting_getbool_default(setting, default)
	local value = minetest.setting_getbool(setting)
	if value == nil then
		value = default
	end
	return value
end

areas.filename =
	minetest.setting_get("areas.filename") or worldpath.."/areas.dat"

-- Allow players with a privilege create their own areas
-- within the maximum size and number
areas.self_protection =
	setting_getbool_default("areas.self_protection", false)
areas.self_protection_privilege =
	minetest.setting_get("areas.self_protection_privilege") or "interact"
areas.self_protection_max_size =
	minetest.setting_get_pos("areas.self_protection_max_size") or
			{x=64, y=128, z=64}
areas.self_protection_max_size_high =
	minetest.setting_get_pos("areas.self_protection_max_size_high") or
			{x=512, y=512, z=512}
areas.self_protection_max_areas =
	tonumber(minetest.setting_get("areas.self_protection_max_areas")) or 4
areas.self_protection_max_areas_high =
	tonumber(minetest.setting_get("areas.self_protection_max_areas_high")) or 32

-- Register compatability functions for node_ownership.
-- legacy_table (owner_defs) compatibility is untested
-- and can not be used if security_safe_mod_api is on.
areas.legacy_table =
	setting_getbool_default("areas.legacy_table", false)

-- Prevent players from punching nodes in a protected area.
-- Usefull for things like delayers, usualy annoying and
-- prevents usage of things like buttons.
areas.protect_punches =
	setting_getbool_default("areas.protect_punches", false)

