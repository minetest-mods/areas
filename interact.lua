local S = minetest.get_translator("areas")

local old_is_protected = minetest.is_protected
function minetest.is_protected(pos, name)
	if not areas:canInteract(pos, name) then
		return true
	end
	return old_is_protected(pos, name)
end

minetest.register_on_protection_violation(function(pos, name)
	if areas:canInteract(pos, name) then
		return
	end

	local owners = areas:getNodeOwners(pos)
	if #owners == 0 then
		-- When require_protection=true
		minetest.chat_send_player(name,
			S("@1 may not be accessed.",
				minetest.pos_to_string(pos)))
		return
	end
	minetest.chat_send_player(name,
		S("@1 is protected by @2.",
			minetest.pos_to_string(pos),
			table.concat(owners, ", ")))
end)
