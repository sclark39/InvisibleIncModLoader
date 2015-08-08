local util = include( "modules/util" )
local quest_templates =
{
	-----------------------------------------------------
	-- Quest item templates

	quest_material = 
	{
		type = "simunit",
		name = "Mysterious Material",
		tooltip = "<ttheader>A block of mysterious material.\n</><ttbody></>",
		icon = "itemrigs/FloorProp_AmmoClip.png",
		profile_icon = "gui/items/item_quest.png",
		traits = {  },
		abilities = { "carryable" },	
		value = 400,	
	},

	empty_disk = 
	{
		type = "simunit",
		name = "Empty Disk",
		tooltip = "<ttheader>EMPTY DISK\n</><ttbody>Reduces hacking training cost by 10%.\nDefinitely enough space to transport an Artifical.</>",
		icon = "itemrigs/FloorProp_AmmoClip.png",
		profile_icon = "gui/items/item_quest.png",
		traits = { hackingCostReduction = 0.1 },
		abilities = { "carryable" },	
	},

	mother_disk = 
	{
		type = "simunit",
		name = "Mother Disk",
		tooltip = "<ttheader>MOTHER DISK\n</><ttbody>Reduces hacking training cost by 10%.\n+1 PWR on any computer hacked.\nContains a powerful Artifical who calls itself Mother.</>",
		icon = "itemrigs/FloorProp_AmmoClip.png",
		profile_icon = "gui/items/item_quest.png",
		traits = { hackingCostReduction = 0.1, hackingBonus = 1 },
		abilities = { "carryable" },	
	},
}

return quest_templates