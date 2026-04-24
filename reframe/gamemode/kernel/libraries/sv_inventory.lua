util.AddNetworkString("InvData")
util.AddNetworkString("InvPickup")
util.AddNetworkString("InvDrop")
util.AddNetworkString("InvMove")
util.AddNetworkString("InvUse")
util.AddNetworkString("InvRequestData")

hook.Add("PlayerInitialSpawn", "InitInventory", function(ply)
    ply.Inventory = {
        backpack = {},
        equipped = {weapon = nil, armor = nil, accessory = nil},
        weight = 0,
        maxWeight = 20
    }
    for x = 1, 8 do
        ply.Inventory.backpack[x] = {}
        for y = 1, 4 do
            ply.Inventory.backpack[x][y] = nil
        end
    end

    ply:GiveItem("apple", 1, 1)
    ply:GiveItem("sword", 3, 1)
end)

local plymeta = FindMetaTable("Player")

function plymeta:GiveItem(itemID, startX, startY)
    local item = GetItemData(itemID)
    if not item then return false end
    local w, h = item.size[1], item.size[2]

    -- Проверка, что все ячейки свободны
    for x = startX, startX + w - 1 do
        for y = startY, startY + h - 1 do
            if self.Inventory.backpack[x] and self.Inventory.backpack[x][y] then
                return false
            end
        end
    end

    -- Занимаем ячейки
    for x = startX, startX + w - 1 do
        for y = startY, startY + h - 1 do
            if not self.Inventory.backpack[x] then self.Inventory.backpack[x] = {} end
            self.Inventory.backpack[x][y] = {id = itemID, parent = nil}
        end
    end

    self:UpdateWeight()
    self:SendInventory()
    return true
end

function plymeta:UpdateWeight()
    local total = 0
    for x = 1, 8 do
        for y = 1, 4 do
            local cell = self.Inventory.backpack[x] and self.Inventory.backpack[x][y]
            if cell then
                local item = GetItemData(cell.id)
                total = total + (item and item.weight or 0)
            end
        end
    end
    self.Inventory.weight = total
end

function plymeta:SendInventory()
    net.Start("InvData")
    net.WriteTable(self.Inventory)
    net.Send(self)
end

function CreateWorldItem(itemID, pos, owner)
    local itemDef = GetItemData(itemID)
    if not itemDef then return end

    local ent = ents.Create("re_item")
    if not IsValid(ent) then return end

    ent:SetData(itemDef.model)     
    ent:SetPos(pos)
    ent:SetItemID(itemID)          
    ent:SetPrintName(itemDef.name)
    ent:SetPrice(itemDef.price or 0)
    if IsValid(owner) then
        ent:SetItemOwner(owner)
    end
    ent:Spawn()
    ent:Activate()

    -- Звук появления
    local matType = itemDef.materialType or MAT_WOOD
    local soundName = string.format("physics/%s/box_impact_soft%d.wav", 
        util.EnumToString(matType):lower():match("^%a+"), math.random(1,2))
    ent:EmitSound(soundName)

    return ent
end

net.Receive("InvPickup", function(len, ply)
    local ent = net.ReadEntity()
    if not IsValid(ent) or ent:GetClass() ~= "re_item" then return end
    local itemID = ent:GetItemID()
    if not itemID then return end

    for x = 1, 8 do
        for y = 1, 4 do
            if ply:GiveItem(itemID, x, y) then
                ent:Break()
                return
            end
        end
    end
end)

net.Receive("InvDrop", function(len, ply)
    local data = net.ReadTable()
    local itemDef = GetItemData(data.itemID)
    if not itemDef then return end

    local pos = ply:GetPos() + ply:GetForward() * 50 + Vector(0, 0, 20)
    local dropped = CreateWorldItem(data.itemID, pos, ply)
    if IsValid(dropped) then
        local phys = dropped:GetPhysicsObject()
        if IsValid(phys) then
            phys:ApplyForceCenter(ply:GetForward() * 300 + Vector(0, 0, 150))
        end
    end

    if data.type == "backpack" then
        local w, h = itemDef.size[1], itemDef.size[2]
        for x = data.x, data.x + w - 1 do
            for y = data.y, data.y + h - 1 do
                if ply.Inventory.backpack[x] then
                    ply.Inventory.backpack[x][y] = nil
                end
            end
        end
    elseif data.type == "equipped" then
        ply.Inventory.equipped[data.slot] = nil
    end
    ply:UpdateWeight()
    ply:SendInventory()
end)

net.Receive("InvMove", function(len, ply)
    local data = net.ReadTable()
    -- Здесь можно реализовать перемещение между слотами, но для простоты оставим заглушку
end)

net.Receive("InvUse", function(len, ply)
    local data = net.ReadTable()
    local item = GetItemData(data.itemID)
    if item and item.usable and item.use_function then
        local success = item.use_function(ply)
        if success then
            if data.type == "backpack" then
                local w, h = item.size[1], item.size[2]
                for x = data.x, data.x + w - 1 do
                    for y = data.y, data.y + h - 1 do
                        if ply.Inventory.backpack[x] then
                            ply.Inventory.backpack[x][y] = nil
                        end
                    end
                end
            elseif data.type == "equipped" then
                ply.Inventory.equipped[data.slot] = nil
            end
            ply:UpdateWeight()
            ply:SendInventory()
        end
    end
end)

net.Receive("InvRequestData", function(len, ply)
    ply:SendInventory()
end)

concommand.Add("re_giveitem", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local itemID = args[1]
    if not itemID or not GetItemData(itemID) then
        ply:PrintMessage(HUD_PRINTTALK, "Использование: re_giveitem <id_предмета> (apple, sword, helmet, ring)")
        return
    end
    local success = ply:GiveItem(itemID, 1, 1)
    if success then
        ply:PrintMessage(HUD_PRINTTALK, "Вы получили " .. GetItemData(itemID).name)
    else
        ply:PrintMessage(HUD_PRINTTALK, "Нет свободного места в инвентаре")
    end
end)

concommand.Add("re_createitem", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local itemID = args[1]
    if not itemID or not GetItemData(itemID) then
        ply:PrintMessage(HUD_PRINTTALK, "Использование: re_createitem <id_предмета>")
        return
    end
    local pos = ply:GetPos() + ply:GetForward() * 100
    CreateWorldItem(itemID, pos, ply)
    ply:PrintMessage(HUD_PRINTTALK, "Предмет " .. GetItemData(itemID).name .. " создан в мире")
end)

print("[Инвентарь] Серверная часть загружена")
