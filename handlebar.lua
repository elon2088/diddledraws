local PlayerHandler = {}

function PlayerHandler.init(ctx)
    local LocalPlayer    = ctx.LocalPlayer
    local Players        = ctx.Players
    local RunService     = ctx.RunService
    local Box            = ctx.Box
    local GetBoundingBox = ctx.GetBoundingBox

    local FadeManager = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/elon2088/diddledraws/refs/heads/main/faddigleadefromthestrooging.lua"
    ))()

    local OFFSETS = {
        Vector3.new( 1,  1,  1), Vector3.new(-1,  1,  1),
        Vector3.new( 1, -1,  1), Vector3.new(-1, -1,  1),
        Vector3.new( 1,  1, -1), Vector3.new(-1,  1, -1),
        Vector3.new( 1, -1, -1), Vector3.new(-1, -1, -1),
    }

    local function getWorldCorners(character)
        local corners = {}
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

    local boxes       = {}
    local connections = {}

    local function Add(player)
        if player == LocalPlayer then return end
        if boxes[player] then return end

        local box          = Box.new()
        local lastCorners  = {}
        local wasDead      = false
        local fadedOnDeath = false

        local charConn = player.CharacterAdded:Connect(function()
            box:Hide()
            lastCorners  = {}
            wasDead      = false
            fadedOnDeath = false
        end)

        boxes[player] = {
            box     = box,
            cleanup = function() charConn:Disconnect() end,
            update  = function()
                local char = player.Character
                if not char then box:Hide() return end

                local hum  = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")

                if root then
                    lastCorners = getWorldCorners(char)
                end

                local isDead = not hum or hum.Health <= 0

                if not isDead then
                    wasDead      = false
                    fadedOnDeath = false
                    local pos, size = GetBoundingBox(char)
                    if pos then
                        box:Update(pos, size)
                        box:SetTransparency(0)
                    else
                        box:Hide()
                    end
                else
                    if not wasDead and not fadedOnDeath then
                        wasDead      = true
                        fadedOnDeath = true
                        if #lastCorners > 0 then
                            local fadeBox = Box.new()
                            FadeManager.trigger(fadeBox, lastCorners)
                        end
                    end
                    box:Hide()
                end
            end,
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
    table.insert(connections, Players.PlayerAdded:Connect(Add))
    table.insert(connections, Players.PlayerRemoving:Connect(Remove))

    local renderConn = RunService.RenderStepped:Connect(function()
        for player, entry in next, boxes do
            entry.update()
        end
    end)

    return function()
        renderConn:Disconnect()
        for _, c in ipairs(connections) do c:Disconnect() end
        for player, entry in next, boxes do
            entry.cleanup()
            entry.box:Destroy()
            boxes[player] = nil
        end
        FadeManager.cleanup()
    end
end

return PlayerHandler
