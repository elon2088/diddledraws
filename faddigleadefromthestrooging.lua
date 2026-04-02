local DrawFade = {}

local Camera     = workspace.CurrentCamera
local RunService = game:GetService("RunService")

local FadeDuration = 2.5
local fades        = {}
local renderConn   = nil

local function projectCorners(corners)
    local minX, minY =  math.huge,  math.huge
    local maxX, maxY = -math.huge, -math.huge
    local anyVis     = false
    for _, wp in ipairs(corners) do
        local screen, vis = Camera:WorldToViewportPoint(wp)
        if vis then
            anyVis = true
            if screen.X < minX then minX = screen.X end
            if screen.Y < minY then minY = screen.Y end
            if screen.X > maxX then maxX = screen.X end
            if screen.Y > maxY then maxY = screen.Y end
        end
    end
    if not anyVis then return nil end
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
                f.box:Hide()
                f.box:Destroy()
                table.remove(fades, i)
            else
                local pos, size = projectCorners(f.corners)
                if pos and size then
                    f.box:Update(pos, size, f.name)
                    f.box:SetAlpha(1 - t)
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

function DrawFade.trigger(box, corners, name)
    box:SetAlpha(0)
    table.insert(fades, {
        box     = box,
        corners = corners,
        name    = name,
        elapsed = 0,
    })
    startRender()
end

function DrawFade.setDuration(n)
    FadeDuration = n
end

function DrawFade.cleanup()
    if renderConn then
        renderConn:Disconnect()
        renderConn = nil
    end
    for _, f in ipairs(fades) do
        f.box:Hide()
        f.box:Destroy()
    end
    table.clear(fades)
end

return DrawFade
