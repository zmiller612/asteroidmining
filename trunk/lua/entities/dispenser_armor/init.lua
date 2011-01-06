AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

util.PrecacheSound( "items/suitchargeno1.wav" )
util.PrecacheSound( "items/suitchargeok1.wav" )

include('shared.lua')

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	self.damaged = 0
	
	self.mute = 0
	self.maxcharges = 0 --max charges
	self.charges = 0 --current charges
	self.rcinterval = 30 --recharge once per minute
	self.rctime = 0 --time at which to add a charge
	
	-- consumption per charge
	self.econ = 0 -- Energy consumption
	self.ircon = 0 -- refined iron consumption
	self.tcon = 0 -- refined titanium consumption
    
	local RD = CAF.GetAddon("Resource Distribution")
	RD.RegisterNonStorageDevice(self)
end

function ENT:Damage()
	if (self.damaged == 0) then self.damaged = 1 end
end

function ENT:Repair()
	self.BaseClass.Repair(self)
	self.Entity:SetColor(255, 255, 255, 255)
	self.damaged = 0
end

function ENT:Destruct()
    CAF.GetAddon("Life Support").Destruct( self.Entity )
end

function ENT:Charge()
	if self.charges < self.maxcharges then
		local AM = CAF.GetAddon("Asteroid Mining")
		local energy = self:GetResourceAmount("energy")
		local iron = self:GetResourceAmount(AM.GetResourceRefinedName("Iron"))
		local titanium = self:GetResourceAmount(AM.GetResourceRefinedName("Titanium"))
		
		--check if it has the resources to charge
		if energy >= self.econ and iron >= self.ircon and titanium > self.tcon then
			self:ConsumeResource("energy",self.econ)
			self:ConsumeResource(AM.GetResourceRefinedName("Iron"),self.ircon)
			self:ConsumeResource(AM.GetResourceRefinedName("Titanium"), self.tcon)
			
			self.charges = self.charges + 1
			self:SetNWInt( "mining_disparm_charges", self.charges or 0)
		end
		
		--output wire stuff
		if WireLib then
			WireLib.TriggerOutput(self, "Charges", self.charges)
		end
	end
end

function ENT:Dispense(ply)
	if self.charges > 0 then
		if ply:IsPlayer() == true then --just to be sure
			if ply:Armor() != 100 then
				--cap armor recharge between 0 to 10hp
				local armor = 100 - ply:Armor()
				if armor > 10 then armor = 10 end
				if armor < 0 then armor = 0 end
				ply:SetArmor(ply:Armor() + armor)
				
				self:EmitSound("items/suitchargeok1.wav")
				
				--update Network stuff
				self.charges = self.charges - 1
				self:SetNWInt( "mining_disparm_charges", self.charges or 0)
			end
		end
	else
		self:EmitSound("items/suitchargeno1.wav")
	end
	
	--output wire stuff
	if WireLib then
		WireLib.TriggerOutput(self, "Last User", ply)
		WireLib.TriggerOutput(self, "Charges", self.charges)
	end
end

function ENT:Think()
	self.BaseClass.Think(self)
	
	--recharge
	if CurTime() > self.rctime then
		self:Charge()
		self.rctime = CurTime() + self.rcinterval
	end
	
	self.Entity:NextThink(CurTime() + 1)
	return true
end

function ENT:AcceptInput(name,activator,caller)
	if name == "Use" and caller:IsPlayer() and caller:KeyDownLast(IN_USE) == false then
		self:Dispense(caller)
	end
end

function ENT:PreEntityCopy()
	self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )
	self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities )
end
