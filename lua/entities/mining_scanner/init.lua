AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

util.PrecacheSound( "Buttons.snd17" )

include('shared.lua')

local BeamLength = 512 --default beam length
local MaxRange = 1024

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	self.Active = 0
	self.damaged = 0
	self.range = 512
	self.energy = 0
	self.mute = 0
	self.roidres = 0
	self.hit = 0
	self.beeptime = 15
	self.beamlength = BeamLength
	
	-- resource attributes
	self.econ = 10 -- Energy consumption
    
	local RD = CAF.GetAddon("Resource Distribution")
	RD.RegisterNonStorageDevice(self)
end

function ENT:TurnOn()
	if self.Active == 0 then
		self.Active = 1
		self:SetOOO(1)
		self:Detect()
		self:UpdateOutput()
		
		if WireLib then
			WireLib.TriggerOutput(self, "On", 1)
		end
		
		if(self.mute == 0) then
			self.Entity:EmitSound( "Buttons.snd17" )
		end
	end
end

function ENT:TurnOff(beep)
	if self.Active == 1 then
		self.Active = 0
		self:SetOOO(0)
		self:UpdateOutput()
		self.beeptime = 15
		
		if WireLib then
			WireLib.TriggerOutput(self, "On", 0)
			WireLib.TriggerOutput(self, "Yield", 0)
			WireLib.TriggerOutput(self, "Hit", 0)
		end
		
		if self.mute == 0 and beep == 1 then
			self.Entity:EmitSound( "common/warning.wav" )
		end
	end
end

function ENT:TriggerInput(iname, value)
	if iname == "On" then
		if value > 0 then
			if  self.Active == 0  then
				self:TurnOn()
			end
		else
			if ( self.Active == 1 ) then
                self:TurnOff(0)
			end
		end
	elseif iname == "Range" then
		if value > 0 then
			self.beamlength = value
			if self.beamlength > MaxRange then
				self.beamlength = MaxRange
			end
		else
			self.beamlength = 512
		end
	elseif iname == "Mute" then
		if (value > 0) then
			self.mute = 1
		else
			self.mute = 0
		end
	end
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

function ENT:Detect()
	self.energy = self.econ * (self.beamlength/BeamLength) --consumption
	
	if self:GetResourceAmount("energy") <= 0 then
		self:TurnOff(1)
		return
	else
		self:ConsumeResource("energy",self.energy)
		
		--beep timer
		if self.mute == 0 then
			if (self.beeptime > 0) then
				self.beeptime = self.beeptime - 1
			else
				self:EmitSound( "Buttons.snd17" )
				self.beeptime = 25
			end
		end
		
		local trace = {}
		trace.start = self:GetPos()
		trace.endpos = self:GetPos()+(self:GetAngles():Up()*self.beamlength)
		trace.filter = { self }
		local tr = util.TraceLine( trace )
		if tr.Entity and tr.Entity.asteroid then
			self.hit = 1
			self.roidres = math.ceil((tr.Entity.totalResources/tr.Entity.maxcap)*100) --percent level
			
			local AM = CAF.GetAddon("Asteroid Mining")
			
			--check if the entity being hit is different from the last one, else don't update array output
			if self.lasthit != tr.Entity:EntIndex() then
				self.lasthit = tr.Entity:EntIndex()
				--format asteroid resources into a table wiremod understands
				local temp = {}
				for k,v in pairs(tr.Entity.resources) do
					table.insert(temp,k)
				end
				
				--output resource array
				if WireLib then
					WireLib.TriggerOutput( self, "Detected Resources", temp)
				end
			end
		else
			self.roidres = 0
			self.hit = 0
			self.lasthit = nil
			
			if WireLib then
				WireLib.TriggerOutput( self, "Detected Resources", {} )
			end
		end
		
		--scan effect
		local effectdata = EffectData()
		effectdata:SetEntity( self )
		effectdata:SetOrigin( self:GetPos() )
		effectdata:SetStart( tr.HitPos+(tr.HitNormal*self.beeptime) )
		util.Effect( "scan_beam", effectdata, true, true )
	end
	
	--output wire stuff
	if WireLib then
		WireLib.TriggerOutput(self, "On", 0)
		WireLib.TriggerOutput(self, "Hit", self.hit)
		WireLib.TriggerOutput(self, "Yield", self.roidres)
	end
end

function ENT:UpdateOutput()
	if self.Active == 1 then
		self:SetNWInt( "proberoid", self.roidres or 0)
	else
		self:SetNWInt( "proberoid", 0)
	end
end

function ENT:Think()
	self.BaseClass.Think(self)
	
	if self.Active == 1 then
		self:Detect()
		self:UpdateOutput()
	end
	
	self.Entity:NextThink(CurTime() + 1)
	return true
end

function ENT:AcceptInput(name,activator,caller)
	if name == "Use" and caller:IsPlayer() and caller:KeyDownLast(IN_USE) == false then
		if ( self.Active == 0 ) then
			self:TurnOn()
		else
			self:TurnOff(0)
		end
	end
end

function ENT:PreEntityCopy()
	self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )
	self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities )
end
