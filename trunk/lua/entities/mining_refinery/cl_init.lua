include('shared.lua')
language.Add("mining_storage", "Mineral Refinery")

local OOO = {}
OOO[0] = "Off"
OOO[1] = "On"
OOO[2] = "Overdrive"

function ENT:DoNormalDraw( bDontDrawModel )
	local mode = self:GetNetworkedInt("overlaymode")
	if RD_OverLay_Mode and mode != 0 then -- Don't enable it if disabled by default!
		if RD_OverLay_Mode.GetInt then
			local nr = math.Round(RD_OverLay_Mode:GetInt())
			if nr >= 0 and nr <= 2 then
				mode = nr;
			end
		end
	end
	local rd_overlay_dist = 512
	if RD_OverLay_Distance then
		if RD_OverLay_Distance.GetInt then
			local nr = RD_OverLay_Distance:GetInt()
			if nr >= 256 then
				rd_overlay_dist = nr
			end
		end
	end
	if ( LocalPlayer():GetEyeTrace().Entity == self.Entity and EyePos():Distance( self.Entity:GetPos() ) < rd_overlay_dist and mode != 0) then
		local trace = LocalPlayer():GetEyeTrace()
		if ( !bDontDrawModel ) then self:DrawModel() end
		local RD = CAF.GetAddon("Resource Distribution")
		local nettable = RD.GetEntityTable(self)
		if table.Count(nettable) <= 0 then return end
		local playername = self:GetPlayerName()
		if playername == "" then
			playername = "World"
		end
		-- 0 = no overlay!
		-- 1 = default overlaytext
		-- 2 = new overlaytext
		
		if not mode or mode != 2 then
			local OverlayText = ""
				OverlayText = OverlayText ..self.PrintName.."\n"
			if nettable.network == 0 then
				OverlayText = OverlayText .. "Not connected to a network\n"
			else
				OverlayText = OverlayText .. "Network " .. nettable.network .."\n"
			end
			OverlayText = OverlayText .. "Owner: " .. playername .."\n"
			local runmode = "UnKnown"
			if self:GetOOO() >= 0 and self:GetOOO() <= 2 then
				runmode = OOO[self:GetOOO()]
			end
			OverlayText = OverlayText .. "Mode: " .. runmode .."\n"
			OverlayText = OverlayText .. "Energy: "..tostring(RD.GetResourceAmount(self,"energy")).."/"..tostring(RD.GetNetworkCapacity(self,"energy")).."\n"
			for k,v in pairs(nettable.resources) do
				if k != "energy" then
					OverlayText = OverlayText ..k..": "..tostring(RD.GetResourceAmount(self,k)).."/"..tostring(RD.GetNetworkCapacity(self,k)).."\n"
				end
			end
			AddWorldTip( self.Entity:EntIndex(), OverlayText, 0.5, self.Entity:GetPos(), self.Entity  )
		else
			local rot = Vector(0,0,90)
			local TempY = 0
			local RD = CAF.GetAddon("Resource Distribution")
			
			local pos = self.Entity:GetPos() + (self.Entity:GetUp() * (self:BoundingRadius( ) + 10))
			local angle =  (LocalPlayer():GetPos() - trace.HitPos):Angle()
			angle.r = angle.r  + 90
			angle.y = angle.y + 90
			angle.p = 0
			
			local textStartPos = -375
			
			cam.Start3D2D(pos,angle,0.03)
				surface.SetDrawColor(0,0,0,125)
				surface.DrawRect( textStartPos, 0, 1250, 500 )
				
				surface.SetDrawColor(155,155,155,255)
				surface.DrawRect( textStartPos, 0, -5, 500 )
				surface.DrawRect( textStartPos, 0, 1250, -5 )
				surface.DrawRect( textStartPos, 500, 1250, -5 )
				surface.DrawRect( textStartPos+1250, 0, 5, 500 )
				
				TempY = TempY + 10
				surface.SetFont("ConflictText")
				surface.SetTextColor(255,255,255,255)
				surface.SetTextPos(textStartPos+15,TempY)
				surface.DrawText(self.PrintName)
				TempY = TempY + 70
				
				surface.SetFont("Flavour")
				surface.SetTextColor(155,155,255,255)
				surface.SetTextPos(textStartPos+15,TempY)
				surface.DrawText("Owner: "..playername)
				TempY = TempY + 70

				surface.SetFont("Flavour")
				surface.SetTextColor(155,155,255,255)
				surface.SetTextPos(textStartPos+15,TempY)
				if nettable.network == 0 then
					surface.DrawText("Not connected to a network")
				else
					surface.DrawText("Network " .. nettable.network)
				end
				TempY = TempY + 70
				
				if HasOOO then
					local runmode = "UnKnown"
					if self:GetOOO() >= 0 and self:GetOOO() <= 2 then
						runmode = OOO[self:GetOOO()]
					end
					surface.SetFont("Flavour")
					surface.SetTextColor(155,155,255,255)
					surface.SetTextPos(textStartPos+15,TempY)
					surface.DrawText("Mode: "..runmode)
					TempY = TempY + 70
				end
				
				surface.SetFont("Flavour")
				surface.SetTextColor(155,155,255,255)
				surface.SetTextPos(textStartPos+15,TempY)
				surface.DrawText("Name: " .. tostring(self:GetNetworkedString( 8 )))
				surface.SetFont("Flavour")
				
				TempY = TempY + 70
				surface.SetFont("Flavour")
				surface.SetTextColor(155,155,255,255)
				surface.SetTextPos(textStartPos+15,TempY)
				surface.DrawText("Energy: "..tostring(RD.GetResourceAmount(self,"energy")).."/"..tostring(RD.GetNetworkCapacity(self,"energy")))
				surface.SetFont("Flavour")
				
				for k,v in pairs(nettable.resources) do
					if k != "energy" then
						TempY = TempY + 70
						surface.SetFont("Flavour")
						surface.SetTextColor(155,155,255,255)
						surface.SetTextPos(textStartPos+15,TempY)
						surface.DrawText(k..": "..tostring(RD.GetResourceAmount(self,k)).."/"..tostring(RD.GetNetworkCapacity(self,k)))
					end
				end
			cam.End3D2D()
		end
	else
		if ( !bDontDrawModel ) then self:DrawModel() end
	end
end