local ply = LocalPlayer()
local invFrame = nil
local inventoryOpen = false

-- ------------------------------------------------------------
-- Создание материалов для иконок (если нет файлов)
-- ------------------------------------------------------------
for id, data in pairs(ITEM_TYPES) do
    if not file.Exists(data.icon .. ".png", "GAME") and not file.Exists(data.icon .. ".vtf", "GAME") then
        local mat = CreateMaterial("item_icon_" .. id, "UnlitGeneric", {["$basetexture"] = "vgui/white", ["$color"] = data.color})
        data.material = mat
    else
        data.material = Material(data.icon)
    end
end

-- ------------------------------------------------------------
-- Панель слота инвентаря
-- ------------------------------------------------------------
local PANEL = {}
AccessorFunc(PANEL, "m_Coords", "Coords")
AccessorFunc(PANEL, "m_ItemPanel", "ItemPanel")
AccessorFunc(PANEL, "m_EquipSlot", "EquipSlot")

function PANEL:Init()
    self:SetSize(32, 32)
    self:SetItemPanel(nil)
    self:SetEquipSlot(nil)
    self:SetCoords({x = 0, y = 0})
    self:SetDroppable("invitem")
    self.Hover = false
    self.DragHover = false
end

function PANEL:OnMouseEnter()
    self.Hover = true
end

function PANEL:OnMouseExit()
    self.Hover = false
    self.DragHover = false
end

function PANEL:OnDrop(dragPanel)
    if not dragPanel then return end
    local item = dragPanel:GetItem()
    if not item then return end
    local w, h = item:GetSize()
    local x0, y0 = self:GetCoords().x, self:GetCoords().y
    local slotType = self:GetEquipSlot()

    if slotType then
        if item:GetEquipSlot() == slotType then
            if item:GetParentPanel() then
                item:GetParentPanel():ClearItem()
            end
            self:SetItemPanel(item)
            item:SetParentPanel(self)
            item:SetPos(self:GetPos())
            net.Start("InvMove")
            net.WriteTable({type = "equip", slot = slotType, itemID = item:GetItemID()})
            net.SendToServer()
        end
    else
        local full = false
        for dx = 0, w - 1 do
            for dy = 0, h - 1 do
                local slot = getSlotAt(x0 + dx, y0 + dy)
                if slot and slot:GetItemPanel() then
                    full = true
                    break
                end
            end
            if full then break end
        end
        if not full then
            if item:GetParentPanel() then
                item:GetParentPanel():ClearItem()
            end
            for dx = 0, w - 1 do
                for dy = 0, h - 1 do
                    local slot = getSlotAt(x0 + dx, y0 + dy)
                    if slot then slot:SetItemPanel(item) end
                end
            end
            item:SetParentPanel(self)
            item:SetPos(self:GetPos())
            net.Start("InvMove")
            net.WriteTable({type = "move", from = item:GetLastParentCoords(), to = {x = x0, y = y0}})
            net.SendToServer()
        end
    end
end

function PANEL:ClearItem()
    self:SetItemPanel(nil)
end

function PANEL:Paint(w, h)
    local col = self.Hover and Color(100, 100, 150, 200) or Color(50, 50, 60, 200)
    if self:GetItemPanel() then
        col = Color(80, 80, 100, 220)
    end
    if self.DragHover then
        col = Color(30, 150, 30, 200)
    end
    surface.SetDrawColor(col)
    surface.DrawRect(0, 0, w, h)
    surface.SetDrawColor(200, 200, 200, 80)
    surface.DrawOutlinedRect(0, 0, w, h)
    if self:GetEquipSlot() then
        surface.SetDrawColor(255, 255, 255, 100)
        surface.DrawRect(2, 2, 10, 10)
    end
end
vgui.Register("InvSlot", PANEL, "DPanel")

-- ------------------------------------------------------------
-- Панель предмета (перетаскиваемый)
-- ------------------------------------------------------------
local PANEL = {}
AccessorFunc(PANEL, "m_ItemID", "ItemID")
AccessorFunc(PANEL, "m_ItemData", "ItemData")
AccessorFunc(PANEL, "m_ParentPanel", "ParentPanel")
AccessorFunc(PANEL, "m_LastParentCoords", "LastParentCoords")

function PANEL:Init()
    self:SetSize(32, 32)
    self:SetItemID(nil)
    self:SetItemData(nil)
    self:SetParentPanel(nil)
    self:SetLastParentCoords(nil)
    self:SetDraggable(true)
    self:SetDroppable(false)
end

function PANEL:SetItem(itemID, itemData)
    self:SetItemID(itemID)
    self:SetItemData(itemData)
    self:SetSize(itemData.size[1] * 32, itemData.size[2] * 32)
end

function PANEL:GetItem()
    return self
end

function PANEL:GetSize()
    local data = self:GetItemData()
    return data.size[1], data.size[2]
end

function PANEL:GetEquipSlot()
    return self:GetItemData().equipSlot
end

function PANEL:OnDragStart()
    self.Dragging = true
    self:SetMouseInputEnabled(false)
end

function PANEL:OnDragEnd()
    self.Dragging = false
    self:SetMouseInputEnabled(true)
    local dropPanel = self:GetDropTarget()
    if not dropPanel or not dropPanel.OnDrop then
        local frame = self:GetParent()
        while frame and frame.GetDropTarget == nil do frame = frame:GetParent() end
        if frame ~= invFrame then
            net.Start("InvDrop")
            local data = {type = self:GetParentPanel():GetEquipSlot() and "equipped" or "backpack", itemID = self:GetItemID()}
            if data.type == "backpack" then
                local coords = self:GetLastParentCoords()
                data.x, data.y = coords.x, coords.y
            else
                data.slot = self:GetParentPanel():GetEquipSlot()
            end
            net.WriteTable(data)
            net.SendToServer()
            self:Remove()
            if self:GetParentPanel() then
                self:GetParentPanel():ClearItem()
            end
        end
    end
end

function PANEL:OnMousePressed(code)
    if code == MOUSE_RIGHT and self:GetItemData().usable then
        net.Start("InvUse")
        local data = {type = self:GetParentPanel():GetEquipSlot() and "equipped" or "backpack", itemID = self:GetItemID()}
        if data.type == "backpack" then
            local coords = self:GetLastParentCoords()
            data.x, data.y = coords.x, coords.y
        else
            data.slot = self:GetParentPanel():GetEquipSlot()
        end
        net.WriteTable(data)
        net.SendToServer()
        self:Remove()
        if self:GetParentPanel() then
            self:GetParentPanel():ClearItem()
        end
    end
end

function PANEL:Paint(w, h)
    local data = self:GetItemData()
    if data.material then
        surface.SetMaterial(data.material)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(0, 0, w, h)
    else
        draw.SimpleText(data.name, "DermaDefault", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    if self.Dragging then
        surface.SetDrawColor(255, 255, 255, 150)
        surface.DrawOutlinedRect(0, 0, w, h)
    end
end
vgui.Register("InvItem", PANEL, "DPanel")

-- ------------------------------------------------------------
-- Основное окно инвентаря
-- ------------------------------------------------------------
local slots = {}
local slotPanels = {}

function getSlotAt(x, y)
    if x >= 1 and x <= 8 and y >= 1 and y <= 4 then
        return slots[x] and slots[x][y]
    end
    return nil
end

local function refreshInventory()
    if not ply.Inventory then return end

    for x = 1, 8 do
        for y = 1, 4 do
            if slots[x][y] and slots[x][y]:GetItemPanel() then
                slots[x][y]:GetItemPanel():Remove()
                slots[x][y]:SetItemPanel(nil)
            end
        end
    end

    for x = 1, 8 do
        for y = 1, 4 do
            local cell = ply.Inventory.backpack[x] and ply.Inventory.backpack[x][y]
            if cell and cell.id then
                if not slots[x][y]:GetItemPanel() then
                    local itemDef = GetItemData(cell.id)
                    if itemDef then
                        local w, h = itemDef.size[1], itemDef.size[2]
                        local occupied = false
                        for dx = 0, w - 1 do
                            for dy = 0, h - 1 do
                                local slot = getSlotAt(x + dx, y + dy)
                                if slot and slot:GetItemPanel() then
                                    occupied = true
                                    break
                                end
                            end
                            if occupied then break end
                        end
                        if not occupied then
                            local itemWidget = vgui.Create("InvItem")
                            itemWidget:SetItem(cell.id, itemDef)
                            itemWidget:SetParentPanel(slots[x][y])
                            itemWidget:SetLastParentCoords({x = x, y = y})
                            itemWidget:SetPos(slots[x][y]:GetPos())
                            for dx = 0, w - 1 do
                                for dy = 0, h - 1 do
                                    local slot = getSlotAt(x + dx, y + dy)
                                    if slot then slot:SetItemPanel(itemWidget) end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    for slot, pnl in pairs(slotPanels) do
        if pnl:GetItemPanel() then
            pnl:GetItemPanel():Remove()
            pnl:SetItemPanel(nil)
        end
        if ply.Inventory.equipped and ply.Inventory.equipped[slot] then
            local itemID = ply.Inventory.equipped[slot]
            local data = GetItemData(itemID)
            if data then
                local itemWidget = vgui.Create("InvItem")
                itemWidget:SetItem(itemID, data)
                itemWidget:SetParentPanel(pnl)
                itemWidget:SetPos(pnl:GetPos())
                pnl:SetItemPanel(itemWidget)
            end
        end
    end
end

local function CreateInventoryWindow()
    if invFrame and invFrame:IsValid() then
        invFrame:Close()
        return
    end

    invFrame = vgui.Create("DFrame")
    invFrame:SetTitle("Инвентарь")
    invFrame:SetSize(500, 450)
    invFrame:Center()
    invFrame:MakePopup()
    invFrame:SetDraggable(true)
    invFrame:SetDeleteOnClose(true)
    invFrame.OnClose = function()
        inventoryOpen = false
        invFrame = nil
    end
    inventoryOpen = true

    local content = vgui.Create("DPanel", invFrame)
    content:Dock(FILL)
    content.Paint = function(_, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 50, 240))
    end

    local weightPanel = vgui.Create("DPanel", content)
    weightPanel:SetHeight(40)
    weightPanel:Dock(TOP)
    weightPanel:DockMargin(5, 5, 5, 5)
    weightPanel.Paint = function(_, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 80, 200))
        local curW = ply.Inventory.weight or 0
        local maxW = ply.Inventory.maxWeight or 20
        local percent = math.Clamp(curW / maxW, 0, 1)
        draw.RoundedBox(4, 4, 4, w - 8, h - 8, Color(30, 30, 40))
        local colorBar = percent > 0.9 and Color(200, 50, 50) or Color(50, 200, 50)
        draw.RoundedBox(4, 4, 4, (w - 8) * percent, h - 8, colorBar)
        draw.SimpleText(string.format("Вес: %.1f / %.1f", curW, maxW), "DermaDefault", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local equipPanel = vgui.Create("DPanel", content)
    equipPanel:SetWidth(100)
    equipPanel:Dock(LEFT)
    equipPanel:DockMargin(5, 5, 5, 5)
    equipPanel.Paint = function(_, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 70, 200))
        draw.SimpleText("Экипировка", "DermaDefault", w / 2, 8, color_white, TEXT_ALIGN_CENTER)
    end

    local equipList = {weapon = "Оружие", armor = "Броня", accessory = "Аксессуар"}
    local yOff = 30
    for slot, name in pairs(equipList) do
        local pnl = vgui.Create("InvSlot", equipPanel)
        pnl:SetPos(10, yOff)
        pnl:SetSize(80, 80)
        pnl:SetEquipSlot(slot)
        pnl:SetCoords({x = 0, y = 0})
        slotPanels[slot] = pnl
        yOff = yOff + 90
    end

    local gridPanel = vgui.Create("DPanel", content)
    gridPanel:Dock(FILL)
    gridPanel:DockMargin(5, 5, 5, 5)
    gridPanel.Paint = function(_, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(45, 45, 65, 200))
    end

    local startX, startY = 10, 15
    local slotSize = 32
    for x = 1, 8 do
        slots[x] = {}
        for y = 1, 4 do
            local slot = vgui.Create("InvSlot", gridPanel)
            slot:SetPos(startX + (x - 1) * slotSize, startY + (y - 1) * slotSize)
            slot:SetCoords({x = x, y = y})
            slots[x][y] = slot
        end
    end

    refreshInventory()

    local closeBtn = vgui.Create("DButton", invFrame)
    closeBtn:SetText("X")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPos(invFrame:GetWide() - 25, 5)
    closeBtn.DoClick = function() invFrame:Close() end
    closeBtn.Paint = function(_, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(150, 50, 50))
        draw.SimpleText("X", "DermaDefault", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

-- ------------------------------------------------------------
-- Сетевые события
-- ------------------------------------------------------------
net.Receive("InvData", function()
    ply.Inventory = net.ReadTable()
    if invFrame and invFrame:IsValid() then
        refreshInventory()
    end
end)

-- ------------------------------------------------------------
-- Открытие по клавише I
-- ------------------------------------------------------------
hook.Add("PlayerBindPress", "OpenInventory", function(_, bind, pressed)
    if bind == "inv" and pressed then
        net.Start("InvRequestData")
        net.SendToServer()
        CreateInventoryWindow()
        return true
    end
end)

-- ------------------------------------------------------------
-- Подбор предмета с земли (клавиша E)
-- ------------------------------------------------------------
hook.Add("StartCommand", "PickupItem", function(_, cmd)
    if ply ~= LocalPlayer() then return end
    local trace = ply:GetEyeTrace()
    if IsValid(trace.Entity) and trace.Entity:GetClass() == "re_item" then
        if cmd:KeyDown(IN_USE) then
            net.Start("InvPickup")
            net.WriteEntity(trace.Entity)
            net.SendToServer()
        end
    end
end)

-- ------------------------------------------------------------
-- Отображение названий предметов в мире
-- ------------------------------------------------------------
hook.Add("PostDrawOpaqueRenderables", "DrawItemNames", function()
    for _, ent in pairs(ents.FindByClass("re_item")) do
        if IsValid(ent) and ent:GetPos():DistToSqr(ply:GetPos()) < 40000 then
            local name = ent:GetPrintName()
            if name and name ~= "" then
                local pos = ent:GetPos() + Vector(0, 0, 20)
                local ang = (ply:GetPos() - pos):Angle()
                ang:RotateAroundAxis(ang:Up(), 90)
                cam.Start3D2D(pos, ang, 0.05)
                    draw.SimpleText(name, "DermaDefault", 0, 0, Color(255, 255, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                cam.End3D2D()
            end
        end
    end
end)

print("[Инвентарь] Клиентская часть загружена. Нажмите I для открытия.")
