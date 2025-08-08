--[[
    Copyright © 2017 TIMON_Z1535
    http://steamcommunity.com/id/TIMON_Z1535/
--]]

SWEP.PrintName = "Road Maker Pointer"
SWEP.Category = "Hammer Road Maker"
SWEP.Instructions = "R: Change mode\nMouse1: Create new point or snap to existing point\nMouse2: Remove last or select nearest point"
SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""

SWEP.ViewModel = "models/weapons/v_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"

-- A small radius (in Hammer units) for snapping
SWEP.SnapDistance = 50

if CLIENT then
	function SWEP:Initialize()
		self.IsCreator = true
		self.Select = 0
	end

	-- Client-side function to provide visual feedback for snapping and selection
	function SWEP:Think()
		if not IsValid(self:GetOwner()) then return end

		local trace = self:GetOwner():GetEyeTrace()
		local hitPos = trace.HitPos

		-- Highlight the selected point
		if self.Select != 0 and RoadMaker.Points[self.Select] then
			debugoverlay.Sphere(RoadMaker.Points[self.Select], 50, 0.1, Color(0, 255, 0, 150), true)
		end

		-- Highlight the point to snap to if in Creator mode
		if self.IsCreator then
			local mindistSqr = self.SnapDistance * self.SnapDistance
			local snapPoint = nil

			for k, pos in ipairs(RoadMaker.Points) do
				local distSqr = hitPos:DistToSqr(pos)
				if (distSqr < mindistSqr) then
					mindistSqr = distSqr
					snapPoint = pos
				end
			end

			if snapPoint then
				debugoverlay.Sphere(snapPoint, 50, 0.1, Color(255, 255, 0, 150), true)
			end
		end
	end

	return
end

function SWEP:Initialize()
	self.IsCreator = true
	self.Select = 0
end

function SWEP:Dirtymake(key, access)
	RoadMaker:UpdatePoint(key)
	RoadMaker.UpdateMeshs(key, access)
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 0.1)

	local trace = util.TraceLine({
		start = self:GetOwner():GetShootPos(),
		endpos = self:GetOwner():GetShootPos() + self:GetOwner():GetAimVector() * 10000,
		filter = function(ent) if (ent:GetClass() == "roadmaker_phys") then return false end end
	})

	local vec = trace.HitPos

	if self.IsCreator then
		local mindistSqr = self.SnapDistance * self.SnapDistance
		local snapPoint = nil

		-- Snap to nearby point
		for k, pos in ipairs(RoadMaker.Points) do
			local distSqr = vec:DistToSqr(pos)
			if (distSqr < mindistSqr) then
				mindistSqr = distSqr
				snapPoint = pos
			end
		end

		local newPoint = snapPoint or (vec + Vector(0,0,32))

		-- Round coordinates if no snap
		if not snapPoint then
			newPoint.x = math.Round(newPoint.x / 8) * 8
			newPoint.y = math.Round(newPoint.y / 8) * 8
			newPoint.z = math.Round(newPoint.z / 8) * 8
		end

		table.insert(RoadMaker.Points, newPoint)
		self:Dirtymake(#RoadMaker.Points)
	elseif self.Select != 0 and RoadMaker.Points[self.Select] then
		-- Snap to nearby point for repositioning
		local mindistSqr = self.SnapDistance * self.SnapDistance
		local snapPoint = nil

		for k, pos in ipairs(RoadMaker.Points) do
			-- Avoid snapping to itself
			if k != self.Select then
				local distSqr = vec:DistToSqr(pos)
				if (distSqr < mindistSqr) then
					mindistSqr = distSqr
					snapPoint = pos
				end
			end
		end

		local newPos = snapPoint or vec

		-- Round if not snapping
		if not snapPoint then
			newPos.x = math.Round(newPos.x / 8) * 8
			newPos.y = math.Round(newPos.y / 8) * 8
			newPos.z = math.Round(newPos.z / 8) * 8
			RoadMaker.Points[self.Select] = newPos + Vector(0,0,32)
		else
			RoadMaker.Points[self.Select] = newPos
		end

		self:Dirtymake(self.Select, true)
	end
end

function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire(CurTime() + 0.1)

	self.Select = 0

	if self.IsCreator then
		local key = #RoadMaker.Points
		RoadMaker.Points[key] = nil
		self:GetOwner():EmitSound("buttons/button18.wav")
		self:Dirtymake(key)
	else
		local mindist = 500000
		local key = 0
		local vec = util.TraceLine({
			start = self:GetOwner():GetShootPos(),
			endpos = self:GetOwner():GetShootPos() + self:GetOwner():GetAimVector() * 10000,
			filter = function(ent) if (ent:GetClass() == "roadmaker_phys") then return false end end
		}).HitPos

		for k, pos in ipairs(RoadMaker.Points) do
			local dist = vec:DistToSqr(pos)

			if (dist < mindist) then
				mindist = dist
				key = k
			end
		end

		if key != 0 then
			self.Select = key
			self:GetOwner():EmitSound("buttons/button14.wav")
		end
	end
end

function SWEP:Reload()
	if self.NextReload and self.NextReload > CurTime() then return end
	self.NextReload = CurTime() + 0.5

	self.IsCreator = not self.IsCreator

	if self.IsCreator then
		self:GetOwner():ChatPrint("Mode: Creator (Snapping Enabled)")
	else
		self:GetOwner():ChatPrint("Mode: Positioner (Point Selection)")
	end
end