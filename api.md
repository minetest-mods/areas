# API Extension

Adding your protections to the HUD
----------------------------------

If you are providing an extra protection mod to work in cunjunction with the
HUD feature of `areas`, you can register a callback to add your mod's code to
display your protection's existence.

Registering a handler:

* `areas.register_hud_handler(handler_name) --> nil`

Handler specification:

* `handler_name(pos,area_list) --> new_area_list`
	* `pos` - the position at which to check for protection coverage by your mod
	* `area_list` - the current list of protected areas
	* `new_area_list` - the list of protected areas, updated with your entries

Area list items:

The area list item is a map table identified with an ID, and properties

The ID should be in the format `modname:` and appended with an identifier for the protection.

Each area list item should be a table with the following properties

* `owner` - (required) the name of the protection owner
* `name` - (optional) the name of the area

Example
-------

	local myhandler = function(pos,area_list)
		local areaowner = find_my_protections(pos)

		if areaowner then
			arealist["mymodname:first"] = {
				name = "Protection name",
				owner = areaowner, 
			}
		end
	end

	areas.register_hud_handler(myhandler)
