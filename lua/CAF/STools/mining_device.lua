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
TOOL.Limit				= 15

CAFToolSetup.SetLang("Asteroid Mining Devices","Create Storage Devices attached to any surface.","Left-Click: Spawn a Device.  Reload: Repair Device.")


TOOL.ExtraCCVars = {
	mute = 0,
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
	
	panel:AddControl("Label", {Text = "Tip: Mining lasers will shut off if your rock ore storage is full!", Description = "A Tip"})
	panel:AddControl("Label", {Text = "Tip: Use rock crushers to recycle/destroy rock ore.", Description = "A Tip"})
end

function TOOL:GetExtraCCVars()
	local Extra_Data = {}
	Extra_Data.mute		= self:GetClientNumber("mute") == 1
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
	--set mining rate and consumption
	local sub = tostring(sub_type)
	if sub == "small_laser" or sub == "default_laser" then
		ent.minerate = 40
		ent.econ = 300
	elseif sub == "medium_laser" then
		ent.minerate = 70
		ent.econ = 520
	elseif sub == "large_laser" then
		ent.minerate = 100
		ent.econ = 740
	else
		ent.minerate = 40
		ent.econ = 310
	end
	
	CAF.GetAddon("Asteroid Mining").SetDeviceToolData(ent, Extra_Data,{ "On", "Range" },{"On", "Hit"})
	local mass = 50
	ent.mass = mass
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
	local rarity = 1
	if type == "mining_device_ref_abundant" then
		rarity = 1
	elseif type == "mining_device_ref_common" then
		rarity = 2
	elseif type == "mining_device_ref_uncommon" then
		rarity = 3
	elseif type == "mining_device_ref_rare" then
		rarity = 4
	elseif type == "mining_device_ref_vrare" then
		rarity = 5
	elseif type == "mining_device_ref_precious" then
		rarity = 6
	end
	
	--add required resources to the refinery ents resource table
	local reslist = AM.resources
	for k,v in pairs(reslist) do
		if v.rarity == rarity then
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

local function mining_device_nukereactor_func(ent,type,sub_type,devinfo,Extra_Data,ent_extras)
	CAF.GetAddon("Asteroid Mining").SetDeviceToolData(ent, Extra_Data, {"On", "Overdrive", "Mute"}, {"On"})

	local mass = 70
	ent.mass = mass
	local maxhealth = 1200
	return mass, maxhealth
end

local function mining_device_dispenserhp_func(ent,type,sub_type,devinfo,Extra_Data,ent_extras)
	CAF.GetAddon("Asteroid Mining").SetDeviceToolSData(ent, Extra_Data, nil, {"Last User", "Charges", "Max Charges"}, {"ENTITY", "NORMAL", "NORMAL"})

	local sub = tostring(sub_type)
	if sub == "small_hpdispenser" then
		ent.maxcharges = 5
		ent.econ = 165
		ent.ircon = 51
		ent.ocon = 51
	elseif sub == "large_hpdispenser" then
		ent.maxcharges = 10
		ent.econ = 320
		ent.ircon = 100
		ent.ocon = 100
	else --if someone uses hax, give them a crap dispenser :P
		ent.maxcharges = 1
		ent.econ = 500
		ent.ircon = 200
		ent.ocon = 200
	end
	
	--send max charges now, then it never needs sending again
	ent:SetNWInt("mining_disp_maxcharges",ent.maxcharges)
	if WireLib then 
		WireLib.TriggerOutput(ent,"Max Charges", ent.maxcharges)
	end
	
	local mass = 30
	ent.mass = mass
	local maxhealth = 400
	return mass, maxhealth
end

local function mining_device_dispenserarm_func(ent,type,sub_type,devinfo,Extra_Data,ent_extras)
	CAF.GetAddon("Asteroid Mining").SetDeviceToolSData(ent, Extra_Data, nil, {"Last User", "Charges", "Max Charges"}, {"ENTITY", "NORMAL", "NORMAL"})

	local sub = tostring(sub_type)
	if sub == "armdispenser" then
		ent.maxcharges = 15
		ent.econ = 450
		ent.ircon = 70
		ent.ocon = 70
	else --if someone uses hax, give them a crap dispenser :P
		ent.maxcharges = 1
		ent.econ = 500
		ent.ircon = 200
		ent.ocon = 200
	end
	
	--send max charges now, then it never needs sending again
	ent:SetNWInt("mining_disparm_maxcharges",ent.maxcharges)
	if WireLib then 
		WireLib.TriggerOutput(ent,"Max Charges", ent.maxcharges)
	end
	
	local mass = 30
	ent.mass = mass
	local maxhealth = 400
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
				model	= "models/syncaidius/mining_laser.mdl",
				skin	= 0,
				legacy	= false,
			},
			medium_laser = {
				Name	= "Medium Laser",
				model	= "models/syncaidius/mining_laser_m.mdl",
				skin	= 0,
				legacy	= false,
			},

			large_laser = {
				Name	= "Large Laser",
				model	= "models/syncaidius/mining_laser_l.mdl",
				skin	= 0,
				legacy	= false,
			},
			default_laser = {
				Name	= "Default Laser",
				model	= "models/props_trainstation/tracklight01.mdl",
				skin	= 0,
				legacy	= false,
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
				legacy	= false,
			},
			crusher2 = {
				Name	= "Default",
				model	= "models/props_industrial/oil_storage.mdl",
				skin	= 0,
				legacy	= false,
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
				legacy	= false,
			},
			icer2 = {
				Name	= "Default",
				model	= "models/props_c17/FurnitureBoiler001a.mdl",
				skin	= 0,
				legacy	= false,
			},
		},
	},
	mining_device_ref_abundant = {
		Name	= "Refinery - Abundant Minerals",
		type	= "mining_device_ref_abundant",
		class	= "mining_refinery",
		func	= mining_device_refinery_func,

		devices = {
			icer1 = {
				Name	= "Refinery",
				model	= "models/syncaidius/mining_refinery.mdl",
				skin	= 0,
				legacy	= false,
			},
		},
	},
	mining_device_ref_common = {
		Name	= "Refinery - Common Minerals",
		type	= "mining_device_ref_common",
		class	= "mining_refinery",
		func	= mining_device_refinery_func,

		devices = {
			icer1 = {
				Name	= "Refinery",
				model	= "models/syncaidius/mining_refinery.mdl",
				skin	= 1,
				legacy	= false,
			},
		},
	},
	mining_device_ref_uncommon = {
		Name	= "Refinery - Uncommon Minerals",
		type	= "mining_device_ref_uncommon",
		class	= "mining_refinery",
		func	= mining_device_refinery_func,

		devices = {
			icer1 = {
				Name	= "Refinery",
				model	= "models/syncaidius/mining_refinery.mdl",
				skin	= 2,
				legacy	= false,
			},
		},
	},
	mining_device_ref_rare = {
		Name	= "Refinery - Rare Minerals",
		type	= "mining_device_ref_rare",
		class	= "mining_refinery",
		func	= mining_device_refinery_func,

		devices = {
			icer1 = {
				Name	= "Refinery",
				model	= "models/syncaidius/mining_refinery.mdl",
				skin	= 3,
				legacy	= false,
			},
		},
	},
	mining_device_ref_vrare = {
		Name	= "Refinery - Very Rare Minerals",
		type	= "mining_device_ref_vrare",
		class	= "mining_refinery",
		func	= mining_device_refinery_func,

		devices = {
			icer1 = {
				Name	= "Refinery",
				model	= "models/syncaidius/mining_refinery.mdl",
				skin	= 4,
				legacy	= false,
			},
		},
	},
	mining_device_ref_precious = {
		Name	= "Refinery - Precious Minerals",
		type	= "mining_device_ref_precious",
		class	= "mining_refinery",
		func	= mining_device_refinery_func,

		devices = {
			icer1 = {
				Name	= "Refinery",
				model	= "models/syncaidius/mining_refinery.mdl",
				skin	= 5,
				legacy	= false,
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
				legacy	= false,
			},
			dev2 = {
				Name	= "Default Scanner 2",
				model	= "MoSs: models/jaanus/wiretool/wiretool_beamcaster.mdl",
				skin	= 0,
				legacy	= false,
			},
		},
	},
	mining_device_nukereactor = {
		Name	= "Nuclear Reactors",
		type	= "mining_device_nukereactor",
		class	= "uranium_reactor",
		func	= mining_device_nukereactor_func,

		devices = {
			dev1 = {
				Name	= "Small Reactor",
				model	= "models/syncaidius/uranium_reactor.mdl",
				skin	= 0,
				legacy	= false,
			},
		},
	},
	mining_device_dispenserhp = {
		Name	= "Health Dispenser",
		type	= "mining_device_dispenserhp",
		class	= "dispenser_health",
		func	= mining_device_dispenserhp_func,

		devices = {
			small_hpdispenser = {
				Name	= "Small Dispenser",
				model	= "models/Items/HealthKit.mdl",
				skin	= 0,
				legacy	= false,
			},
			large_hpdispenser = {
				Name	= "Large Dispenser",
				model	= "models/props_combine/health_charger001.mdl",
				skin	= 0,
				legacy	= false,
			},
		},
	},
	mining_device_dispenserarm = {
		Name	= "Armor Dispenser",
		type	= "mining_device_dispenserarm",
		class	= "dispenser_armor",
		func	= mining_device_dispenserarm_func,

		devices = {
			armdispenser = {
				Name	= "Large Dispenser",
				model	= "models/props_combine/suit_charger001.mdl",
				skin	= 0,
				legacy	= false,
			},
		},
	},
}


	
	
	
