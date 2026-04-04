local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Camera      = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local CFG = {
    BorderColor  = Color3.fromRGB(255, 255, 255),
    OutlineColor = Color3.fromRGB(0, 0, 0),
    BorderThick  = 2,
    OutlineThick = 1,
    NameColor    = Color3.fromRGB(255, 255, 255),
    NameSize     = 13,
    DistLerp     = 0.1,
    HpBarWidth   = 3,
    HpBarGap     = 3,
    HpLerp       = 0.08,
}

local function loadCustomFont(url, name)
    local ttfPath  = name .. ".ttf"
    local fontPath = name .. ".font"
    local data     = game:HttpGet(url)
    writefile(ttfPath, data)
    local fontJson = HttpService:JSONEncode({
        name  = name,
        faces = {{
            name    = "Regular",
            weight  = 400,
            style   = "normal",
            assetId = getcustomasset(ttfPath)
        }}
    })
    writefile(fontPath, fontJson)
    return Font.new(getcustomasset(fontPath), Enum.FontWeight.Regular, Enum.FontStyle.Normal)
end

local PixelFont = loadCustomFont(
    "https://github.com/elon2088/diddledraws/raw/refs/heads/main/smallest_pixel-7.ttf",
    "smallest_pixel"
)

local gui          = Instance.new("ScreenGui")
gui.Name           = "namesp"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent         = gethui and gethui() or game:GetService("CoreGui")

local DrawFade = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/elon2088/diddledraws/refs/heads/main/faddigleadefromthestrooging.lua"
))()

local function getEquippedTool(character)
    if not character then return nil end
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            return child.Name
        end
    end
    return nil
end

local function hpColor(pct)
    pct = math.clamp(pct, 0, 1)
    if pct > 0.6 then
        local t = (pct - 0.6) / 0.4
        return Color3.fromRGB(
            math.floor(180 * (1 - t) + 30 * t),
            math.floor(120 * t + 80 * (1 - t)),
            0
        )
    elseif pct > 0.35 then
        local t = (pct - 0.35) / 0.25
        return Color3.fromRGB(
            math.floor(160 * (1 - t) + 180 * t),
            math.floor(60 + 20 * t),
            0
        )
    else
        local t = pct / 0.35
        return Color3.fromRGB(
            math.floor(120 + 40 * t),
            math.floor(15 * t),
            0
        )
    end
end

local Box = {}
Box.__index = Box

function Box.new()
    local self       = setmetatable({}, Box)
    self._smoothDist = nil
    self._smoothHp   = nil

    self._outer            = Drawing.new("Square")
    self._outer.Visible    = false
    self._outer.Filled     = false
    self._outer.Color      = CFG.OutlineColor
    self._outer.Thickness  = CFG.OutlineThick + CFG.BorderThick

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

    self._hpTrack          = Drawing.new("Square")
    self._hpTrack.Visible  = false
    self._hpTrack.Filled   = true
    self._hpTrack.Color    = Color3.fromRGB(15, 15, 15)
    self._hpTrack.Thickness = 0

    self._hpFill           = Drawing.new("Square")
    self._hpFill.Visible   = false
    self._hpFill.Filled    = true
    self._hpFill.Color     = Color3.fromRGB(30, 120, 30)
    self._hpFill.Thickness = 0

    self._hpCapTop         = Drawing.new("Circle")
    self._hpCapTop.Visible = false
    self._hpCapTop.Filled  = true
    self._hpCapTop.Thickness = 0
    self._hpCapTop.NumSides  = 12

    self._hpCapBot         = Drawing.new("Circle")
    self._hpCapBot.Visible = false
    self._hpCapBot.Filled  = true
    self._hpCapBot.Thickness = 0
    self._hpCapBot.NumSides  = 12

    local label                  = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.BorderSizePixel        = 0
    label.AnchorPoint            = Vector2.new(0.5, 1)
    label.Size                   = UDim2.new(0, 300, 0, CFG.NameSize + 6)
    label.FontFace               = PixelFont
    label.TextSize               = CFG.NameSize
    label.TextColor3             = CFG.NameColor
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
    label.TextXAlignment         = Enum.TextXAlignment.Center
    label.Text                   = ""
    label.Visible                = false
    label.Parent                 = gui
    self._label                  = label

    local toolLabel                  = Instance.new("TextLabel")
    toolLabel.BackgroundTransparency = 1
    toolLabel.BorderSizePixel        = 0
    toolLabel.AnchorPoint            = Vector2.new(0.5, 0)
    toolLabel.Size                   = UDim2.new(0, 300, 0, CFG.NameSize + 6)
    toolLabel.FontFace               = PixelFont
    toolLabel.TextSize               = CFG.NameSize
    toolLabel.TextColor3             = CFG.NameColor
    toolLabel.TextStrokeTransparency = 0
    toolLabel.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
    toolLabel.TextXAlignment         = Enum.TextXAlignment.Center
    toolLabel.Text                   = ""
    toolLabel.Visible                = false
    toolLabel.Parent                 = gui
    self._toolLabel                  = toolLabel

    return self
end

function Box:Update(pos, size, displayName, dist, character, health, maxHealth)
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

    local bw  = CFG.HpBarWidth
    local gap = CFG.HpBarGap
    local bx  = x - gap - bw - 1
    local r   = math.floor(bw * 0.5)

    local pct = (health and maxHealth and maxHealth > 0)
        and math.clamp(health / maxHealth, 0, 1)
        or 1

    if not self._smoothHp then
        self._smoothHp = pct
    else
        self._smoothHp = self._smoothHp + (pct - self._smoothHp) * CFG.HpLerp
    end

    local trackH = h + 2
    local fillH  = math.max(0, math.floor(trackH * self._smoothHp))
    local fillY  = y - 1 + (trackH - fillH)
    local barColor = hpColor(self._smoothHp)

    self._hpTrack.Position = Vector2.new(bx, y - 1)
    self._hpTrack.Size     = Vector2.new(bw, trackH)
    self._hpTrack.Visible  = true

    if fillH > 0 then
        self._hpFill.Position = Vector2.new(bx, fillY)
        self._hpFill.Size     = Vector2.new(bw, fillH)
        self._hpFill.Color    = barColor
        self._hpFill.Visible  = true

        self._hpCapTop.Position  = Vector2.new(bx + r, fillY)
        self._hpCapTop.Radius    = r
        self._hpCapTop.Color     = barColor
        self._hpCapTop.Visible   = true

        self._hpCapBot.Position  = Vector2.new(bx + r, fillY + fillH)
        self._hpCapBot.Radius    = r
        self._hpCapBot.Color     = barColor
        self._hpCapBot.Visible   = true
    else
        self._hpFill.Visible    = false
        self._hpCapTop.Visible  = false
        self._hpCapBot.Visible  = false
    end

    if displayName then
        if dist then
            if not self._smoothDist then
                self._smoothDist = dist
            else
                self._smoothDist = self._smoothDist + (dist - self._smoothDist) * CFG.DistLerp
            end
            self._label.Text = displayName .. " [" .. math.floor(self._smoothDist) .. "]"
        else
            self._label.Text = displayName
        end
        self._label.Position = UDim2.fromOffset(x + w * 0.5, y - 1)
        self._label.Visible  = true
    end

    local tool = getEquippedTool(character)
    self._toolLabel.Text     = "[" .. (tool or "none") .. "]"
    self._toolLabel.Position = UDim2.fromOffset(x + w * 0.5, y + h + 1)
    self._toolLabel.Visible  = true
end

function Box:SetAlpha(t)
    local alpha = math.clamp(t, 0, 1)
    local vis = alpha > 0.01

    self._outer.Visible      = vis
    self._outer.Transparency = alpha
    self._border.Visible     = vis
    self._border.Transparency = alpha
    self._inner.Visible      = vis
    self._inner.Transparency = alpha

    self._hpTrack.Visible      = vis
    self._hpTrack.Transparency = alpha
    self._hpFill.Visible       = vis and (self._smoothHp or 1) > 0.01
    self._hpFill.Transparency  = alpha
    self._hpCapTop.Visible     = self._hpFill.Visible
    self._hpCapTop.Transparency = alpha
    self._hpCapBot.Visible     = self._hpFill.Visible
    self._hpCapBot.Transparency = alpha

    local textInv = 1 - alpha
    self._label.Visible                  = vis
    self._label.TextTransparency         = textInv
    self._label.TextStrokeTransparency   = textInv
    self._toolLabel.Visible              = vis
    self._toolLabel.TextTransparency     = textInv
    self._toolLabel.TextStrokeTransparency = textInv
end

function Box:Hide()
    self._outer.Visible     = false
    self._border.Visible    = false
    self._inner.Visible     = false
    self._hpTrack.Visible   = false
    self._hpFill.Visible    = false
    self._hpCapTop.Visible  = false
    self._hpCapBot.Visible  = false
    self._label.Visible     = false
    self._toolLabel.Visible = false
end

function Box:Destroy()
    self._outer:Remove()
    self._border:Remove()
    self._inner:Remove()
    self._hpTrack:Remove()
    self._hpFill:Remove()
    self._hpCapTop:Remove()
    self._hpCapBot:Remove()
    self._label:Destroy()
    self._toolLabel:Destroy()
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
