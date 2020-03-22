local world_path = minetest.get_worldpath()

areas.config = {}

local function setting(name, tp, default)
	local full_name = "areas." .. name
	local value
	if tp == "bool" then
		value = minetest.settings:get_bool(full_name)
		default = value == nil and minetest.is_yes(default)
	elseif tp == "string" then
		value = minetest.settings:get(full_name)
	elseif tp == "v3f" then
		value = minetest.setting_get_pos(full_name)
		default = value == nil and minetest.string_to_pos(default)
	elseif tp == "float" or tp == "int" then
		value = tonumber(minetest.settings:get(full_name))
		local v, other = default:match("^(%S+) (.+)")
		default = value == nil and tonumber(other and v or default)
	else
		error("Cannot parse setting type " .. tp)
	end

	if value == nil then
		value = default
		assert(default ~= nil, "Cannot parse default for " .. full_name)
	end
	--print("add", name, default, value)
	areas.config[name] = value
end

local file = io.open(areas.modpath .. "/settingtypes.txt", "r")
for line in file:lines() do
	local name, tp, value = line:match("^areas%.(%S+) %(.*%) (%S+) (.*)")
	if value then
		setting(name, tp, value)
	end
end
file:close()

--------------
-- Settings --
--------------

setting("filename", "string", world_path.."/areas.dat")
