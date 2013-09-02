
-- Gives a player a warning message about a area being protected
local function printWarning(name, pos)
	local owners = areas:getNodeOwners(pos)
	minetest.chat_send_player(name, ("%s is protected by %s.")
			:format(minetest.pos_to_string(pos), table.concat(owners, ", ")))
end

if minetest.can_interact then
	old_can_interact = minetest.can_interact
	function minetest.can_interact(pos, name)
		if not areas:canInteract(pos, name) then
			printWarning(name, pos)
			return false
		end
		return old_can_interact(pos, name)
	end
else
	local old_node_place = minetest.item_place_node
	function minetest.item_place_node(itemstack, placer, pointed_thing)
		-- XXX: buildable_to nodes can mess this up
		local pos = pointed_thing.above
		if not areas:canInteract(pos, placer:get_player_name()) then
			printWarning(placer:get_player_name(), pos)
			return itemstack -- Abort place.
		end
		return old_node_place(itemstack, placer, pointed_thing)
	end

	local old_node_dig = minetest.node_dig
	function minetest.node_dig(pos, node, digger)
		if not areas:canInteract(pos, digger:get_player_name()) then
			printWarning(digger:get_player_name(), pos)
			return -- Abort dig.
		end
		return old_node_dig(pos, node, digger)
	end
end

