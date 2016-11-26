# API Extension

Adding your protections to the HUD
----------------------------------

If you are providing an extra protection mod to work in cunjunction with the
HUD feature of `areas`, you can register a callback to add your mod's code to
display your protection's existence. For example

	local myhandler = function(pos,arealist)
		local areaowner = find_my_protections(pos)

		if areaowner then
			arealist["mymodname"] = {
				name = "Protection name",
				owner = areaowner, 
			}
		end
	end

	areas.register_hud_handler(myhandler)
