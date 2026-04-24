re.FACTION = re.FACTION or {}
re.FACTION.List = {}            
re.FACTION.DefaultID = nil

function re.FACTION:Register(tbl)
    if not istable(tbl) then
        ErrorNoHalt("[FACTION] Attempt to register a non-table!\n")
        return
    end
    if not tbl.uniqueID or type(tbl.uniqueID) ~= "string" then
        ErrorNoHalt("[FACTION] Faction without a unique ID, skipped.\n")
        return
    end
    if self.List[tbl.uniqueID] then
        ErrorNoHalt("[FACTION] Faction with ID '" .. tbl.uniqueID .. "' already exists. Skipped.\n")
        return
    end

    tbl.name        = tbl.name or "Unknown"
    tbl.description = tbl.description or ""
    tbl.color       = tbl.color or Color(255,255,255)
    tbl.model       = tbl.model or "models/player/kleiner.mdl"
    tbl.default     = tbl.default or false

    if tbl.default then
        if self.DefaultID and self.DefaultID ~= tbl.uniqueID then
            ErrorNoHalt(string.format(
                "[FACTION] Error: default! Already have '%s', now '%s'. The first one is left as standard.\n",
                self.DefaultID, tbl.uniqueID
            ))
            tbl.default = false
        else
            self.DefaultID = tbl.uniqueID
        end
    end
    
    team.SetUp(tbl.uniqueID, tbl.name, tbl.color, tbl.default)

    self.List[tbl.uniqueID] = tbl
end

function re.FACTION:Get(id)
    return self.List[id]
end

function re.FACTION:GetAll()
    local out = {}
    for id, fac in pairs(self.List) do
        out[id] = {
            uniqueID    = id,
            name        = fac.name,
            description = fac.description,
            color       = fac.color,
            model       = fac.model,
            default     = fac.default
        }
    end
    return out
end


if SERVER then
    if not re.FACTION.DefaultID then
        ErrorNoHalt("[FACTION] WARNING: No default faction has been selected! Players will not receive an auto-faction.\n")
    end
    
    hook.Add("PlayerInitialSpawn", "Faction.AutoAssignDefault", function(ply)
        if not ply:GetNWString("faction", nil) or ply:GetNWString("faction", "") == "" then
            if re.FACTION.DefaultID then
                ply:SetNWString("faction", re.FACTION.DefaultID)
                print(ply:Nick() .. " automatically received a faction: " .. re.FACTION.DefaultID)
            else
                print(ply:Nick() .. " did not receive a faction: no default!")
            end
        end
    end)
    
    util.AddNetworkString("FactionChangeRequest")
    
    net.Receive("FactionChangeRequest", function(len, ply)
        local requestedID = net.ReadString()
        local fac = re.FACTION:Get(requestedID)
        if not fac then
            ply:ChatPrint("[Error] There is no such faction.")
            return
        end
    
        
        ply:SetNWString("faction", requestedID)
        ply:ChatPrint("You have become: " .. fac.name)
    
        ply:KillSilent()
    end)
    
    hook.Add("PlayerSpawn", "Faction.ApplyAppearance", function(ply)
        local factionID = ply:GetNWString("faction", "")
        local fac = re.FACTION:Get(factionID)
        if not fac then return end
    
        if fac.model and util.IsValidModel(fac.model) then
            ply:SetModel(fac.model)
        end
    
        if fac.color then
            ply:SetPlayerColor(Vector(fac.color.r/255, fac.color.g/255, fac.color.b/255))
            for _, v in ipairs(ply:GetChildren()) do
                if v:IsNPC() or v:IsPlayer() then continue end
                if v.GetColor then v:SetColor(fac.color) end
            end
        end
    end)
end