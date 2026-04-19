local rec = {}
_G.rec = rec

local type    = type
local tonumber= tonumber
local tostring= tostring
local pairs   = pairs
local ipairs  = ipairs
local math_huge = math.huge
local IsValid = IsValid
local Vector  = Vector
local Angle   = Angle
local Color   = Color
local Entity  = Entity
local player  = player
local GetConVar = GetConVar
local EffectData = EffectData

local TYPE_MARKERS = {
    NIL          = 0,
    FALSE        = 1,
    TRUE         = 2,
    NUMBER       = 3,
    STRING       = 4,
    TABLE_ARRAY  = 5,
    TABLE_DICT   = 6,
    VECTOR       = 7,
    ANGLE        = 8,
    COLOR        = 9,
    ENTITY       = 10,
    PLAYER       = 11,
    CONVAR       = 12,
    PHYSOBJ      = 13,
    EFFECTDATA   = 14,
    REFERENCE    = 255,
    
    NEG_INFINITY = 253,
    POS_INFINITY = 254,
}

local ENTITY_TYPE = {
    DEFAULT = 0,
    PLAYER  = 1,
    NPC     = 2,
    WEAPON  = 3,
}

local function escape_string(s)
    s = string.gsub(s, "\\", "\\\\")
    s = string.gsub(s, "\"", "\\\"")
    s = string.gsub(s, "\n", "\\n")
    s = string.gsub(s, "\r", "\\r")
    s = string.gsub(s, "\t", "\\t")
    s = string.gsub(s, "\0", "\\0")
    return s
end

local function unescape_string(s)
    s = string.gsub(s, "\\\"", "\"")
    s = string.gsub(s, "\\\\", "\\")
    s = string.gsub(s, "\\n", "\n")
    s = string.gsub(s, "\\r", "\r")
    s = string.gsub(s, "\\t", "\t")
    s = string.gsub(s, "\\0", "\0")
    return s
end


local encode_value

local function write_byte(buf, byte)
    buf[#buf + 1] = string.char(byte)
end

local function write_string(buf, s)
    buf[#buf + 1] = s
end

function encode_value(val, buf, refs)
    local t = type(val)

    if t == "nil" then
        write_byte(buf, TYPE_MARKERS.NIL)

    elseif t == "boolean" then
        write_byte(buf, val and TYPE_MARKERS.TRUE or TYPE_MARKERS.FALSE)

    elseif t == "number" then
        if val == math_huge then
            write_byte(buf, TYPE_MARKERS.POS_INFINITY)
        elseif val == -math_huge then
            write_byte(buf, TYPE_MARKERS.NEG_INFINITY)
        else
            write_byte(buf, TYPE_MARKERS.NUMBER)
            write_string(buf, tostring(val))
            write_byte(buf, 0)
        end

    elseif t == "string" then
        write_byte(buf, TYPE_MARKERS.STRING)
        write_string(buf, escape_string(val))
        write_byte(buf, 0)

    elseif t == "table" then
        for i, ref in ipairs(refs) do
            if ref == val then
                write_byte(buf, TYPE_MARKERS.REFERENCE)
                write_string(buf, tostring(i - 1))
                write_byte(buf, 0)
                return
            end
        end

        local ref_index = #refs + 1
        refs[ref_index] = val

        local is_array = true
        local count = 0
        for k in pairs(val) do
            count = count + 1
            if type(k) ~= "number" or k < 1 or k > #val or math.floor(k) ~= k then
                is_array = false
                break
            end
        end
        if count ~= #val then
            is_array = false
        end

        if is_array then
            write_byte(buf, TYPE_MARKERS.TABLE_ARRAY)
            write_string(buf, tostring(#val))
            write_byte(buf, 0)
            for i = 1, #val do
                encode_value(val[i], buf, refs)
            end
        else
            write_byte(buf, TYPE_MARKERS.TABLE_DICT)
            local count = 0
            for _ in pairs(val) do count = count + 1 end
            write_string(buf, tostring(count))
            write_byte(buf, 0)
            for k, v in pairs(val) do
                encode_value(k, buf, refs)
                encode_value(v, buf, refs)
            end
        end

    elseif t == "Vector" then
        write_byte(buf, TYPE_MARKERS.VECTOR)
        write_string(buf, tostring(val.x))
        write_byte(buf, 0)
        write_string(buf, tostring(val.y))
        write_byte(buf, 0)
        write_string(buf, tostring(val.z))
        write_byte(buf, 0)

    elseif t == "Angle" then
        write_byte(buf, TYPE_MARKERS.ANGLE)
        write_string(buf, tostring(val.p))
        write_byte(buf, 0)
        write_string(buf, tostring(val.y))
        write_byte(buf, 0)
        write_string(buf, tostring(val.r))
        write_byte(buf, 0)

    elseif t == "Color" then
        write_byte(buf, TYPE_MARKERS.COLOR)
        write_string(buf, tostring(val.r))
        write_byte(buf, 0)
        write_string(buf, tostring(val.g))
        write_byte(buf, 0)
        write_string(buf, tostring(val.b))
        write_byte(buf, 0)
        write_string(buf, tostring(val.a))
        write_byte(buf, 0)

    elseif t == "Player" then
        if not IsValid(val) then
            encode_value(nil, buf, refs)
            return
        end
        write_byte(buf, TYPE_MARKERS.PLAYER)
        write_string(buf, tostring(val:EntIndex()))
        write_byte(buf, 0)

    elseif t == "NPC" then
        if not IsValid(val) then
            encode_value(nil, buf, refs)
            return
        end
        write_byte(buf, TYPE_MARKERS.ENTITY)
        write_string(buf, tostring(ENTITY_TYPE.NPC))
        write_byte(buf, 0)
        write_string(buf, tostring(val:EntIndex()))
        write_byte(buf, 0)

    elseif t == "Weapon" then
        if not IsValid(val) then
            encode_value(nil, buf, refs)
            return
        end
        write_byte(buf, TYPE_MARKERS.ENTITY)
        write_string(buf, tostring(ENTITY_TYPE.WEAPON))
        write_byte(buf, 0)
        write_string(buf, tostring(val:EntIndex()))
        write_byte(buf, 0)

    elseif t == "Entity" then
        if not IsValid(val) then
            encode_value(nil, buf, refs)
            return
        end
        write_byte(buf, TYPE_MARKERS.ENTITY)
        write_string(buf, tostring(ENTITY_TYPE.DEFAULT))
        write_byte(buf, 0)
        write_string(buf, tostring(val:EntIndex()))
        write_byte(buf, 0)

    elseif t == "CEffectData" then
        write_byte(buf, TYPE_MARKERS.EFFECTDATA)
        local fields = {}
        local origin = val:GetOrigin()
        if origin ~= Vector(0,0,0) then fields.o = origin end
        local angles = val:GetAngle()
        if angles ~= Angle(0,0,0) then fields.a = angles end
        local ent = val:GetEntity()
        if IsValid(ent) then fields.e = ent end
        local norm = val:GetNormal()
        if norm ~= Vector(0,0,0) then fields.n = norm end
        local mag = val:GetMagnitude()
        if mag ~= 0 then fields.m = mag end
        local rad = val:GetRadius()
        if rad ~= 0 then fields.r = rad end
        local scale = val:GetScale()
        if scale ~= 0 then fields.c = scale end
        local start = val:GetStart()
        if start ~= 0 then fields.s = start end
        local attach = val:GetAttachment()
        if attach ~= 0 then fields.h = attach end
        local surf = val:GetSurfaceProp()
        if surf ~= 0 then fields.p = surf end
        encode_value(fields, buf, refs)

    elseif t == "ConVar" then
        write_byte(buf, TYPE_MARKERS.CONVAR)
        write_string(buf, escape_string(val:GetName()))
        write_byte(buf, 0)

    elseif t == "PhysObj" then
        local parent = val:GetEntity()
        if not IsValid(parent) then
            encode_value(nil, buf, refs)
            return
        end
        local bone = -1
        for i = 1, parent:GetPhysicsObjectCount() do
            if parent:GetPhysicsObjectNum(i) == val then
                bone = i
                break
            end
        end
        write_byte(buf, TYPE_MARKERS.PHYSOBJ)
        write_string(buf, tostring(parent:EntIndex()))
        write_byte(buf, 0)
        write_string(buf, tostring(bone))
        write_byte(buf, 0)

    else
        error(string.format("rec.encode: unsupported type %s", t))
    end
end

function rec.encode(data)
    local buf = {}
    local refs = {}
    encode_value(data, buf, refs)
    return table.concat(buf)
end

local function read_byte(stream)
    local b = string.byte(stream.data, stream.pos)
    stream.pos = stream.pos + 1
    return b
end

local function read_string_until_null(stream)
    local start = stream.pos
    while stream.pos <= #stream.data do
        local b = string.byte(stream.data, stream.pos)
        if b == 0 then
            local s = string.sub(stream.data, start, stream.pos - 1)
            stream.pos = stream.pos + 1
            return s
        end
        stream.pos = stream.pos + 1
    end
    error("rec.decode: unexpected end of stream while reading string")
end

local decode_value

function decode_value(stream, refs)
    local b = read_byte(stream)
    if not b then
        error("rec.decode: unexpected end of stream")
    end

    if b == TYPE_MARKERS.NIL then
        return nil

    elseif b == TYPE_MARKERS.FALSE then
        return false

    elseif b == TYPE_MARKERS.TRUE then
        return true

    elseif b == TYPE_MARKERS.NUMBER then
        local s = read_string_until_null(stream)
        return tonumber(s) or 0

    elseif b == TYPE_MARKERS.STRING then
        local s = read_string_until_null(stream)
        return unescape_string(s)

    elseif b == TYPE_MARKERS.TABLE_ARRAY then
        local len_str = read_string_until_null(stream)
        local len = tonumber(len_str) or 0
        local t = {}
        refs[#refs + 1] = t
        for i = 1, len do
            t[i] = decode_value(stream, refs)
        end
        return t

    elseif b == TYPE_MARKERS.TABLE_DICT then
        local count_str = read_string_until_null(stream)
        local count = tonumber(count_str) or 0
        local t = {}
        refs[#refs + 1] = t
        for i = 1, count do
            local k = decode_value(stream, refs)
            local v = decode_value(stream, refs)
            t[k] = v
        end
        return t

    elseif b == TYPE_MARKERS.VECTOR then
        local x = tonumber(read_string_until_null(stream)) or 0
        local y = tonumber(read_string_until_null(stream)) or 0
        local z = tonumber(read_string_until_null(stream)) or 0
        return Vector(x, y, z)

    elseif b == TYPE_MARKERS.ANGLE then
        local p = tonumber(read_string_until_null(stream)) or 0
        local y = tonumber(read_string_until_null(stream)) or 0
        local r = tonumber(read_string_until_null(stream)) or 0
        return Angle(p, y, r)

    elseif b == TYPE_MARKERS.COLOR then
        local r = tonumber(read_string_until_null(stream)) or 255
        local g = tonumber(read_string_until_null(stream)) or 255
        local b = tonumber(read_string_until_null(stream)) or 255
        local a = tonumber(read_string_until_null(stream)) or 255
        return Color(r, g, b, a)

    elseif b == TYPE_MARKERS.ENTITY then
        local etype = tonumber(read_string_until_null(stream)) or 0
        local idx = tonumber(read_string_until_null(stream)) or -1
        local ent = Entity(idx)
        if not IsValid(ent) then return nil end
        if etype == ENTITY_TYPE.PLAYER then
            return ent
        elseif etype == ENTITY_TYPE.NPC and ent:IsNPC() then
            return ent
        elseif etype == ENTITY_TYPE.WEAPON and ent:IsWeapon() then
            return ent
        else
            return ent
        end

    elseif b == TYPE_MARKERS.PLAYER then
        local idx = tonumber(read_string_until_null(stream)) or -1
        return player.GetByID(idx)

    elseif b == TYPE_MARKERS.CONVAR then
        local name = unescape_string(read_string_until_null(stream))
        return GetConVar(name)

    elseif b == TYPE_MARKERS.PHYSOBJ then
        local entIdx = tonumber(read_string_until_null(stream)) or -1
        local bone = tonumber(read_string_until_null(stream)) or -1
        local ent = Entity(entIdx)
        if not IsValid(ent) then return nil end
        return ent:GetPhysicsObjectNum(bone)

    elseif b == TYPE_MARKERS.EFFECTDATA then
        local fields = decode_value(stream, refs)
        local ed = EffectData()
        if fields.o then ed:SetOrigin(fields.o) end
        if fields.a then ed:SetAngles(fields.a) end
        if fields.e then ed:SetEntity(fields.e) end
        if fields.n then ed:SetNormal(fields.n) end
        if fields.m then ed:SetMagnitude(fields.m) end
        if fields.r then ed:SetRadius(fields.r) end
        if fields.c then ed:SetScale(fields.c) end
        if fields.s then ed:SetStart(fields.s) end
        if fields.h then ed:SetAttachment(fields.h) end
        if fields.p then ed:SetSurfaceProp(fields.p) end
        return ed

    elseif b == TYPE_MARKERS.REFERENCE then
        local idx_str = read_string_until_null(stream)
        local idx = tonumber(idx_str) or 0
        return refs[idx + 1]

    elseif b == TYPE_MARKERS.POS_INFINITY then
        return math_huge
    elseif b == TYPE_MARKERS.NEG_INFINITY then
        return -math_huge

    else
        error(string.format("rec.decode: unknown type marker %d at position %d", b, stream.pos))
    end
end

function rec.decode(str)
    if type(str) ~= "string" then
        error("rec.decode: expected string, got " .. type(str))
    end
    if #str == 0 then
        return nil
    end
    local stream = { data = str, pos = 1 }
    local refs = {}
    return decode_value(stream, refs)
end

return rec