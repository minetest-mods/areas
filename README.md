Areas mod for Minetest 0.4.8+
=============================

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Configuration
-------------
If you wish to specify configuration options, such as whether players are
allowed to protect their own areas with /protect (Disabled by default), you
should check config.lua and set the appropriate settings in your minetest.conf.


Tutorial
--------
To protect an area you must first set the corner positions of the area.
In order to set the corner positions you run:
1. "/area\_pos set" punch the two border nodes.
2. "/area\_pos set1/2" punch only the first or second border node.
3. "/area\_pos1/2" set position one or two to your current position.
4. "/area\_pos1/2 X Y Z" set position one or two to the specified coordinates.

Once you have set the border positions you can protect the area by running:
1. "/set\_owner &lt;OwnerName&gt; &lt;AreaName&gt;"
	-- If you are a administrator or moderator with the "areas" privilege.
2. "/protect &lt;AreaName&gt;"
	-- If the server administraor has enabled area self-protection.

The area name is used so that you can easily find the area that you want when
using a command like /list\_areas. It is not used for any other purpose.
For example: /set\_owner SomePlayer Diamond city

Now that you own an area you may want to add sub-owners to it. You can do this
with the /add\_owner command. Anyone with an area can use the add\_owner
command on their areas. Before using the add\_owner command you have to select
the corners of the sub-area as you did for set\_owner. If your markers are
still around your original area and you want to grant access to your entire
area you will not have to re-set them. You can also use select\_area to place
the markers at the corners of an existing area.
The add\_owner command expects three arguments:
1. The id of the parent area. (The area that you want it to be a sub-area of)
2. The name of the player that will own the sub-area.
3. The name of the sub-area.

For example: /add\_owner 123 BobTheBuilder Diamond lighthouse

Chat commands
-------------
 * /protect &lt;AreaName&gt;
	Protects an area for yourself. (If self-protection is enabled)

 * /set\_owner &lt;OwnerName&gt; &lt;AreaName&gt;
	Protects an area. (Requires the "areas" privilege)

 * /add\_owner &lt;ParentID&gt; &lt;OwnerName&gt; &lt;ChildName&gt;
	Grants another player control over part (or all) of an area.

 * /rename\_area &lt;ID&gt; &lt;NewName&gt;
	Renames an existing area, useful after converting from node_ownership
	when all areas are unnamed.

 * /list\_areas
	Lists all of the areas that you own.
	(Or all of them if you have the "areas" privilege)

 * /find\_areas &lt;Regex&gt;
	Finds areas using a Lua regular expresion.
	For example:
	/find_areas [Cc]astle To find castles.

 * /remove\_area &lt;ID&gt;
	Removes an area that you own. Any sub-areas of that area are made sub-areas
	of the removed area's parent, if it exists. Otherwise they will have no
	parent.

 * /recursive\_remove\_areas &lt;ID&gt;
	Removes an area and all sub-areas of it.

 * /change\_owner &lt;ID&gt; &lt;NewOwner&gt;
	Change the owner of an area.

 * /select\_area &lt;ID&gt;
	Sets the area positions to those of an existing area.

 * /area\_pos {set,set1,set2,get}
	Sets the area positions by punching nodes or shows the current area positions.

 * /area\_pos1 \[X,Y,Z|X Y Z\]
	Sets area position one to your position or the one supplied.

 * /area\_pos2 \[X,Y,Z|X Y Z\]
	Sets area position two to your position or the one supplied.

License
-------
Copyright (C) 2013 ShadowNinja

Licensed under the GNU LGPL version 2.1 or higher.
See LICENSE.txt and http://www.gnu.org/licenses/lgpl-2.1.txt

