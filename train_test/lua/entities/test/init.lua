AddCSLuaFile( "cl_init.lua" ) -- Make sure clientside
AddCSLuaFile( "shared.lua" )  -- and shared scripts are sent.

include('shared.lua')

function ENT:Initialize()
	local model = ( "models/props/de_train/flatcar.mdl" )
	self:SetModel( model )
	self:PhysicsInit( SOLID_VPHYSICS )      -- Make us work with physics,
	self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
	self:SetSolid( SOLID_VPHYSICS )         -- Toolbox
	self:SetGravity(0)
        local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(50000)
	end
	self:SetMoveType(4) --PUSH movetype, should move through world
	self.ships = {}
	self.startingPos = Vector(1087.253296, -2044.023193, -166.758865)+Vector(0,0,-35)--self:GetPos()
	self.travelDir = Vector(0,1,0)--self:GetRight()
	self.angle = Angle(0,90,0)--self:GetAngles()
	self:SetAngles(self.angle)
	self.curT = 0
	self.delta = RealTime()
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
		
		crate:SetPos(self.startingPos + makeRandomVec(70,637, 65))
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
		crate:SetAngles(Angle(0,0,0))
		--crate:SetParent(self)
		constraint.Weld(crate, self, 0, 0, 0, true, false)
		self.ships[i] = crate
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
end


function ENT:Use( activator, caller )
    return
end
 
function ENT:Think()
	local deltaT = RealTime() - self.delta
	self.delta = RealTime()
	self.curT = self.curT + deltaT
	
	local pos = self.travelDir*self.curT*self.spd
	self:SetPos(self.startingPos + pos)
	self:SetAngles(self.angle)
	self:NextThink( CurTime() )
	rm_ind = {}
	for i, crate in pairs(self.ships) do
		if IsValid(crate) and crate:IsPlayerHolding() then
			constraint.RemoveConstraints(crate, "Weld")
			self.ships[i] = nil
		end
	end
	
	if not self:IsInWorld() then
		self:Remove() --die once we're out of world
	end
	return true
end
