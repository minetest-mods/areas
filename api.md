Areas mod API
===

*NOTE: Undocumented variables, functions and behaviour may change at any time.*

API list
---

 * `areas:registerOnAdd(func(id, area))`
 * `areas:registerOnRemove(func(id))`
 * `areas:registerOnMove(func(id, area, pos1, pos2))`


Protection Conditions
---

* `areas:registerProtectionCondition([name,] func(pos1, pos2, name))`
   * Registers a rule to control whether to allow or prohibit the creation of an area.
   * `name` (optional, string): Unique name of the condition. Should follow the
     `modname:callbackname` convention.
   * If a condition already exist under the same `name`, it is overwritten.
   * Callback arguments:
      * `pos1` (min), `pos2` (max): vector. Edge positions of the area.
      * `name` (string): Player name.
   * Callback return value(s):
      * `true`: Forcefully allows the area creation. This overwrites the outcome of any
        previously executed conditions, including the default ones registered by this mod.
      * `false, errMsg`: Disable the creation of the area and return an error message.
      * `nil` (or no return value): Enable the creation of the area,
        unless specified otherwise by the other registered callbacks.
* `areas:getProtectionCondition(name)`
   * `name` (string): Unique name of the condition.
   * Return values:
      1. (function) Callback function.
      2. (string) Originating mod name. May be `"??"` if the mod could not be determined.
   * Returns `nil, nil` if `name` could not be found.


HUD
---

* `areas:registerHudHandler(handler)`
   * Registers a handler to add items to the Areas HUD.

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
