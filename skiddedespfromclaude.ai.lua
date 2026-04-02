local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local Camera      = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local CFG = {
    BorderColor  = Color3.fromRGB(173, 216, 230),
    OutlineColor = Color3.fromRGB(0, 0, 0),
    BorderThick  = 1,
    OutlineThick = 1,
    NameColor    = Color3.fromRGB(255, 255, 255),
    NameSize     = 13,
}

local DrawFade = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/elon2088/diddledraws/refs/heads/main/faddigleadefromthestrooging.lua"
))()

local Box = {}
Box.__index = Box

function Box.new()
    local self = setmetatable({}, Box)

    self._outer            = Drawing.new("Square")
    self._outer.Visible    = false
    self._outer.Filled     = false
    self._outer.Color      = CFG.OutlineColor
    self._outer.Thickness  = CFG.OutlineThick

    self._border           = Drawing.new("Square")
    self._border.Visible   = false
    self._border.Filled    = false
    self._border.Color     = CFG.BorderColor
    self._border.Thickness = CFG.BorderThick

    self._inner            = Drawing.new("Square")
    self._inner.Visible    = false
    self._inner.Filled     = false
    self._inner.Color      = CFG.OutlineColor
    self._inner.Thickness  = CFG.OutlineThick

    self._name             = Drawing.new("Text")
    self._name.Visible     = false
    self._name.Color       = CFG.NameColor
    self._name.Size        = CFG.NameSize
    self._name.Center      = true
    self._name.Outline     = true
    self._name.OutlineColor = CFG.OutlineColor
    self._name.Text        = ""

    return self
end

function Box:Update(pos, size, displayName)
    local x, y, w, h = pos.X, pos.Y, size.X, size.Y

    self._outer.Position  = Vector2.new(x - 1, y - 1)
    self._outer.Size      = Vector2.new(w + 2,  h + 2)
    self._outer.Visible   = true

    self._border.Position = Vector2.new(x, y)
    self._border.Size     = Vector2.new(w, h)
    self._border.Visible  = true

    self._inner.Position  = Vector2.new(x + 1, y + 1)
    self._inner.Size      = Vector2.new(w - 2, h - 2)
    self._inner.Visible   = true

    if displayName then
        self._name.Text     = displayName
        self._name.Position = Vector2.new(x + w * 0.5, y - CFG.NameSize - 2)
        self._name.Visible  = true
    end
end

function Box:SetAlpha(t)
    local visible             = t < 1
    self._outer.Visible       = visible
    self._outer.Transparency  = t
    self._border.Visible      = visible
    self._border.Transparency = t
    self._inner.Visible       = visible
    self._inner.Transparency  = t
    self._name.Visible        = visible
    self._name.Transparency   = t
end

function Box:Hide()
    self._outer.Visible  = false
    self._border.Visible = false
    self._inner.Visible  = false
    self._name.Visible   = false
end

function Box:Destroy()
    self._outer:Remove()
    self._border:Remove()
    self._inner:Remove()
    self._name:Remove()
end

local OFFSETS = {
    Vector3.new( 1,  1,  1), Vector3.new(-1,  1,  1),
    Vector3.new( 1, -1,  1), Vector3.new(-1, -1,  1),
    Vector3.new( 1,  1, -1), Vector3.new(-1,  1, -1),
    Vector3.new( 1, -1, -1), Vector3.new(-1, -1, -1),
}

local function GetBoundingBox(character)
    local minX, minY =  math.huge,  math.huge
    local maxX, maxY = -math.huge, -math.huge
    local valid      = false
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local cf = part.CFrame
            local hX = part.Size.X * 0.5
            local hY = part.Size.Y * 0.5
            local hZ = part.Size.Z * 0.5
            for _, o in ipairs(OFFSETS) do
                local screen, vis = Camera:WorldToViewportPoint(
                    cf * Vector3.new(o.X * hX, o.Y * hY, o.Z * hZ)
                )
                if vis then
                    valid = true
                    if screen.X < minX then minX = screen.X end
                    if screen.Y < minY then minY = screen.Y end
                    if screen.X > maxX then maxX = screen.X end
                    if screen.Y > maxY then maxY = screen.Y end
                end
            end
        end
    end
    if not valid then return nil end
    return Vector2.new(minX, minY), Vector2.new(maxX - minX, maxY - minY)
end

local PlayerHandler = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/elon2088/diddledraws/refs/heads/main/handlebar.lua"
))()

local Destroy = PlayerHandler.init({
    LocalPlayer    = LocalPlayer,
    Players        = Players,
    RunService     = RunService,
    Box            = Box,
    GetBoundingBox = GetBoundingBox,
    DrawFade       = DrawFade,
})
