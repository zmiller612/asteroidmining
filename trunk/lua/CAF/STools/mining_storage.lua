TOOL.Category			= "Asteroid Mining"
TOOL.Name				= "#Storages"

TOOL.DeviceName			= "Storage Device"
TOOL.DeviceNamePlural	= "Storage Devices"
TOOL.ClassName			= "mining_storage"

TOOL.DevSelect			= true
TOOL.CCVar_type			= "mining_storage_rock"
TOOL.CCVar_sub_type		= "Small Chamber"
TOOL.CCVar_model		= "models/props_wasteland/laundry_basket001.mdl"

TOOL.Limited			= true
TOOL.LimitName			= "mining_storage"
TOOL.Limit				= 20

CAFToolSetup.SetLang("Asteroid Mining Storages","Create Storages attached to any surface.","Left-Click: Spawn a Storage.  Reload: Repair Storage.")


TOOL.ExtraCCVars = {
	wireamount = 0,
	wirecapacity = 0,
	rarity = 1,
}

function TOOL.EnableFunc()
	local SB = CAF.GetAddon("Spacebuild")
	local RD = CAF.GetAddon("Resource Distribution")
	if not SB or not SB.GetStatus() or not RD or not RD.GetStatus() then
		return false;
	end
	return true;
end

function TOOL.ExtraCCVarsCP( tool, panel )
	panel:CheckBox( "Amount Outputs", "mining_storage_wireamount")
	panel:CheckBox( "Capacity Outputs", "mining_storage_wirecapacity" )
	
	combobox = {}
	combobox.Label = "Storage Rarity Type"
	combobox.Description = "Storage Rarity Type"
	combobox.MenuButton = 0
	combobox.Options = {}
	local raritytable = CAF.GetAddon("Asteroid Mining").rarity_levels
	for k,v in pairs(raritytable) do
		combobox.Options[v.name.." minerals"] = {mining_storage_rarity = k}
	end
	panel:AddControl("Label", {Text = "Storage Rarity Type:", Description = "Rarity"})
	panel:AddControl("ComboBox", combobox)
end

function TOOL:GetExtraCCVars()
	local Extra_Data = {}
	Extra_Data.wireamount		= self:GetClientNumber("wireamount") == 1
	Extra_Data.wirecapacity		= self:GetClientNumber("wirecapacity") == 1
	Extra_Data.rarity			= self:GetClientNumber("rarity")
	return Extra_Data
end


TOOL.Renamed = {
	class = {
		rock_storage	= "mining_storage_rock",
		ore_storage		= "mining_storage_ore",
		refined_storage	= "mining_storage_refined"
	},
	type = {
		rock_storage	= "mining_storage_rock",
		ore_storage		= "mining_storage_ore",
		refined_storage	= "mining_storage_refined"
	},
}

local volumeMul = 1.3

local function mining_storage_rock_func(ent,type,sub_type,devinfo,Extra_Data,ent_extras)
	local phys = ent:GetPhysicsObject()
	local maxcap = 100
	local rockpercent = 20 --how much of the maxcap can hold rock
	if phys:IsValid() and phys.GetVolume then
		maxcap = math.floor((phys:GetVolume()*volumeMul))
	end
	
	--add refined version of asteroid resources to storage
	local RD = CAF.GetAddon("Resource Distribution")
	local AM = CAF.GetAddon("Asteroid Mining")
	
	RD.AddResource(ent,"Rock "..AM.language.ore, math.floor((maxcap/100)*rockpercent))
	CAF.GetAddon("Asteroid Mining").SetStorageToolData(ent,Extra_Data, {"Rock "..AM.language.ore}, {"Rock "..AM.language.ore.." Capacity"})
	
	table.insert(ent.reslist,"rock "..AM.language.ore)
	
	local mass = maxcap/1000
	ent.mass = mass
	local maxhealth = math.Round(maxcap/100)
	return mass, maxhealth
end

local function mining_storage_ore_func(ent,type,sub_type,devinfo,Extra_Data,ent_extras)
	local phys = ent:GetPhysicsObject()
	local maxcap = 100
	if phys:IsValid() and phys.GetVolume then
		maxcap = math.floor((phys:GetVolume()*volumeMul))
	end
	
	--add refined version of asteroid resources to storage
	local AM = CAF.GetAddon("Asteroid Mining")
	local RD = CAF.GetAddon("Resource Distribution")
	local reslist = AM.resources
	local outamounts = {} --wire outputs for resource amounts
	local outcaps = {} --wire outputs for resource capacities
	for k,v in pairs(reslist) do
		if v.rarity == Extra_Data.rarity then
			local raritylevel = AM.rarity_levels[v.rarity]
			RD.AddResource(ent,AM.GetResourceOreName(k), math.floor((maxcap/100)*raritylevel.minPercent))
			table.insert(outamounts,AM.GetResourceOreName(k))
			table.insert(outcaps,AM.GetResourceOreName(k).." Capacity")
			table.insert(ent.reslist,AM.GetResourceOreName(k))
		end
	end
	
	CAF.GetAddon("Asteroid Mining").SetStorageToolData(ent,Extra_Data, outamounts, outcaps)

	local mass = maxcap/1000
	ent.mass = mass
	local maxhealth = math.Round(maxcap/10)
	return mass, maxhealth
end

local function mining_storage_refined_func(ent,type,sub_type,devinfo,Extra_Data,ent_extras)
	local phys = ent:GetPhysicsObject()
	local maxcap = 100
	if phys:IsValid() and phys.GetVolume then
		maxcap = math.floor((phys:GetVolume()*volumeMul))
	end
	
	--add refined version of asteroid resources to storage
	local AM = CAF.GetAddon("Asteroid Mining")
	local RD = CAF.GetAddon("Resource Distribution")
	local reslist = AM.resources
	local outamounts = {} --wire outputs for resource amounts
	local outcaps = {} --wire outputs for resource capacities
	for k,v in pairs(reslist) do
		if v.rarity == Extra_Data.rarity then
			local raritylevel = AM.rarity_levels[v.rarity]
			RD.AddResource(ent,AM.GetResourceRefinedName(k), math.floor((maxcap/100)*(raritylevel.maxPercent-raritylevel.minPercent)))
			table.insert(outamounts,AM.GetResourceRefinedName(k))
			table.insert(outcaps,AM.GetResourceRefinedName(k).." Capacity")
			table.insert(ent.reslist,AM.GetResourceRefinedName(k))
		end
	end
	
	CAF.GetAddon("Asteroid Mining").SetStorageToolData(ent,Extra_Data, outamounts, outcaps)

	local mass = maxcap/1000
	ent.mass = mass
	local maxhealth = math.Round(maxcap/10)
	return mass, maxhealth
end

TOOL.Devices = {
	mining_storage_rock = {
		Name	= "Rock Storages",
		type	= "mining_storage_rock",
		class	= "mining_storage",
		func	= mining_storage_rock_func,

		devices = {
			small_store = {
				Name	= "Small Chamber",
				model	= "models/props_wasteland/laundry_basket001.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
			small_store2 = {
				Name	= "Slyfo Barrel",
				model	= "models/Slyfo/barrel_orange.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
			large_store = {
				Name	= "Large Chamber",
				model	= "models/props_wasteland/laundry_washer001a.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
		},
	},
	mining_storage_ore = {
		Name	= "Ore Storages",
		type	= "mining_storage_ore",
		class	= "mining_storage",
		func	= mining_storage_ore_func,
		devices = {
			small_store = {
				--EnableFunc = function() return false end,
				Name	= "Small Tank",
				model	= "models/Slyfo/t-eng.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
			small_store2 = {
				--EnableFunc = function() return false end,
				Name	= "Slyfo Barrel",
				model	= "models/Slyfo/barrel_unrefined.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
			medium_store = {
				--EnableFunc = function() return false end,
				Name	= "Medium Tank (left)",
				model	= "models/Slyfo/nacshortsleft.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
			medium_store2 = {
				--EnableFunc = function() return false end,
				Name	= "Medium Tank (right)",
				model	= "models/Slyfo/nacshortsright.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
			large_store = {
				--EnableFunc = function() return false end,
				Name	= "Large Tank (Left)",
				model	= "models/Slyfo/nacshuttleleft.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
			large_store2 = {
				--EnableFunc = function() return false end,
				Name	= "Large Tank (right)",
				model	= "models/Slyfo/nacshuttleright.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
		},
	},
	mining_storage_refined = {
		Name	= "Refined Mineral Storages",
		type	= "mining_storage_refined",
		class	= "mining_storage",
		func	= mining_storage_refined_func,
		devices = {
			small_store = {
				--EnableFunc = function() return false end,
				Name	= "Small Tank",
				model	= "models/ce_ls3additional/energy_cells/energy_cell_small.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
			small_store2 = {
				--EnableFunc = function() return false end,
				Name	= "Slyfo Barrel",
				model	= "models/Slyfo/barrel_refined.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
			medium_store = {
				--EnableFunc = function() return false end,
				Name	= "Medium Tank",
				model	= "models/ce_ls3additional/energy_cells/energy_cell_medium.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
			large_store = {
				--EnableFunc = function() return false end,
				Name	= "Large Tank",
				model	= "models/ce_ls3additional/energy_cells/energy_cell_large.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
		},
	},
}


	
	
	
