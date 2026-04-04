local PlayerHandler = {}

function PlayerHandler.init(ctx)
    local boxes, localRoot = {}, nil
    local function updateLocalRoot() 
        localRoot = ctx.LocalPlayer.Character and ctx.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") 
    end

    local function getWorldCorners(char)
        local c = {}
        if not char then return c end
        for _, p in ipairs(char:GetChildren()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                local cf, s = p.CFrame, p.Size * 0.5
                table.insert(c, cf * Vector3.new(1,1,1)*s); table.insert(c, cf * Vector3.new(-1,1,1)*s)
                table.insert(c, cf * Vector3.new(1,-1,1)*s); table.insert(c, cf * Vector3.new(-1,-1,1)*s)
                table.insert(c, cf * Vector3.new(1,1,-1)*s); table.insert(c, cf * Vector3.new(-1,1,-1)*s)
                table.insert(c, cf * Vector3.new(1,-1,-1)*s); table.insert(c, cf * Vector3.new(-1,-1,-1)*s)
            end
        end
        return c
    end

    local function Add(p)
        if p == ctx.LocalPlayer then return end
        local box, lastCorners, lastDist, lastHealth = ctx.Box.new(), {}, nil, 1
        boxes[p] = ctx.RunService.RenderStepped:Connect(function()
            local char, hum, root = p.Character, nil, nil
            if char then
                hum = char:FindFirstChildOfClass("Humanoid")
                root = char:FindFirstChild("HumanoidRootPart")
            end

            if char and hum and hum.Health > 0 and root then
                lastCorners = getWorldCorners(char)
                lastHealth = hum.Health / hum.MaxHealth
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
    ctx.Players.PlayerRemoving:Connect(function(p) if boxes[p] then boxes[p]:Disconnect(); boxes[p]=nil end end)
    for _, p in ipairs(ctx.Players:GetPlayers()) do Add(p) end
    ctx.RunService.RenderStepped:Connect(updateLocalRoot)
end

return PlayerHandler
