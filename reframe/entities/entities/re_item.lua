AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName		= L("item.baseitem")
ENT.Author			= "RE: ITEM"
ENT.Category		= "RE"

ENT.Spawnable 		= true
ENT.AdminOnly 		= true
ENT.ItemCategory    = 2
ENT.IsItem = true

ENT.RenderGroup                 = RENDERGROUP_BOTH
ENT.AutomaticFrameAdvance = false;

ENT.DoNotDuplicate = true

ENT.IsMonoItem = true

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "PrintName")
    self:NetworkVar("String", 1, "ItemID")

    self:NetworkVar("Float", 0, "Price")
    self:NetworkVar("Float", 1, "NameplateAimThreshold")


    self:NetworkVar("Entity", 0 ,"ItemOwner")
end

function ENT:SpawnFunction(ply, tr, ClassName)
    if not tr.Hit then return end

    local SpawnPos = tr.HitPos

    local ent = ents.Create(ClassName)
    ent:SetPos(SpawnPos + tr.HitNormal * 16)
    ent:Spawn()
    ent:Activate()

    return ent
end

function ENT:Initialize()
    self:SetCollisionGroup( COLLISION_GROUP_PASSABLE_DOOR )

    if( SERVER ) then
        self:SetHealth( 100 )
    end
end

if SERVER then
	function ENT:Break()
		SafeRemoveEntity( self )

		local nMatType = self:GetMaterialType()

		if nMatType == MAT_CONCRETE then
			self:EmitSound( "physics/concrete/concrete_break"..math.random( 1, 2 )..".wav" )
		elseif nMatType == MAT_FLESH then
			self:EmitSound( "physics/flesh/flesh_squishy_impact_hard"..math.random( 3, 4 )..".wav" )
		elseif nMatType == MAT_PLASTIC then
			self:EmitSound( "physics/plastic/plastic_box_break"..math.random( 1, 2 )..".wav" )
		elseif nMatType == MAT_METAL then
			self:EmitSound( "physics/metal/metal_box_break"..math.random( 1, 2 )..".wav" )
		elseif nMatType == MAT_GLASS then
			self:EmitSound( "physics/glass/glass_pottery_break"..math.random( 1, 4 )..".wav" )
		else
			self:EmitSound( "physics/wood/wood_plank_break"..math.random( 1, 4 )..".wav" )
		end
	end

	function ENT:OnTakeDamage( oDamage )
		local nDamage = oDamage:GetDamage()

		self:SetHealth( self:Health() - nDamage )
        if self:Health() <= 0 then
			self:Break()
		end
	end

    function ENT:PhysicsCollide( tData )
    end
end

function ENT:SetData(data)
    self:SetModel(data)
    self:PhysicsInit(SOLID_VPHYSICS)   
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)      
    self:SetUseType(SIMPLE_USE)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
        self:EmitSound(phys:GetMaterial()..".ImpactSoft")
    else
        self:PhysicsInitBox(Vector(-8,-8,0),Vector(8,8,16))
        self:SetSolid(SOLID_BBOX)
    end

    self:SetTrigger(true)
end

function ENT:Use(act)
    if act:KeyDown(IN_WALK) then
        if IsValid( self:GetPhysicsObject() ) then
            local ePhysObj = self:GetPhysicsObject()
            ePhysObj:EnableMotion( not ePhysObj:IsMotionEnabled() )
        end
    
        return
    end
end

if SERVER then
    concommand.Add("re_createitem",function(ply, cmd, args)
        if not IsValid(ply) then return end
        if not ply:IsSuperAdmin() then return end
    end)

    concommand.Add("re_giveitem", function(ply, cmd, args)
        if not IsValid(ply) then return end
        if not ply:IsSuperAdmin() then return end
    end)
end
