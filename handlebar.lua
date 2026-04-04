local PlayerHandler = {}

function PlayerHandler.init(ctx)
    local boxes, localRoot = {}, nil
    local function updateLocalRoot() 
        localRoot = ctx.LocalPlayer.Character and ctx.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") 
    end

    local function getWorldCorners(char)
        local c = {}
        for _, p in ipairs(char:GetChildren()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                local cf, s = p.CFrame, p.Size * 0.5
                for x = -1, 1, 2 do for y = -1, 1, 2 do for z = -1, 1, 2 do
                    table.insert(c, cf * Vector3.new(x, y, z) * s)
                end end end
            end
        end
        return c
    end

    local function Add(p)
        if p == ctx.LocalPlayer then return end
        local box, lastCorners, lastDist, lastHealth = ctx.Box.new(), {}, nil, 1
        boxes[p] = ctx.RunService.RenderStepped:Connect(function()
            local char = p.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if char and hum and hum.Health > 0 and root then
                lastCorners, lastHealth = getWorldCorners(char), hum.Health / hum.MaxHealth
                lastDist = localRoot and (localRoot.Position - root.Position).Magnitude
                local pos, size = ctx.GetBoundingBox(char)
                if pos then box:Update(pos, size, p.DisplayName, lastDist, char) else box:Hide() end
            else
                if #lastCorners > 0 then
                    ctx.DrawFade.trigger(ctx.Box.new(), lastCorners, p.DisplayName, lastDist, lastHealth)
                    table.clear(lastCorners)
                end
                box:Hide()
            end
        end)
    end

    ctx.Players.PlayerAdded:Connect(Add)
    for _, p in ipairs(ctx.Players:GetPlayers()) do Add(p) end
    ctx.RunService.RenderStepped:Connect(updateLocalRoot)
end

return PlayerHandler
