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
    "https://raw.githubusercontent.com/elon2088/diddledraws/refs/heads/main/fadooglingstrooglingfadesfromdaooooo.lua"
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

local Box = {}
Box.__index = Box

local function makeStrokedFrame(parent, pos, size, strokeColor, strokeThick)
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.Position = pos
    f.Size = size
    f.Parent = parent
    local s = Instance.new("UIStroke")
    s.Color = strokeColor
    s.Thickness = strokeThick
    s.LineJoinMode = Enum.LineJoinMode.Miter
    s.Parent = f
    return f, s
end

function Box.new()
    local self       = setmetatable({}, Box)
    self._smoothDist = nil

    self._container = Instance.new("Frame")
    self._container.BackgroundTransparency = 1
    self._container.BorderSizePixel = 0
    self._container.Visible = false
    self._container.Parent = gui

    self._outer, self._outerStroke = makeStrokedFrame(
        self._container,
        UDim2.fromOffset(-1, -1),
        UDim2.new(1, 2, 1, 2),
        CFG.OutlineColor, 1
    )

    self._border, self._borderStroke = makeStrokedFrame(
        self._container,
        UDim2.fromOffset(0, 0),
        UDim2.new(1, 0, 1, 0),
        CFG.BorderColor, 1
    )

    self._inner, self._innerStroke = makeStrokedFrame(
        self._container,
        UDim2.fromOffset(1, 1),
        UDim2.new(1, -2, 1, -2),
        CFG.OutlineColor, 1
    )

    self._label = Instance.new("TextLabel")
    self._label.BackgroundTransparency = 1
    self._label.BorderSizePixel = 0
    self._label.AnchorPoint = Vector2.new(0.5, 1)
    self._label.Size = UDim2.new(0, 300, 0, CFG.NameSize + 6)
    self._label.FontFace = PixelFont
    self._label.TextSize = CFG.NameSize
    self._label.TextColor3 = CFG.NameColor
    self._label.TextStrokeTransparency = 0
    self._label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    self._label.TextXAlignment = Enum.TextXAlignment.Center
    self._label.Visible = false
    self._label.Parent = self._container

    self._toolLabel = Instance.new("TextLabel")
    self._toolLabel.BackgroundTransparency = 1
    self._toolLabel.BorderSizePixel = 0
    self._toolLabel.AnchorPoint = Vector2.new(0.5, 0)
    self._toolLabel.Size = UDim2.new(0, 300, 0, CFG.NameSize + 6)
    self._toolLabel.FontFace = PixelFont
    self._toolLabel.TextSize = CFG.NameSize
    self._toolLabel.TextColor3 = CFG.NameColor
    self._toolLabel.TextStrokeTransparency = 0
    self._toolLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    self._toolLabel.TextXAlignment = Enum.TextXAlignment.Center
    self._toolLabel.Visible = false
    self._toolLabel.Parent = self._container

    return self
end

function Box:Update(pos, size, displayName, dist, character)
    self._container.Position = UDim2.fromOffset(pos.X, pos.Y)
    self._container.Size = UDim2.fromOffset(size.X, size.Y)
    self._container.Visible = true

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
        self._label.Position = UDim2.new(0.5, 0, 0, -1)
        self._label.Visible = true
    end

    local tool = getEquippedTool(character)
    self._toolLabel.Text = "[" .. (tool or "none") .. "]"
    self._toolLabel.Position = UDim2.new(0.5, 0, 1, 1)
    self._toolLabel.Visible = true
end

function Box:SetAlpha(t)
    local alpha = math.clamp(t, 0, 1)
    self._container.Visible = alpha > 0.01

    local inv = 1 - alpha
    self._outerStroke.Transparency  = inv
    self._borderStroke.Transparency = inv
    self._innerStroke.Transparency  = inv

    self._label.TextTransparency          = inv
    self._label.TextStrokeTransparency    = inv
    self._toolLabel.TextTransparency      = inv
    self._toolLabel.TextStrokeTransparency = inv
end

function Box:Hide()
    self._container.Visible = false
end

function Box:Destroy()
    self._container:Destroy()
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
    "https://raw.githubusercontent.com/elon2088/diddledraws/refs/heads/main/playerballsackhandler.lua"
))()

local Destroy = PlayerHandler.init({
    LocalPlayer    = LocalPlayer,
    Players        = Players,
    RunService     = RunService,
    Box            = Box,
    GetBoundingBox = GetBoundingBox,
    DrawFade       = DrawFade,
})
