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
    HpLerp       = 0.07,
    HpBarWidth   = 2,
    HpBarGap     = 2,
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
    if pct > 0.75 then
        local t = (pct - 0.75) / 0.25
        return Color3.fromRGB(
            math.floor(20  + (50  - 20)  * (1 - t)),
            math.floor(110 + (140 - 110) * t),
            20
        )
    elseif pct > 0.5 then
        local t = (pct - 0.5) / 0.25
        return Color3.fromRGB(
            math.floor(160 + (20  - 160) * t),
            math.floor(110 + (140 - 110) * t),
            15
        )
    elseif pct > 0.25 then
        local t = (pct - 0.25) / 0.25
        return Color3.fromRGB(
            math.floor(170 + (160 - 170) * (1 - t)),
            math.floor(60  + (110 - 60)  * t),
            10
        )
    else
        local t = pct / 0.25
        return Color3.fromRGB(
            math.floor(120 + (170 - 120) * t),
            math.floor(15  + (60  - 15)  * t),
            10
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

    self._inner           = Drawing.new("Square")
    self._inner.Visible   = false
    self._inner.Filled    = false
    self._inner.Color     = CFG.OutlineColor
    self._inner.Thickness = CFG.OutlineThick

    self._hpBg          = Drawing.new("Square")
    self._hpBg.Visible  = false
    self._hpBg.Filled   = true
    self._hpBg.Color    = Color3.fromRGB(0, 0, 0)
    self._hpBg.Thickness = 1

    self._hpFill         = Drawing.new("Square")
    self._hpFill.Visible = false
    self._hpFill.Filled  = true
    self._hpFill.Color   = Color3.fromRGB(30, 140, 20)
    self._hpFill.Thickness = 1

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

    if health and maxHealth and maxHealth > 0 then
        local rawPct = math.clamp(health / maxHealth, 0, 1)
        if not self._smoothHp then
            self._smoothHp = rawPct
        else
            self._smoothHp = self._smoothHp + (rawPct - self._smoothHp) * CFG.HpLerp
        end

        local bw   = CFG.HpBarWidth
        local bx   = x - CFG.HpBarGap - bw - 1
        local by   = y - 1
        local bh   = h + 2
        local fillH = math.max(1, bh * self._smoothHp)
        local fy    = by + bh - fillH

        self._hpBg.Position  = Vector2.new(bx - 1, by - 1)
        self._hpBg.Size      = Vector2.new(bw + 2,  bh + 2)
        self._hpBg.Visible   = true

        self._hpFill.Position = Vector2.new(bx, fy)
        self._hpFill.Size     = Vector2.new(bw, fillH)
        self._hpFill.Color    = hpColor(self._smoothHp)
        self._hpFill.Visible  = true
    end
end

function Box:SetAlpha(t)
    local alpha = math.clamp(t, 0, 1)
    local vis   = alpha > 0.01

    self._outer.Visible       = vis
    self._outer.Transparency  = alpha
    self._border.Visible      = vis
    self._border.Transparency = alpha
    self._inner.Visible       = vis
    self._inner.Transparency  = alpha

    self._hpBg.Visible          = vis
    self._hpBg.Transparency     = alpha
    self._hpFill.Visible        = vis
    self._hpFill.Transparency   = alpha

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
    self._hpBg.Visible      = false
    self._hpFill.Visible    = false
    self._label.Visible     = false
    self._toolLabel.Visible = false
end

function Box:Destroy()
    self._outer:Remove()
    self._border:Remove()
    self._inner:Remove()
    self._hpBg:Remove()
    self._hpFill:Remove()
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
