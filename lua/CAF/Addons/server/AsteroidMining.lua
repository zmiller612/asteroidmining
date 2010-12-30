--[[ Serverside Custom Addon file Base ]]--
local AM = {}

--server-side console variables
CreateConVar( "AM_asteroidlimit", "70" )
CreateConVar( "AM_respawn_time", "10" )
CreateConVar( "AM_respawn_count", "5" )
CreateConVar( "AM_respawn_maxlife", "10" )

AM.asteroids = {} --stores all asteroids entities
AM.roid_models = {}
AM.roid_models[1] = "models/syncaidius/asteroid_01.mdl"
AM.roid_models[2] = "models/syncaidius/asteroid_01.mdl"
AM.roid_models[3] = "models/syncaidius/asteroid_03.mdl"
AM.roid_models[4] = "models/props_wasteland/rockgranite02a.mdl"
AM.roid_models[5] = "models/props_wasteland/rockgranite03b.mdl"
AM.roid_models[6] = "models/props_wasteland/rockgranite04a.mdl"
AM.roid_models[7] = "models/props_foliage/rock_coast02h.mdl"
AM.roid_models[8] = "models/props_wasteland/rockcliff07e.mdl"
AM.roid_models[9] = "models/props_wasteland/rockcliff07b.mdl"
AM.roid_models[10] = "models/props_wasteland/rockcliff06i.mdl"
AM.roid_models[11] = "models/props_wasteland/rockcliff06d.mdl"
AM.roid_models[12] = "models/props_wasteland/rockcliff01f.mdl"
AM.roid_models[13] = "models/props_wasteland/rockgranite04b.mdl"
AM.roid_models[14] = "models/props_wasteland/rockcliff01J.mdl"
AM.roid_models[15] = "models/props_wasteland/rockcliff01b.mdl"

--rarity table which contains mining difficulty/rarity values
AM.rarity_levels = {}
AM.rarity_levels[1] = {name="abundant", difficulty=1, minPercent=30, maxPercent=55}
AM.rarity_levels[2] = {name="common", difficulty=2, minPercent=15, maxPercent=25}
AM.rarity_levels[3] = {name="uncommon", difficulty=4, minPercent=10, maxPercent=20}
AM.rarity_levels[4] = {name="rare", difficulty=6, minPercent=8, maxPercent=16}
AM.rarity_levels[5] = {name="very rare", difficulty=8, minPercent=6, maxPercent=10}
AM.rarity_levels[6] = {name="precious", difficulty=10, minPercent=1, maxPercent=7}


AM.respawn = {}
AM.respawn.count = 5 --how many asteroids to respawn each wave
AM.respawn.lastCount = 0 --how many asteroids were spawned on the last count
AM.respawn.minRarity = 0
AM.respawn.maxRarity = 10000
AM.respawn.minDist = 500 --min distance from a planet asteroids can spawn
AM.respawn.maxDist = 1000 --max distance from a planet asteroids can spawn

--[[asteroids containing resources with a difficulty greater than this value will
spawn near a sun, if the map has one. Otherwise they will spawn as normal, around planets]]
AM.respawn.sundifficulty = 8 

AM.resources = {}

AM.asteroidCount = 0
AM.spawns = {}
AM.stars = {} --stars could be used for spawning the really difficult resources (risk of frying your ship etc).
AM.ready = false

AM.language = {}
AM.language.refined = "Refined"
AM.language.ore = "ore"

--Helper function for asteroid mining-based device CAF STools
function AM.SetDeviceToolData(ent, Extra_Data, wireinputs, wireoutputs)
	--set mute on/off
	if Extra_Data.mute == true then ent.mute = 1 else ent.mute = 0 end
	--apply wire inputs/outputs to entity
	if Extra_Data.wired == true then 
		ent.wired = 1
		if WireLib then
			ent.WireDebugName = ent.PrintName
			ent.Inputs = WireLib.CreateInputs(ent, wireinputs)
			ent.Outputs = WireLib.CreateOutputs(ent, wireoutputs) 
		end
	else 
		ent.wired = 0
	end
end

--Same as above, except handles special wire outputs
function AM.SetDeviceToolSData(ent, Extra_Data, wireinputs, wireoutputs, wireouttypes)
	--set mute on/off
	if Extra_Data.mute == true then ent.mute = 1 else ent.mute = 0 end
	--apply wire inputs/outputs to entity
	if Extra_Data.wired == true then 
		ent.wired = 1
		if WireLib then
			ent.WireDebugName = ent.PrintName
			ent.Inputs = WireLib.CreateInputs(ent, wireinputs)
			WireLib.CreateSpecialOutputs(ent, wireoutputs, wireouttypes)
		end
	else 
		ent.wired = 0
	end
end

--Helper function for asteroid mining-based storage CAF STools
function AM.SetStorageToolData(ent, Extra_Data, wireout, wireoutcaps)
	local outputs = {}
	if Extra_Data.wireamount == true then 
		if WireLib then
			ent.wireamount = 1
			ent.WireDebugName = ent.PrintName
			table.Add(outputs,wireout)
		else
			ent.wireamount = 0
		end
	else 
		ent.wireamount = 0
	end
	
	--apply wire inputs to entity
	if Extra_Data.wirecapacity == true then 
		ent.wirecapacity = 1
		if WireLib then
			ent.wirecapacity = 1
			ent.WireDebugName = ent.PrintName
			table.Add(outputs,wireoutcaps)
		else
			ent.wirecapacity = 0
		end
	else 
		ent.wirecapacity = 0
	end
	
	--apply wire outputs to storage ent
	if ent.wireamount == 1 or ent.wirecapacity == 1 then
		ent.Outputs = WireLib.CreateOutputs(ent, outputs) 
	end
end

local function PhysgunPickup(ply , ent)
	local notallowed =  { "asteroid"}
	if table.HasValue(notallowed, ent:GetClass()) then
		return false
	end
end
hook.Add("PhysgunPickup", "AM_Block_Mah_Physgun", PhysgunPickup) 

--[[adds a custom resource to the asteroid res table.
any resources in this table have a chance of appearing in asteroids.
difficulty affects how fast a resource can be mined and whether or not
it will spawn around any stars if the map has any.
Rarity = rarity class the resource is part of (e.g. 1 - 5)
rMin and rMax = the rarity range (sort of like a chance of spawning range)]]
function AM.AddAsteroidResource(res, Rarity, rMin, rMax)
	if not AM.rarity_levels[Rarity] then Rarity = 3 end --set rarity to default if this happens
	AM.resources[res] = {rarity=Rarity, rarityMin=rMin, rarityMax=rMax, difficulty=AM.rarity_levels[Rarity]}
end

--adds a new model to the table of possible asteroid models
function AM.AddAsteroidModel(model)
	table.insert(AM.roid_models, model)
end

--Removes an asteroid entity.
function AM.RemoveAsteroid(ent)
	if ent.asteroid then
		table.remove(AM.asteroids,ent:EntIndex())
		ent:Remove()
		
		AM.asteroidCount = AM.asteroidCount - 1
	end
end

--[[adds a custom asteroid spawn. The radius determines the min distance
asteroids are allowed to spawn from the spawn position.
Im sure someone will find a use for this :P]]
function AM.AddCustomSpawn(position, sRadius)
	table.insert(AM.spawns, {pos=position,radius=sRadius})
end

--returns given resource name with ore keyword appended to it
function AM.GetResourceOreName(res)
	return res.." "..AM.language.ore
end

--returns given resource name with refined keyword inserted at the start
function AM.GetResourceRefinedName(res)
	return AM.language.refined.." "..res
end

--runs an asteroid spawn cycle. Improvements needed.
function AM.SpawnAsteroids()
	if CAF.GetAddon("Spacebuild") and AM.enabled == true then
		--how many asteroids can be spawned in this cycle
		local allowed = server_settings.Int("AM_asteroidlimit") - AM.asteroidCount
		local rCount = server_settings.Int("AM_respawn_count")
		if allowed >  rCount then allowed = rCount end
		
		--randomize random seeder (because we can :P)
		math.randomseed(os.time())
		
		--spawn asteroids
		if allowed > 0 then
			local spawned = 0
			
			for i=1,allowed do
				local model = AM.roid_models[math.random(table.Count(AM.roid_models))]
				local planet = AM.spawns[math.random(table.Count(AM.spawns))]
				local spawnX = ((1-(math.random(0,1))*2)) * (math.random(AM.respawn.minDist,AM.respawn.maxDist) + planet.radius)
				local spawnY = ((1-(math.random(0,1))*2)) * (math.random(AM.respawn.minDist,AM.respawn.maxDist) + planet.radius)
				local spawnZ = ((1-(math.random(0,1))*2)) * (math.random(AM.respawn.minDist,AM.respawn.maxDist) + planet.radius)
				
				--clamp pos values 300 units inside max map area
				--source max map size is -16384 to 16384 XYZ
				spawnX = math.Clamp(planet.pos.x+spawnX,-16084, 16084) 
				spawnY = math.Clamp(planet.pos.y+spawnY,-16084, 16084)
				spawnZ = math.Clamp(planet.pos.z+spawnZ,-16084, 16084)
				local pos = Vector(spawnX,spawnY,spawnZ)
				
				--spawn asteroid entity
				local aent = ents.Create("asteroid")
				aent:SetModel(model)
				aent:SetPos(pos)
				aent:SetAngles(Angle(math.random(0,360),math.random(0,360),math.random(0,360)))
				aent:Spawn()
				aent.asteroid = true
				aent.lifetime = CurTime() + (server_settings.Int("AM_respawn_maxlife")*60)
				local phys = aent:GetPhysicsObject( )
				
				--setup resources for asteroid
				local rarityindex = math.random(AM.respawn.minRarity,AM.respawn.maxRarity)
				local maxcap = phys:GetVolume()/100 --max resources the asteroid can hold 
				local curcap = maxcap
				
				aent.maxcap = maxcap
				for k,v in pairs(AM.resources) do
					if rarityindex >= v.rarityMin and rarityindex <= v.rarityMax then
						local rarityLevel = AM.rarity_levels[v.rarity]
						local percent = math.random(rarityLevel.minPercent,rarityLevel.maxPercent)
						local a = (maxcap/100) * percent --resource amount
						local diff = rarityLevel.difficulty --mining difficulty level
						if a <= curcap then
							curcap = curcap - a --subtract from remaining capacity
							aent.resources[k] = {amount=a, rock=false, difficulty=diff}
							aent.totalResources = aent.totalResources + a
						elseif curcap > 0 then
							aent.resources[k] = {amount=curcap, rock=false, difficulty=diff}
							aent.totalResources = aent.totalResources + curcap
							curcap = 0
						else
							break --break from loop, no point continuing if asteroid is full
						end
					end
				end
				
				--if the asteroid has capacity left, fill it with rock :D
				if curcap > 0 then
					aent.resources["Rock"] = {amount=curcap, rock=true, difficulty=1}
				end
				
				--if the asteroid has no resources, dont bother adding it
				--this might happen if none of the resource rarity ranges were hit
				if aent.totalResources > 0 then
					aent.lastrescheck = aent.totalResources
					
					--add new asteroid to asteroid table
					AM.asteroids[aent:EntIndex()] = aent
					spawned = spawned + 1
				else
					aent:Remove()
				end
			end
			
			--update asteroid count
			AM.asteroidCount = AM.asteroidCount + spawned
			Msg("ASTEROID MINING: "..tostring(spawned).." asteroids spawned. Total: "..tostring(AM.asteroidCount).."/"..tostring(server_settings.Int("AM_asteroidlimit")).."\n")
		end
	end
end
hook.Add("InitPostEntity","AsteroidMining_SpawnRoids",timer.Simple(1,AM.SpawnAsteroids))

local NextThinkTime = 0
function AM.Think()
    if CurTime() >= NextThinkTime then
        NextThinkTime = CurTime() + server_settings.Int("AM_respawn_time")
		
		
		AM.SpawnAsteroids()
    end
end
hook.Add("Think", "AsteroidMining_ThinkyStuff", AM.Think)


function AM.__Construct()
	if status then return false, "Already Active!" end
	if not CAF.GetAddon("Resource Distribution") or not CAF.GetAddon("Resource Distribution").GetStatus() then return false, "Resource Distribution is Required and needs to be Active!" end
	
	--locate all planets and stars on the map to use as spawn points
	--should of checked if SB had a way to retrieve its own planet list really, before coding this.
	local spawns = ents.FindByClass("logic_case")
	for k,ent in ipairs(spawns) do
		local values = ent:GetKeyValues()
		for key,value in pairs(values) do
			if key == "Case01" then
				if value == "planet" || value == "planet2" then
					for key2,value2 in pairs(values) do
						if key2 == "Case02" then
							table.insert(AM.spawns, {pos=ent:GetPos(),radius=value2})
						end
					end
				elseif value == "star" || value == "star2" then
					for key2,value2 in pairs(values) do
						if key2 == "Case02" then
							table.insert(AM.stars, {pos=ent:GetPos(),radius=value2})
						end
					end
				end
			end
		end
	end
	
	--make sure the map actually has some planets/stars to use before enabling
	if table.Count(AM.spawns) > 0 or table.Count(AM.stars) > 0 then
		--setup standard asteroid resources ready for use
		AM.AddAsteroidResource("Ice",1,2000,5000)
		AM.AddAsteroidResource("Uranium",3,5001,6000)
		AM.AddAsteroidResource("Iron",2,5500,8000)
		AM.AddAsteroidResource("Titanium",3,5501, 6000)
		AM.AddAsteroidResource("Iridium",6,6500,7000)
		AM.AddAsteroidResource("Gold",6,0,200)
		AM.AddAsteroidResource("Silver",6,150,300)
		AM.AddAsteroidResource("Chromite",5,220,390)
		AM.AddAsteroidResource("Lithium",4,391,600)
		AM.AddAsteroidResource("Aluminium",3,601,1100)
		AM.AddAsteroidResource("Plutonium",5,5800,6000)
		AM.AddAsteroidResource("Mercury",6,1100,1500)
		AM.AddAsteroidResource("Copper",3,7900,8500)
	
		AM.enabled = true
	end
	
	return true
end

function AM.__Destruct()
	--TODO: remove asteroids on disable/destruct.
	--TODO: set AM.ready to false and return true
	return false
end

function AM.GetRequiredAddons()
	return {"Resource Distribution"}
end


function AM.GetStatus()
	return status
end


function AM.GetVersion()
	return 1.00, "Alpha"
end

/**
	Get any custom options this Custom Addon Class might have
*/
function AM.GetExtraOptions()
	return {}
end

/**
	Get the Custom String Status from this Addon Class
*/
function AM.GetCustomStatus()
	return "Not Implemented Yet"
end

/**
	You can send all the files from here that you want to add to send to the client
*/
function AM.AddResourcesToSend()
	
end

--[[ Asteroid destruction call, called when an asteroid is destroyed from being hit or over mined.]]
function AM.Destruct( class,id,pos,type,reason,volumename )
	
end

CAF.RegisterAddon("Asteroid Mining", AM, "3") 

