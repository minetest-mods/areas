unused_args = false

read_globals = {
	"DIR_DELIM",
	"core",
	"dump",
	"vector", "nodeupdate",
	"VoxelManip", "VoxelArea",
	"PseudoRandom", "ItemStack",
	"AreaStore",
	"default",
	"factions",
	table = { fields = { "copy", "getn" } }
}

globals = {
	"minetest",
	-- mod namespace
	"areas",
	-- legacy
	"IsPlayerNodeOwner",
	"GetNodeOwnerName",
	"HasOwner",
	"owner_defs"
}

files["legacy.lua"] = {
	ignore = {"512"}
}
