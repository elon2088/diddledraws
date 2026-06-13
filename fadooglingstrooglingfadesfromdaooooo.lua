local FadeManager = {}

local Camera     = workspace.CurrentCamera
local RunService = game:GetService("RunService")

local CFG = {
    FadeDuration = 2.5,
}

local fades       = {}
local render_conn = nil

local function project_corners(corners)
    local min_x, min_y =  math.huge,  math.huge
    local max_x, max_y = -math.huge, -math.huge
    local any_vis = false

    for _, wp in ipairs(corners) do
        local screen, vis = Camera:WorldToViewportPoint(wp)
        if vis then
            any_vis = true
            if screen.X < min_x then min_x = screen.X end
            if screen.Y < min_y then min_y = screen.Y end
            if screen.X > max_x then max_x = screen.X end
            if screen.Y > max_y then max_y = screen.Y end
        end
    end

    if not any_vis then return nil end
    return Vector2.new(min_x, min_y), Vector2.new(max_x - min_x, max_y - min_y)
end

local function start_render()
    if render_conn then return end
    render_conn = RunService.RenderStepped:Connect(function(dt)
        local i = 1
        while i <= #fades do
            local f = fades[i]
            f.elapsed = f.elapsed + dt
            local t = math.clamp(f.elapsed / CFG.FadeDuration, 0, 1)

            if t >= 1 then
                f.box:Hide()
                f.box:Destroy()
                table.remove(fades, i)
            else
                local pos, size = project_corners(f.corners)

                if pos and size then
                    f.box:Update(pos, size, f.name, f.last_dist, 0, 100, nil)
                    f.box:SetAlpha(1 - t)
                else
                    f.box:Hide()
                end

                i = i + 1
            end
        end

        if #fades == 0 then
            render_conn:Disconnect()
            render_conn = nil
        end
    end)
end

function FadeManager.trigger(box, world_pos, display_name, last_pos, last_size, last_dist, corners)
    box:SetAlpha(1)
    table.insert(fades, {
        box       = box,
        world_pos = world_pos,
        name      = display_name,
        last_dist = last_dist,
        corners   = corners,
        elapsed   = 0,
    })
    start_render()
end

function FadeManager.setConfig(key, value)
    CFG[key] = value
end

function FadeManager.cleanup()
    if render_conn then
        render_conn:Disconnect()
        render_conn = nil
    end
    for _, f in ipairs(fades) do
        f.box:Hide()
        f.box:Destroy()
    end
    table.clear(fades)
end

return FadeManager
