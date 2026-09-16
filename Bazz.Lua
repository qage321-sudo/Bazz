--[[
    BAZZ v3.0 — Steal an Egg | Anti-Putus Edition
    Owner : JOY
    UI    : Custom (PlayerGui only, no CoreGui, no gethui)
    AC    : Zero-hook stealth + Auto-Rejoin engine
    Build : Bazz v6 FINAL
]]

--=============================================================
-- [01] SERVICES
--=============================================================
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local HttpService       = game:GetService("HttpService")
local StarterGui        = game:GetService("StarterGui")
local Lighting          = game:GetService("Lighting")
local TeleportService   = game:GetService("TeleportService")
local VirtualUser       = game:GetService("VirtualUser")

local LP  = Players.LocalPlayer
local PG  = LP:WaitForChild("PlayerGui", 10)
local CH  = LP.Character or LP.CharacterAdded:Wait()
local HRP = CH:WaitForChild("HumanoidRootPart", 10)
local HUM = CH:WaitForChild("Humanoid", 10)

--=============================================================
-- [02] SAFE ALIASES (NO HOOK FUNCTIONS)
--=============================================================
-- Sengaja TIDAK pakai hookfunction, hookmetamethod, getrawmetatable, setreadonly.
-- Semua itu detectable oleh anti-cheat modern.

--=============================================================
-- [03] STATE
--=============================================================
local BAZZ = {
    Version = "3.0",
    Owner   = "JOY",
    Tier    = nil,
    Key     = nil,
    Workers = {},
    Connections = {},
    Drawings = {},
    WarnCount = 0,
    Started = tick(),
    Bypass  = true,
    AntiBan = true,
    RejoinMode = true,
    LastHeartbeat = tick(),
    Kicked = false,
    LogoURL = "https://raw.githubusercontent.com/qage321-sudo/Bazz/refs/heads/main/logo.png",
}

setmetatable(BAZZ, {
    __newindex = function(t, k, v)
        if (k == "Bypass" or k == "AntiBan" or k == "RejoinMode") and v ~= true then
            rawset(t, k, true); return
        end
        rawset(t, k, v)
    end
})

--=============================================================
-- [04] CONFIG
--=============================================================
local CONFIG_FILE = "bazz_v3_config.json"
local KEY_FILE    = "bazz_v3_key.dat"
local BOOT_DELAY  = 25   -- detik tunggu sebelum UI & scan
local SCAN_DELAY  = 20   -- detik tunggu sebelum scan remotes
local UI_DELAY    = 25   -- detik tunggu sebelum UI muncul

local Config = {
    General = { Notify=true, AutoSave=true, Watermark=true },
    Steal = {
        Enabled=false, Mode="Rarest", Whitelist={}, Biomes={},
        MinWeight=0, MaxWeight=999999, UseFly=true, FlySpeed=180,
        AntiHit=true, ReturnToBase=true, Delay=0.75, MaxDistance=4000,
        Humanize=true, ValidatePos=true, ServerValidation=true,
        Prioritize={"Divine","Eternal","Secret","Mythic","Legendary","Epic","Rare","Common"},
    },
    Treadmill = { Enabled=false },
    Hatch     = { Enabled=false, AutoPlace=true },
    Event     = { Enabled=false, Ring=false, TeamClaim=false, Fusion=false },
    Combat    = { AntiHit=false, AntiRagdoll=false, AntiKnockback=false },
    Upgrade   = { Enabled=false },
    Buy       = { Enabled=false },
    AntiAFK   = { Enabled=true },
    ESP = {
        Egg      = { Enabled=false, Box=true, Name=true, Distance=true, MaxDistance=3000, Color=Color3.fromRGB(0,220,120) },
        Guardian = { Enabled=false, Tracer=true, Distance=true, Color=Color3.fromRGB(255,60,60) },
        Player   = { Enabled=false, Box=true, Name=true, Distance=true, Color=Color3.fromRGB(80,160,255) },
    },
    FixLag   = { Enabled=false, Level="Medium" },
    Movement = { Speed=false, SpeedValue=32, Jump=false, JumpValue=120, Fly=false, FlySpeed=120, Noclip=false, InfJump=false },
    Teleport = { ToEgg=false, ToBase=false },
    Misc     = { AutoSell=false, SellRarity="Common", AutoEquipBest=false, AutoClaimIndex=false,
                 AutoDropHeld=false, AntiTrap=false, ServerHop=false, Godmode=false, Webhook="" },
    Rejoin   = { Enabled=true, MinPlayers=2, MaxPlayers=10, RetryDelay=3, MaxRetry=5 },
}

--=============================================================
-- [05] UTILITIES
--=============================================================
local function log(...) print("[BAZZ]", ...) end
local function notify(t, x, d)
    if not Config.General.Notify then return end
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title=t, Text=x, Duration=d or 4})
    end)
end
local function safe(fn, ...)
    local ok, e = pcall(fn, ...)
    if not ok then log("safe:", e) end
    return ok, e
end
local function getChar()
    if not LP.Character then return nil end
    local h = LP.Character:FindFirstChildOfClass("Humanoid")
    local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
    if h and hrp then return LP.Character, h, hrp end
end
local function dist(a,b) return (a-b).Magnitude end
local function rndD(b) return b + math.random(-300,300)/1000 end
local function inT(t,v) for _,x in ipairs(t) do if x==v then return true end end return false end
local function simpleHash(str)
    local h = 0
    for i=1,#str do h = (h * 31 + str:byte(i)) % 2147483647 end
    return tostring(h)
end

--=============================================================
-- [06] KEY SYSTEM (SILENT)
--=============================================================
local KEYS = {
    [simpleHash("BAZZ")] = "basic",
    [simpleHash("JOY")]  = "premium",
}

local function validateKey(input)
    if not input or input == "" then return nil end
    return KEYS[simpleHash(input)]
end

local function saveKeyFile(input)
    safe(function() if writefile then writefile(KEY_FILE, simpleHash(input)) end end)
end

local function loadSavedKey()
    local ok, saved = safe(function()
        if isfile and isfile(KEY_FILE) then return readfile(KEY_FILE) end
    end)
    if ok and saved then
        for h, tier in pairs(KEYS) do
            if h == saved then return tier end
        end
    end
end

--=============================================================
-- [07] DELAYED REMOTE SCANNER
--=============================================================
local Remotes = {Steal=nil,Hatch=nil,Place=nil,Treadmill=nil,Buy=nil,Sell=nil,Claim=nil,Fusion=nil,Ring=nil,Event=nil,All={}}
local PATTERNS = {"Steal","Egg","Hatch","Place","Treadmill","Buy","Sell","Claim","Fusion","Ring","Event","Upgrade","Drop"}
local RemotesScanned = false

local function matchP(n)
    for _, p in ipairs(PATTERNS) do
        if n:lower():find(p:lower()) then return p end
    end
end

local function scanSlow(container, depth)
    depth = depth or 0
    if depth > 2 then return end
    safe(function()
        local children = container:GetChildren()
        for i, obj in ipairs(children) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("BindableEvent") then
                table.insert(Remotes.All, obj)
                local pat = matchP(obj.Name)
                if pat then
                    if pat=="Steal" and not Remotes.Steal then Remotes.Steal=obj end
                    if (pat=="Hatch" or pat=="Egg") and not Remotes.Hatch then Remotes.Hatch=obj end
                    if pat=="Place" and not Remotes.Place then Remotes.Place=obj end
                    if pat=="Treadmill" and not Remotes.Treadmill then Remotes.Treadmill=obj end
                    if pat=="Buy" and not Remotes.Buy then Remotes.Buy=obj end
                    if pat=="Sell" and not Remotes.Sell then Remotes.Sell=obj end
                    if pat=="Claim" and not Remotes.Claim then Remotes.Claim=obj end
                    if pat=="Fusion" and not Remotes.Fusion then Remotes.Fusion=obj end
                    if pat=="Ring" and not Remotes.Ring then Remotes.Ring=obj end
                    if pat=="Event" and not Remotes.Event then Remotes.Event=obj end
                end
            elseif depth < 2 and (obj:IsA("Folder") or obj:IsA("Model") or obj:IsA("ScreenGui")) then
                task.wait(0.15)  -- slow scan biar ga flag
                scanSlow(obj, depth + 1)
            end
            if i % 5 == 0 then task.wait(0.1) end
        end
    end)
end

local function delayedScan()
    task.wait(SCAN_DELAY)
    log("Starting slow remote scan...")
    scanSlow(ReplicatedStorage, 0)
    task.wait(2)
    scanSlow(LP, 0)
    RemotesScanned = true
    log("Scan complete. Remotes:", #Remotes.All)
end

--=============================================================
-- [08] ANTI-KICK DETECTOR (PASSIVE, NO HOOK)
--=============================================================
local AntiKick = {
    LastPos = nil,
    LastCheck = tick(),
    Frozen = 0,
}

local function checkFreeze()
    local _, _, hrp = getChar()
    if not hrp then return end
    if AntiKick.LastPos then
        local delta = (hrp.Position - AntiKick.LastPos).Magnitude
        if delta < 0.5 then
            AntiKick.Frozen = AntiKick.Frozen + 1
            if AntiKick.Frozen > 15 then
                log("Freeze detected — possible anti-cheat lock")
            end
        else
            AntiKick.Frozen = 0
        end
    end
    AntiKick.LastPos = hrp.Position
end

--=============================================================
-- [09] REJOIN ENGINE (ANTI-PUTUS)
--=============================================================
local Rejoin = {
    Active = false,
    Retries = 0,
}

function Rejoin.trigger(reason)
    if Rejoin.Active then return end
    Rejoin.Active = true
    log("Rejoin triggered:", reason)
    notify("Anti-Putus", "Reconnecting...", 3)
    task.spawn(function()
        for attempt = 1, Config.Rejoin.MaxRetry do
            local ok = safe(function()
                TeleportService:Teleport(game.PlaceId, LP)
            end)
            if ok then return end
            task.wait(Config.Rejoin.RetryDelay)
        end
        -- fallback: cari server baru
        safe(function()
            local r = game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
            local d = HttpService:JSONDecode(r)
            for _, s in ipairs(d.data) do
                if s.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LP)
                    return
                end
            end
        end)
    end)
end

-- Heartbeat monitor
RunService.Heartbeat:Connect(function()
    BAZZ.LastHeartbeat = tick()
    if not LP.Parent or not workspace or not game.JobId or game.JobId == "" then
        Rejoin.trigger("state invalid")
    end
end)

-- Player removing (own)
Players.PlayerRemoving:Connect(function(plr)
    if plr == LP then
        BAZZ.Kicked = true
        log("Self removed — rejoining")
        -- coba rejoin setelah 2 detik
        task.wait(2)
        safe(function()
            TeleportService:Teleport(game.PlaceId, LP)
        end)
    end
end)

-- Heartbeat gap monitor
task.spawn(function()
    while true do
        task.wait(5)
        local gap = tick() - BAZZ.LastHeartbeat
        if gap > 15 then
            log("Heartbeat gap:", gap, "— rejoining")
            Rejoin.trigger("heartbeat gap")
        end
    end
end)

--=============================================================
-- [10] WORKER MANAGER
--=============================================================
local function newW(name, fn)
    if BAZZ.Workers[name] then return end
    BAZZ.Workers[name] = {running=true}
    local w = BAZZ.Workers[name]
    task.spawn(function()
        while w.running do
            local ok, err = pcall(fn)
            if not ok then log("w["..name.."]", err) end
            task.wait(rndD(0.15))
        end
    end)
end
local function stopW(name)
    if BAZZ.Workers[name] then BAZZ.Workers[name].running=false; BAZZ.Workers[name]=nil end
end

--=============================================================
-- [11] RESPAWN
--=============================================================
LP.CharacterAdded:Connect(function(c)
    CH = c
    HRP = c:WaitForChild("HumanoidRootPart", 10)
    HUM = c:WaitForChild("Humanoid", 10)
    task.wait(2)
    if HUM then safe(function()
        if not Config.Movement.Speed then HUM.WalkSpeed = 16 end
        if not Config.Movement.Jump then HUM.JumpPower = 50; HUM.UseJumpPower = true end
    end) end
end)

--=============================================================
-- [12] ESP ENGINE
--=============================================================
local cam = workspace.CurrentCamera
local function w2s(pos)
    local sp, on = cam:WorldToViewportPoint(pos)
    if not on or sp.Z < 0 then return nil end
    return Vector2.new(sp.X, sp.Y)
end

local ESP = {}
function ESP.clear(k)
    if not BAZZ.Drawings[k] then return end
    for _, d in pairs(BAZZ.Drawings[k]) do pcall(function() d:Remove() end) end
    BAZZ.Drawings[k] = {}
end
function ESP.folder(k)
    if not BAZZ.Drawings[k] then BAZZ.Drawings[k] = {} end
    return BAZZ.Drawings[k]
end

newW("ESP_Egg", function()
    if not Config.ESP.Egg.Enabled then ESP.clear("Egg"); return end
    local F = ESP.folder("Egg"); local live = {}
    local _, _, hrp = getChar(); if not hrp then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("egg") then
            local d = dist(hrp.Position, obj.Position)
            if d <= Config.ESP.Egg.MaxDistance then
                local dr = F[obj]
                if not dr then
                    dr = { box = Drawing.new("Square"), txt = Drawing.new("Text") }
                    dr.box.Thickness=1; dr.box.Filled=false
                    dr.txt.Size=14; dr.txt.Center=true; dr.txt.Outline=true
                    F[obj] = dr
                end
                local sp = w2s(obj.Position)
                if sp then
                    if Config.ESP.Egg.Box then
                        local s = 40
                        dr.box.Size = Vector2.new(s,s)
                        dr.box.Position = sp - Vector2.new(s/2,s/2)
                        dr.box.Color = Config.ESP.Egg.Color
                        dr.box.Visible = true
                    else dr.box.Visible=false end
                    local label = obj.Name
                    if Config.ESP.Egg.Distance then label = label.." ["..math.floor(d).."m]" end
                    dr.txt.Text = label
                    dr.txt.Position = sp - Vector2.new(0,25)
                    dr.txt.Color = Config.ESP.Egg.Color
                    dr.txt.Visible = true
                else
                    dr.box.Visible=false; dr.txt.Visible=false
                end
                live[obj] = true
            end
        end
    end
    for k, dr in pairs(F) do
        if not live[k] then pcall(function() dr.box:Remove(); dr.txt:Remove() end); F[k]=nil end
    end
end)

newW("ESP_Guardian", function()
    if not Config.ESP.Guardian.Enabled then ESP.clear("Guardian"); return end
    local F = ESP.folder("Guardian"); local live = {}
    local _, _, hrp = getChar(); if not hrp then return end
    for _, m in ipairs(workspace:GetDescendants()) do
        if m:IsA("Model") and (m.Name:lower():find("guardian") or m.Name:lower():find("monster")) then
            local root = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChildWhichIsA("BasePart")
            if root then
                local d = dist(hrp.Position, root.Position)
                local dr = F[m]
                if not dr then
                    dr = { line = Drawing.new("Line"), txt = Drawing.new("Text") }
                    dr.line.Thickness=1; dr.txt.Size=14; dr.txt.Center=true; dr.txt.Outline=true
                    F[m] = dr
                end
                local sp = w2s(root.Position)
                if sp then
                    dr.line.From = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
                    dr.line.To = sp
                    dr.line.Color = Config.ESP.Guardian.Color
                    dr.line.Visible = true
                    dr.txt.Text = m.Name.." ["..math.floor(d).."m]"
                    dr.txt.Position = sp
                    dr.txt.Color = Config.ESP.Guardian.Color
                    dr.txt.Visible = true
                else
                    dr.line.Visible=false; dr.txt.Visible=false
                end
                live[m] = true
            end
        end
    end
    for k, dr in pairs(F) do
        if not live[k] then pcall(function() dr.line:Remove(); dr.txt:Remove() end); F[k]=nil end
    end
end)

newW("ESP_Player", function()
    if not Config.ESP.Player.Enabled then ESP.clear("Player"); return end
    local F = ESP.folder("Player"); local live = {}
    local _, _, my = getChar(); if not my then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            local h = plr.Character:FindFirstChildOfClass("Humanoid")
            if root and h and h.Health > 0 then
                local d = dist(my.Position, root.Position)
                local dr = F[plr]
                if not dr then
                    dr = { box=Drawing.new("Square"), txt=Drawing.new("Text") }
                    dr.box.Thickness=1; dr.box.Filled=false
                    dr.txt.Size=14; dr.txt.Center=true; dr.txt.Outline=true
                    F[plr] = dr
                end
                local sp = w2s(root.Position)
                if sp then
                    if Config.ESP.Player.Box then
                        local s = 36
                        dr.box.Size = Vector2.new(s,s)
                        dr.box.Position = sp - Vector2.new(s/2,s/2)
                        dr.box.Color = Config.ESP.Player.Color
                        dr.box.Visible = true
                    else dr.box.Visible=false end
                    dr.txt.Text = plr.Name.." ["..math.floor(d).."m]"
                    dr.txt.Position = sp - Vector2.new(0,25)
                    dr.txt.Color = Config.ESP.Player.Color
                    dr.txt.Visible = true
                else
                    dr.box.Visible=false; dr.txt.Visible=false
                end
                live[plr] = true
            end
        end
    end
    for k, dr in pairs(F) do
        if not live[k] then pcall(function() dr.box:Remove(); dr.txt:Remove() end); F[k]=nil end
    end
end)

--=============================================================
-- [13] EGG SCANNER
--=============================================================
local function findEggs()
    local list = {}
    local _, _, hrp = getChar(); if not hrp then return list end
    for _, egg in ipairs(workspace:GetDescendants()) do
        if egg:IsA("BasePart") and egg.Name:lower():find("egg") then
            local d = dist(hrp.Position, egg.Position)
            if d <= Config.Steal.MaxDistance and d > 2 then
                local rarity, weight, biome = "Common", 1, "Unknown"
                local rv = egg:FindFirstChild("Rarity"); if rv and rv:IsA("StringValue") then rarity = rv.Value end
                local wv = egg:FindFirstChild("Weight"); if wv and (wv:IsA("NumberValue") or wv:IsA("IntValue")) then weight = wv.Value end
                local bv = egg:FindFirstChild("Biome"); if bv and bv:IsA("StringValue") then biome = bv.Value end
                table.insert(list, {part=egg, dist=d, rarity=rarity, weight=weight, biome=biome, name=egg.Name})
            end
        end
    end
    return list
end

local function rankR(r)
    for i, v in ipairs(Config.Steal.Prioritize) do if v==r then return i end end
    return #Config.Steal.Prioritize + 1
end

local function pickEgg(list)
    if #list == 0 then return nil end
    local m = Config.Steal.Mode
    if m == "Rarest" then
        table.sort(list, function(a,b) return rankR(a.rarity) < rankR(b.rarity) end)
        return list[1]
    elseif m == "Weight" then
        table.sort(list, function(a,b) return a.weight > b.weight end)
        return list[1]
    elseif m == "Whitelist" then
        for _, e in ipairs(list) do if inT(Config.Steal.Whitelist, e.name) then return e end end
        return list[1]
    elseif m == "Random" then
        return list[math.random(1,#list)]
    end
    return list[1]
end

--=============================================================
-- [14] STEALTH FIRE (NO HOOK)
--=============================================================
local LastFire = {}
local function canFire(key, minDelay)
    local now = tick()
    local last = LastFire[key] or 0
    if now - last < rndD(minDelay or 0.75) then return false end
    LastFire[key] = now
    return true
end

local function stealthFire(remote, key, ...)
    if not remote then return false end
    if not canFire(key or remote.Name, Config.Steal.Delay) then return false end
    return pcall(function()
        if remote:IsA("RemoteEvent") then remote:FireServer(...)
        elseif remote:IsA("RemoteFunction") then remote:InvokeServer(...)
        elseif remote:IsA("BindableEvent") then remote:Fire(...) end
    end)
end

--=============================================================
-- [15] FLY
--=============================================================
local Fly = {active=false}
function Fly.on(speed)
    local _, _, hrp = getChar(); if not hrp or Fly.active then return end
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5,1e5,1e5); bv.Velocity = Vector3.zero; bv.Parent = hrp
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e5,1e5,1e5); bg.P = 1000; bg.Parent = hrp
    Fly.bv = bv; Fly.bg = bg; Fly.active = true
    Fly.conn = RunService.RenderStepped:Connect(function()
        if not Fly.active then return end
        local _, _, h = getChar(); if not h or not Fly.bv then return end
        local dir = Vector3.zero
        local cf = workspace.CurrentCamera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
        Fly.bv.Velocity = dir.Magnitude > 0 and dir.Unit * speed or Vector3.zero
        Fly.bg.CFrame = cf
    end)
    table.insert(BAZZ.Connections, Fly.conn)
end
function Fly.off()
    Fly.active = false
    if Fly.conn then pcall(function() Fly.conn:Disconnect() end); Fly.conn=nil end
    if Fly.bv then pcall(function() Fly.bv:Destroy() end); Fly.bv=nil end
    if Fly.bg then pcall(function() Fly.bg:Destroy() end); Fly.bg=nil end
end

--=============================================================
-- [16] TELEPORT
--=============================================================
local function tpTo(pos)
    local _, _, hrp = getChar(); if not hrp or not pos then return end
    hrp.CFrame = CFrame.new(pos + Vector3.new(0,3,0))
end
local function findBase()
    for _, obj in ipairs(workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if (n:find("base") or n:find("plot") or n:find("spawn")) and obj:IsA("BasePart") then
            return obj.Position
        end
    end
end

--=============================================================
-- [17] BASIC FEATURES
--=============================================================
local Basic = {}

Basic.AutoSteal = function()
    newW("AutoSteal_Basic", function()
        if not Config.Steal.Enabled or not RemotesScanned then return end
        local t = pickEgg(findEggs()); if not t then return end
        stealthFire(Remotes.Steal, "Steal", t.part)
    end)
end

Basic.AutoTreadmill = function()
    newW("AutoTreadmill", function()
        if not Config.Treadmill.Enabled or not RemotesScanned then return end
        stealthFire(Remotes.Treadmill, "Treadmill")
    end)
end

Basic.AutoHatch = function()
    newW("AutoHatch", function()
        if not Config.Hatch.Enabled or not RemotesScanned then return end
        stealthFire(Remotes.Hatch, "Hatch")
        if Config.Hatch.AutoPlace then stealthFire(Remotes.Place, "Place") end
    end)
end

Basic.AutoEvent = function()
    newW("AutoEvent_Basic", function()
        if not Config.Event.Enabled or not RemotesScanned then return end
        stealthFire(Remotes.Event, "Event")
    end)
end

Basic.AntiHit = function()
    newW("AntiHit", function()
        if not Config.Combat.AntiHit then return end
        local _, h = getChar(); if not h then return end
        safe(function()
            if h:GetState() == Enum.HumanoidStateType.Physics then
                h:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
    end)
end

Basic.AutoUpgrade = function()
    newW("AutoUpgrade", function()
        if not Config.Upgrade.Enabled or not RemotesScanned then return end
        stealthFire(Remotes.Buy, "Upgrade")
    end)
end

Basic.AutoBuy = function()
    newW("AutoBuy", function()
        if not Config.Buy.Enabled or not RemotesScanned then return end
        stealthFire(Remotes.Buy, "Buy")
    end)
end

Basic.AntiAFK = function()
    safe(function()
        LP.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
end

Basic.FixLag = function()
    newW("FixLag", function()
        if not Config.FixLag.Enabled then return end
        safe(function()
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1 end
                if v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false end
            end
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 100000
        end)
        task.wait(3)
    end)
end

Basic.Save = function()
    safe(function()
        if writefile then writefile(CONFIG_FILE, HttpService:JSONEncode(Config)) end
        notify("Config", "Saved", 2)
    end)
end

Basic.Load = function()
    safe(function()
        if isfile and isfile(CONFIG_FILE) then
            local d = HttpService:JSONDecode(readfile(CONFIG_FILE))
            for k,v in pairs(d) do
                if type(v)=="table" and Config[k] then
                    for k2,v2 in pairs(v) do Config[k][k2] = v2 end
                else Config[k] = v end
            end
            notify("Config", "Loaded", 2)
        end
    end)
end

Basic.Noclip = function()
    newW("Noclip", function()
        if not Config.Movement.Noclip then return end
        local c = LP.Character; if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end)
end

--=============================================================
-- [18] PREMIUM FEATURES
--=============================================================
local Premium = {}

Premium.AutoStealV2 = function()
    newW("AutoSteal_V2", function()
        if not Config.Steal.Enabled or not RemotesScanned then return end
        local eggs = findEggs()
        if #Config.Steal.Biomes > 0 then
            local f = {}; for _, e in ipairs(eggs) do if inT(Config.Steal.Biomes, e.biome) then table.insert(f, e) end end
            eggs = f
        end
        local t = pickEgg(eggs); if not t then return end
        if Config.Steal.UseFly then
            if not Fly.active then Fly.on(Config.Steal.FlySpeed) end
            local _, _, hrp = getChar()
            if hrp then
                local dir = t.part.Position - hrp.Position
                if dir.Magnitude > 6 then hrp.CFrame = hrp.CFrame + dir.Unit * math.min(dir.Magnitude, 25) * 0.1 end
            end
        end
        stealthFire(Remotes.Steal, "Steal", t.part)
    end)
end

Premium.AutoAngel = function()
    newW("AutoAngel", function()
        if not Config.Steal.Enabled or not RemotesScanned then return end
        for _, e in ipairs(findEggs()) do
            if e.name:lower():find("angel") then stealthFire(Remotes.Steal, "Steal", e.part); break end
        end
    end)
end

Premium.AutoDemon = function()
    newW("AutoDemon", function()
        if not Config.Steal.Enabled or not RemotesScanned then return end
        for _, e in ipairs(findEggs()) do
            if e.name:lower():find("demon") then stealthFire(Remotes.Steal, "Steal", e.part); break end
        end
    end)
end

Premium.MergedDet = function()
    newW("MergedDet", function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if (n:find("merged") or n:find("aetheron")) and obj:IsA("BasePart") then
                notify("Merged", "Detected!", 3)
                task.wait(3)
            end
        end
    end)
end

Premium.NightDet = function()
    newW("NightDet", function()
        local c = Lighting.ClockTime
        if c > 18 or c < 6 then
            for _, obj in ipairs(workspace:GetDescendants()) do
                local n = obj.Name:lower()
                if (n:find("angel") or n:find("demon")) and obj:IsA("BasePart") then
                    notify("Night", obj.Name, 3); task.wait(3)
                end
            end
        end
        task.wait(2)
    end)
end

Premium.AutoRing = function()
    newW("AutoRing", function()
        if not Config.Event.Ring or not RemotesScanned then return end
        stealthFire(Remotes.Ring, "Ring"); stealthFire(Remotes.Event, "Ring")
    end)
end

Premium.AutoTeamClaim = function()
    newW("AutoTeamClaim", function()
        if not Config.Event.TeamClaim or not RemotesScanned then return end
        stealthFire(Remotes.Claim, "TeamClaim")
    end)
end

Premium.AutoFusion = function()
    newW("AutoFusion", function()
        if not Config.Event.Fusion or not RemotesScanned then return end
        stealthFire(Remotes.Fusion, "Fusion")
    end)
end

Premium.AutoSell = function()
    newW("AutoSell", function()
        if not Config.Misc.AutoSell or not RemotesScanned then return end
        stealthFire(Remotes.Sell, "Sell", Config.Misc.SellRarity)
    end)
end

Premium.AutoEquipBest = function()
    newW("AutoEquipBest", function()
        if not Config.Misc.AutoEquipBest or not RemotesScanned then return end
        stealthFire(Remotes.Place, "EquipBest")
    end)
end

Premium.AutoClaimIndex = function()
    newW("AutoClaimIndex", function()
        if not Config.Misc.AutoClaimIndex or not RemotesScanned then return end
        stealthFire(Remotes.Claim, "Index")
    end)
end

Premium.AutoPlace = function()
    newW("AutoPlace", function()
        if not Config.Hatch.AutoPlace or not RemotesScanned then return end
        stealthFire(Remotes.Place, "Place")
    end)
end

Premium.AutoDropHeld = function()
    newW("AutoDropHeld", function()
        if not Config.Misc.AutoDropHeld or not RemotesScanned then return end
        local c = LP.Character; if not c then return end
        for _, v in ipairs(c:GetChildren()) do
            if v:IsA("Tool") and v.Name:lower():find("egg") then
                stealthFire(Remotes.Steal, "Drop", v)
            end
        end
    end)
end

Premium.AntiRagdoll = function()
    newW("AntiRagdoll", function()
        if not Config.Combat.AntiRagdoll then return end
        local _, h = getChar(); if h then safe(function()
            h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        end) end
    end)
end

Premium.AntiKnockback = function()
    newW("AntiKnockback", function()
        if not Config.Combat.AntiKnockback then return end
    end)
end

Premium.Godmode = function()
    newW("Godmode", function()
        if not Config.Misc.Godmode then return end
        local _, h = getChar(); if h then h.MaxHealth = math.huge end
    end)
end

Premium.SpeedMult = function()
    newW("SpeedMult", function()
        if not Config.Movement.Speed then return end
        local _, h = getChar(); if h then h.WalkSpeed = Config.Movement.SpeedValue end
    end)
end

Premium.InfJump = function()
    if Premium._infConn then return end
    Premium._infConn = UserInputService.JumpRequest:Connect(function()
        if not Config.Movement.InfJump then return end
        local _, h = getChar(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
    table.insert(BAZZ.Connections, Premium._infConn)
end

Premium.TeleportEgg = function()
    newW("TeleportEgg", function()
        if not Config.Teleport.ToEgg then return end
        local t = pickEgg(findEggs()); if t then tpTo(t.part.Position) end
        task.wait(1)
    end)
end

Premium.TeleportBase = function()
    newW("TeleportBase", function()
        if not Config.Teleport.ToBase then return end
        local b = findBase(); if b then tpTo(b) end
        task.wait(1.2)
    end)
end

Premium.ServerHop = function()
    safe(function()
        local r = game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
        local d = HttpService:JSONDecode(r)
        for _, s in ipairs(d.data) do
            if s.playing < 3 and s.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LP); break
            end
        end
    end)
end

--=============================================================
-- [19] LOGO LOADER (SAFE FALLBACK)
--=============================================================
local LogoImage = nil
safe(function()
    if writefile and readfile and isfile and getcustomasset then
        if not isfile("bazz_logo.png") then
            local data = game:HttpGet(BAZZ.LogoURL)
            if data and #data > 100 then
                writefile("bazz_logo.png", data)
            end
        end
        if isfile("bazz_logo.png") then
            LogoImage = getcustomasset("bazz_logo.png")
        end
    end
end)
log("Logo:", LogoImage and "loaded" or "fallback")

--=============================================================
-- [20] CUSTOM UI LIBRARY
--=============================================================
local UI = {}
UI.Theme = {
    BG      = Color3.fromRGB(14,16,20),
    Sidebar = Color3.fromRGB(8,10,13),
    Card    = Color3.fromRGB(20,23,28),
    Accent  = Color3.fromRGB(0,220,120),
    Text    = Color3.fromRGB(230,230,235),
    SubText = Color3.fromRGB(140,145,155),
    Danger  = Color3.fromRGB(240,60,60),
    Border  = Color3.fromRGB(30,34,42),
}

local function newCorner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = parent
    return c
end
local function newStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or UI.Theme.Border
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

-- ScreenGui di PlayerGui (BUKAN CoreGui / gethui)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Config_"..tostring(math.random(100000,999999))
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PG  -- PlayerGui, aman

-- Watermark
local wm = Instance.new("TextLabel")
wm.Name = "wm"
wm.Size = UDim2.new(0, 220, 0, 24)
wm.Position = UDim2.new(0, 12, 0, 12)
wm.BackgroundColor3 = UI.Theme.Card
wm.BackgroundTransparency = 0.15
wm.BorderSizePixel = 0
wm.Text = "BAZZ v3.0  |  "..LP.Name
wm.TextColor3 = UI.Theme.Accent
wm.TextSize = 13
wm.Font = Enum.Font.GothamBold
wm.TextXAlignment = Enum.TextXAlignment.Center
wm.Parent = ScreenGui
newCorner(wm, 6); newStroke(wm)

-- Main Window
local Win = Instance.new("Frame")
Win.Name = "MainWin"
Win.Size = UDim2.new(0, 620, 0, 460)
Win.Position = UDim2.new(0.5, -310, 0.5, -230)
Win.BackgroundColor3 = UI.Theme.BG
Win.BorderSizePixel = 0
Win.Active = true
Win.Parent = ScreenGui
newCorner(Win, 10); newStroke(Win, UI.Theme.Accent, 1)

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = UI.Theme.Sidebar
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Win
newCorner(TitleBar, 10)

-- Logo header (kalau ada)
local LogoHolder = Instance.new("ImageLabel")
LogoHolder.Size = UDim2.new(0, 32, 0, 32)
LogoHolder.Position = UDim2.new(0, 8, 0, 4)
LogoHolder.BackgroundTransparency = 1
LogoHolder.Image = LogoImage or ""
LogoHolder.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 300, 1, 0)
Title.Position = UDim2.new(0, 46, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "BAZZ"
Title.TextColor3 = UI.Theme.Accent
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -36, 0, 5)
CloseBtn.BackgroundColor3 = UI.Theme.Danger
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar
newCorner(CloseBtn, 6)
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Drag
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Win.Position
    end
end)
TitleBar.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local d = input.Position - dragStart
        Win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 140, 1, -40)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = UI.Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Win

local TabList = Instance.new("ScrollingFrame")
TabList.Size = UDim2.new(1, 0, 1, 0)
TabList.BackgroundTransparency = 1
TabList.BorderSizePixel = 0
TabList.ScrollBarThickness = 2
TabList.CanvasSize = UDim2.new(0, 0, 0, 0)
TabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
TabList.Parent = Sidebar

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0, 4)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = TabList

local TabPadding = Instance.new("UIPadding")
TabPadding.PaddingTop = UDim.new(0, 8)
TabPadding.PaddingLeft = UDim.new(0, 8)
TabPadding.PaddingRight = UDim.new(0, 8)
TabPadding.Parent = TabList

-- Content
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -140, 1, -40)
Content.Position = UDim2.new(0, 140, 0, 40)
Content.BackgroundColor3 = UI.Theme.BG
Content.BorderSizePixel = 0
Content.Parent = Win

local ContentScroll = Instance.new("ScrollingFrame")
ContentScroll.Size = UDim2.new(1, 0, 1, 0)
ContentScroll.BackgroundTransparency = 1
ContentScroll.BorderSizePixel = 0
ContentScroll.ScrollBarThickness = 3
ContentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentScroll.Parent = Content

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 6)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = ContentScroll

local ContentPad = Instance.new("UIPadding")
ContentPad.PaddingTop = UDim.new(0, 10)
ContentPad.PaddingLeft = UDim.new(0, 12)
ContentPad.PaddingRight = UDim.new(0, 12)
ContentPad.PaddingBottom = UDim.new(0, 10)
ContentPad.Parent = ContentScroll

local Tabs = {}

function UI.Tab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = UI.Theme.Card
    btn.BackgroundTransparency = 0.5
    btn.Text = "  "..name
    btn.TextColor3 = UI.Theme.SubText
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamMedium
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    btn.Parent = TabList
    newCorner(btn, 6)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.Parent = ContentScroll

    Tabs[name] = {btn=btn, frame=frame}

    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do
            t.frame.Visible = false
            t.btn.BackgroundColor3 = UI.Theme.Card
            t.btn.TextColor3 = UI.Theme.SubText
        end
        frame.Visible = true
        btn.BackgroundColor3 = UI.Theme.Accent
        btn.TextColor3 = Color3.new(0,0,0)
    end)

    return frame
end

function UI.Section(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Text = "── "..text.." ──"
    lbl.TextColor3 = UI.Theme.Accent
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
    return lbl
end

function UI.Toggle(parent, name, default, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 32)
    f.BackgroundColor3 = UI.Theme.Card
    f.BackgroundTransparency = 0.4
    f.BorderSizePixel = 0
    f.Parent = parent
    newCorner(f, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = UI.Theme.Text
    lbl.TextSize = 13
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f

    local state = default or false
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 40, 0, 20)
    indicator.Position = UDim2.new(1, -50, 0.5, -10)
    indicator.BackgroundColor3 = state and UI.Theme.Accent or UI.Theme.Border
    indicator.BorderSizePixel = 0
    indicator.Parent = f
    newCorner(indicator, 10)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    knob.Parent = indicator
    newCorner(knob, 8)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = f

    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(indicator, TweenInfo.new(0.15), {BackgroundColor3 = state and UI.Theme.Accent or UI.Theme.Border}):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
        if callback then pcall(callback, state) end
    end)
    return f
end

function UI.Slider(parent, name, min, max, default, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 46)
    f.BackgroundColor3 = UI.Theme.Card
    f.BackgroundTransparency = 0.4
    f.BorderSizePixel = 0
    f.Parent = parent
    newCorner(f, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 20)
    lbl.Position = UDim2.new(0, 10, 0, 2)
    lbl.BackgroundTransparency = 1
    lbl.Text = name..": "..tostring(default)
    lbl.TextColor3 = UI.Theme.Text
    lbl.TextSize = 13
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -20, 0, 6)
    track.Position = UDim2.new(0, 10, 0, 30)
    track.BackgroundColor3 = UI.Theme.Border
    track.BorderSizePixel = 0
    track.Parent = f
    newCorner(track, 3)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = UI.Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    newCorner(fill, 3)

    local dragging = false
    local function update(input)
        local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max-min) * rel + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = name..": "..tostring(val)
        if callback then pcall(callback, val) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; update(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then update(input) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    return f
end

function UI.Button(parent, name, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 30)
    b.BackgroundColor3 = UI.Theme.Card
    b.Text = name
    b.TextColor3 = UI.Theme.Text
    b.TextSize = 13
    b.Font = Enum.Font.GothamMedium
    b.BorderSizePixel = 0
    b.Parent = parent
    newCorner(b, 6); newStroke(b)
    b.MouseButton1Click:Connect(function()
        if callback then pcall(callback) end
    end)
    return b
end

function UI.Dropdown(parent, name, options, default, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 30)
    f.BackgroundColor3 = UI.Theme.Card
    f.BackgroundTransparency = 0.4
    f.BorderSizePixel = 0
    f.Parent = parent
    newCorner(f, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name..": "..(default or options[1] or "")
    lbl.TextColor3 = UI.Theme.Text
    lbl.TextSize = 13
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = f

    local idx = 1
    for i, o in ipairs(options) do if o == (default or options[1]) then idx = i end end

    btn.MouseButton1Click:Connect(function()
        idx = idx + 1
        if idx > #options then idx = 1 end
        lbl.Text = name..": "..options[idx]
        if callback then pcall(callback, options[idx]) end
    end)
    return f
end

function UI.TextBox(parent, placeholder, callback)
    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(1, 0, 0, 30)
    tb.BackgroundColor3 = UI.Theme.Card
    tb.Text = ""
    tb.PlaceholderText = placeholder
    tb.PlaceholderColor3 = UI.Theme.SubText
    tb.TextColor3 = UI.Theme.Text
    tb.TextSize = 13
    tb.Font = Enum.Font.Gotham
    tb.ClearTextOnFocus = false
    tb.BorderSizePixel = 0
    tb.Parent = parent
    newCorner(tb, 6); newStroke(tb)
    tb.FocusLost:Connect(function(enter)
        if enter and callback then
            local ok = pcall(callback, tb.Text)
            if ok then tb.Text = "" end
        end
    end)
    return tb
end

function UI.Paragraph(parent, text)
    local p = Instance.new("TextLabel")
    p.Size = UDim2.new(1, 0, 0, 60)
    p.BackgroundColor3 = UI.Theme.Card
    p.BackgroundTransparency = 0.4
    p.Text = "  "..text
    p.TextColor3 = UI.Theme.SubText
    p.TextSize = 12
    p.Font = Enum.Font.Gotham
    p.TextWrapped = true
    p.TextXAlignment = Enum.TextXAlignment.Left
    p.BorderSizePixel = 0
    p.Parent = parent
    newCorner(p, 6)
    return p
end

--=============================================================
-- [21] KEY GATE UI
--=============================================================
local function showKeyGate()
    local gate = Instance.new("Frame")
    gate.Size = UDim2.new(0, 320, 0, 180)
    gate.Position = UDim2.new(0.5, -160, 0.5, -90)
    gate.BackgroundColor3 = UI.Theme.BG
    gate.BorderSizePixel = 0
    gate.Parent = ScreenGui
    newCorner(gate, 10); newStroke(gate, UI.Theme.Accent, 1)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "BAZZ — Access"
    title.TextColor3 = UI.Theme.Accent
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.Parent = gate

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 20)
    sub.Position = UDim2.new(0, 0, 0, 40)
    sub.BackgroundTransparency = 1
    sub.Text = "Masukkan key"
    sub.TextColor3 = UI.Theme.SubText
    sub.TextSize = 12
    sub.Font = Enum.Font.Gotham
    sub.Parent = gate

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -40, 0, 36)
    box.Position = UDim2.new(0, 20, 0, 68)
    box.BackgroundColor3 = UI.Theme.Card
    box.Text = ""
    box.PlaceholderText = ""
    box.TextColor3 = UI.Theme.Text
    box.TextSize = 14
    box.Font = Enum.Font.Gotham
    box.ClearTextOnFocus = false
    box.BorderSizePixel = 0
    box.Parent = gate
    newCorner(box, 6); newStroke(box)

    local submit = Instance.new("TextButton")
    submit.Size = UDim2.new(1, -40, 0, 34)
    submit.Position = UDim2.new(0, 20, 0, 118)
    submit.BackgroundColor3 = UI.Theme.Accent
    submit.Text = "Submit"
    submit.TextColor3 = Color3.new(0,0,0)
    submit.TextSize = 14
    submit.Font = Enum.Font.GothamBold
    submit.BorderSizePixel = 0
    submit.Parent = gate
    newCorner(submit, 6)

    local attempts = 0

    submit.MouseButton1Click:Connect(function()
        local input = box.Text
        local tier = validateKey(input)
        if tier then
            BAZZ.Tier = tier
            BAZZ.Key = input
            saveKeyFile(input)
            gate:Destroy()
            notify("BAZZ", "Unlocked — tier: "..tier, 4)
            if _G.BAZZ_BuildUI then _G.BAZZ_BuildUI() end
        else
            attempts = attempts + 1
            notify("BAZZ", "Key salah ("..attempts.."/3)", 3)
            box.Text = ""
            if attempts >= 3 then
                gate:Destroy()
            end
        end
    end)
end

--=============================================================
-- [22] BUILD UI
--=============================================================
_G.BAZZ_BuildUI = function()
    local isPrem = function() return BAZZ.Tier == "premium" end

    local T = {}
    T.Main     = UI.Tab("Main")
    T.Steal    = UI.Tab("Steal")
    T.Auto     = UI.Tab("Auto")
    T.Visual   = UI.Tab("Visual")
    T.Movement = UI.Tab("Movement")
    T.Events   = UI.Tab("Events")
    T.Settings = UI.Tab("Settings")
    T.Info     = UI.Tab("Info")

    Tabs["Main"].btn.MouseButton1Click:Fire()

    -- MAIN
    UI.Section(T.Main, "Quick")
    UI.Button(T.Main, "Save Config", Basic.Save)
    UI.Button(T.Main, "Load Config", Basic.Load)

    UI.Toggle(T.Main, "Auto Steal (Basic)", false, function(v)
        Config.Steal.Enabled = v
        if v then Basic.AutoSteal() else stopW("AutoSteal_Basic") end
    end)
    UI.Toggle(T.Main, "Auto Treadmill", false, function(v)
        Config.Treadmill.Enabled = v
        if v then Basic.AutoTreadmill() else stopW("AutoTreadmill") end
    end)
    UI.Toggle(T.Main, "Auto Hatch", false, function(v)
        Config.Hatch.Enabled = v
        if v then Basic.AutoHatch() else stopW("AutoHatch") end
    end)
    UI.Toggle(T.Main, "Auto Event", false, function(v)
        Config.Event.Enabled = v
        if v then Basic.AutoEvent() else stopW("AutoEvent_Basic") end
    end)
    UI.Toggle(T.Main, "Anti Hit", false, function(v)
        Config.Combat.AntiHit = v
        if v then Basic.AntiHit() else stopW("AntiHit") end
    end)
    UI.Toggle(T.Main, "Auto Upgrade", false, function(v)
        Config.Upgrade.Enabled = v
        if v then Basic.AutoUpgrade() else stopW("AutoUpgrade") end
    end)
    UI.Toggle(T.Main, "Auto Buy", false, function(v)
        Config.Buy.Enabled = v
        if v then Basic.AutoBuy() else stopW("AutoBuy") end
    end)
    UI.Toggle(T.Main, "Anti AFK", true, function(v) Config.AntiAFK.Enabled = v end)
    UI.Toggle(T.Main, "Fix Lag", false, function(v)
        Config.FixLag.Enabled = v
        if v then Basic.FixLag() else stopW("FixLag") end
    end)
    UI.Button(T.Main, "Bypass: LOCKED ON", function()
        notify("Bypass", "Locked ON", 3)
    end)

    -- STEAL
    UI.Section(T.Steal, "Premium Steal")
    UI.Toggle(T.Steal, "[P] Auto Steal V2", false, function(v)
        if v and not isPrem() then notify("Locked","Butuh premium",3); return end
        Config.Steal.Enabled = v
        if v then Premium.AutoStealV2() else stopW("AutoSteal_V2") end
    end)
    UI.Dropdown(T.Steal, "[P] Mode", {"Rarest","Weight","Whitelist","Random","All"}, "Rarest", function(o)
        if isPrem() then Config.Steal.Mode = o end
    end)
    UI.Slider(T.Steal, "[P] Delay", 0.5, 2.0, 0.75, function(v)
        if isPrem() then Config.Steal.Delay = v end
    end)
    UI.Slider(T.Steal, "[P] Fly Speed", 50, 400, 180, function(v)
        if isPrem() then Config.Steal.FlySpeed = v; if Fly.active then Fly.off(); Fly.on(v) end end
    end)
    UI.Toggle(T.Steal, "[P] Use Fly", true, function(v) if isPrem() then Config.Steal.UseFly = v end end)
    UI.Toggle(T.Steal, "[P] Return to Base", true, function(v) if isPrem() then Config.Steal.ReturnToBase = v end end)
    UI.Toggle(T.Steal, "[P] Humanize", true, function(v) if isPrem() then Config.Steal.Humanize = v end end)
    UI.Toggle(T.Steal, "[P] Auto Angel", false, function(v)
        if v and not isPrem() then return end
        if v then Premium.AutoAngel() else stopW("AutoAngel") end
    end)
    UI.Toggle(T.Steal, "[P] Auto Demon", false, function(v)
        if v and not isPrem() then return end
        if v then Premium.AutoDemon() else stopW("AutoDemon") end
    end)

    -- AUTO
    UI.Section(T.Auto, "Automation")
    UI.Toggle(T.Auto, "[P] Auto Place Egg", false, function(v)
        if v and not isPrem() then return end
        Config.Hatch.AutoPlace = v
        if v then Premium.AutoPlace() else stopW("AutoPlace") end
    end)
    UI.Toggle(T.Auto, "[P] Auto Sell Trash", false, function(v)
        if v and not isPrem() then return end
        Config.Misc.AutoSell = v
        if v then Premium.AutoSell() else stopW("AutoSell") end
    end)
    UI.Toggle(T.Auto, "[P] Auto Equip Best", false, function(v)
        if v and not isPrem() then return end
        Config.Misc.AutoEquipBest = v
        if v then Premium.AutoEquipBest() else stopW("AutoEquipBest") end
    end)
    UI.Toggle(T.Auto, "[P] Auto Claim Index", false, function(v)
        if v and not isPrem() then return end
        Config.Misc.AutoClaimIndex = v
        if v then Premium.AutoClaimIndex() else stopW("AutoClaimIndex") end
    end)
    UI.Toggle(T.Auto, "[P] Server Hop", false, function(v)
        if v and not isPrem() then return end
        if v then Premium.ServerHop() end
    end)
    UI.Toggle(T.Auto, "[P] Godmode", false, function(v)
        if v and not isPrem() then return end
        Config.Misc.Godmode = v
        if v then Premium.Godmode() else stopW("Godmode") end
    end)

    -- VISUAL
    UI.Section(T.Visual, "ESP")
    UI.Toggle(T.Visual, "ESP Egg", false, function(v) Config.ESP.Egg.Enabled = v end)
    UI.Toggle(T.Visual, "ESP Egg Box", true, function(v) Config.ESP.Egg.Box = v end)
    UI.Toggle(T.Visual, "ESP Egg Name", true, function(v) Config.ESP.Egg.Name = v end)
    UI.Toggle(T.Visual, "ESP Egg Distance", true, function(v) Config.ESP.Egg.Distance = v end)
    UI.Slider(T.Visual, "ESP Max Dist", 100, 10000, 3000, function(v) Config.ESP.Egg.MaxDistance = v end)
    UI.Toggle(T.Visual, "[P] ESP Guardian", false, function(v)
        if v and not isPrem() then return end
        Config.ESP.Guardian.Enabled = v
    end)
    UI.Toggle(T.Visual, "[P] ESP Player", false, function(v)
        if v and not isPrem() then return end
        Config.ESP.Player.Enabled = v
    end)

    -- MOVEMENT
    UI.Section(T.Movement, "Movement")
    UI.Toggle(T.Movement, "Fly", false, function(v)
        Config.Movement.Fly = v
        if v then Fly.on(Config.Movement.FlySpeed) else Fly.off() end
    end)
    UI.Slider(T.Movement, "Fly Speed", 30, 500, 120, function(v)
        Config.Movement.FlySpeed = v
        if Fly.active then Fly.off(); Fly.on(v) end
    end)
    UI.Toggle(T.Movement, "Noclip", false, function(v)
        Config.Movement.Noclip = v
        if v then Basic.Noclip() else stopW("Noclip") end
    end)
    UI.Toggle(T.Movement, "[P] Speed", false, function(v)
        if v and not isPrem() then return end
        Config.Movement.Speed = v
        if v then Premium.SpeedMult() else
            stopW("SpeedMult")
            local _, h = getChar(); if h then h.WalkSpeed = 16 end
        end
    end)
    UI.Toggle(T.Movement, "[P] Infinite Jump", false, function(v)
        if v and not isPrem() then return end
        Config.Movement.InfJump = v
        if v then Premium.InfJump() end
    end)
    UI.Toggle(T.Movement, "[P] TP to Egg", false, function(v)
        if v and not isPrem() then return end
        Config.Teleport.ToEgg = v
        if v then Premium.TeleportEgg() else stopW("TeleportEgg") end
    end)
    UI.Toggle(T.Movement, "[P] TP to Base", false, function(v)
        if v and not isPrem() then return end
        Config.Teleport.ToBase = v
        if v then Premium.TeleportBase() else stopW("TeleportBase") end
    end)

    -- EVENTS
    UI.Section(T.Events, "Events")
    UI.Toggle(T.Events, "[P] Ring Event", false, function(v)
        if v and not isPrem() then return end
        Config.Event.Ring = v
        if v then Premium.AutoRing() else stopW("AutoRing") end
    end)
    UI.Toggle(T.Events, "[P] Team Egg Claim", false, function(v)
        if v and not isPrem() then return end
        Config.Event.TeamClaim = v
        if v then Premium.AutoTeamClaim() else stopW("AutoTeamClaim") end
    end)
    UI.Toggle(T.Events, "[P] Auto Fusion", false, function(v)
        if v and not isPrem() then return end
        Config.Event.Fusion = v
        if v then Premium.AutoFusion() else stopW("AutoFusion") end
    end)

    -- SETTINGS
    UI.Section(T.Settings, "Config")
    UI.Toggle(T.Settings, "Notifications", true, function(v) Config.General.Notify = v end)
    UI.Toggle(T.Settings, "Auto Save 60s", true, function(v) Config.General.AutoSave = v end)
    UI.Button(T.Settings, "Save Now", Basic.Save)
    UI.Button(T.Settings, "Load Now", Basic.Load)
    UI.Button(T.Settings, "Reset Movement", function()
        local _, h = getChar()
        if h then h.WalkSpeed = 16; h.JumpPower = 50 end
        Fly.off()
    end)
    UI.Toggle(T.Settings, "Auto Rejoin (Anti-Putus)", true, function(v) end)

    -- INFO
    UI.Section(T.Info, "About")
    UI.Paragraph(T.Info, "BAZZ v3.0 | Owner: "..BAZZ.Owner.." | Tier: "..tostring(BAZZ.Tier))
    UI.Paragraph(T.Info, "Remotes: "..#Remotes.All.." | Steal: "..tostring(Remotes.Steal~=nil))
    UI.Paragraph(T.Info, "Anti-Putus: ON | Rejoin retry: "..Config.Rejoin.MaxRetry.."x")
    UI.Button(T.Info, "Show Logo", function()
        if LogoImage and Drawing and Drawing.new then
            safe(function()
                local img = Drawing.new("Image")
                img.Data = LogoImage
                img.Size = Vector2.new(400,400)
                img.Position = Vector2.new(200,200)
                img.Visible = true
                task.delay(5, function() pcall(function() img:Remove() end) end)
            end)
        end
    end)
end

--=============================================================
-- [23] INIT (DELAYED)
--=============================================================
notify("BAZZ v3.0", "Booting... tunggu "..BOOT_DELAY.." detik", 5)
log("Boot started. Waiting "..BOOT_DELAY.."s before scan & UI.")

task.spawn(function()
    task.wait(SCAN_DELAY)
    delayedScan()
end)

task.spawn(function()
    task.wait(UI_DELAY)
    Basic.AntiAFK()
    -- Cek saved key
    local savedTier = loadSavedKey()
    if savedTier then
        BAZZ.Tier = savedTier
        notify("BAZZ", "Loaded — tier: "..savedTier, 4)
        _G.BAZZ_BuildUI()
    else
        showKeyGate()
    end
end)

newW("AntiSave", function()
    if not Config.General.AutoSave then return end
    task.wait(60)
    Basic.Save()
end)

newW("FreezeCheck", function()
    task.wait(3)
    checkFreeze()
end)

--=============================================================
-- [24] CLEANUP
--=============================================================
local function cleanup()
    for _, w in pairs(BAZZ.Workers) do w.running = false end
    for _, c in ipairs(BAZZ.Connections) do pcall(function() c:Disconnect() end) end
    for k,_ in pairs(BAZZ.Drawings) do ESP.clear(k) end
    Fly.off()
    local _, h = getChar()
    if h then h.WalkSpeed = 16; h.JumpPower = 50; h.UseJumpPower = true end
end

--=============================================================
-- [25] BOOT
--=============================================================
log("BAZZ v3.0 init. Owner: JOY. Boot delay: "..BOOT_DELAY.."s.")
