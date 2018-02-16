# API Extension

Adding your protections to the HUD
----------------------------------

If you are providing an extra protection mod to work in conjunction with the
HUD feature of `areas`, you can register a callback to add your mod's code to
display your protection's existence.

Registering a handler:

* `areas.registerHudHandler(handler) --> nil`

Handler specification:

* `handler(pos,area_list) --> new_area_list`
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
=======
Areas mod API
===

API list
---

 * `areas.registerHudHandler(handler)` - Registers a handler to add items to the Areas HUD.  See [HUD](#hud).


HUD
---

If you are making a protection mod or a similar mod that adds invisible regions
to the world, and you would like then to show up in the areas HUD element, you
can register a callback to show your areas.

HUD handler specification:

 * `handler(pos, list)`
   * `pos` - The position to check.
   * `list` - The list of area HUD elements, this should be modified in-place.

The area list item is a table containing a list of tables with the following fields:

 * `id` - An identifier for the area. This should be a unique string in the format `mod:id`.
 * `name` - The name of the area.
 * `owner` - The player name of the region owner, if any.

All of the fields are optional but at least one of them must be set.

### Example

	local function areas_hud_handler(pos, areas)
		local val = find_my_protection(pos)

		if val then
			table.insert(areas, {
				id = "mod:"..val.id,
				name = val.name,
				owner = val.owner,
			})
		end
	end

	areas:registerHudHandler(areas_hud_handler)
