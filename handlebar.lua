local PlayerHandler = {}

function PlayerHandler.init(ctx)
    local LocalPlayer    = ctx.LocalPlayer
    local Players        = ctx.Players
    local RunService     = ctx.RunService
    local Box            = ctx.Box
    local GetBoundingBox = ctx.GetBoundingBox
    local DrawFade       = ctx.DrawFade

    local boxes     = {}
    local localRoot = nil

    local OFFSETS = {
        Vector3.new( 1,  1,  1), Vector3.new(-1,  1,  1),
        Vector3.new( 1, -1,  1), Vector3.new(-1, -1,  1),
        Vector3.new( 1,  1, -1), Vector3.new(-1,  1, -1),
        Vector3.new( 1, -1, -1), Vector3.new(-1, -1, -1),
    }

    local function updateLocalRoot()
        local char = LocalPlayer.Character
        localRoot  = char and char:FindFirstChild("HumanoidRootPart")
    end

    local function getWorldCorners(character)
        local corners = {}
        if not character then return corners end
        for _, part in ipairs(character:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                local cf = part.CFrame
                local hX = part.Size.X * 0.5
                local hY = part.Size.Y * 0.5
                local hZ = part.Size.Z * 0.5
                for _, o in ipairs(OFFSETS) do
                    table.insert(corners, cf * Vector3.new(o.X * hX, o.Y * hY, o.Z * hZ))
                end
            end
        end
        return corners
    end

    updateLocalRoot()
    LocalPlayer.CharacterAdded:Connect(function()
        task.defer(updateLocalRoot)
    end)

    local function Add(player)
        if player == LocalPlayer then return end
        if boxes[player] then return end

        local box            = Box.new()
        local lastCorners    = {}
        local lastDist       = nil
        local wasDead        = false
        local fadedThisDeath = false

        local charConn = player.CharacterAdded:Connect(function()
            box:Hide()
            lastCorners      = {}
            lastDist         = nil
            wasDead          = false
            fadedThisDeath   = false
        end)

        boxes[player] = {
            box     = box,
            cleanup = function() charConn:Disconnect() end,
            update  = function()
                local char = player.Character
                if not char then box:Hide() return end

                local hum    = char:FindFirstChildOfClass("Humanoid")
                local root   = char:FindFirstChild("HumanoidRootPart")
                local isDead = not hum or hum.Health <= 0

                if not isDead then
                    wasDead        = false
                    fadedThisDeath = false

                    if root then
                        lastCorners = getWorldCorners(char)
                        lastDist    = localRoot
                            and (localRoot.Position - root.Position).Magnitude
                            or nil
                    end

                    local pos, size = GetBoundingBox(char)
                    if pos then
                        box:Update(pos, size, player.DisplayName, lastDist, char)
                    else
                        box:Hide()
                    end
                else
                    if not wasDead and not fadedThisDeath and #lastCorners > 0 then
                        wasDead        = true
                        fadedThisDeath = true
                        local fadeBox  = Box.new()
                        DrawFade.trigger(fadeBox, lastCorners, player.DisplayName, lastDist, char)
                    end
                    box:Hide()
                end
            end
        }
    end

    local function Remove(player)
        local entry = boxes[player]
        if entry then
            entry.cleanup()
            entry.box:Destroy()
            boxes[player] = nil
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do Add(p) end
    local addedConn   = Players.PlayerAdded:Connect(Add)
    local removedConn = Players.PlayerRemoving:Connect(Remove)

    local renderConn = RunService.RenderStepped:Connect(function()
        if not localRoot then updateLocalRoot() end
        for player, entry in next, boxes do
            entry.update()
        end
    end)

    return function()
        renderConn:Disconnect()
        addedConn:Disconnect()
        removedConn:Disconnect()
        for player, entry in next, boxes do
            entry.cleanup()
            entry.box:Destroy()
            boxes[player] = nil
        end
        DrawFade.cleanup()
    end
end

return PlayerHandler
