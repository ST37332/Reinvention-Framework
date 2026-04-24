ITEM_TYPES = ITEM_TYPES or {}

ITEM_TYPES.apple = {
    name = "Яблоко",
    size = {1, 1},
    weight = 1,
    model = "models/props_junk/apple.mdl",
    icon = "vgui/items/apple",
    color = Color(255, 80, 80),
    usable = true,
    equip_slot = nil,
    price = 5,
    materialType = MAT_FLESH,
    use_function = function(ply)
        ply:SetHealth(math.min(ply:Health() + 20, ply:GetMaxHealth()))
        return true
    end
}

ITEM_TYPES.sword = {
    name = "Меч",
    size = {2, 1},
    weight = 3,
    model = "models/weapons/w_sword_slow.mdl",
    icon = "vgui/items/sword",
    color = Color(200, 200, 255),
    usable = false,
    equip_slot = "weapon",
    price = 50,
    materialType = MAT_METAL,
    attack_damage = 25
}

ITEM_TYPES.helmet = {
    name = "Шлем",
    size = {1, 1},
    weight = 2,
    model = "models/player/items/humans/helmet.mdl",
    icon = "vgui/items/helmet",
    color = Color(180, 180, 180),
    usable = false,
    equip_slot = "armor",
    price = 30,
    materialType = MAT_METAL,
    armor_value = 10
}

ITEM_TYPES.ring = {
    name = "Кольцо",
    size = {1, 1},
    weight = 0.5,
    model = "models/props_c17/ring.mdl",
    icon = "vgui/items/ring",
    color = Color(255, 215, 0),
    usable = false,
    equip_slot = "accessory",
    price = 15,
    materialType = MAT_PLASTIC
}

function GetItemData(id)
    return ITEM_TYPES[id]
end