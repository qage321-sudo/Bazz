--[[
    BAZZ v3 — STEAL AN EGG
    Lightweight | Full Tabs | Premium Lock | ESP Native | Angel vs Daemon
--]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local Http = game:GetService("HttpService")
local Teleport = game:GetService("TeleportService")
local LP = Players.LocalPlayer

local _writefile = writefile or getgenv().writefile
local _readfile = readfile or getgenv().readfile
local _isfile = isfile or getgenv().isfile
local _isfolder = isfolder or getgenv().isfolder
local _makefolder = makefolder or getgenv().makefolder
local _gethui = gethui or getgenv().gethui or function() return game:GetService("CoreGui") end
local _getrawmetatable = getrawmetatable or getgenv().getrawmetatable
local _setreadonly = setreadonly or getgenv().setreadonly
local _getnamecallmeth = getnamecallmethod or getgenv().getnamecallmethod
local _newcclosure = newcclosure or getgenv().newcclosure or function(f) return f end

local FOLDER = "BazzConfig"
local CONFIG_FILE = FOLDER .. "/stealanegg_v3.json"
if not _isfolder(FOLDER) then _makefolder(FOLDER) end

-- Hidden keys
local _k1 = "ba" .. "zz"
local _k2 = "J" .. "oy"

-- State
local S = {
    tier = "none",
    authed = false,
    conn = {},
    remotes = {},
    espCache = {},
    highlightCache = {},
    config = {},
    ui = {},
    kickBlocked = 0,
    paused = false,
    run = true
}

-- Config: semua fitur default OFF, kecuali bypass
local DEFAULT = {
    -- Steal (OFF)
    autoSteal = false, stealDelay = 0.35, stealBig = false, stealSecret = false,
    stealBiome = "all", stealWeightMin = 0,
    -- Auto (OFF)
    autoHatch = false, autoPlace = false, autoSell = false,
    autoTreadmill = false, autoUpgrade = false, autoEvent = false, claimReward = false,
    -- ESP (OFF)
    espEgg = false, espGuardian = false, espPlayer = false,
    espMaxDist = math.huge, espTeamCheck = false,
    -- Movement (OFF)
    speedBoost = false, speedValue = 50,
    infiniteJump = false, noclip = false,
    fly = false, flyMode = "CFrame", flySpeed = 80,
    -- Premium (OFF)
    guardianBypass = false, advancedSteal = false,
    -- Anti-ban (ON — bypass)
    antiBan = true, antiKick = true, antiRob = true, autoRejoin = true,
    uiKeybind = "RightShift"
}

local function deepCopy(t)
    local o = {}
    for k, v in pairs(t) do o[k] = type(v) == "table" and deepCopy(v) or v end
    return o
end

local function loadConfig()
    S.config = deepCopy(DEFAULT)
    if _isfile and _isfile(CONFIG_FILE) then
        local ok, data = pcall(function() return Http:JSONDecode(_readfile(CONFIG_FILE)) end)
        if ok and type(data) == "table" then
            for k, v in pairs(data) do S.config[k] = v end
        end
    end
end

local function saveConfig()
    if not _writefile then return end
    pcall(function() _writefile(CONFIG_FILE, Http:JSONEncode(S.config)) end)
end

loadConfig()

-- Remote patterns
local PATTERNS = {
    steal = {"steal","grab","collect","take","pickup","snatch"},
    hatch = {"hatch","open","eggopen","unbox"},
    treadmill = {"treadmill","train","walk"},
    upgrade = {"upgrade","buyupgrade"},
    sell = {"sell","sellpet","discard"},
    place = {"place","setegg","deploy"},
    event = {"event","claim","reward","rift","angel","daemon"}
}

local function discover()
    for cat, pats in pairs(PATTERNS) do
        for _, o in ipairs(RS:GetDescendants()) do
            if o:IsA("RemoteEvent") or o:IsA("RemoteFunction") then
                local low = string.lower(o.Name)
                for _, p in ipairs(pats) do
                    if string.find(low, p, 1, true) then
                        S.remotes[cat] = o
                        break
                    end
                end
                if S.remotes[cat] then break end
            end
        end
    end
end

local function discoverRetry()
    for i = 1, 3 do
        discover()
        task.wait(1)
    end
end

-- Notif ringan
local function notify(title, text)
    local gui = S.ui.screen
    if not gui then return end
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 220, 0, 46)
    f.Position = UDim2.new(1, -240, 0, 16)
    f.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    f.BorderSizePixel = 0
    f.Parent = gui
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke", f)
    s.Color = Color3.fromRGB(0, 200, 120); s.Thickness = 1
    local t = Instance.new("TextLabel", f)
    t.Size = UDim2.new(1, -12, 0, 18); t.Position = UDim2.new(0, 8, 0, 4)
    t.BackgroundTransparency = 1; t.Text = title
    t.TextColor3 = Color3.fromRGB(0, 200, 120); t.TextXAlignment = Enum.TextXAlignment.Left
    t.Font = Enum.Font.GothamBold; t.TextSize = 12
    local b = Instance.new("TextLabel", f)
    b.Size = UDim2.new(1, -12, 0, 22); b.Position = UDim2.new(0, 8, 0, 22)
    b.BackgroundTransparency = 1; b.Text = text
    b.TextColor3 = Color3.fromRGB(210, 210, 210); b.TextXAlignment = Enum.TextXAlignment.Left
    b.Font = Enum.Font.Gotham; b.TextSize = 10
    task.delay(3, function() f:Destroy() end)
end

-- Anti-ban
local function startAntiBan()
    if not S.config.antiBan then return end
    if _getrawmetatable and _setreadonly then
        pcall(function()
            local mt = _getrawmetatable(game)
            local old = mt.__namecall
            _setreadonly(mt, false)
            mt.__namecall = _newcclosure(function(self, ...)
                local m = _getnamecallmeth()
                if m == "Kick" and S.config.antiKick then
                    S.kickBlocked = S.kickBlocked + 1
                    return nil
                end
                return old(self, ...)
            end)
            _setreadonly(mt, true)
        end)
    end
    if S.config.autoRejoin then
        table.insert(S.conn, LP.AncestryChanged:Connect(function()
            if not LP.Parent then
                task.wait(3)
                pcall(function()
                    Teleport:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
                end)
            end
        end))
    end
end

-- Steal
local function fireSteal(egg)
    local r = S.remotes.steal
    if not r then
        -- fallback generic
        for _, o in ipairs(RS:GetDescendants()) do
            if (o:IsA("RemoteEvent") or o:IsA("RemoteFunction")) then
                local low = string.lower(o.Name)
                if string.find(low,"egg",1,true) or string.find(low,"steal",1,true) then
                    pcall(function()
                        if o:IsA("RemoteEvent") then o:FireServer(egg)
                        else o:InvokeServer(egg) end
                    end)
                end
            end
        end
    else
        pcall(function()
            if r:IsA("RemoteEvent") then r:FireServer(egg)
            else r:InvokeServer(egg) end
        end)
    end
    pcall(function()
        for _, d in ipairs(egg:GetDescendants()) do
            if d:IsA("ProximityPrompt") then fireproximityprompt(d) end
        end
    end)
end

local function getBiome(egg)
    local b = egg:GetAttribute("Biome")
    if b then return b end
    local p = egg.Parent
    if p then
        local pn = string.lower(p.Name)
        if string.find(pn,"angel",1,true) then return "Angel" end
        if string.find(pn,"daemon",1,true) or string.find(pn,"demon",1,true) then return "Daemon" end
        for _, name in ipairs({"Forest","Lake","Desert","Jungle","Snow","Volcano","Abyss","Prehistoric","Cosmic","Cherry","Titan"}) do
            if string.find(pn,string.lower(name),1,true) then return name end
        end
    end
    return "all"
end

local function collectEggs()
    local list = {}
    for _, e in ipairs(workspace:GetDescendants()) do
        if e:IsA("Model") and e.PrimaryPart and string.find(string.lower(e.Name),"egg",1,true) then
            local rarity = e:GetAttribute("Rarity") or "Common"
            local biome = getBiome(e)
            local lowN = string.lower(e.Name)
            if not S.config.stealBig and (string.find(lowN,"big",1,true) or string.find(lowN,"huge",1,true)) then continue end
            if not S.config.stealSecret and (rarity=="Secret" or rarity=="Eternal" or rarity=="Divine") then continue end
            if S.config.stealBiome ~= "all" and string.lower(biome) ~= string.lower(S.config.stealBiome) then continue end
            table.insert(list, e)
        end
    end
    return list
end

local function workerSteal()
    while S.run do
        task.wait(S.config.stealDelay + math.random(-30,30)/1000)
        if not S.config.autoSteal or S.paused then continue end
        local eggs = collectEggs()
        if #eggs == 0 then continue end
        fireSteal(eggs[1])
    end
end

local function fireRemote(cat, ...)
    local r = S.remotes[cat]
    if not r then return end
    pcall(function()
        if r:IsA("RemoteEvent") then r:FireServer(...)
        else r:InvokeServer(...) end
    end)
end

local function workerHatch()
    while S.run do
        task.wait(1)
        if S.config.autoHatch then fireRemote("hatch") end
    end
end

local function workerPlace()
    while S.run do
        task.wait(1.5)
        if S.config.autoPlace then fireRemote("place") end
    end
end

local function workerSell()
    while S.run do
        task.wait(3)
        if S.config.autoSell then fireRemote("sell") end
    end
end

local function workerTreadmill()
    while S.run do
        task.wait(3)
        if S.config.autoTreadmill then fireRemote("treadmill") end
    end
end

local function workerUpgrade()
    while S.run do
        task.wait(5)
        if S.config.autoUpgrade then fireRemote("upgrade", "upgrade") end
    end
end

local function workerEvent()
    while S.run do
        task.wait(8)
        if S.config.autoEvent then fireRemote("event", "claim") end
    end
end

local function workerReward()
    while S.run do
        task.wait(10)
        if S.config.claimReward then
            for _, k in ipairs({"daily","season","index"}) do
                fireRemote("event", "claim", k)
                task.wait(0.5)
            end
        end
    end
end

-- Movement (Heartbeat ringan)
local function startMovement()
    table.insert(S.conn, RunService.Heartbeat:Connect(function()
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if S.config.speedBoost and hum.WalkSpeed < S.config.speedValue then
            hum.WalkSpeed = math.min(hum.WalkSpeed + 1, S.config.speedValue)
        end
        if S.config.noclip and char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
        if S.config.fly and S.tier == "premium" then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local cam = workspace.CurrentCamera
                local dir = Vector3.zero
                if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
                hrp.CFrame = hrp.CFrame + dir * (S.config.flySpeed/60)
            end
        end
    end))
    table.insert(S.conn, UIS.JumpRequest:Connect(function()
        if S.config.infiniteJump then
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end))
end

-- ESP native (Highlight + BillboardGui) — RINGAN
local function getOrCreateHL(part, color)
    local id = part:GetDebugId()
    if S.highlightCache[id] then return S.highlightCache[id] end
    local h = Instance.new("Highlight")
    h.FillColor = color
    h.OutlineColor = color
    h.FillTransparency = 0.75
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee = part
    h.Parent = part
    S.highlightCache[id] = h
    return h
end

local function getOrCreateBillboard(part, name)
    local id = "bb_" .. part:GetDebugId()
    if S.espCache[id] then return S.espCache[id] end
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 200, 0, 40)
    bb.StudsOffset = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = math.huge
    bb.LightInfluence = 0
    bb.Adornee = part
    bb.Parent = part
    local tl = Instance.new("TextLabel", bb)
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Text = name
    tl.TextColor3 = Color3.fromRGB(255,255,255)
    tl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    tl.TextStrokeTransparency = 0
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = 16
    tl.TextScaled = false
    S.espCache[id] = {bb = bb, tl = tl}
    return S.espCache[id]
end

local function clearESP()
    for _, h in pairs(S.highlightCache) do pcall(function() h:Destroy() end) end
    for _, c in pairs(S.espCache) do pcall(function() c.bb:Destroy() end) end
    S.highlightCache = {}
    S.espCache = {}
end

local function startESP()
    table.insert(S.conn, task.spawn(function()
        while S.run do
            task.wait(0.5)
            if not (S.config.espEgg or S.config.espGuardian or S.config.espPlayer) then
                clearESP()
                continue
            end
            local active = {}

            if S.config.espEgg then
                for _, e in ipairs(workspace:GetDescendants()) do
                    if e:IsA("Model") and e.PrimaryPart and string.find(string.lower(e.Name),"egg",1,true) then
                        local rarity = e:GetAttribute("Rarity") or "Common"
                        local color = Color3.fromRGB(255, 120, 120)
                        if rarity == "Secret" or rarity == "Eternal" or rarity == "Divine" then
                            color = Color3.fromRGB(255, 215, 0)
                        elseif rarity == "Mythic" or rarity == "Cosmic" then
                            color = Color3.fromRGB(200, 100, 255)
                        end
                        getOrCreateHL(e.PrimaryPart, color)
                        local bb = getOrCreateBillboard(e.PrimaryPart, e.Name .. " [" .. rarity .. "]")
                        bb.tl.TextColor3 = color
                        active[e.PrimaryPart:GetDebugId()] = true
                    end
                end
            end

            if S.config.espGuardian then
                for _, g in ipairs(workspace:GetDescendants()) do
                    if g:IsA("Model") and g.PrimaryPart and string.find(string.lower(g.Name),"guardian",1,true) then
                        getOrCreateHL(g.PrimaryPart, Color3.fromRGB(255,0,0))
                        local bb = getOrCreateBillboard(g.PrimaryPart, "GUARDIAN: " .. g.Name)
                        bb.tl.TextColor3 = Color3.fromRGB(255,60,60)
                        active[g.PrimaryPart:GetDebugId()] = true
                    end
                end
            end

            if S.config.espPlayer and S.tier == "premium" then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            getOrCreateHL(hrp, Color3.fromRGB(0,200,255))
                            local bb = getOrCreateBillboard(hrp, p.Name)
                            bb.tl.TextColor3 = Color3.fromRGB(0,220,255)
                            active["bb_" .. hrp:GetDebugId()] = true
                        end
                    end
                end
            end

            -- cleanup yang gak aktif
            for id, h in pairs(S.highlightCache) do
                if not active[id] then
                    pcall(function() h:Destroy() end)
                    S.highlightCache[id] = nil
                end
            end
            for id, c in pairs(S.espCache) do
                if not active[id] then
                    pcall(function() c.bb:Destroy() end)
                    S.espCache[id] = nil
                end
            end
        end
    end))
end

local function startAntiRob()
    table.insert(S.conn, task.spawn(function()
        while S.run do
            task.wait(1)
            if not S.config.antiRob then continue end
            local base = workspace:FindFirstChild("Base") or workspace:FindFirstChild("Home")
            if not base or not base.PrimaryPart then continue end
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local phrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if phrp and (phrp.Position - base.PrimaryPart.Position).Magnitude < 30 then
                        hrp.CFrame = base.PrimaryPart.CFrame + Vector3.new(0,5,0)
                        break
                    end
                end
            end
        end
    end))
end

-- UI
local function makeToggle(parent, label, key, premium)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
    row.BorderSizePixel = 0
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local l = Instance.new("TextLabel", row)
    l.Size = UDim2.new(1, -70, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = label
    l.TextColor3 = Color3.fromRGB(220,220,220)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.Gotham
    l.TextSize = 12

    local b = Instance.new("TextButton", row)
    b.Size = UDim2.new(0, 44, 0, 22)
    b.Position = UDim2.new(1, -52, 0, 4)
    b.BackgroundColor3 = S.config[key] and Color3.fromRGB(0,200,120) or Color3.fromRGB(60,60,70)
    b.Text = ""
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 11)

    local knob = Instance.new("Frame", b)
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = S.config[key] and UDim2.new(1, -20, 0, 2) or UDim2.new(0, 2, 0, 2)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 9)

    local locked = false
    if premium and S.tier ~= "premium" then
        locked = true
        local ov = Instance.new("Frame", row)
        ov.Size = UDim2.new(1, 0, 1, 0)
        ov.BackgroundColor3 = Color3.fromRGB(15,15,18)
        ov.BackgroundTransparency = 0.45
        ov.BorderSizePixel = 0
        ov.ZIndex = 10
        Instance.new("UICorner", ov).CornerRadius = UDim.new(0, 6)
        -- cross
        local c1 = Instance.new("Frame", ov)
        c1.Size = UDim2.new(1, 0, 0, 2)
        c1.Position = UDim2.new(0, 0, 0.5, -1)
        c1.BackgroundColor3 = Color3.fromRGB(255,60,60)
        c1.BorderSizePixel = 0
        c1.Rotation = 6
        c1.ZIndex = 11
        local c2 = Instance.new("Frame", ov)
        c2.Size = UDim2.new(1, 0, 0, 2)
        c2.Position = UDim2.new(0, 0, 0.5, -1)
        c2.BackgroundColor3 = Color3.fromRGB(255,60,60)
        c2.BorderSizePixel = 0
        c2.Rotation = -6
        c2.ZIndex = 11
    end

    b.MouseButton1Click:Connect(function()
        if locked then
            notify("Premium", "Fitur ini butuh tier atas")
            return
        end
        S.config[key] = not S.config[key]
        local t = S.config[key]
        b.BackgroundColor3 = t and Color3.fromRGB(0,200,120) or Color3.fromRGB(60,60,70)
        TS:Create(knob, TweenInfo.new(0.15), {Position = t and UDim2.new(1,-20,0,2) or UDim2.new(0,2,0,2)}):Play()
        saveConfig()
    end)
end

local function makeSlider(parent, label, key, min, max)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
    row.BorderSizePixel = 0
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local l = Instance.new("TextLabel", row)
    l.Size = UDim2.new(1, -20, 0, 16)
    l.Position = UDim2.new(0, 10, 0, 2)
    l.BackgroundTransparency = 1
    l.Text = label .. ": " .. string.format("%.2f", S.config[key])
    l.TextColor3 = Color3.fromRGB(220,220,220)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.Gotham
    l.TextSize = 11

    local bar = Instance.new("Frame", row)
    bar.Size = UDim2.new(1, -20, 0, 8)
    bar.Position = UDim2.new(0, 10, 0, 26)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
    bar.BorderSizePixel = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)

    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new(math.clamp((S.config[key]-min)/(max-min),0,1), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0,200,120)
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

    local drag = false
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true end
    end)
    bar.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local pct = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local v = min + (max-min)*pct
            S.config[key] = v
            fill.Size = UDim2.new(pct, 0, 1, 0)
            l.Text = label .. ": " .. string.format("%.2f", v)
            saveConfig()
        end
    end)
end

local function makeDropdown(parent, label, key, opts)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
    row.BorderSizePixel = 0
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local l = Instance.new("TextLabel", row)
    l.Size = UDim2.new(0.5, 0, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = label
    l.TextColor3 = Color3.fromRGB(220,220,220)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.Gotham
    l.TextSize = 12

    local b = Instance.new("TextButton", row)
    b.Size = UDim2.new(0.45, 0, 0, 20)
    b.Position = UDim2.new(0.5, 0, 0, 5)
    b.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
    b.Text = tostring(S.config[key])
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.Gotham
    b.TextSize = 10
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)

    local idx = 1
    for i, o in ipairs(opts) do if o == S.config[key] then idx = i end end

    b.MouseButton1Click:Connect(function()
        idx = idx + 1
        if idx > #opts then idx = 1 end
        S.config[key] = opts[idx]
        b.Text = opts[idx]
        saveConfig()
    end)
end

local function makeSection(parent, name)
    local s = Instance.new("TextLabel", parent)
    s.Size = UDim2.new(1, 0, 0, 22)
    s.BackgroundColor3 = Color3.fromRGB(42, 42, 50)
    s.Text = "  " .. name
    s.TextColor3 = Color3.fromRGB(0,200,120)
    s.TextXAlignment = Enum.TextXAlignment.Left
    s.Font = Enum.Font.GothamBold
    s.TextSize = 11
    s.BorderSizePixel = 0
    Instance.new("UICorner", s).CornerRadius = UDim.new(0, 4)
end

local function createUI()
    local screen = Instance.new("ScreenGui")
    screen.Name = "Settings"
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = true
    pcall(function() screen.Parent = _gethui() end)
    if not screen.Parent then screen.Parent = game:GetService("CoreGui") end
    S.ui.screen = screen
    pcall(function() getgenv().BazzUI = screen end)

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 580, 0, 400)
    main.Position = UDim2.new(0.5, -290, 0.5, -200)
    main.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    main.BorderSizePixel = 0
    main.Parent = screen
    S.ui.main = main
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
    local st = Instance.new("UIStroke", main)
    st.Color = Color3.fromRGB(45,45,52); st.Thickness = 1

    -- topbar
    local top = Instance.new("Frame", main)
    top.Size = UDim2.new(1, 0, 0, 40)
    top.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    top.BorderSizePixel = 0
    Instance.new("UICorner", top).CornerRadius = UDim.new(0, 12)

    local title = Instance.new("TextLabel", top)
    title.Size = UDim2.new(1, -120, 1, 0)
    title.Position = UDim2.new(0, 14, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "BAZZ HUB  •  Steal An Egg"
    title.TextColor3 = Color3.fromRGB(230,230,230)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13

    local minB = Instance.new("TextButton", top)
    minB.Size = UDim2.new(0, 26, 0, 26); minB.Position = UDim2.new(1, -92, 0, 7)
    minB.BackgroundTransparency = 1; minB.Text = "—"; minB.TextColor3 = Color3.fromRGB(220,220,220)
    minB.Font = Enum.Font.GothamBold; minB.TextSize = 16

    local maxB = Instance.new("TextButton", top)
    maxB.Size = UDim2.new(0, 26, 0, 26); maxB.Position = UDim2.new(1, -62, 0, 7)
    maxB.BackgroundTransparency = 1; maxB.Text = "⛶"; maxB.TextColor3 = Color3.fromRGB(220,220,220)
    maxB.Font = Enum.Font.GothamBold; maxB.TextSize = 14

    local closeB = Instance.new("TextButton", top)
    closeB.Size = UDim2.new(0, 26, 0, 26); closeB.Position = UDim2.new(1, -32, 0, 7)
    closeB.BackgroundTransparency = 1; closeB.Text = "✕"; closeB.TextColor3 = Color3.fromRGB(220,220,220)
    closeB.Font = Enum.Font.GothamBold; closeB.TextSize = 14

    -- sidebar
    local side = Instance.new("Frame", main)
    side.Size = UDim2.new(0, 140, 1, -40)
    side.Position = UDim2.new(0, 0, 0, 40)
    side.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    side.BorderSizePixel = 0
    local sl = Instance.new("UIListLayout", side)
    sl.SortOrder = Enum.SortOrder.LayoutOrder
    sl.Padding = UDim.new(0, 4)
    local sp = Instance.new("UIPadding", side)
    sp.PaddingTop = UDim.new(0, 8); sp.PaddingLeft = UDim.new(0, 8); sp.PaddingRight = UDim.new(0, 8)

    -- content scroll
    local scroll = Instance.new("ScrollingFrame", main)
    scroll.Size = UDim2.new(1, -152, 1, -50)
    scroll.Position = UDim2.new(0, 146, 0, 44)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(0,200,120)
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local cl = Instance.new("UIListLayout", scroll)
    cl.SortOrder = Enum.SortOrder.LayoutOrder
    cl.Padding = UDim.new(0, 5)

    -- icon (minimize)
    local icon = Instance.new("TextButton", screen)
    icon.Size = UDim2.new(0, 44, 0, 44)
    icon.Position = UDim2.new(0, 20, 0.5, -22)
    icon.BackgroundColor3 = Color3.fromRGB(0, 200, 120)
    icon.Text = "B"
    icon.TextColor3 = Color3.fromRGB(255,255,255)
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 20
    icon.BorderSizePixel = 0
    icon.Visible = false
    Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 8)

    -- tabs
    local tabs = {}
    local function addTab(name)
        local b = Instance.new("TextButton", side)
        b.Size = UDim2.new(1, 0, 0, 32)
        b.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
        b.BackgroundTransparency = 1
        b.Text = "   " .. name
        b.TextColor3 = Color3.fromRGB(200,200,200)
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 12
        b.BorderSizePixel = 0
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)

        local p = Instance.new("Frame", scroll)
        p.Size = UDim2.new(1, 0, 0, 0)
        p.AutomaticSize = Enum.AutomaticSize.Y
        p.BackgroundTransparency = 1
        p.Visible = false
        local pl = Instance.new("UIListLayout", p)
        pl.SortOrder = Enum.SortOrder.LayoutOrder
        pl.Padding = UDim.new(0, 5)
        tabs[#tabs+1] = p

        b.MouseButton1Click:Connect(function()
            for _, x in ipairs(tabs) do x.Visible = false end
            p.Visible = true
            for _, x in ipairs(side:GetChildren()) do
                if x:IsA("TextButton") then
                    x.BackgroundTransparency = 1
                    x.TextColor3 = Color3.fromRGB(200,200,200)
                end
            end
            b.BackgroundTransparency = 0
            b.TextColor3 = Color3.fromRGB(0,200,120)
        end)
        return p
    end

    local tMain = addTab("Main")
    local tSteal = addTab("Steal")
    local tAuto = addTab("Auto")
    local tESP = addTab("ESP")
    local tMove = addTab("Movement")
    local tPrem = addTab("Premium")
    local tSet = addTab("Settings")

    -- MAIN
    makeSection(tMain, "Info")
    local info = Instance.new("TextLabel", tMain)
    info.Size = UDim2.new(1, 0, 0, 80)
    info.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
    info.Text = "Tier: " .. string.upper(S.tier) .. "\nKicks blocked: 0\nExecutor: " .. tostring(({identifyexecutor()})[1] or "Unknown") .. "\nUptime: 0s"
    info.TextColor3 = Color3.fromRGB(220,220,220)
    info.Font = Enum.Font.Code
    info.TextSize = 12
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.BorderSizePixel = 0
    Instance.new("UICorner", info).CornerRadius = UDim.new(0, 6)
    info.Text = "  " .. info.Text
    local t0 = tick()
    task.spawn(function()
        while S.run and screen.Parent do
            task.wait(1)
            info.Text = string.format("  Tier: %s\n  Kicks blocked: %d\n  Executor: %s\n  Uptime: %ds",
                string.upper(S.tier), S.kickBlocked, tostring(({identifyexecutor()})[1] or "Unknown"), math.floor(tick()-t0))
        end
    end)

    -- STEAL
    makeSection(tSteal, "Auto Steal")
    makeToggle(tSteal, "Auto Steal", "autoSteal")
    makeSlider(tSteal, "Delay", "stealDelay", 0.1, 2.0)
    makeToggle(tSteal, "Big Egg", "stealBig")
    makeToggle(tSteal, "Secret Egg", "stealSecret")
    makeDropdown(tSteal, "Biome", "stealBiome",
        {"all","Forest","Lake","Desert","Jungle","Snow","Volcano","Abyss","Prehistoric","Cosmic","Cherry Blossom","Titan Temple","Angel","Daemon"})
    makeSlider(tSteal, "Weight Min", "stealWeightMin", 0, 100)

    -- AUTO
    makeSection(tAuto, "Auto")
    makeToggle(tAuto, "Auto Hatch", "autoHatch")
    makeToggle(tAuto, "Auto Place", "autoPlace")
    makeToggle(tAuto, "Auto Sell", "autoSell")
    makeToggle(tAuto, "Auto Treadmill", "autoTreadmill")
    makeToggle(tAuto, "Auto Upgrade", "autoUpgrade")
    makeToggle(tAuto, "Auto Event", "autoEvent")
    makeToggle(tAuto, "Claim Reward", "claimReward")

    -- ESP
    makeSection(tESP, "ESP — Unlimited Range")
    makeToggle(tESP, "ESP Egg", "espEgg")
    makeToggle(tESP, "ESP Guardian", "espGuardian")
    makeToggle(tESP, "ESP Player", "espPlayer", true)

    -- MOVEMENT
    makeSection(tMove, "Movement")
    makeToggle(tMove, "Speed Boost", "speedBoost")
    makeSlider(tMove, "Speed Value", "speedValue", 16, 300)
    makeToggle(tMove, "Infinite Jump", "infiniteJump")
    makeToggle(tMove, "Noclip", "noclip")

    -- PREMIUM
    makeSection(tPrem, "Premium Only")
    makeToggle(tPrem, "Fly", "fly", true)
    makeDropdown(tPrem, "Fly Mode", "flyMode", {"CFrame","BodyVelocity"})
    makeSlider(tPrem, "Fly Speed", "flySpeed", 20, 400)
    makeToggle(tPrem, "Guardian Bypass", "guardianBypass", true)
    makeToggle(tPrem, "Advanced Steal", "advancedSteal", true)

    -- SETTINGS
    makeSection(tSet, "Anti-Ban / Bypass")
    makeToggle(tSet, "Anti-Ban", "antiBan")
    makeToggle(tSet, "Anti-Kick", "antiKick")
    makeToggle(tSet, "Anti-Rob", "antiRob")
    makeToggle(tSet, "Auto Rejoin", "autoRejoin")

    -- toggle show/hide
    local function hideAll()
        main.Visible = false
        icon.Visible = true
    end
    local function showAll()
        main.Visible = true
        icon.Visible = false
    end
    closeB.MouseButton1Click:Connect(hideAll)
    minB.MouseButton1Click:Connect(hideAll)
    icon.MouseButton1Click:Connect(showAll)

    -- drag icon
    local iDrag, iStart
    icon.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            iDrag = true; iStart = i.Position
        end
    end)
    icon.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then iDrag = false end
    end)
    UIS.InputChanged:Connect(function(i)
        if iDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - iStart; iStart = i.Position
            icon.Position = UDim2.new(icon.Position.X.Scale, icon.Position.X.Offset + d.X, icon.Position.Y.Scale, icon.Position.Y.Offset + d.Y)
        end
    end)

    -- drag main
    local mDrag, mStart, mPos
    top.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            mDrag = true; mStart = i.Position; mPos = main.Position
        end
    end)
    top.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then mDrag = false end
    end)
    UIS.InputChanged:Connect(function(i)
        if mDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - mStart
            main.Position = UDim2.new(mPos.X.Scale, mPos.X.Offset + d.X, mPos.Y.Scale, mPos.Y.Offset + d.Y)
        end
    end)

    -- keybind
    UIS.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.KeyCode == Enum.KeyCode.RightShift then
            main.Visible = not main.Visible
            icon.Visible = not main.Visible
        end
    end)

    tMain.Visible = true
    local firstTab = side:FindFirstChildOfClass("TextButton")
    if firstTab then firstTab.BackgroundTransparency = 0; firstTab.TextColor3 = Color3.fromRGB(0,200,120) end
end

-- Auth
local function showAuth()
    local screen = Instance.new("ScreenGui")
    screen.Name = "Config"
    screen.ResetOnSpawn = false
    pcall(function() screen.Parent = _gethui() end)
    if not screen.Parent then screen.Parent = game:GetService("CoreGui") end

    local f = Instance.new("Frame", screen)
    f.Size = UDim2.new(0, 300, 0, 150)
    f.Position = UDim2.new(0.5, -150, 0.5, -75)
    f.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke", f)
    s.Color = Color3.fromRGB(0, 200, 120); s.Thickness = 1.5

    local t = Instance.new("TextLabel", f)
    t.Size = UDim2.new(1, 0, 0, 30)
    t.BackgroundTransparency = 1
    t.Text = "BAZZ HUB"
    t.TextColor3 = Color3.fromRGB(0, 200, 120)
    t.Font = Enum.Font.GothamBold; t.TextSize = 15

    local tb = Instance.new("TextBox", f)
    tb.Size = UDim2.new(1, -30, 0, 32); tb.Position = UDim2.new(0, 15, 0, 40)
    tb.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
    tb.PlaceholderText = "code"
    tb.Text = ""
    tb.TextColor3 = Color3.fromRGB(255,255,255)
    tb.Font = Enum.Font.Gotham; tb.TextSize = 13
    tb.BorderSizePixel = 0
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 6)

    local b = Instance.new("TextButton", f)
    b.Size = UDim2.new(1, -30, 0, 32); b.Position = UDim2.new(0, 15, 0, 82)
    b.BackgroundColor3 = Color3.fromRGB(0, 200, 120)
    b.Text = "ENTER"
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.GothamBold; b.TextSize = 13
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)

    local info = Instance.new("TextLabel", f)
    info.Size = UDim2.new(1, -30, 0, 20); info.Position = UDim2.new(0, 15, 0, 120)
    info.BackgroundTransparency = 1; info.Text = ""
    info.TextColor3 = Color3.fromRGB(255, 80, 80); info.Font = Enum.Font.Gotham; info.TextSize = 10

    local function doAuth()
        local input = tb.Text
        if input == _k1 then S.tier = "basic"; S.authed = true
        elseif input == _k2 then S.tier = "premium"; S.authed = true
        else info.Text = "invalid"; return end
        screen:Destroy()
        createUI()
        task.spawn(discoverRetry)
        task.spawn(workerSteal)
        task.spawn(workerHatch)
        task.spawn(workerPlace)
        task.spawn(workerSell)
        task.spawn(workerTreadmill)
        task.spawn(workerUpgrade)
        task.spawn(workerEvent)
        task.spawn(workerReward)
        startMovement()
        startESP()
        startAntiBan()
        startAntiRob()
        notify("Loaded", "Tier: " .. string.upper(S.tier))
    end

    b.MouseButton1Click:Connect(doAuth)
    tb.FocusLost:Connect(function(enter) if enter then doAuth() end end)
end

notify("BAZZ", "Loading...")
task.wait(0.5)
showAuth()}

local function deepCopy(t)
    local o = {}
    for k, v in pairs(t) do o[k] = type(v) == "table" and deepCopy(v) or v end
    return o
end

local function loadConfig()
    State.config = deepCopy(DEFAULT_CONFIG)
    if _isfile and _isfile(CONFIG_FILE) then
        local ok, data = pcall(function() return HttpService:JSONDecode(_readfile(CONFIG_FILE)) end)
        if ok and type(data) == "table" then
            for k, v in pairs(data) do State.config[k] = v end
        end
    end
end

local function saveConfig()
    if not _writefile then return end
    pcall(function() _writefile(CONFIG_FILE, HttpService:JSONEncode(State.config)) end)
end

loadConfig()

-- Remote pattern
local PATTERNS = {
    steal = {"steal","grab","collect","take","pickup"},
    hatch = {"hatch","open","eggopen","unbox"},
    treadmill = {"treadmill","train","speed"},
    upgrade = {"upgrade","buyupgrade"},
    sell = {"sell","sellpet","discard"},
    place = {"place","setegg","deploy"},
    event = {"event","claim","reward","rift"}
}

local function discover()
    for cat, pats in pairs(PATTERNS) do
        for _, o in ipairs(RS:GetDescendants()) do
            if o:IsA("RemoteEvent") or o:IsA("RemoteFunction") then
                local low = string.lower(o.Name)
                for _, p in ipairs(pats) do
                    if string.find(low, p, 1, true) then
                        State.remotes[cat] = o
                        break
                    end
                end
                if State.remotes[cat] then break end
            end
        end
    end
end

-- Notification ringan
local function notify(title, text)
    local gui = State.ui.screen
    if not gui then return end
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 240, 0, 50)
    f.Position = UDim2.new(1, -260, 0, 20)
    f.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    f.BorderSizePixel = 0
    f.Parent = gui
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke", f)
    s.Color = Color3.fromRGB(0, 255, 150); s.Thickness = 1
    local t = Instance.new("TextLabel", f)
    t.Size = UDim2.new(1, -12, 0, 20); t.Position = UDim2.new(0, 6, 0, 4)
    t.BackgroundTransparency = 1; t.Text = title
    t.TextColor3 = Color3.fromRGB(0, 255, 150); t.TextXAlignment = Enum.TextXAlignment.Left
    t.Font = Enum.Font.GothamBold; t.TextSize = 12
    local b = Instance.new("TextLabel", f)
    b.Size = UDim2.new(1, -12, 0, 22); b.Position = UDim2.new(0, 6, 0, 24)
    b.BackgroundTransparency = 1; b.Text = text
    b.TextColor3 = Color3.fromRGB(220, 220, 220); b.TextXAlignment = Enum.TextXAlignment.Left
    b.Font = Enum.Font.Gotham; b.TextSize = 11
    task.delay(3, function() f:Destroy() end)
end

-- Anti-ban minimalis
local function startAntiBan()
    if not State.config.antiBan then return end
    -- block Kick via metatable
    if _getrawmetatable and _setreadonly then
        pcall(function()
            local mt = _getrawmetatable(game)
            local old = mt.__namecall
            _setreadonly(mt, false)
            mt.__namecall = _newcclosure(function(self, ...)
                local m = _getnamecallmeth()
                if m == "Kick" then
                    State.kickBlocked = State.kickBlocked + 1
                    return nil
                end
                return old(self, ...)
            end)
            _setreadonly(mt, true)
        end)
    end
    -- auto rejoin
    if State.config.autoRejoin then
        table.insert(State.connections, LP.AncestryChanged:Connect(function()
            if not LP.Parent then
                task.wait(3)
                pcall(function()
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
                end)
            end
        end))
    end
end

-- Steal function
local function fireSteal(egg)
    local r = State.remotes.steal
    if not r then return end
    pcall(function()
        if r:IsA("RemoteEvent") then r:FireServer(egg)
        else r:InvokeServer(egg) end
    end)
    -- fallback proximity
    pcall(function()
        for _, d in ipairs(egg:GetDescendants()) do
            if d:IsA("ProximityPrompt") then fireproximityprompt(d) end
        end
    end)
end

local function collectEggs()
    local eggs = {}
    for _, e in ipairs(workspace:GetDescendants()) do
        if e:IsA("Model") and string.find(string.lower(e.Name), "egg") and e.PrimaryPart then
            local rarity = e:GetAttribute("Rarity") or "Common"
            local biome = e:GetAttribute("Biome") or "all"
            if not State.config.stealBigEgg and string.find(string.lower(e.Name), "big") then continue end
            if not State.config.stealSecret and (rarity == "Secret" or rarity == "Eternal" or rarity == "Divine") then continue end
            if State.config.stealBiome ~= "all" and biome ~= State.config.stealBiome then continue end
            table.insert(eggs, e)
        end
    end
    return eggs
end

local function startAutoSteal()
    table.insert(State.connections, task.spawn(function()
        while true do
            task.wait(State.config.stealDelay + math.random(-30, 30) / 1000)
            if not State.config.autoSteal or State.paused then continue end
            local eggs = collectEggs()
            if #eggs == 0 then continue end
            fireSteal(eggs[1])
        end
    end))
end

local function startAutoHatch()
    table.insert(State.connections, task.spawn(function()
        while true do
            task.wait(1)
            if not State.config.autoHatch then continue end
            local r = State.remotes.hatch
            if r then
                pcall(function()
                    if r:IsA("RemoteEvent") then r:FireServer()
                    else r:InvokeServer() end
                end)
            end
        end
    end))
end

local function startAutoPlace()
    table.insert(State.connections, task.spawn(function()
        while true do
            task.wait(1.5)
            if not State.config.autoPlace then continue end
            local r = State.remotes.place
            if r then
                pcall(function()
                    if r:IsA("RemoteEvent") then r:FireServer()
                    else r:InvokeServer() end
                end)
            end
        end
    end))
end

local function startAutoSell()
    table.insert(State.connections, task.spawn(function()
        while true do
            task.wait(3)
            if not State.config.autoSell then continue end
            local r = State.remotes.sell
            if r then
                pcall(function()
                    if r:IsA("RemoteEvent") then r:FireServer()
                    else r:InvokeServer() end
                end)
            end
        end
    end))
end

local function startAutoTreadmill()
    table.insert(State.connections, task.spawn(function()
        while true do
            task.wait(3)
            if not State.config.autoTreadmill then continue end
            local r = State.remotes.treadmill
            if r then
                pcall(function()
                    if r:IsA("RemoteEvent") then r:FireServer()
                    else r:InvokeServer() end
                end)
            end
        end
    end))
end

local function startAutoUpgrade()
    table.insert(State.connections, task.spawn(function()
        while true do
            task.wait(5)
            if not State.config.autoUpgrade then continue end
            local r = State.remotes.upgrade or State.remotes.treadmill
            if r then
                pcall(function()
                    if r:IsA("RemoteEvent") then r:FireServer("upgrade")
                    else r:InvokeServer("upgrade") end
                end)
            end
        end
    end))
end

local function startAutoEvent()
    table.insert(State.connections, task.spawn(function()
        while true do
            task.wait(8)
            if not State.config.autoEvent then continue end
            local r = State.remotes.event
            if r then
                pcall(function()
                    if r:IsA("RemoteEvent") then r:FireServer("claim")
                    else r:InvokeServer("claim") end
                end)
            end
        end
    end))
end

local function startMovement()
    table.insert(State.connections, RunService.Heartbeat:Connect(function()
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if State.config.speedBoost and hum.WalkSpeed < State.config.speedValue then
            hum.WalkSpeed = math.min(hum.WalkSpeed + 1, State.config.speedValue)
        end
        if State.config.noclip and char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
        if State.config.fly and State.tier == "premium" then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local cam = workspace.CurrentCamera
                local dir = Vector3.zero
                if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
                hrp.CFrame = hrp.CFrame + dir * (State.config.flySpeed / 60)
            end
        end
    end))
    table.insert(State.connections, UIS.JumpRequest:Connect(function()
        if State.config.infiniteJump then
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end))
end

-- ESP ringan: scan tiap 0.3s, bukan RenderStepped
local function startESP()
    if not Drawing then return end
    local function box(label)
        return {
            sq = Drawing.new("Square"),
            tx = Drawing.new("Text")
        }
    end
    for _, v in pairs(State.espCache) do
        if v.sq then v.sq:Remove() end
        if v.tx then v.tx:Remove() end
    end
    State.espCache = {}

    table.insert(State.connections, task.spawn(function()
        while true do
            task.wait(0.3)
            local cam = workspace.CurrentCamera
            if not cam then continue end
            local camPos = cam.CFrame.Position
            local active = {}

            local function render(obj, name, dist, color)
                if dist > State.config.espMaxDist then return end
                local pos, onScreen = cam:WorldToViewportPoint(obj)
                if not onScreen then return end
                local id = name
                if not State.espCache[id] then State.espCache[id] = box(name) end
                local c = State.espCache[id]
                c.sq.Size = Vector2.new(40, 40)
                c.sq.Position = Vector2.new(pos.X - 20, pos.Y - 20)
                c.sq.Color = color
                c.sq.Thickness = 1
                c.sq.Filled = false
                c.sq.Visible = true
                c.tx.Text = name .. " [" .. math.floor(dist) .. "]"
                c.tx.Position = Vector2.new(pos.X, pos.Y - 32)
                c.tx.Size = 12
                c.tx.Color = color
                c.tx.Center = true
                c.tx.Outline = true
                c.tx.Visible = true
                active[id] = true
            end

            if State.config.espEgg then
                for _, e in ipairs(workspace:GetDescendants()) do
                    if e:IsA("Model") and string.find(string.lower(e.Name), "egg") and e.PrimaryPart then
                        local rarity = e:GetAttribute("Rarity") or "Common"
                        render(e.PrimaryPart.Position, e.Name .. " (" .. rarity .. ")",
                            (e.PrimaryPart.Position - camPos).Magnitude,
                            Color3.fromRGB(255, 100, 100))
                    end
                end
            end
            if State.config.espGuardian then
                for _, g in ipairs(workspace:GetDescendants()) do
                    if g:IsA("Model") and string.find(string.lower(g.Name), "guardian") and g.PrimaryPart then
                        render(g.PrimaryPart.Position, "GUARDIAN: " .. g.Name,
                            (g.PrimaryPart.Position - camPos).Magnitude,
                            Color3.fromRGB(255, 0, 0))
                    end
                end
            end
            if State.config.espPlayer and State.tier == "premium" then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            render(hrp.Position, p.Name, (hrp.Position - camPos).Magnitude,
                                Color3.fromRGB(0, 200, 255))
                        end
                    end
                end
            end

            for id, c in pairs(State.espCache) do
                if not active[id] then
                    c.sq.Visible = false
                    c.tx.Visible = false
                end
            end
        end
    end))
end

local function startAntiRob()
    table.insert(State.connections, task.spawn(function()
        while true do
            task.wait(1)
            if not State.config.antiRob then continue end
            local base = workspace:FindFirstChild("Base") or workspace:FindFirstChild("Home")
            if not base or not base.PrimaryPart then continue end
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local phrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if phrp and (phrp.Position - base.PrimaryPart.Position).Magnitude < 30 then
                        hrp.CFrame = base.PrimaryPart.CFrame + Vector3.new(0, 5, 0)
                        break
                    end
                end
            end
        end
    end))
end

-- UI
local function createUI()
    local screen = Instance.new("ScreenGui")
    screen.Name = "Settings"
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = true
    pcall(function() screen.Parent = _gethui() end)
    if not screen.Parent then screen.Parent = game:GetService("CoreGui") end
    State.ui.screen = screen

    -- protect dari destroy
    pcall(function() getgenv().BazzUI = screen end)

    -- Main
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 560, 0, 380)
    main.Position = UDim2.new(0.5, -280, 0.5, -190)
    main.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    main.BorderSizePixel = 0
    main.Parent = screen
    State.ui.main = main
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
    local st = Instance.new("UIStroke", main)
    st.Color = Color3.fromRGB(0, 255, 150); st.Thickness = 1.5

    -- Topbar
    local top = Instance.new("Frame")
    top.Size = UDim2.new(1, 0, 0, 36)
    top.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    top.BorderSizePixel = 0
    top.Parent = main
    Instance.new("UICorner", top).CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "BAZZ PANEL"
    title.TextColor3 = Color3.fromRGB(0, 255, 150)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.Parent = top

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 26, 0, 26)
    minBtn.Position = UDim2.new(1, -60, 0, 5)
    minBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    minBtn.Text = "—"
    minBtn.TextColor3 = Color3.fromRGB(255,255,255)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 14
    minBtn.BorderSizePixel = 0
    minBtn.Parent = top
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 5)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 26, 0, 26)
    closeBtn.Position = UDim2.new(1, -30, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = top
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 5)

    -- Icon minimize (floating button)
    local icon = Instance.new("TextButton")
    icon.Size = UDim2.new(0, 44, 0, 44)
    icon.Position = UDim2.new(0, 20, 0.5, -22)
    icon.BackgroundColor3 = Color3.fromRGB(0, 200, 120)
    icon.Text = "B"
    icon.TextColor3 = Color3.fromRGB(255,255,255)
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 20
    icon.BorderSizePixel = 0
    icon.Visible = false
    icon.Parent = screen
    Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 8)
    local iStroke = Instance.new("UIStroke", icon)
    iStroke.Color = Color3.fromRGB(0, 255, 150); iStroke.Thickness = 2

    -- Sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 110, 1, -36)
    sidebar.Position = UDim2.new(0, 0, 0, 36)
    sidebar.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
    sidebar.BorderSizePixel = 0
    sidebar.Parent = main
    local sl = Instance.new("UIListLayout", sidebar)
    sl.SortOrder = Enum.SortOrder.LayoutOrder
    sl.Padding = UDim.new(0, 4)
    local sp = Instance.new("UIPadding", sidebar)
    sp.PaddingTop = UDim.new(0, 8); sp.PaddingLeft = UDim.new(0, 6); sp.PaddingRight = UDim.new(0, 6)

    -- Content scroll
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -120, 1, -46)
    scroll.Position = UDim2.new(0, 115, 0, 41)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 150)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = main
    local cl = Instance.new("UIListLayout", scroll)
    cl.SortOrder = Enum.SortOrder.LayoutOrder
    cl.Padding = UDim.new(0, 5)

    State.ui.top = top
    State.ui.icon = icon
    State.ui.screen = screen

    -- tabs container
    local tabs = {}
    local function addTab(name)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        btn.Text = "  " .. name
        btn.TextColor3 = Color3.fromRGB(220,220,220)
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 11
        btn.BorderSizePixel = 0
        btn.Parent = sidebar
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

        local page = Instance.new("Frame")
        page.Size = UDim2.new(1, 0, 0, 0)
        page.AutomaticSize = Enum.AutomaticSize.Y
        page.BackgroundTransparency = 1
        page.Visible = false
        page.Parent = scroll
        local pl = Instance.new("UIListLayout", page)
        pl.SortOrder = Enum.SortOrder.LayoutOrder
        pl.Padding = UDim.new(0, 4)
        tabs[#tabs+1] = page

        btn.MouseButton1Click:Connect(function()
            for _, p in ipairs(tabs) do p.Visible = false end
            page.Visible = true
        end)
        return page
    end

    -- toggle component
    local function addToggle(parent, label, key, premiumOnly)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 26)
        f.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
        f.BorderSizePixel = 0
        f.Parent = parent
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -60, 1, 0)
        l.Position = UDim2.new(0, 10, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = label .. (premiumOnly and " [P]" or "")
        l.TextColor3 = premiumOnly and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(220,220,220)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Font = Enum.Font.Gotham
        l.TextSize = 11
        l.Parent = f

        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 40, 0, 20)
        b.Position = UDim2.new(1, -50, 0, 3)
        b.BackgroundColor3 = State.config[key] and Color3.fromRGB(0, 200, 120) or Color3.fromRGB(50, 50, 60)
        b.Text = State.config[key] and "ON" or "OFF"
        b.TextColor3 = Color3.fromRGB(255,255,255)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 10
        b.BorderSizePixel = 0
        b.Parent = f
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)

        b.MouseButton1Click:Connect(function()
            if premiumOnly and State.tier ~= "premium" then
                notify("Locked", "Fitur ini butuh tier atas")
                return
            end
            State.config[key] = not State.config[key]
            b.BackgroundColor3 = State.config[key] and Color3.fromRGB(0, 200, 120) or Color3.fromRGB(50, 50, 60)
            b.Text = State.config[key] and "ON" or "OFF"
            saveConfig()
        end)
    end

    -- slider
    local function addSlider(parent, label, key, min, max)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 40)
        f.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
        f.BorderSizePixel = 0
        f.Parent = parent
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -20, 0, 16)
        l.Position = UDim2.new(0, 10, 0, 2)
        l.BackgroundTransparency = 1
        l.Text = label .. ": " .. string.format("%.2f", State.config[key])
        l.TextColor3 = Color3.fromRGB(220,220,220)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Font = Enum.Font.Gotham
        l.TextSize = 11
        l.Parent = f

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -20, 0, 8)
        bar.Position = UDim2.new(0, 10, 0, 24)
        bar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        bar.BorderSizePixel = 0
        bar.Parent = f
        Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((State.config[key]-min)/(max-min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(0, 200, 120)
        fill.BorderSizePixel = 0
        fill.Parent = bar
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

        local drag = false
        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true end
        end)
        bar.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
        end)
        UIS.InputChanged:Connect(function(i)
            if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local mx = i.Position.X
                local pct = math.clamp((mx - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                local v = min + (max - min) * pct
                State.config[key] = v
                fill.Size = UDim2.new(pct, 0, 1, 0)
                l.Text = label .. ": " .. string.format("%.2f", v)
                saveConfig()
            end
        end)
    end

    -- dropdown
    local function addDropdown(parent, label, key, opts)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 26)
        f.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
        f.BorderSizePixel = 0
        f.Parent = parent
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0.5, 0, 1, 0)
        l.Position = UDim2.new(0, 10, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = label
        l.TextColor3 = Color3.fromRGB(220,220,220)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Font = Enum.Font.Gotham
        l.TextSize = 11
        l.Parent = f

        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.45, 0, 0, 18)
        b.Position = UDim2.new(0.5, 0, 0, 4)
        b.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        b.Text = tostring(State.config[key])
        b.TextColor3 = Color3.fromRGB(255,255,255)
        b.Font = Enum.Font.Gotham
        b.TextSize = 10
        b.BorderSizePixel = 0
        b.Parent = f
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)

        local idx = 1
        for i, o in ipairs(opts) do if o == State.config[key] then idx = i end end

        b.MouseButton1Click:Connect(function()
            idx = idx + 1
            if idx > #opts then idx = 1 end
            State.config[key] = opts[idx]
            b.Text = opts[idx]
            saveConfig()
        end)
    end

    local function addSection(parent, name)
        local s = Instance.new("TextLabel")
        s.Size = UDim2.new(1, 0, 0, 20)
        s.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        s.Text = "  " .. name
        s.TextColor3 = Color3.fromRGB(0, 255, 150)
        s.TextXAlignment = Enum.TextXAlignment.Left
        s.Font = Enum.Font.GothamBold
        s.TextSize = 11
        s.BorderSizePixel = 0
        s.Parent = parent
        Instance.new("UICorner", s).CornerRadius = UDim.new(0, 4)
    end

    -- BUILD TABS
    local tMain = addTab("Main")
    local tSteal = addTab("Steal")
    local tAuto = addTab("Auto")
    local tESP = addTab("ESP")
    local tMove = addTab("Move")
    local tPrem = addTab("Premium")
    local tSet = addTab("Setting")

    addSection(tMain, "Info")
    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(1, 0, 0, 60)
    statusLbl.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    statusLbl.Text = "Tier: " .. string.upper(State.tier) .. "\nKicks blocked: 0\nExecutor: " .. tostring(({identifyexecutor()})[1] or "Unknown")
    statusLbl.TextColor3 = Color3.fromRGB(200,200,200)
    statusLbl.Font = Enum.Font.Code
    statusLbl.TextSize = 11
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.BorderSizePixel = 0
    statusLbl.Parent = tMain
    Instance.new("UICorner", statusLbl).CornerRadius = UDim.new(0, 5)
    task.spawn(function()
        while screen.Parent do
            task.wait(1)
            statusLbl.Text = string.format("Tier: %s\nKicks blocked: %d\nExecutor: %s",
                string.upper(State.tier), State.kickBlocked, tostring(({identifyexecutor()})[1] or "Unknown"))
        end
    end)

    addSection(tSteal, "Auto Steal")
    addToggle(tSteal, "Auto Steal", "autoSteal")
    addSlider(tSteal, "Delay", "stealDelay", 0.1, 2.0)
    addToggle(tSteal, "Big Egg", "stealBigEgg")
    addToggle(tSteal, "Secret Egg", "stealSecret")
    addDropdown(tSteal, "Biome", "stealBiome", {"all","Forest","Lake","Desert","Jungle","Snow","Volcano","Abyss","Prehistoric","Cosmic","Cherry Blossom","Titan Temple"})
    addSlider(tSteal, "Weight Min", "stealWeightMin", 0, 100)

    addSection(tAuto, "Auto")
    addToggle(tAuto, "Auto Hatch", "autoHatch")
    addToggle(tAuto, "Auto Place", "autoPlace")
    addToggle(tAuto, "Auto Sell", "autoSell")
    addToggle(tAuto, "Auto Treadmill", "autoTreadmill")
    addToggle(tAuto, "Auto Upgrade", "autoUpgrade")
    addToggle(tAuto, "Auto Event", "autoEvent")
    addToggle(tAuto, "Claim Reward", "claimReward")

    addSection(tESP, "ESP")
    addToggle(tESP, "ESP Egg", "espEgg")
    addToggle(tESP, "ESP Guardian", "espGuardian")
    addToggle(tESP, "ESP Player", "espPlayer", true)
    addSlider(tESP, "Max Distance", "espMaxDist", 50, 1000)

    addSection(tMove, "Movement")
    addToggle(tMove, "Speed Boost", "speedBoost")
    addSlider(tMove, "Speed Value", "speedValue", 16, 300)
    addToggle(tMove, "Infinite Jump", "infiniteJump")
    addToggle(tMove, "Noclip", "noclip")

    addSection(tPrem, "Premium Only")
    addToggle(tPrem, "Fly", "fly", true)
    addDropdown(tPrem, "Fly Mode", "flyMode", {"CFrame","BodyVelocity"})
    addSlider(tPrem, "Fly Speed", "flySpeed", 20, 400)
    addToggle(tPrem, "Guardian Bypass", "guardianBypass", true)
    addToggle(tPrem, "Advanced Steal", "advancedSteal", true)

    addSection(tSet, "Anti-Ban")
    addToggle(tSet, "Anti-Ban", "antiBan")
    addToggle(tSet, "Anti-Kick", "antiKick")
    addToggle(tSet, "Anti-Rob", "antiRob")
    addToggle(tSet, "Auto Rejoin", "autoRejoin")

    -- Hide/show behavior
    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = false
        icon.Visible = true
    end)
    minBtn.MouseButton1Click:Connect(function()
        main.Visible = false
        icon.Visible = true
    end)
    icon.MouseButton1Click:Connect(function()
        main.Visible = true
        icon.Visible = false
    end)

    -- Icon draggable
    local iDrag, iStart
    icon.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            iDrag = true
            iStart = i.Position
        end
    end)
    icon.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then iDrag = false end
    end)
    UIS.InputChanged:Connect(function(i)
        if iDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - iStart
            iStart = i.Position
            icon.Position = UDim2.new(icon.Position.X.Scale, icon.Position.X.Offset + d.X, icon.Position.Y.Scale, icon.Position.Y.Offset + d.Y)
        end
    end)

    -- Topbar draggable
    local mDrag, mStart, mPos
    top.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            mDrag = true
            mStart = i.Position
            mPos = main.Position
        end
    end)
    top.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then mDrag = false end
    end)
    UIS.InputChanged:Connect(function(i)
        if mDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - mStart
            main.Position = UDim2.new(mPos.X.Scale, mPos.X.Offset + d.X, mPos.Y.Scale, mPos.Y.Offset + d.Y)
        end
    end)

    -- keybind
    UIS.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.KeyCode == Enum.KeyCode.RightShift then
            main.Visible = not main.Visible
            icon.Visible = not main.Visible
        end
    end)

    -- show first tab
    tMain.Visible = true
end

-- Auth prompt (hidden keys)
local function showAuth()
    local screen = Instance.new("ScreenGui")
    screen.Name = "Config"
    screen.ResetOnSpawn = false
    pcall(function() screen.Parent = _gethui() end)
    if not screen.Parent then screen.Parent = game:GetService("CoreGui") end

    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 300, 0, 150)
    f.Position = UDim2.new(0.5, -150, 0.5, -75)
    f.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    f.BorderSizePixel = 0
    f.Parent = screen
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke", f)
    s.Color = Color3.fromRGB(0, 255, 150); s.Thickness = 1.5

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, 0, 0, 30)
    t.BackgroundTransparency = 1
    t.Text = "BAZZ PANEL"
    t.TextColor3 = Color3.fromRGB(0, 255, 150)
    t.Font = Enum.Font.GothamBold
    t.TextSize = 15
    t.Parent = f

    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(1, -30, 0, 32)
    tb.Position = UDim2.new(0, 15, 0, 40)
    tb.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    tb.PlaceholderText = "code"
    tb.Text = ""
    tb.TextColor3 = Color3.fromRGB(255,255,255)
    tb.Font = Enum.Font.Gotham
    tb.TextSize = 13
    tb.BorderSizePixel = 0
    tb.Parent = f
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 5)

    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -30, 0, 32)
    b.Position = UDim2.new(0, 15, 0, 82)
    b.BackgroundColor3 = Color3.fromRGB(0, 200, 120)
    b.Text = "ENTER"
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.BorderSizePixel = 0
    b.Parent = f
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -30, 0, 20)
    info.Position = UDim2.new(0, 15, 0, 120)
    info.BackgroundTransparency = 1
    info.Text = ""
    info.TextColor3 = Color3.fromRGB(255, 80, 80)
    info.Font = Enum.Font.Gotham
    info.TextSize = 10
    info.Parent = f

    b.MouseButton1Click:Connect(function()
        local input = tb.Text
        if input == _k1 then
            State.tier = "basic"; State.authed = true
        elseif input == _k2 then
            State.tier = "premium"; State.authed = true
        else
            info.Text = "invalid"
            return
        end
        screen:Destroy()
        createUI()
        discover()
        startAutoSteal()
        startAutoHatch()
        startAutoPlace()
        startAutoSell()
        startAutoTreadmill()
        startAutoUpgrade()
        startAutoEvent()
        startMovement()
        startESP()
        startAntiBan()
        startAntiRob()
        notify("Loaded", "Tier: " .. string.upper(State.tier))
    end)

    tb.FocusLost:Connect(function(enter)
        if enter then b.MouseButton1Click:Fire() end
    end)
end

-- boot
notify("BAZZ", "Loading...")
task.wait(0.5)
showAuth()
