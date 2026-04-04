local DrawFade = {}
local Camera, RunService = workspace.CurrentCamera, game:GetService("RunService")
local FadeDuration, fades, renderConn = 2.5, {}, nil

local function projectCorners(corners)
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local anyVis = false
    for _, wp in ipairs(corners) do
        local screen, vis = Camera:WorldToViewportPoint(wp)
        if vis then
            anyVis = true
            minX, minY, maxX, maxY = math.min(minX, screen.X), math.min(minY, screen.Y), math.max(maxX, screen.X), math.max(maxY, screen.Y)
        end
    end
    return anyVis and Vector2.new(minX, minY), anyVis and Vector2.new(maxX - minX, maxY - minY)
end

local function startRender()
    if renderConn then return end
    renderConn = RunService.RenderStepped:Connect(function(dt)
        for i = #fades, 1, -1 do
            local f = fades[i]
            f.elapsed = f.elapsed + dt
            local progress = math.clamp(f.elapsed / FadeDuration, 0, 1)
            if progress >= 1 then
                f.box:Destroy(); table.remove(fades, i)
            else
                local pos, size = projectCorners(f.corners)
                if pos and size then
                    f.box:Update(pos, size, f.displayName, f.lastDist, f.savedHealth)
                    f.box:SetAlpha(1 - progress)
                else
                    f.box:Hide()
                end
            end
        end
        if #fades == 0 then renderConn:Disconnect(); renderConn = nil end
    end)
end

function DrawFade.trigger(box, corners, name, dist, health)
    table.insert(fades, {box=box, corners=corners, displayName=name, lastDist=dist, savedHealth=health or 0, elapsed=0})
    startRender()
end

return DrawFade
