AddCSLuaFile( "cl_init.lua" ) -- Make sure clientside
AddCSLuaFile( "shared.lua" )  -- and shared scripts are sent.

include('shared.lua')

sound.Add( {
name = "train_loop_1",
channel = CHAN_STATIC,
volume = 1.0,
level = 80,
pitch = { 95, 110 },
sound = "ambient/machines/train_freight_loop1.wav"
} )

viable_crate_positions = {}
for i = 1, 10 do
	local crate_p1 = Vector(-20,-256+i*51,65)
	local crate_p2 = Vector(20,-256+i*51,65)
	table.insert(viable_crate_positions, crate_p1)
	table.insert(viable_crate_positions, crate_p2)
end

function vec_string(vector)
	local x = math.floor(vector.x)
	local y = math.floor(vector.y)
	local z = math.floor(vector.z)
	return tostring(x).." "..tostring(y).." "..tostring(z)
end

function shuffle(t)
	local sawp_vals = function(arr, i1, i2)
		if i1 == i2 then return end
		arr[i1], arr[i2] = arr[i2], arr[i1]
	end
	local index = #t
	while index > 1 do
		local other_index = math.random(#t)
		sawp_vals(t, index, other_index)
		index = index - 1
	end
end

function AttachShipments(train_car_ent, numOfShips, shipment_table)
	local makeRandomVec = function(x,y,z) return Vector(math.random(x)-(x/2), math.random(y)-(y/2), z) end
	shuffle(viable_crate_positions)
	for i=1, numOfShips do
		local crate = ents.Create("spawned_shipment")
		local ply = player.GetAll()[1]
		local selectedIndex = math.random(1,5)
		local found, foundKey = DarkRP.getShipmentByName(shipment_table[selectedIndex])
		crate.SID = ply.SID
		crate:Setowning_ent(ply)
		crate:SetContents(foundKey, found.amount)
		local tpos = viable_crate_positions[i]
		train_car_ent.ship_pos[i] = tpos--makeRandomVec(70,637, 65)
		crate:SetPos(train_car_ent.startingPos + train_car_ent.ship_pos[i])
		crate.nodupe = true
		crate.ammoadd = found.spareammo
		crate.clip1 = found.clip1
		crate.clip2 = found.clip2
		crate:Spawn()
		crate:SetPlayer(ply)
		local phys = crate:GetPhysicsObject()
		phys:Wake()
		if found.weight then
			phys:SetMass(10)
		end
		--crate:SetMoveType(MOVETYPE_FLY)
		crate:SetAngles(Angle(0,0,0))
		--constraint.Weld(crate, self, 0, 0, 0, true, false)
		crate:SetParent(train_car_ent)
		--print(vec_string(tpos))
		train_car_ent.ships[vec_string(tpos)] = crate
	end
end


function Init_Car(self)
	self:PhysicsInit( SOLID_VPHYSICS )  -- Make us work with physics,
	--self:SetMoveType( MOVETYPE_NOCLIP ) -- this is aparently necessary for things to work
	self:SetMoveType( MOVETYPE_PUSH )   -- we want our cars to basically behave the same as moving platforms
	--self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid( SOLID_VPHYSICS )     
	self:SetGravity(0)
		local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(50000)
	end
	self.ships = {}
	self.ship_pos = {}
	self.startingPos = Vector(1087.253296, -2044.023193, -166.758865)+Vector(0,0,-35)+Vector(-400,0,340)--self:GetPos()
	self.endPos = self.startingPos+Vector(0,4500,0)
	self.travelDir = (self.endPos-self.startingPos):GetNormalized()--self:GetRight()
	self.ply_on = {}
	self.ply_on_ind = {}
	self.ply_on_c = 0
	self.angle = Angle(0,90,0)--self:GetAngles()
	self:SetAngles(self.angle)
	self.spd = 400
	self:SetPos(self.startingPos) --Dumb hand inserted offset so it doesn't spawn in the ground
	local _, bbmax = self:GetCollisionBounds()
	self.floor_level = bbmax.z
	self:CallOnRemove("CleanUp", function(ent)
		ent:StopSound('train_loop_1')
		for _,crate in pairs(ent.ships) do
			if IsValid(crate) then
				crate:Remove()
			end
		end
	end
	)
	self:EmitSound('train_loop_1')
	local move_dist = (self.endPos - self.startingPos):Length()
	self.move_dist = move_dist
	self:SetSaveValue("m_flMoveDoneTime", CurTime()+(move_dist/self.spd))
	self:SetMoveType(MOVETYPE_PUSH)
	self:SetLocalVelocity(self.travelDir*self.spd)
	self:GetPhysicsObject():Wake()
	self:SetTrigger(true) --this is for the start/end touch calls which we need to keep track of who's on the train
	--self:SetSaveValue("m_CollisionGroup", 3)
	print(self:GetSaveTable()["m_CollisionGroup"])
	--self:StartMotionController() -- we'll see why we need these below
	--self.shadowParams = {}
end

function ENT:Initialize()
	local models = {"models/props/de_train/tanker.mdl", "models/props/de_train/boxcar.mdl", "models/props/de_train/diesel.mdl"}
	local SPAWN_TYPE = math.random(1,2)
	if SPAWN_TYPE == 1 then
		local model = ( "models/props/de_train/flatcar.mdl" )
		self:SetModel( model )
		Init_Car(self)
		self.floor_level = 62
		AttachShipments(self, math.random(10), {"AK47", "MP5", "M4", "Mac 10", "Pump Shotgun"})
	elseif SPAWN_TYPE==2 then
		local model = models[math.random(1,3)]
		self:SetModel( model )
		Init_Car(self)
	end
end
--[[
function ENT:PhysicsSimulate( phys, deltatime )
	phys:Wake()
	self.shadowParams.secondstoarrive = self.move_dist/self.spd
	self.shadowParams.pos = self.endPos
	self.shadowParams.angle = self.angle
	self.shadowParams.maxangular = 5000
	self.shadowParams.maxangulardamp = 10000
	self.shadowParams.maxspeed = 100000
	self.shadowParams.maxspeeddamp = 10000
	self.shadowParams.dampfactor = 0.0
	self.shadowParams.teleportdistance = 100000
	self.shadowParams.deltatime = deltatime
	
	phys:ComputeShadowControl( self.shadowParams )
end]]--
function ENT:add_onboard_player( ply )
	if ply:IsPlayer() then
		if self.ply_on_ind[ply:AccountID()] then return end --if the player is already in the table
		self.ply_on_c = self.ply_on_c +1
		local index = self.ply_on_c
		self.ply_on_ind[ply:AccountID()] = index
		self.ply_on[index] = ply
	end
end

function ENT:remove_onboard_player( ply )
	if ply:IsPlayer() then
		if self.ply_on_ind[ply:AccountID()]==nil or self.ply_on_c == 0 then return end --if there is no one by that name to remove_onboard_player
		local swap_index = self.ply_on_ind[ply:AccountID()]
		
		self.ply_on_ind[swap_index] = nil --tell our fast lookup table that the swap index is nolonger valid for that id
		self.ply_on[swap_index] = self.ply_on[self.ply_on_c] --swap with last entry in our table
		self.ply_on_ind[self.ply_on[swap_index]:AccountID()] = swap_index --update that entries index in our fast lookup table
		self.ply_on_ind[ply:AccountID()]=nil
		self.ply_on[self.ply_on_c] = nil --set that position to nil for the iteratior
		self.ply_on_c = self.ply_on_c - 1 --decrment count
	end
end

function ENT:onboard_contains( ply )
	return not self.ply_on_ind[ply:AccountID()]
end

function ENT:Use( activator, caller )
    return
end

function IsInFront(ent1, ent2)
	local pos2 = ent2:GetPos()
	local pos_loc = ent1:WorldToLocal(pos2)
	local bbmin, bbmax = ent1:GetCollisionBounds()

	local frontc_pos = Vector(bbmax.x, (bbmax.y+bbmin.y)/2, (bbmax.z+bbmin.z)/2)
	if (pos_loc.x >= frontc_pos.x-30) and (pos_loc.y >= bbmin.y and pos_loc.y < bbmax.y) and (pos_loc.z < bbmax.z) then
		return true
	else 
		return false
	end
	
end

function IsOnTop(ent1, ent2)
	local pos2 = ent2:GetPos()
	local pos_loc = ent1:WorldToLocal(pos2)
	local bbmin, bbmax = ent1:GetCollisionBounds()
	
	local topc_pos = Vector((bbmax.x+bbmin.x)/2, (bbmax.y+bbmin.y)/2, bbmax.z)
	if (pos_loc.x >= bbmin.x and pos_loc.x < bbmax.x) and (pos_loc.y >= bbmin.y and pos_loc.y < bbmax.y) and (pos_loc.z >= ent1.floor_level) then
		return true
	else
		return false
	end
end

function ENT:StartTouch( impact )
	if IsInFront(self, impact) then
		if impact:IsPlayer() then
			--impact:Kill()
		else
			--impact:Remove()
		end
	end
	if impact:IsPlayer() and IsOnTop(self, impact) then
		--print("ADDING TO TABLE")
		self:add_onboard_player( impact )
	end
end

function ENT:EndTouch( impact )
	--print (IsOnTop(self, impact))
	if impact:IsPlayer() and (not IsOnTop(self, impact)) then
		self:remove_onboard_player( impact )
	end
end

function IsTargetCrate(ply, train)
	if not ply:IsPlayer() then return nil end -- do nothing if we were passed a non-player
	if (ply:GetActiveWeapon():GetClass() == "weapon_physcannon") and ply:KeyDown(IN_ATTACK2) then
		local tr = ply:GetEyeTrace()
		local pos = tr.HitPos
		local local_pos = train:WorldToLocal(pos)
		--so this is a bit tricky, but basically, we want to test and see if our position is close enough to one of our crate positions
		--the first thing to do is find what "sector" our position is in on the flat bed, we'll do this by 
		local sector_vec = Vector(40*math.floor((-local_pos.y)/40)+20, 51*math.floor((local_pos.x+26.5)/51)-1, 65) -- this will correspond to the closest crate

		local found_crate = train.ships[vec_string(sector_vec)]
		if found_crate then
			local dist_sqr = (tr.StartPos-tr.HitPos):LengthSqr()
			print(dist_sqr)
			if dist_sqr > 8600 then return nil end
		end
		return found_crate, vec_string(sector_vec)
	end
end

function ENT:GetLookingCrate(pos)

end

function ENT:Think()
	self:NextThink( CurTime() )
	rm_ind = {}
	if self.ply_on_c > 0 then
		for i = 1, self.ply_on_c do
			--print(self.ply_on[i])
			local ply = self.ply_on[i]
			local crate, crate_sec = IsTargetCrate(ply, self)
			if crate then
				crate:SetParent(nil)
				crate:GetPhysicsObject():Wake()
				self.ships[crate_sec] = nil
			end
			--print(crate)
		end
	end
	local diff_start = (self:GetPos() - self.startingPos):Length()
	if diff_start > self.move_dist then
		self:Remove() --die once we're out of world
	end
	return true
end
