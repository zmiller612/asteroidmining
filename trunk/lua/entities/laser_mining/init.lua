AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

local BeamLength = 512 --default beam length
local Maxlength = 1024

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	
	self.Active = 0
	self.Minelevel = Minelevel
	self.beamlength = BeamLength
	
	self:SetMaxHealth(500)
	self:SetHealth(self:GetMaxHealth())
	
	RD.AddResource(self,"energy",0)
	self.econ = 310 --base energy consumption
	self.energy = 0
	self.minerate = 0
	self.loopsound = CreateSound(self, Sound("weapons/gauss/chargeloop.wav"))
	
	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(40)
	end
end

function ENT:TriggerInput(iname, value)
	if iname == "On" then
		if value > 0 then
			self:TurnOn()
		else
			self:TurnOff()
		end
	elseif iname == "Range" then
		self.beamlength = value
		if self.beamlength > Maxlength then
			self.beamlength = Maxlength
		end
	end
end

function ENT:Damage()
	if (self.damaged == 0) then
		self.damaged = 1
	end
	if ((self.Active == 1) and self:Health() <= 100) then
		self:TurnOff()
	end
end

function ENT:Repair()
	self.Entity:SetColor(255, 255, 255, 255)
	self:SetHealth(self:GetMaxHealth())
	self.damaged = 0
end

function ENT:Destruct()
	CAF.GetAddon("Life Support").Destruct( self.Entity )
end

function ENT:OnRemove()
	self.BaseClass.OnRemove(self)
	self.Entity:StopSound( "weapons/gauss/chargeloop.wav" )
end

function ENT:TurnOn()
	if(self.Active == 0) then
		self.Active = 1
		self:SetOOO(1)
		self.loopsound:Play()
		
		if WireLib then
			WireLib.TriggerOutput(self, "On", self.Active)
		end
	end
end

function ENT:TurnOff()
	if (self.Active == 1) then
		self.loopsound:Stop()
		self.Entity:EmitSound( "weapons/physgun_off.wav" )
		self.Active = 0
		self:SetOOO(0)
		if WireLib then 
			WireLib.TriggerOutput(self, "On", self.Active) 
		end
	end
end

function ENT:OnOff()
	if self.Active == 1 then
		self:TurnOff()
	else
		self:TurnOn()
	end
end

function ENT:TakeFromAsteroid(aent, res, amount)
	local taken = 0
	
	if aent.resources[res].amount < amount then
		taken = aent.resources[res].amount
		aent.resources[res].amount = 0
	else
		taken = amount
		aent.resources[res].amount = aent.resources[res].amount - amount
	end
	
	--if the resource isn't rock, subract it from the amount remaining, otherwise
	--dont count it, since rock is just a filler resource
	if aent.resources[res].rock == false then
		aent.totalResources = aent.totalResources - taken
	end
	
	local AM = CAF.GetAddon("Asteroid Mining")
	self:SupplyResource(AM.GetResourceOreName(res),taken)
	
	return taken
end

--check if rock storages are full
function ENT:RockFull()
	local AM = CAF.GetAddon("Asteroid Mining")
	local rock = AM.GetResourceOreName("Rock")
	if self:GetResourceAmount(rock) >= self:GetNetworkCapacity(rock) then
		return true
	end
	
	return false
end

function ENT:Mine()
	local ent = self.Entity
	--calculate consumption
	self.energy = math.ceil(self.econ * (self.beamlength/BeamLength) )+math.random(1,10)

	if (self:GetResourceAmount("energy") >= self.energy) then
		self:ConsumeResource("energy", self.energy)
		
		--work out beam position and hit pos
		local Pos = ent:GetPos()
		local Ang = ent:GetAngles()
		local trace = {}
		trace.start = Pos
		trace.endpos = Pos+(Ang:Forward()*self.beamlength)
		trace.filter = { ent }
		local tr = util.TraceLine( trace )

		if tr.Entity.asteroid then
			for k,v in pairs(tr.Entity.resources) do
				self:TakeFromAsteroid(tr.Entity, k, (self.minerate/v.difficulty)+math.random(1,3))
			end
			
			--check if the asteroid has any resources left
			if tr.Entity.totalResources < 1 then 
				CAF.GetAddon("Asteroid Mining").RemoveAsteroid(tr.Entity)
			end
			
			if WireLib then
				WireLib.TriggerOutput(self, "Hit", 1)
			end
		elseif tr.Entity:IsPlayer() then
			tr.Entity:TakeDamage(10, self:GetOwner(), self)
			
			if WireLib  then
				WireLib.TriggerOutput(self, "Hit", 0)
			end
		else
			--TODO: damage system stuff here
			
			if WireLib then
				WireLib.TriggerOutput(self, "Hit", 0)
			end
		end
		
		--set beam effect data
		local effectdata = EffectData()
		effectdata:SetEntity( ent )
		effectdata:SetOrigin( Pos )
		effectdata:SetStart( tr.HitPos )
		effectdata:SetAngle( Ang )
		util.Effect( "mining_beam", effectdata, true, true )
	else
		self:TurnOff()
	end
end

function ENT:Think()
	self.BaseClass.Think(self)
	if ( self.Active == 1 ) then
		--if rock storage full, turn off
		if self:RockFull() == false then
			self:Mine()
		else
			self:TurnOff()
		end
	end
	self.Entity:NextThink( CurTime() + 1 )
	return true
end

function ENT:AcceptInput(name,activator,caller)
	if name == "Use" and caller:IsPlayer() and caller:KeyDownLast(IN_USE) == false then
		self:OnOff()
	end
end

function ENT:PreEntityCopy()
  self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )
  self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities )
end
