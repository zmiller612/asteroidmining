AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
util.PrecacheSound( "apc_engine_start" )
util.PrecacheSound( "apc_engine_stop" )

include('shared.lua')

function ENT:Initialize()
	self.BaseClass.Initialize(self)
    
	self.damaged = 0
	self.overdrive = 0
	self.overdrivefactor = 0
	
	-- maximum overdrive value allowed via wire input. Anything over this value may severely damage or destroy the device.
	self.maxoverdrive = 4 
	
	self.Active = 0
	self.maxhealth = 250
	self.health = self.maxhealth
	
	self.energy = 0
	self.ice = 0
	self.mute = 0
	self.wired = 1
	self.multiply = 1
	
    -- resource attributes
	self.icecon = 140 --rock ore consumption
	self.econ = 120 -- Energy consumption
    
	local RD = CAF.GetAddon("Resource Distribution")
	RD.AddResource(self,"energy",0)
	RD.AddResource(self,CAF.GetAddon("Asteroid Mining").GetResourceRefinedName("Ice"),0)
	
	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(80)
	end
end

function ENT:TriggerInput(iname, value)
	if (iname == "On") then
		if (value > 0) then
			if ( self.Active == 0 ) then
				self:TurnOn()
				if (self.overdrive == 1) then
					self:OverdriveOn()
				end
			end
		else
			if ( self.Active == 1 ) then
                self:TurnOff()
				if self.overdrive>0 then
					self:OverdriveOff()
				end
			end
		end
	elseif (iname == "Overdrive") then
		if (self.Active == 1) then
			if (value > 0) then
				self:OverdriveOn()
				self.overdrivefactor = value
			else
				self:OverdriveOff()
			end
		end
	elseif (iname == "Mute") then
		if (value > 0) then
			self.mute = 1
		else
			self.mute = 0
		end
	end
end

function ENT:OnRemove()
	self.BaseClass.OnRemove(self)
	self.Entity:StopSound( "apc_engine_stop" )
	self.Entity:StopSound( "apc_engine_start" )
end

function ENT:Damage()
	if (self.damaged == 0) then
		self.damaged = 1
	end
	if ((self.Active == 1) and self:Health() <= 20) then
		self:TurnOff()
	end
end

function ENT:Repair()
	self.health = self.maxhealth
	self.damaged = 0
end

function ENT:TurnOn()
	if self.Active == 0 then
		self.Active = 1
		self:SetOOO(1)
		
		if WireLib and self.wired == 1 then
			WireLib.TriggerOutput(self, "On", 1)
		end
		
		if(self.mute == 0) then
			self.Entity:EmitSound( "apc_engine_start" )
		end
	end
end

function ENT:TurnOff()
	if self.Active == 1 then
		self.Active = 0
		self.overdrive = 0
		self:SetOOO(0)
		
		if WireLib and self.wired == 1 then
			WireLib.TriggerOutput(self, "On", 0)
		end
		
		self.Entity:StopSound( "apc_engine_start" )
		if(self.mute == 0) then
			self.Entity:EmitSound( "apc_engine_stop" )
		end
	end
end

function ENT:OverdriveOn()
    self.overdrive = 1
    self:SetOOO(2)
    
    self.Entity:StopSound( "apc_engine_start" )
    if(self.mute == 0) then
		self.Entity:EmitSound( "apc_engine_stop" )
		self.Entity:EmitSound( "apc_engine_start" )
	end
end

function ENT:OverdriveOff()
    self.overdrive = 0
    self:SetOOO(1)
    
    self.Entity:StopSound( "apc_engine_start" )
    if(self.mute == 0) then
		self.Entity:EmitSound( "apc_engine_stop" )
		self.Entity:EmitSound( "apc_engine_start" )
	end
end

function ENT:Destruct()
    CAF.GetAddon("Life Support").Destruct( self.Entity )
end

function ENT:Output()
	return 1
end

function ENT:Supply()
	self.energy = (self.econ + math.random(1,3)) * self.multiply
	self.ice = (self.icecon + math.random(1,6))* self.multiply
	
	--handle overdrive damage/multiplier
	if ( self.overdrive == 1 ) then
        self.energy = self.energy * self.overdrivefactor
        self.ice = self.ice * self.overdrivefactor
        
        if self.overdrivefactor > 1 then
            if CAF and CAF.GetAddon("Life Support") then
				CAF.GetAddon("Life Support").DamageLS(self, math.random(5,8)*self.overdrivefactor)
			else
				self:SetHealth( self:Health( ) - math.random(5,8)*self.overdrivefactor)
				if self:Health() <= 0 then
					self:Remove()
				end
			end
			if self.overdrivefactor > self.maxoverdrive then
				self:Destruct()
			end
        end
    end
    
	if self:CanRun() == true then
		self:ConsumeResource("energy", self.energy)
		self:ConsumeResource(CAF.GetAddon("Asteroid Mining").GetResourceRefinedName("Ice"),self.ice)
		self:SupplyResource("water",self.ice*10)
	else
		self:TurnOff()
	end
		
	return
end

function ENT:CanRun()
	local energy = self:GetResourceAmount("energy")
	local rock = self:GetResourceAmount(CAF.GetAddon("Asteroid Mining").GetResourceRefinedName("Ice"))
	if (energy >= self.energy) and (rock >= self.ice) then
		return true
	else
		return false
	end
end

function ENT:Think()
  self.BaseClass.Think(self)
    
	if ( self.Active == 1 ) then
		self:Supply()
	end
    
	self.Entity:NextThink( CurTime() + 1 )
	return true
end

function ENT:AcceptInput(name,activator,caller)
	if name == "Use" and caller:IsPlayer() and caller:KeyDownLast(IN_USE) == false then
		if ( self.Active == 0 ) then
			self:TurnOn()
		elseif (self.Active == 1 && self.overdrive==0) then
			self:OverdriveOn()
			self.overdrivefactor = 2
		elseif (self.overdrive > 0) then
			self:TurnOff()
		end
	end
end

function ENT:PreEntityCopy()
	self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )
	self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities )
end
