AddCSLuaFile( "cl_init.lua" ) -- Make sure clientside
AddCSLuaFile( "shared.lua" )  -- and shared scripts are sent.

include('shared.lua')

function ENT:Initialize()
	local models = {"models/props/de_train/tanker.mdl", "models/props/de_train/boxcar.mdl", "models/props/de_train/diesel.mdl"}
	local SPAWN_TYPE = math.random(1,2)
	if SPAWN_TYPE == 1 then
		local model = ( "models/props/de_train/flatcar.mdl" )
		self:SetModel( model )
		self:PhysicsInit( SOLID_VPHYSICS )      -- Make us work with physics,
		self:SetMoveType( MOVETYPE_NOCLIP ) -- this is aparently necessary for things to work
		self:SetMoveType( MOVETYPE_PUSH )   -- we want our cars to basically behave the same as moving platforms
		self:SetSolid( SOLID_VPHYSICS )     
		self:SetGravity(0)
			local phys = self:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:Wake()
			phys:SetMass(50000)
		end
		self.ships = {}
		self.ship_pos = {}
		self.startingPos = Vector(1087.253296, -2044.023193, -166.758865)+Vector(0,0,-35)--self:GetPos()
		self.endPos = self.startingPos+Vector(0,4500,0)
		self.travelDir = (self.endPos-self.startingPos):GetNormalized()--self:GetRight()
		
		self.angle = Angle(0,90,0)--self:GetAngles()
		self.diff_pos = self.startingPos
		self:SetAngles(self.angle)
		self.spd = 400
		self:SetPos(self.startingPos) --Dumb hand inserted offset so it doesn't spawn in the ground
		
		
		local spawnableShips = {"AK47", "MP5", "M4", "Mac 10", "Pump Shotgun"}
		local numOfShips = math.random(10)
		local makeRandomVec = function(x,y,z) return Vector(math.random(x)-(x/2), math.random(y)-(y/2), z) end
		
		for i=1, numOfShips do
			local crate = ents.Create("spawned_shipment")
			local ply = player.GetAll()[1]
			selectedIndex = math.random(1,5)
			local found, foundKey = DarkRP.getShipmentByName(spawnableShips[selectedIndex])
			crate.SID = ply.SID
			crate:Setowning_ent(ply)
			
			crate:SetContents(foundKey, found.amount)
			self.ship_pos[i] = makeRandomVec(70,637, 65)
			crate:SetPos(self.startingPos + self.ship_pos[i])
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
			
			--constraint.Weld(crate, self, 0, 0, 0, false, false)
			self.ships[i] = crate
			
		end
	
	elseif SPAWN_TYPE==2 then
		local model = models[math.random(1,3)]
		self:SetModel( model )
		self:PhysicsInit( SOLID_VPHYSICS )      -- Make us work with physics,
		self:SetMoveType( MOVETYPE_NOCLIP ) -- this is aparently necessary for things to work
		self:SetMoveType( MOVETYPE_PUSH )   -- we want our cars to basically behave the same as moving platforms
		self:SetSolid( SOLID_VPHYSICS )     
		self:SetGravity(0)
			local phys = self:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:Wake()
			phys:SetMass(50000)
		end
		self.ships = {}
		self.ship_pos = {}
		self.startingPos = Vector(1087.253296, -2044.023193, -166.758865)+Vector(0,0,-35)--self:GetPos()
		self.endPos = self.startingPos+Vector(0,4500,0)
		self.travelDir = (self.endPos-self.startingPos):GetNormalized()--self:GetRight()
		
		self.angle = Angle(0,90,0)--self:GetAngles()
		self.diff_pos = self.startingPos
		self:SetAngles(self.angle)
		self.spd = 400
		self:SetPos(self.startingPos) --Dumb hand inserted offset so it doesn't spawn in the ground
		
	end
	self:CallOnRemove("CleanUp", function(ent)
		ent:StopSound('train_loop_1')
		for _,crate in pairs(ent.ships) do
			if IsValid(crate) then
				crate:Remove()
			end
		end
	end
	)
	
	sound.Add( {
	name = "train_loop_1",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 80,
	pitch = { 95, 110 },
	sound = "ambient/machines/train_freight_loop1.wav"
	} )
	self:EmitSound('train_loop_1')
	
	local move_dist = (self.endPos - self.startingPos):Length()
	self.move_dist = move_dist
	self:SetSaveValue("m_flMoveDoneTime", CurTime()+(move_dist/self.spd))
	self:SetMoveType(MOVETYPE_PUSH)
	self:SetLocalVelocity(self.travelDir*self.spd)

end


function ENT:Use( activator, caller )
    return
end

function ENT:Think()

	local diff_pos = self:GetPos() - self.diff_pos
	self.diff_pos = self:GetPos()
	--self:SetPos(self.startingPos + pos)
	--self:SetAngles(self.angle)
	
	self:NextThink( CurTime() )
	rm_ind = {}
	for i, crate in pairs(self.ships) do
		if IsValid(crate) then
			crate:SetPos(self:GetPos()+self.ship_pos[i])
			crate:SetAngles(Angle(0,0,0))
			if crate:IsPlayerHolding() then
				constraint.RemoveConstraints(crate, "Weld")
				--crate:SetParent(nil)
				self.ships[i] = nil
			end
		end
	end
	local diff_start = (self:GetPos() - self.startingPos):Length()
	if diff_start > self.move_dist then
		self:Remove() --die once we're out of world
	end
	return true
end
