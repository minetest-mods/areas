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
	table = { fields = { "copy", "getn", "indexof" } }
}

globals = {
	"minetest",
	-- mod namespace
	"areas"
}

files["legacy.lua"] = {
	ignore = {"512"}
}
