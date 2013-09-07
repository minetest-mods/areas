
-- Gives a player a warning message about a area being protected
local function printWarning(pos, name)
	local owners = areas:getNodeOwners(pos)
	minetest.chat_send_player(name, ("%s is protected by %s.")
			:format(minetest.pos_to_string(pos), table.concat(owners, ", ")))
end

if minetest.is_protected then
	old_is_protected = minetest.is_protected
	function minetest.is_protected(pos, name)
		if not areas:canInteract(pos, name) then
			return true
		end
		return old_is_protected(pos, name)
	end

	minetest.register_on_protection_violation(function(pos, name)
		if not areas:canInteract(pos, name) then
			printWarning(pos, name)
		end
	end)

else
	local old_node_place = minetest.item_place_node
	function minetest.item_place_node(itemstack, placer, pointed_thing)
		local pos = pointed_thing.above
		local under_node = minetest.get_node(pointed_thing.under)
		local under_def = minetest.registered_nodes[under_node.name]

		if under_def and under_def.buildable_to then
			pos = pointed_thing.under
		end

		if not areas:canInteract(pos, placer:get_player_name()) then
			printWarning(pos, placer:get_player_name())
			return itemstack -- Abort place.
		end
		return old_node_place(itemstack, placer, pointed_thing)
	end

	local old_node_dig = minetest.node_dig
	function minetest.node_dig(pos, node, digger)
		if not areas:canInteract(pos, digger:get_player_name()) then
			printWarning(pos, digger:get_player_name())
			return -- Abort dig.
		end
		return old_node_dig(pos, node, digger)
	end
end

