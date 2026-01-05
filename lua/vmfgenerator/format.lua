--[[
	Copyright © 2017 TIMON_Z1535
	http://steamcommunity.com/id/TIMON_Z1535/
	VMF exporter with correct face-space UVs
--]]

local function Normalize(v)
	local l = math.sqrt(v.x*v.x + v.y*v.y + v.z*v.z)
	return Vector(v.x / l, v.y / l, v.z / l)
end

local function Cross(a, b)
	return Vector(
		a.y * b.z - a.z * b.y,
		a.z * b.x - a.x * b.z,
		a.x * b.y - a.y * b.x
	)
end

local function Dot(a, b)
	return a.x*b.x + a.y*b.y + a.z*b.z
end

concommand.Add('roadmaker_getvmf', function()
	local width  = tonumber(RoadMaker.Cfgs['width']:GetString()) or 1
	local offset = 0
	local texScale = 0.4  -- 50% of current size
	local uShift = 200   -- move 200 units along U
	local vShift = 0

	local vmf    = 'world\n{'

	for brk, faces in ipairs(VMFGenerator.brushes) do
		vmf = vmf .. '\n\tsolid\n\t{'

		for fk, verts in ipairs(faces) do
			local mat = RoadMaker.Cvars[verts.mat]:GetString()

			vmf = vmf .. '\n\t\tside\n\t\t{'
			vmf = vmf .. '\n\t\t\t"plane" "'

			for i, pos in ipairs(verts) do
				vmf = vmf .. (i == 1 and '' or ' ')
				vmf = vmf .. '(' .. pos.x .. ' ' .. pos.y .. ' ' .. pos.z .. ')'
			end

			vmf = vmf .. '"'

			-- ================= TOP FACE =================
			if fk == 1 then
				-- maintain texture continuity
				if brk % 2 == 1 then
					offset = offset + VMFGenerator.textures[brk][2]
					while offset > width do
						offset = offset - width
					end
				end

				-- face normal
				local p1, p2, p3 = verts[1], verts[2], verts[3]
				local normal = Normalize(Cross(p2 - p1, p3 - p1))

				-- road forward direction (world)
				local yaw = VMFGenerator.textures[brk][1]
				local forward = Angle(0, yaw, 0):Forward()

				-- project forward onto the face plane
				forward = forward - normal * Dot(forward, normal)
				forward = Normalize(forward)

				-- build perpendicular axis on plane
				local right = Normalize(Cross(normal, forward))

				-- write face-space axes
				vmf = vmf .. '\n\t\t\t"uaxis" "['
					.. right.x .. ' ' .. right.y .. ' ' .. right.z .. ' ' .. uShift .. '] ' .. texScale .. '"'

				vmf = vmf .. '\n\t\t\t"vaxis" "['
					.. (-forward.x) .. ' ' .. (-forward.y) .. ' ' .. (-forward.z) .. ' ' .. (vShift + offset) .. '] ' .. texScale .. '"'

				vmf = vmf .. '\n\t\t\t"rotation" "0"'
				vmf = vmf .. '\n\t\t\t"material" "' .. mat .. '"'

			-- ================= OTHER FACES =================
			else
				vmf = vmf .. '\n\t\t\t"uaxis" "[1 0 0 0] 1"'
				vmf = vmf .. '\n\t\t\t"vaxis" "[0 -1 0 0] 1"'
				vmf = vmf .. '\n\t\t\t"rotation" "0"'
				vmf = vmf .. '\n\t\t\t"material" "' .. mat .. '"'
			end

			vmf = vmf .. '\n\t\t}'
		end

		vmf = vmf .. '\n\t}'
	end

	vmf = vmf .. '\n}'
	file.Write('vmfgenerator.vmf.txt', vmf)
end)
