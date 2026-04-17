local R3D = R3D or {} 

R3D.DefaultFont = "re.body"
R3D.DefaultColor = Color(255, 255, 255)
R3D.EnableShadows = true
R3D.ShadowOffset = 2
R3D.ShadowColor = Color(0, 0, 0, 150)
R3D.GlobalScale = 0.1

R3D.Cache = {
    fonts = {},
    matrixStack = {}
}

local function WorldToScreen(pos)
    local screen = pos:ToScreen()
    return screen.x, screen.y, screen.visible
end

local function CalcTextSize(text, font, scale)
    surface.SetFont(font)
    local w, h = surface.GetTextSize(text)
    return w * scale, h * scale
end

local function GetBillboardAngles(pos, mode)
    local camPos = EyePos()
    local dir = (pos - camPos):GetNormalized()
    local ang = dir:Angle()
    ang:RotateAroundAxis(ang:Right(), 90)
    ang:RotateAroundAxis(ang:Up(), 90)
    if mode == "horizontal" then
        ang.p = 0
        ang.r = 0
    elseif mode == "vertical" then
        ang.y = 0
        ang.r = 0
    end
    return ang
end


--[[
    Text rendering in 3D
    pos       - Vector position in the world
    text      - string
    color     - Color (optional)
    font      - font name (optional)
    align     - TEXT_ALIGN_LEFT/CENTER/RIGHT, TEXT_ALIGN_TOP/CENTER/BOTTOM
    scale     - size multiplier (optional)
    billboard - true/false/"horizontal"/"vertical" (optional)
    shadow    - draw a shadow? (optional, default from R3D.EnableShadows)
]]
function R3D.Text(pos, text, color, font, align, scale, billboard, shadow)
    if not pos or not text then return end

    color = color or R3D.DefaultColor
    font = font or R3D.DefaultFont
    align = align or TEXT_ALIGN_LEFT
    scale = (scale or 1) * R3D.GlobalScale
    billboard = billboard or false
    shadow = (shadow == nil) and R3D.EnableShadows or shadow

    local ang = angle_zero
    if billboard then
        ang = GetBillboardAngles(pos, billboard == true and "full" or billboard)
    end

    cam.Start3D2D(pos, ang, scale)
        if shadow then
            local shadowCol = R3D.ShadowColor
            draw.SimpleText(text, font, R3D.ShadowOffset, R3D.ShadowOffset, shadowCol, align, align)
        end
        draw.SimpleText(text, font, 0, 0, color, align, align)
    cam.End3D2D()
end

--[[
    Drawing a rectangle (filled or outline).
    pos    - Vector позиция
    width  - width
    height - height
    color  - Color
    angle  - rotation angle (optional, default 0)
    outline- outline thickness (nil or false = fill, number = outline)
    billboard - как у Text
]]
function R3D.Rect(pos, width, height, color, angle, outline, billboard)
    if not pos or width <= 0 or height <= 0 then return end

    angle = angle or 0
    color = color or R3D.DefaultColor
    local ang = angle_zero
    if billboard then
        ang = GetBillboardAngles(pos, billboard == true and "full" or billboard)
    end

    cam.Start3D2D(pos, ang, 1)
        surface.SetDrawColor(color)
        if outline then
            surface.DrawOutlinedRect(0, 0, width, height, outline)
        else
            surface.DrawRect(0, 0, width, height)
        end
    cam.End3D2D()
end

--[[
    Drawing a circle/ellipse.
    pos      - Vector
    radius   - radius
    color    - Color
    segments - number of segments (32 by default)
    angle    - angle of rotation (plane)
    outline  - contour thickness
    billboard
]]
function R3D.Circle(pos, radius, color, segments, angle, outline, billboard)
    if not pos or radius <= 0 then return end

    segments = segments or 32
    color = color or R3D.DefaultColor
    angle = angle or 0
    local ang = angle_zero
    if billboard then
        ang = GetBillboardAngles(pos, billboard == true and "full" or billboard)
    end

    cam.Start3D2D(pos, ang, 1)
        surface.SetDrawColor(color)
        if outline then
            surface.DrawCircle(0, 0, radius, color.r, color.g, color.b, color.a, segments, outline)
        else
            surface.DrawCircle(0, 0, radius, color.r, color.g, color.b, color.a, segments)
        end
    cam.End3D2D()
end

--[[
    Drawing a line between two points.
    startPos, endPos - Vector
    color - Color
    width - line thickness in pixels (independent of distance)
]]
function R3D.Line(startPos, endPos, color, width)
    if not startPos or not endPos then return end
    color = color or R3D.DefaultColor
    width = width or 1

    render.DrawLine(startPos, endPos, color, false)
end

--[[
    Rendering a sprite (from Material) in 3D.
    pos      - Vector
    material - IMaterial or the path to the texture
    width, height - dimensions (if nil, then 1x1)
    color    - Color
    angle    - angle
    billboard
]]
function R3D.Sprite(pos, material, width, height, color, angle, billboard)
    if not pos or not material then return end

    if type(material) == "string" then
        material = Material(material)
    end
    width = width or 64
    height = height or 64
    color = color or R3D.DefaultColor
    angle = angle or 0
    local ang = angle_zero
    if billboard then
        ang = GetBillboardAngles(pos, billboard == true and "full" or billboard)
    end

    cam.Start3D2D(pos, ang, 1)
        surface.SetMaterial(material)
        surface.SetDrawColor(color)
        surface.DrawTexturedRectRotated(0, 0, width, height, angle)
    cam.End3D2D()
end

--[[
    Drawing a rectangle with a gradient.
    pos, width, height, angle, billboard как у Rect.
    gradient - таблица с параметрами:
        { type = "horizontal" или "vertical",
          start = Color(),
          end   = Color() }
]]
function R3D.RectGradient(pos, width, height, gradient, angle, billboard)
    if not pos or not gradient then return end

    local ang = angle_zero
    if billboard then
        ang = GetBillboardAngles(pos, billboard == true and "full" or billboard)
    end

    cam.Start3D2D(pos, ang, 1)
        draw.RoundedBox(0, 0, 0, width, height, gradient.start)
        surface.SetDrawColor(gradient.start)
        surface.DrawRect(0, 0, width, height)
        if gradient.type == "horizontal" then
            surface.DrawTexturedRectRotated(0, 0, width, height, 0)
        end
        -- TODO: implement the gradient correctly if necessary
    cam.End3D2D()
end

function R3D.PushMatrix()
    local mat = Matrix()
    mat:Set(unpack(R3D.Cache.matrixStack[#R3D.Cache.matrixStack] or {}))
    table.insert(R3D.Cache.matrixStack, mat)
    cam.PushModelMatrix(mat)
end

function R3D.PopMatrix()
    if #R3D.Cache.matrixStack > 0 then
        table.remove(R3D.Cache.matrixStack)
        cam.PopModelMatrix()
    end
end

function R3D.Translate(pos)
    local current = R3D.Cache.matrixStack[#R3D.Cache.matrixStack]
    if current then
        current:Translate(pos)
        cam.PopModelMatrix()
        cam.PushModelMatrix(current)
    end
end

function R3D.Rotate(ang)
    local current = R3D.Cache.matrixStack[#R3D.Cache.matrixStack]
    if current then
        current:Rotate(ang)
        cam.PopModelMatrix()
        cam.PushModelMatrix(current)
    end
end

function R3D.Scale(vec)
    local current = R3D.Cache.matrixStack[#R3D.Cache.matrixStack]
    if current then
        current:Scale(vec)
        cam.PopModelMatrix()
        cam.PushModelMatrix(current)
    end
end

R3D.RenderQueue = R3D.RenderQueue or {}

function R3D.QueueAdd(item)
    table.insert(R3D.RenderQueue, item)
end

function R3D.QueueClear()
    R3D.RenderQueue = {}
end

function R3D.QueueRender()
    for _, item in ipairs(R3D.RenderQueue) do
        if item.type == "text" then
            R3D.Text(item.pos, item.text, item.color, item.font, item.align, item.scale, item.billboard, item.shadow)
        elseif item.type == "rect" then
            R3D.Rect(item.pos, item.w, item.h, item.color, item.angle, item.outline, item.billboard)
        elseif item.type == "circle" then
            R3D.Circle(item.pos, item.radius, item.color, item.segments, item.angle, item.outline, item.billboard)
        elseif item.type == "sprite" then
            R3D.Sprite(item.pos, item.mat, item.w, item.h, item.color, item.angle, item.billboard)
        end
    end
end

function R3D.Above(target, offset)
    offset = offset or 0
    local pos
    if type(target) == "Vector" then
        pos = target
    elseif IsValid(target) then
        pos = target:GetPos() + target:OBBCenter()
    else
        return Vector(0,0,0)
    end
    return pos + Vector(0, 0, offset)
end

function R3D.InFront(target, distance)
    distance = distance or 50
    local pos, ang
    if IsValid(target) then
        pos = target:GetPos()
        ang = target:GetAngles()
    else
        return Vector(0,0,0)
    end
    return pos + ang:Forward() * distance
end

hook.Add("PostDrawOpaqueRenderables", "re_Render3D_Queue", function()
    if #R3D.RenderQueue > 0 then
        R3D.QueueRender()
    end
end)

re.Render3D = R3D

-- Examples:
--[[
    -- Adding text above the player's head
    hook.Add("HUDPaint", "My3D2D", function()
        for _, ply in ipairs(player.GetAll()) do
            if ply == LocalPlayer() then continue end
            local pos = ply:GetPos() + Vector(0,0,80)
            re.Render3D.Text(pos, ply:Nick(), Color(255,200,100), "re.h1", TEXT_ALIGN_CENTER, 1, true, true)
        end
    end)

    -- Or with a queue:
    re.Render3D.QueueClear()
    for _, ply in ipairs(player.GetAll()) do
        re.Render3D.QueueAdd({
            type = "text",
            pos = ply:GetPos() + Vector(0,0,80),
            text = ply:Nick(),
            color = Color(255,200,100),
            font = "re.h1",
            align = TEXT_ALIGN_CENTER,
            scale = 1,
            billboard = true,
            shadow = true
        })
    end
    -- The rendering will occur automatically in PostDrawOpaqueRenderables
]]