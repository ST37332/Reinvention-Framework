re.FACTION = re.FACTION or {}
re.FACTION.List = {}            
re.FACTION.DefaultID = nil

/*
    EXAMPLES

re.FACTION:Register({
  uniqueID    = "citizen",
  name        = L"jobs.name.citizen",
  description = L"jobs.desc.citizen",
  color       = Color(100, 200, 100),
  model       = "models/player/group01/male_01.mdl",
  default     = true
})

re.FACTION:Register({
  uniqueID    = "police",
  name        = L"jobs.name.police",
  description = L"jobs.desc.police",
  color       = Color(50, 50, 200),
  model       = "models/player/combine_soldier.mdl"
})
*/

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
                print(L('faction.notify.received', {player = ply:Nick(), faction = re.FACTION.DefaultID}))
            else
                print(L('faction.notify.err_rec', {player = ply:Nick()}))
            end
        end
    end)
    
    util.AddNetworkString("FactionChangeRequest")
    
    net.Receive("FactionChangeRequest", function(len, ply)
        local requestedID = net.ReadString()
        local fac = re.FACTION:Get(requestedID)
        if not fac then
            ply:ChatPrint(L("misc.error", {error = "There is no such faction."}))
            return
        end
    
        
        ply:SetNWString("faction", requestedID)
        ply:ChatPrint(L"faction.become" .. fac.name)
    
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
else
    concommand.Add("faction_menu", function()
        if not LocalPlayer():Alive() then
            chat.AddText(Color(255,100,100), L"faction.notify.alive")
            return
        end
        CreateFactionMenu()
    end)

    function CreateFactionMenu()
        if IsValid(FactionFrame) then FactionFrame:Remove() end

        local frame = vgui.Create("DFrame")
        frame:SetSize(400, 300)
        frame:Center()
        frame:SetTitle(L"faction.choosing")
        frame:MakePopup()
        frame.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, Color(30,30,30,240))
        end
        FactionFrame = frame

        local scroll = vgui.Create("DScrollPanel", frame)
        scroll:Dock(FILL)
        scroll:DockMargin(10,10,10,10)

        local currentFaction = LocalPlayer():GetNWString("faction", "")
        local factions = re.FACTION:GetAll()

        local title = vgui.Create("DLabel", scroll)
        title:SetText(L"faction.avilable")
        title:SetTextColor(Color(255,255,255))
        title:SizeToContents()
        scroll:AddItem(title)

        for id, fac in SortedPairsByMemberValue(factions, "name") do
            local panel = vgui.Create("DButton", scroll)
            panel:SetTall(40)
            panel:Dock(TOP)
            panel:DockMargin(0,2,0,2)
            panel:SetText("")

            local isCurrent = (id == currentFaction)

            panel.Paint = function(self, w, h)
                local bgColor = isCurrent and Color(60, 60, 60, 200) or Color(50,50,50,200)
                if self:IsHovered() then bgColor = Color(80,80,80,200) end
                draw.RoundedBox(4, 0, 0, w, h, bgColor)

                draw.RoundedBox(0, 0, 0, 4, h, fac.color)

                draw.DrawText(fac.name, "DermaDefault", 12, 8, fac.color, TEXT_ALIGN_LEFT)

                if isCurrent then
                    draw.DrawText(L"faction.choosed", "DermaDefault", w-10, 8, Color(150,255,150), TEXT_ALIGN_RIGHT)
                end

                if fac.default then
                    draw.DrawText(L"misc.default", "DermaDefault", 12, 22, Color(200,200,100), TEXT_ALIGN_LEFT)
                end
            end

            panel.DoClick = function()
                net.Start("FactionChangeRequest")
                    net.WriteString(id)
                net.SendToServer()
                frame:Remove()
            end

            scroll:AddItem(panel)
        end

        local closeBtn = vgui.Create("DButton", frame)
        closeBtn:SetSize(100, 25)
        closeBtn:SetPos(150, 270)
        closeBtn:SetText(L"ui.close")
        closeBtn.DoClick = function() frame:Remove() end
    end

    hook.Add("PlayerBindPress", "Faction.MenuBind", function(ply, bind)
    end)
end