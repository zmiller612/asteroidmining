local AM = {}

--rarity table which contains mining difficulty values
AM.rarity_levels = {}
AM.rarity_levels[1] = {name="Abundant", difficulty=1}
AM.rarity_levels[2] = {name="Common", difficulty=2}
AM.rarity_levels[3] = {name="Uncommon", difficulty=4}
AM.rarity_levels[4] = {name="Rare", difficulty=6}
AM.rarity_levels[5] = {name="Very rare", difficulty=8}
AM.rarity_levels[6] = {name="Precious", difficulty=10}

AM.language = {}
AM.language.refined = "Refined"
AM.language.ore = "Ore"

local status = false

--returns given resource name with ore keyword appended to it
function AM.GetResourceOreName(res)
	return res.." "..AM.language.ore
end

--returns given resource name with refined keyword inserted at the start
function AM.GetResourceRefinedName(res)
	return AM.language.refined.." "..res
end

--The Class
function AM.__Construct()
	status = true
	return true , "Not Implementation yet"
end

function AM.__Destruct()
	return false , "Can't disable"
end

function AM.GetRequiredAddons()
	return {"Resource Distribution"}
end

function AM.GetStatus()
	return status
end

function AM.GetVersion()
	return 1.0, "Release"
end

function AM.GetExtraOptions()
	return {}
end

function AM.GetMenu(menutype, menuname)//Name is nil for main menu, String for others
	local data = {}
	return data
end

function AM.GetCustomStatus()
	return "Implemented"
end

CAF.RegisterAddon("Asteroid Mining", AM, "3")


