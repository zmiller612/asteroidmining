AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

function ENT:Initialize()
    self.BaseClass.Initialize(self)

    local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(300)
	end
	
	self.damaged = 0
	self.wireamount = 1
	self.wirecapacity = 1
    self:SetMaxHealth(600)
	self:SetHealth(self:GetMaxHealth())
	
	self.reslist = {}
end

function ENT:OnRemove()
    self.BaseClass.OnRemove(self)
end

function ENT:Damage()
	if (self.damaged == 0) then
		self.damaged = 1
	end
end

function ENT:TakeDamage(amount, attacker, inflictor)
	self:SetHealth(self:Health()-amount)
	if self:Health()<=0 then
		self:Destruct()
	end
end

function ENT:Repair()
	self.Entity:SetColor(255,255,255,255)
	self:SetHealth(self:GetMaxHealth())
	self.damaged = 0
end

function ENT:Destruct()
	CAF.GetAddon("Life Support").Destruct( self.Entity )
end

function ENT:Output()
	return 1
end

function ENT:UpdateWireOutputs()
	if self.wireamount == 1 or self.wirecapacity == 1 then
		local restable = CAF.GetAddon("Resource Distribution").GetEntityTable(self).resources
		if self.wireamount == 1 then
			for k,v in pairs(restable) do
				WireLib.TriggerOutput(self, k, self:GetResourceAmount(k))
			end
		end
		
		if self.wirecapacity == 1 then
			for k,v in pairs(restable) do
				WireLib.TriggerOutput(self, k.." Capacity", self:GetNetworkCapacity(k))
			end
		end
	end
end

function ENT:ShowOutput()
	self.Entity:SetNetworkedInt( 1, self.force or 0 )
	
	--send res values
	local netid = 10
	for k,v in pairs(self.reslist) do
		self.Entity:SetNWInt( netid ,k) -- energy consumption
	end
end

function ENT:Think()
    self.BaseClass.Think(self)
    
    self:UpdateWireOutputs()
    
	self.Entity:NextThink( CurTime() + 1 )
	return true
end

function ENT:AcceptInput(name,activator,caller)

end

function ENT:PreEntityCopy()
    self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )
    self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities )
end
