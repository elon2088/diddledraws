local PlayerHandler = {}

function PlayerHandler.init(ctx)
    local LocalPlayer    = ctx.LocalPlayer
    local Players        = ctx.Players
    local RunService     = ctx.RunService
    local Box            = ctx.Box
    local GetBoundingBox = ctx.GetBoundingBox
    local DrawFade       = ctx.DrawFade

    local boxes       = {}
    local connections = {}
    local local_root  = nil

    local OFFSETS = {
        Vector3.new( 1,  1,  1), Vector3.new(-1,  1,  1),
        Vector3.new( 1, -1,  1), Vector3.new(-1, -1,  1),
        Vector3.new( 1,  1, -1), Vector3.new(-1,  1, -1),
        Vector3.new( 1, -1, -1), Vector3.new(-1, -1, -1),
    }

    local function get_world_corners(character)
        local corners = {}
        for _, part in ipairs(character:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                local cf = part.CFrame
                local hx = part.Size.X * 0.5
                local hy = part.Size.Y * 0.5
                local hz = part.Size.Z * 0.5
                for _, o in ipairs(OFFSETS) do
                    table.insert(corners, cf * Vector3.new(o.X * hx, o.Y * hy, o.Z * hz))
                end
            end
        end
        return corners
    end

    local function update_local_root()
        local char = LocalPlayer.Character
        local_root = char and char:FindFirstChild("HumanoidRootPart")
    end

    update_local_root()
    table.insert(connections, LocalPlayer.CharacterAdded:Connect(function()
        task.defer(update_local_root)
    end))

    local function add(player)
        if player == LocalPlayer then return end
        if boxes[player] then return end

        local box            = Box.new()
        local last_pos       = nil
        local last_size      = nil
        local last_dist      = nil
        local last_root      = nil
        local last_corners   = {}
        local was_dead       = false
        local faded_death    = false

        local char_conn = player.CharacterAdded:Connect(function()
            box:Hide()
            last_pos     = nil
            last_size    = nil
            last_dist    = nil
            last_corners = {}
            was_dead     = false
            faded_death  = false
        end)

        boxes[player] = {
            box     = box,
            cleanup = function() char_conn:Disconnect() end,
            update  = function()
                local char = player.Character
                if not char then box:Hide() return end

                local hum  = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")

                if root then
                    last_root    = root.Position
                    last_corners = get_world_corners(char)
                end

                local is_dead = not hum or hum.Health <= 0

                if not is_dead then
                    was_dead    = false
                    faded_death = false

                    local pos, size = GetBoundingBox(char)
                    if pos then
                        local dist = local_root and root
                            and (local_root.Position - root.Position).Magnitude
                            or nil

                        last_pos  = pos
                        last_size = size
                        last_dist = dist

                        box:Update(pos, size, player.DisplayName, dist, hum.Health, hum.MaxHealth, char)
                        box:SetAlpha(1)
                    else
                        box:Hide()
                    end
                else
                    if not was_dead and not faded_death then
                        was_dead    = true
                        faded_death = true
                        if last_pos and last_size and #last_corners > 0 then
                            local fade_box = Box.new()
                            DrawFade.trigger(
                                fade_box,
                                last_root,
                                player.DisplayName,
                                last_pos,
                                last_size,
                                last_dist,
                                last_corners
                            )
                        end
                    end
                    box:Hide()
                end
            end
        }
    end

    local function remove(player)
        local entry = boxes[player]
        if entry then
            entry.cleanup()
            entry.box:Destroy()
            boxes[player] = nil
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do add(p) end
    table.insert(connections, Players.PlayerAdded:Connect(add))
    table.insert(connections, Players.PlayerRemoving:Connect(remove))

    local render_conn = RunService.RenderStepped:Connect(function()
        if not local_root then update_local_root() end
        for _, entry in next, boxes do
            entry.update()
        end
    end)

    return function()
        render_conn:Disconnect()
        for _, conn in ipairs(connections) do conn:Disconnect() end
        for _, entry in next, boxes do
            entry.cleanup()
            entry.box:Destroy()
        end
        DrawFade.cleanup()
    end
end

return PlayerHandler
