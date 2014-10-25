Areas mod for Minetest 0.4.8+
=============================


Configuration
-------------

If you wish to specify configuration options, such as whether players are
allowed to protect their own areas with the `protect` command (disabled by
default), you should check config.lua and set the appropriate settings in your
server's configuration file (probably `minetest.conf`).


Tutorial
--------

To protect an area you must first set the corner positions of the area.
In order to set the corner positions you can run:
  * `/area_pos set` and punch the two corner nodes to set them.
  * `/area_pos set1/set2` and punch only the first or second corner node to
	set them one at a time.
  * `/area_pos1/2` to set one of the positions to your current position.
  * `/area_pos1/2 X Y Z` to set one of the positions to the specified
	coordinates.

Once you have set the border positions you can protect the area by running one
of the following commands:
  * `/set_owner <OwnerName> <AreaName>` -- If you have the `areas` privilege.
  * `/protect <AreaName>` -- If you have the `areas` privilege or the server
	administrator has enabled area self-protection.

The area name is used only for informational purposes (so that you know what
an area is for).  It is not used for any other purpose.
For example: `/set_owner SomePlayer Mese city`

Now that you own an area you may want to add sub-owners to it. You can do this
with the `add_owner` command.  Anyone with an area can use the `add_owner`
command on their areas.  Before using the `add_owner` command you have to
select the corners of the sub-area as you did for `set_owner`. If your markers
are still around your original area and you want to grant access to your
entire area you will not have to re-set them. You can also use `select_area` to
place the markers at the corners of an existing area if you've reset your
markers and want to grant access to a full area.
The `add_owner` command expects three arguments:
  1. The ID number of the parent area (the area that you want to add a
	sub-area to).
  2. The name of the player that will own the sub-area.
  3. The name of the sub-area. (can contain spaces)

For example: `/add_owner 123 BobTheBuilder Diamond lighthouse`


Commands
--------

  * `/protect <AreaName>` -- Protects an area for yourself. (if
	self-protection is enabled)

  * `/set_owner <OwnerName> <AreaName>` -- Protects an area for a specified
	player. (requires the `areas` privilege)

  * `/add_owner <ParentID> <OwnerName> <ChildName>` -- Grants another player
	control over part (or all) of an area.

  * `/rename_area <ID> <NewName>` -- Renames an existing area.

  * `/list_areas` -- Lists all of the areas that you own, or all areas if you
	have the `areas` privilege.

  * `/find_areas <Regex>` -- Finds areas using a Lua regular expresion.
	For example, to find castles:

		/find_areas [Cc]astle

  * `/remove_area <ID>` -- Removes an area that you own. Any sub-areas of that
	area are made sub-areas of the removed area's parent, if it exists.
	If the removed area has no parent it's sub-areas will have no parent.

  * `/recursive_remove_areas <ID>` -- Removes an area and all sub-areas of it.

  * `/change_owner <ID> <NewOwner>` -- Change the owner of an area.

  * `/select_area <ID>` -- Sets the area positions to those of an existing
	area.

  * `/area_pos {set,set1,set2,get}` -- Sets the area positions by punching
	nodes or shows the current area positions.

  * `/area_pos1 [X,Y,Z|X Y Z]` -- Sets area position one to your position or
	the one supplied.

  * `/area_pos2 [X,Y,Z|X Y Z]` -- Sets area position two to your position or
	the one supplied.

License
-------

Copyright (C) 2013 ShadowNinja

Licensed under the GNU LGPL version 2.1 or later.
See LICENSE.txt and http://www.gnu.org/licenses/lgpl-2.1.txt

