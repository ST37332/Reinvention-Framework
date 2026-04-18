ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.Author = ""
ENT.PrintName = "Item"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.UsableInVehicle = true

function ENT:SetupDataTables()
	self:DTVar("Int", 0, "index")
end