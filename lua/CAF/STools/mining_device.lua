TOOL.Category			= "Asteroid Mining"
TOOL.Name				= "#Devices"

TOOL.DeviceName			= "Mining Device"
TOOL.DeviceNamePlural	= "Mining Devices"
TOOL.ClassName			= "mining_device"

TOOL.DevSelect			= true
TOOL.CCVar_type			= "laser_mining"
TOOL.CCVar_sub_type		= "Default Laser"
TOOL.CCVar_model		= "models/props_trainstation/tracklight01.mdl"

TOOL.Limited			= true
TOOL.LimitName			= "mining_device"
TOOL.Limit				= 20

CAFToolSetup.SetLang("Asteroid Mining Devices","Create Storage Devices attached to any surface.","Left-Click: Spawn a Device.  Reload: Repair Device.")


TOOL.ExtraCCVars = {
	mute = 0,
	wired = 0,
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
	panel:CheckBox( "Mute Sound", "mining_device_mute" )
	panel:CheckBox( "Wire Inputs/Outputs", "mining_device_wired" )
	
	combobox = {}
	combobox.Label = "Storage Rarity Type"
	combobox.Description = "Storage Rarity Type"
	combobox.MenuButton = 0
	combobox.Options = {}
	local raritytable = CAF.GetAddon("Asteroid Mining").rarity_levels
	for k,v in pairs(raritytable) do
		combobox.Options[v.name.." minerals"] = {mining_device_rarity = k}
	end
	panel:AddControl("Label", {Text = "Refinery Rarity Type:", Description = "Rarity"})
	panel:AddControl("ComboBox", combobox)
	
	panel:AddControl("Label", {Text = "Tip: Mining lasers will shut off if your rock ore storage is full!", Description = "A Tip"})
	panel:AddControl("Label", {Text = "Tip: Use rock crushers to recycle/destroy rock ore.", Description = "A Tip"})
end

function TOOL:GetExtraCCVars()
	local Extra_Data = {}
	Extra_Data.mute		= self:GetClientNumber("mute") == 1
	Extra_Data.wired 	= self:GetClientNumber("wired") == 1
	Extra_Data.rarity	= self:GetClientNumber("rarity")
	return Extra_Data
end


TOOL.Renamed = {
	class = {
		mining_laser	= "mining_device_laser",
		rock_cursher = "mining_device_crusher",
		ice_processor = "mining_device_icer",
		mining_refinery = "mining_device_refinery"
	},
	type = {
		mining_laser	= "mining_device_laser",
		rock_cursher = "mining_device_crusher",
		ice_processor = "mining_device_icer",
		mining_refinery = "mining_device_refinery"
	},
}

local function mining_device_laser_func(ent,type,sub_type,devinfo,Extra_Data,ent_extras)
	local mass = 50
	ent.mass = mass
	CAF.GetAddon("Asteroid Mining").SetDeviceToolData(ent, Extra_Data,{ "On", "Range" },{"On", "Hit"})
	local maxhealth = 400
	return mass, maxhealth
end

local function mining_device_crusher_func(ent,type,sub_type,devinfo,Extra_Data,ent_extras)
	CAF.GetAddon("Asteroid Mining").SetDeviceToolData(ent, Extra_Data, {"On", "Overdrive", "Mute"}, {"On"})

	local mass = 60
	ent.mass = mass
	local maxhealth = 500
	return mass, maxhealth
end

local function mining_device_icer_func(ent,type,sub_type,devinfo,Extra_Data,ent_extras)
	CAF.GetAddon("Asteroid Mining").SetDeviceToolData(ent, Extra_Data, {"On", "Overdrive", "Mute"}, {"On"})

	local mass = 40
	ent.mass = mass
	local maxhealth = 400
	return mass, maxhealth
end

local function mining_device_refinery_func(ent,type,sub_type,devinfo,Extra_Data,ent_extras)
	local mass = 40
	local AM = CAF.GetAddon("Asteroid Mining")
	--add required resources to the refinery ents resource table
	local reslist = AM.resources
	for k,v in pairs(reslist) do
		if v.rarity == Extra_Data.rarity then
			local raritylevel = AM.rarity_levels[v.rarity]
			RD.AddResource(ent,AM.GetResourceOreName(k), 0)
			ent.reslist[k] = {difficulty = raritylevel.difficulty}
		end
	end
	
	AM.SetDeviceToolData(ent, Extra_Data, {"On", "Overdrive", "Mute"}, {"On"})
	
	local maxhealth = 500
	local phys = ent:GetPhysicsObject()
	if IsValid(phys) then
		maxhealth = phys:GetVolume()/100
		mass = maxhealth/10
	end
	
	ent.mass = mass
	return mass, maxhealth
end

local function mining_device_scanner_func(ent,type,sub_type,devinfo,Extra_Data,ent_extras)
	local AM = CAF.GetAddon("Asteroid Mining")
	
	--configure special wire outputs
	AM.SetDeviceToolSData(ent, Extra_Data, {"On", "Range", "Mute"}, {"On", "Hit", "Yield", "Detected Resources"}, {"NORMAL", "NORMAL", "NORMAL", "ARRAY"})

	local mass = 40
	ent.mass = mass
	local maxhealth = 100
	return mass, maxhealth
end

TOOL.Devices = {
	mining_device_laser = {
		Name	= "Mining Lasers",
		type	= "mining_device_laser",
		class	= "laser_mining",
		func	= mining_device_laser_func,

		devices = {
			small_laser = {
				Name	= "Small Laser",
				model	= "models/Slyfo/warhead.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
			medium_laser = {
				Name	= "Medium Laser",
				model	= "models/Spacebuild/cannon1_gen.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},

			large_laser = {
				Name	= "Large Laser",
				model	= "models/Slyfo/torpedo2.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
			default_laser = {
				Name	= "Default Laser",
				model	= "models/props_trainstation/tracklight01.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
		},
	},
	mining_device_crusher = {
		Name	= "Rock Crushers",
		type	= "mining_device_crusher",
		class	= "rock_crusher",
		func	= mining_device_crusher_func,

		devices = {
			crusher1 = {
				Name	= "SBEP Crusher",
				model	= "models/Cerus/Modbridge/Misc/Accessories/acc_furnace1.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
			crusher2 = {
				Name	= "Default",
				model	= "models/props_industrial/oil_storage.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
		},
	},
	mining_device_icer = {
		Name	= "Ice Processors",
		type	= "mining_device_icer",
		class	= "ice_processor",
		func	= mining_device_icer_func,

		devices = {
			icer1 = {
				Name	= "SBEP Processor",
				model	= "models/ce_ls3additional/water_pump/water_pump.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
			icer2 = {
				Name	= "Default",
				model	= "models/props_c17/FurnitureBoiler001a.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
		},
	},
	mining_device_refinery = {
		Name	= "Ore Refineries",
		type	= "mining_device_refinery",
		class	= "mining_refinery",
		func	= mining_device_refinery_func,

		devices = {
			icer1 = {
				Name	= "SBEP Refinery 1",
				model	= "models/Spacebuild/emount4_fighter.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
			icer2 = {
				Name	= "SBEP Refinery 2",
				model	= "models/Spacebuild/dronefighter_1.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
			icer3 = {
				Name	= "SBEP Refinery 3",
				model	= "models/Cerus/Modbridge/Misc/Engines/eng_sq11b.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
			icer4 = {
				Name	= "Default",
				model	= "models/props_wasteland/laundry_washer003.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
		},
	},
	mining_device_scanner = {
		Name	= "Mineral Scanners",
		type	= "mining_device_scanner",
		class	= "mining_scanner",
		func	= mining_device_scanner_func,

		devices = {
			dev1 = {
				Name	= "Default Scanner",
				model	= "models/props_combine/combine_mine01.mdl",
				skin	= 0,
				legacy	= false, --these two vars must be defined per ent as the old tanks (defined in external file) require different values
			},
		},
	},
}


	
	
	
