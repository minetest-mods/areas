-- Areas mod by ShadowNinja
-- Based on node_ownership
-- License: LGPLv2+

areas = {}

-- Load support for intllib.
local MP = minetest.get_modpath(minetest.get_current_modname())
local S, NS = dofile(MP.."/intllib.lua")
areas.intllib = S

areas.adminPrivs = {areas=true}
areas.startTime = os.clock()

areas.modpath = minetest.get_modpath("areas")
dofile(areas.modpath.."/settings.lua")
dofile(areas.modpath.."/api.lua")
dofile(areas.modpath.."/internal.lua")
dofile(areas.modpath.."/chatcommands.lua")
dofile(areas.modpath.."/pos.lua")
dofile(areas.modpath.."/interact.lua")
dofile(areas.modpath.."/legacy.lua")
dofile(areas.modpath.."/hud.lua")

areas:load()

minetest.register_privilege("areas", {
	description = S("Can administer areas.")
})
minetest.register_privilege("areas_high_limit", {
	description = S("Can can more, bigger areas.")
})

if not minetest.registered_privileges[areas.config.self_protection_privilege] then
	minetest.register_privilege(areas.config.self_protection_privilege, {
		description = S("Can protect areas."),
	})
end

if minetest.settings:get_bool("log_mod") then
	local diffTime = os.clock() - areas.startTime
	minetest.log("action", S("[MOD]areas loaded in @1s.", diffTime))
end

