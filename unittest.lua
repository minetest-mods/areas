
areas:registerProtectionCondition(function(pos1, pos2, name)
	return false, "no name"
end)

local function named_condition(pos1, pos2, name)
	return false, "with name"
end
areas:registerProtectionCondition("foo:bar", named_condition)

do
	-- Getter
	local cb, mod_name = areas:getProtectionCondition("foo:bar")
	assert(cb == named_condition)
	assert(mod_name == "areas")
end

do
	local old_count = #areas.registered_protection_conditions
	-- Overwrite
	local function new_condition(pos1, pos2, name)
		return true, "overwritten"
	end
	areas:registerProtectionCondition("foo:bar", new_condition)
	local cb, _ = areas:getProtectionCondition("foo:bar")
	assert(cb == new_condition)

	assert(old_count == #areas.registered_protection_conditions)
end

error("Unittest passed! Please disable them now.")
