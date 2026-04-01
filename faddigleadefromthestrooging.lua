local FadeManager = {}

local Camera     = workspace.CurrentCamera
local RunService = game:GetService("RunService")

local FadeDuration = 2.5
local fades        = {}
local renderConn   = nil

local function projectCorners(corners)
    local minX, minY =  math.huge,  math.huge
    local maxX, maxY = -math.huge, -math.huge
    local any = false
    for _, wp in ipairs(corners) do
        local s, vis = Camera:WorldToViewportPoint(wp)
        if vis then
            any = true
            if s.X < minX then minX = s.X end
            if s.Y < minY then minY = s.Y end
            if s.X > maxX then maxX = s.X end
            if s.Y > maxY then maxY = s.Y end
        end
    end
    if not any then return nil end
    return Vector2.new(minX, minY), Vector2.new(maxX - minX, maxY - minY)
end

local function startRender()
    if renderConn then return end
    renderConn = RunService.RenderStepped:Connect(function(dt)
        local i = 1
        while i <= #fades do
            local f = fades[i]
            f.elapsed = f.elapsed + dt
            local t   = math.clamp(f.elapsed / FadeDuration, 0, 1)
            if t >= 1 then
                f.box:Destroy()
                table.remove(fades, i)
            else
                local pos, size = projectCorners(f.corners)
                if pos then
                    f.box:Update(pos, size)
                    f.box:SetTransparency(t)
                else
                    f.box:Hide()
                end
                i = i + 1
            end
        end
        if #fades == 0 then
            renderConn:Disconnect()
            renderConn = nil
        end
    end)
end

function FadeManager.trigger(box, corners)
    box:SetTransparency(0)
    table.insert(fades, {
        box     = box,
        corners = corners,
        elapsed = 0,
    })
    startRender()
end

function FadeManager.setDuration(d)
    FadeDuration = d
end

function FadeManager.cleanup()
    if renderConn then
        renderConn:Disconnect()
        renderConn = nil
    end
    for _, f in ipairs(fades) do
        f.box:Destroy()
    end
    table.clear(fades)
end

return FadeManager
