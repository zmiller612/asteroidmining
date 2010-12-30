local AM = {}

--rarity table which contains mining difficulty values
AM.rarity_levels = {}
AM.rarity_levels[1] = {name="abundant", difficulty=1}
AM.rarity_levels[2] = {name="common", difficulty=2}
AM.rarity_levels[3] = {name="uncommon", difficulty=4}
AM.rarity_levels[4] = {name="rare", difficulty=6}
AM.rarity_levels[5] = {name="very rare", difficulty=8}
AM.rarity_levels[6] = {name="precious", difficulty=10}

local status = false

--The Class
/**
	The Constructor for this Custom Addon Class
*/
function AM.__Construct()
	status = true
	return true , "Not Implementation yet"
end

/**
	The Destructor for this Custom Addon Class
*/
function AM.__Destruct()
	return false , "Can't disable"
end

/**
	Get the required Addons for this Addon Class
*/
function AM.GetRequiredAddons()
	return {"Resource Distribution"}
end

/**
	Get the Boolean Status from this Addon Class
*/
function AM.GetStatus()
	return status
end

/**
	Get the Version of this Custom Addon Class
*/
function AM.GetVersion()
	return 1.0, "Release"
end

/**
	Get any custom options this Custom Addon Class might have
*/
function AM.GetExtraOptions()
	return {}
end

/**
	Gets a menu from this Custom Addon Class
*/
function AM.GetMenu(menutype, menuname)//Name is nil for main menu, String for others
	local data = {}
	return data
end

/**
	Get the Custom String Status from this Addon Class
*/
function AM.GetCustomStatus()
	return "Implemented"
end

CAF.RegisterAddon("Asteroid Mining", AM, "2")


