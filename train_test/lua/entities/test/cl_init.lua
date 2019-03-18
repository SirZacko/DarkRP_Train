include('shared.lua')

function ENT:Draw()
    -- self.BaseClass.Draw(self) -- Overrides Draw
    --self:DrawEntityOutline( 1.0 ) -- Draw an outline of 1 world unit.
    self:DrawModel() -- Draws Model Client Side
    --AddWorldTip( self:EntIndex(), "BATHTUB TIME!", 0.5, self:GetPos(), self  )
    -- This is not required, infact if you're hosting a different gamemode, I suggest you remove this, because I think this might be only in Sandbox.
end