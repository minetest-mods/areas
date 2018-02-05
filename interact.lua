
local old_is_protected = minetest.is_protected
function minetest.is_protected(pos, name)
	if not areas:canInteract(pos, name) then
		return true
	end
	return old_is_protected(pos, name)
end

minetest.register_on_protection_violation(function(pos, name)
	local player = minetest.get_player_by_name(name)
	local playerpos = player:getpos()
	if not areas:canInteract(pos, name) then
		local owners = areas:getNodeOwners(pos)
		minetest.chat_send_player(name,
			("%s is protected by %s."):format(
				minetest.pos_to_string(pos),
				table.concat(owners, ", ")))
		minetest.after(1,anti_lag,{player=player,playerpos=playerpos})
		--player:setpos(playerpos)
	end
end)

function anti_lag(player)
	player.player:setpos(player.playerpos)
end