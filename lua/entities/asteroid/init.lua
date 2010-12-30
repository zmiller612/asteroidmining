AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

local function physgunPickup( userid, Ent )  	
	if Ent:GetClass() == "asteroid" then  		
		return false
	end  
end     
hook.Add( "PhysgunPickup", "AM_epicsauce_asteroid_pickup", physgunPickup )

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_VPHYSICS )
	if self:GetModel() == nil then self:Remove() ErrorNoHalt("Model for asteroid was not set.") end
	
	self.resources = {}
	self.asteroid = true
	self.totalResources = 0
	self.lastrescheck = 0 --how many resources were there last time the asteroid checked?
	self.maxcap = 0
	self.lifetime = 0
end

function ENT:AddResource(res)
	table.insert(self.resources,res)
end

function ENT:TriggerInput(iname, value)

end

function ENT:Damage()
	if (self.damaged == 0) then
		self.damaged = 1
		
	end
end


function ENT:OnTakeDamage(dmg)

end

function ENT:OnRemove()
	self:Remove()
end

function ENT:Think()
	if self.totalResources < 1 then
		CAF.GetAddon("Asteroid Mining").RemoveAsteroid(self)
	elseif CurTime() > self.lifetime then
		--check if it was mined in its current life. If so, extend its life.
		--Otherwise, remove it. Obviously nobody cared for the poor thing anyway. :(
		if self.totalResources != self.lastrescheck then
			self.lifetime = CurTime() + (server_settings.Int("AM_respawn_maxlife")*60)
			self.lastrescheck = self.totalResources --update for next check
		else
			CAF.GetAddon("Asteroid Mining").RemoveAsteroid(self)
		end
	end
	
	self.Entity:NextThink( CurTime() + 10)
	return true
end

function ENT:CanTool()
	return false
end

function ENT:GravGunPunt()
	return false
end

function ENT:GravGunPickupAllowed()
	return false
end
