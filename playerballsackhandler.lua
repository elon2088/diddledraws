local PlayerHandler = {}

function PlayerHandler.init(ctx)
    local LocalPlayer    = ctx.LocalPlayer
    local Players        = ctx.Players
    local RunService     = ctx.RunService
    local Box            = ctx.Box
    local GetBoundingBox = ctx.GetBoundingBox
    local DrawFade       = ctx.DrawFade

    local boxes = {}
    local localRoot = nil

    local function updateLocalRoot()
        local char = LocalPlayer.Character
        localRoot  = char and char:FindFirstChild("HumanoidRootPart")
    end

    local function getWorldCorners(character)
        local corners = {}
        for _, part in ipairs(character:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                local cf = part.CFrame
                local size = part.Size * 0.5
                for x = -1, 1, 2 do
                    for y = -1, 1, 2 do
                        for z = -1, 1, 2 do
                            table.insert(corners, cf * Vector3.new(x * size.X, y * size.Y, z * size.Z))
                        end
                    end
                end
            end
        end
        return corners
    end

    updateLocalRoot()
    LocalPlayer.CharacterAdded:Connect(function() task.defer(updateLocalRoot) end)

    local function Add(player)
        if player == LocalPlayer then return end
        local box = Box.new()
        local lastCorners, lastDist = {}, nil
        local lastH, lastMH = 100, 100
        local wasDead, fadedThisDeath = false, false

        local charConn = player.CharacterAdded:Connect(function()
            box:Hide()
            lastCorners, lastDist = {}, nil
            lastH, lastMH = 100, 100
            wasDead, fadedThisDeath = false, false
        end)

        boxes[player] = {
            box = box,
            cleanup = function() charConn:Disconnect() box:Destroy() end,
            update = function()
                local char = player.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local root = char and char:FindFirstChild("HumanoidRootPart")
                
                if char and hum and hum.Health > 0 then
                    wasDead, fadedThisDeath = false, false
                    lastCorners = getWorldCorners(char)
                    lastDist = localRoot and (localRoot.Position - root.Position).Magnitude or nil
                    lastH, lastMH = hum.Health, hum.MaxHealth
                    
                    local pos, size = GetBoundingBox(char)
                    if pos then
                        box:Update(pos, size, player.DisplayName, lastDist, char, lastH, lastMH)
                    else
                        box:Hide()
                    end
                else
                    if not wasDead and not fadedThisDeath and #lastCorners > 0 then
                        wasDead, fadedThisDeath = true, true
                        -- Pass 0 health to ensure the fade bar shows empty
                        DrawFade.trigger(Box.new(), lastCorners, player.DisplayName, lastDist, 0, lastMH)
                    end
                    box:Hide()
                end
            end
        }
    end

    Players.PlayerAdded:Connect(Add)
    Players.PlayerRemoving:Connect(function(p) if boxes[p] then boxes[p].cleanup() boxes[p] = nil end end)
    for _, p in ipairs(Players:GetPlayers()) do Add(p) end

    RunService.RenderStepped:Connect(function()
        for _, entry in next, boxes do entry.update() end
    end)
end

return PlayerHandler
