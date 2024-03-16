Areas mod API
===

API list
---

 * `areas:registerHudHandler(handler)` - Registers a handler to add items to the Areas HUD.  See [HUD](#hud).
 * `areas:registerProtectionCondition(func(pos1, pos2, name))` - 
See [Protection Conditions](#Protection-Conditions)
 * `areas:registerOnAdd(func(id, area))`
 * `areas:registerOnRemove(func(id))`
 * `areas:registerOnMove(func(id, area, pos1, pos2))`


Protection Conditions
---

With `areas:registerProtectionCondition(func(pos1, pos2, name))`
you can register rules to control whether to allow or prohibit the creation of an area.

Return values:
* `true` Forcefully allows the area creation. This overwrites the outcome of any
  previously executed conditions, including the default ones registered by this mod.
* `false, errMsg` Disable the creation of the area and return an error message.
* `nil` (or no return value) Enable the creation of the area,
  unless specified otherwise by the other registered callbacks.


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
