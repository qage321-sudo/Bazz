--[[
    Steal An Egg — Script v2.0
    Author  : joy
    Version : 2.0.0
    UI      : Custom (bukan Rayfield/Foxname)
    Map     : Steal An Egg
    Fitur   : 42 (28 Basic + 14 Premium)
    Key     : Basic (free) / Premium ("Joy")
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UIS               = game:GetService("UserInputService")
local Lighting          = game:GetService("Lighting")
local StarterGui        = game:GetService("StarterGui")
local VirtualUser       = game:GetService("VirtualUser")
local HttpService       = game:GetService("HttpService")
local TeleportService   = game:GetService("TeleportService")
local CoreGui           = game:GetService("CoreGui")
local TweenService      = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============================================================
-- CONFIG
-- ============================================================
local Config = {
    Enabled = true,
    Notify  = true,
    Key     = "",
    IsPremium = false,

    -- ESP
    ESP_Egg_Enabled       = false,
    ESP_Egg_MaxDist       = 99999,
    ESP_Egg_ShowTier      = true,
    ESP_Egg_ShowName      = true,
    ESP_Egg_ShowDist      = true,
    ESP_Player_Enabled    = false,
    ESP_Player_Name       = true,
    ESP_Player_HP         = true,
    ESP_Player_Dist       = true,
    ESP_Base_Enabled      = false,
    ESP_Antena_Enabled    = false,
    ESP_Antena_Height     = 250,
    ESP_Antena_Thickness  = 2,
    ESP_Biome_Enabled     = false,
    ESP_Event_Enabled     = false,

    -- Steal
    Steal_Enabled         = false,
    Steal_Priority        = "Nearest",
    Steal_Delay           = 0.5,
    Steal_Filter          = "All",
    Steal_FilterName      = "",
    ReturnBase_Enabled    = false,
    ReturnBase_Delay      = 0.3,

    -- Collect
    CollectEgg_Enabled    = false,
    CollectEgg_Range      = 100,
    Deposit_Enabled       = false,
    Deposit_Interval      = 0.5,
    Hatch_Enabled         = false,
    FarmTreadmill_Enabled = false,

    -- Auto
    Rebirth_Enabled       = false,
    Rebirth_Interval      = 5,
    BuyEgg_Enabled        = false,
    BuyEgg_Tier           = "All",
    Upgrade_Enabled       = false,
    ClaimDaily_Enabled    = false,
    AutoEvent_Enabled     = false,
    AutoRift_Enabled      = false,
    AutoMerged_Enabled    = false,

    -- Defense
    GodMode_Enabled       = false,
    GodMode_LockHP        = 1000,
    AntiGuardian_Enabled  = false,
    AntiSteal_Enabled     = false,

    -- Movement
    Speed_Enabled         = false,
    Speed_Value           = 60,
    InfJump_Enabled       = false,
    Fly_Enabled           = false,
    Fly_Speed             = 50,
    NoClip_Enabled        = false,

    -- Visual
    FullBright_Enabled    = false,

    -- Premium
    StealFly_Enabled      = false,
    StealFly_Speed        = 120,
    SilentSteal_Enabled   = false,
    PriorityDivine_Enabled= false,
    KillAura_Enabled      = false,
    KillAura_Range        = 30,

    -- Misc
    AntiAFK_Enabled       = true,
    Bypass_MaxSpeed       = 60,
}

-- ============================================================
-- TIER DATA
-- ============================================================
local TierOrder = {
    "Common", "Uncommon", "Rare", "Epic", "Legendary",
    "Mythic", "Cosmic", "Secret", "Eternal", "Divine"
}

local TierColor = {
    Common    = Color3.fromRGB(180, 180, 180),
    Uncommon  = Color3.fromRGB(100, 255, 100),
    Rare      = Color3.fromRGB(80, 150, 255),
    Epic      = Color3.fromRGB(180, 80, 255),
    Legendary = Color3.fromRGB(255, 200, 50),
    Mythic    = Color3.fromRGB(255, 100, 200),
    Cosmic    = Color3.fromRGB(150, 100, 255),
    Secret    = Color3.fromRGB(255, 80, 80),
    Eternal   = Color3.fromRGB(255, 255, 100),
    Divine    = Color3.fromRGB(255, 255, 255),
}

local TierValue = {
    Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5,
    Mythic=6, Cosmic=7, Secret=8, Eternal=9, Divine=10
}

local BiomeList = {
    "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano",
    "Abyss Ocean", "Prehistoric", "Cosmic", "Cherry Blossom",
    "Titan Temple"
}

local EventKeywords = {
    "angel", "demon", "daemon", "rift", "meteor", "airdrop", "air drop",
    "boss", "titan", "event", "raid", "admin", "merged"
}

-- ============================================================
-- STATE
-- ============================================================
local State = {
    Conns         = {},
    ESP           = {},
    EggESP        = {},
    BaseESP       = {},
    BiomeESP      = {},
    EventESP      = {},
    UI            = {},
    Watermark     = nil,
    SpeedBV       = nil,
    FlyBV         = nil,
    FlyBG         = nil,
    OrigWS        = 16,
    Hooked        = false,
    LastSteal     = 0,
    LastDeposit   = 0,
    LastRebirth   = 0,
    OrigLight     = {
        Ambient        = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Brightness     = Lighting.Brightness,
        FogEnd         = Lighting.FogEnd,
        GlobalShadows  = Lighting.GlobalShadows,
    },
}

-- ============================================================
-- UTIL
-- ============================================================
local function Notify(title, text)
    if not Config.Notify then return end
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 3 })
    end)
end

local function GetChar(plr)
    if not plr then return nil end
    local c = plr.Character
    if not c then return nil end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return nil end
    return c, hrp, hum
end

local function W2S(pos)
    local sp, on = Camera:WorldToViewportPoint(pos)
    if not on or sp.Z <= 0 then return nil end
    return Vector2.new(sp.X, sp.Y)
end

local function GetMyHRP()
    local c = LP.Character
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart")
end

local function FirePrompt(obj)
    if not obj then return end
    local pp = obj:FindFirstChildOfClass("ProximityPrompt")
    if not pp then
        for _, d in ipairs(obj:GetDescendants()) do
            if d:IsA("ProximityPrompt") then pp = d; break end
        end
    end
    if pp then pcall(function() fireproximityprompt(pp) end) end
end

local function IsEgg(obj)
    if not obj then return false end
    local nm = obj.Name:lower()
    return nm:find("egg") and not nm:find("eggshell")
end

local function IsBase(obj)
    if not obj then return false end
    local nm = obj.Name:lower()
    return nm:find("base") or nm:find("plot") or nm:find("pen") or nm:find("farm")
end

local function GetEggTier(egg)
    if not egg then return "Common" end
    local nm = egg.Name:lower()

    -- Cek attribute dulu
    local attr = egg:GetAttribute("Rarity")
        or egg:GetAttribute("Tier")
        or egg:GetAttribute("Type")
    if attr then
        for _, t in ipairs(TierOrder) do
            if tostring(attr):lower() == t:lower() then return t end
        end
    end

    -- Fallback ke nama
    for i = #TierOrder, 1, -1 do
        local t = TierOrder[i]
        if nm:find(t:lower()) then return t end
    end
    return "Common"
end

local function TierColor3(tier)
    return TierColor[tier] or Color3.fromRGB(200, 200, 200)
end

local function GetEggsInMap()
    local eggs = {}
    local myHRP = GetMyHRP()
    if not myHRP then return eggs end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and IsEgg(obj) then
            local tier = GetEggTier(obj)
            local d = (obj.Position - myHRP.Position).Magnitude
            table.insert(eggs, { Part = obj, Distance = d, Tier = tier, TierVal = TierValue[tier] or 1 })
        end
    end
    return eggs
end

local function IsFiring()
    if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return true end
    if UIS.TouchEnabled and #UIS:GetTouches() > 0 then return true end
    return false
end

local function IsPremiumOnly(featureName)
    if Config.IsPremium then return true end
    Notify("Premium Only", featureName .. " cuma buat Premium. ketik key 'Joy'.")
    return false
end

-- ============================================================
-- HOOKS (Bypass + God Mode)
-- ============================================================
local function SetupHooks()
    if State.Hooked then return end
    State.Hooked = true

    pcall(function()
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then State.OrigWS = hum.WalkSpeed end
    end)

    pcall(function()
        local mt = getrawmetatable(game)
        local on = mt.__newindex
        setreadonly(mt, false)

        mt.__newindex = newcclosure(function(self, k, v)
            if not checkcaller() and typeof(self) == "Instance" then
                if self:IsA("Humanoid") then
                    if k == "WalkSpeed" and typeof(v) == "number"
                       and v > Config.Bypass_MaxSpeed and not Config.Speed_Enabled and not Config.StealFly_Enabled then
                        return on(self, k, Config.Bypass_MaxSpeed)
                    end
                    if Config.GodMode_Enabled and k == "Health" and typeof(v) == "number" then
                        if v < Config.GodMode_LockHP and self.Parent == LP.Character then
                            return on(self, k, Config.GodMode_LockHP)
                        end
                    end
                end
            end
            return on(self, k, v)
        end)

        setreadonly(mt, true)
    end)
end

local function RunBypassTick()
    local c = LP.Character
    if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if hum.WalkSpeed > Config.Bypass_MaxSpeed and not Config.Speed_Enabled and not Config.StealFly_Enabled then
        hum.WalkSpeed = State.OrigWS
    end
end

-- ============================================================
-- STEAL EGG
-- ============================================================
local function FilterEgg(egg)
    if Config.Steal_Filter == "All" then return true end
    if Config.Steal_Filter == "Priority" then
        return egg.Tier == Config.Steal_FilterName
    end
    return true
end

local function RunStealEgg()
    if not Config.Steal_Enabled then return end
    local now = tick()
    if now - State.LastSteal < Config.Steal_Delay then return end
    State.LastSteal = now

    local myHRP = GetMyHRP()
    if not myHRP then return end

    local eggs = GetEggsInMap()
    if #eggs == 0 then return end

    -- Filter
    local filtered = {}
    for _, e in ipairs(eggs) do
        if FilterEgg(e) then table.insert(filtered, e) end
    end
    if #filtered == 0 then return end

    -- Premium: Priority Divine/Rare
    if Config.PriorityDivine_Enabled and Config.IsPremium then
        table.sort(filtered, function(a, b)
            return (a.TierVal or 0) > (b.TierVal or 0)
        end)
    elseif Config.Steal_Priority == "Nearest" then
        table.sort(filtered, function(a, b) return a.Distance < b.Distance end)
    elseif Config.Steal_Priority == "Rarest" then
        table.sort(filtered, function(a, b) return (a.TierVal or 0) > (b.TierVal or 0) end)
    elseif Config.Steal_Priority == "LowestTier" then
        table.sort(filtered, function(a, b) return (a.TierVal or 0) < (b.TierVal or 0) end)
    end

    local target = filtered[1]
    if not target then return end

    -- Teleport ke egg
    if Config.StealFly_Enabled and Config.IsPremium then
        -- Premium pakai fly-style teleport (smooth + no clip sementara)
        pcall(function()
            myHRP.CFrame = CFrame.new(target.Part.Position + Vector3.new(0, 8, 0))
        end)
    else
        -- Basic pakai daratan + speed tinggi
        pcall(function()
            myHRP.CFrame = CFrame.new(target.Part.Position + Vector3.new(0, 3, 0))
        end)
    end

    -- Trigger pickup
    if Config.SilentSteal_Enabled and Config.IsPremium then
        pcall(function()
            firetouchinterest(myHRP, target.Part, 0)
            task.wait(0.05)
            firetouchinterest(myHRP, target.Part, 1)
        end)
    else
        FirePrompt(target.Part)
        pcall(function()
            firetouchinterest(myHRP, target.Part, 0)
            task.wait()
            firetouchinterest(myHRP, target.Part, 1)
        end)
    end

    -- Return base
    if Config.ReturnBase_Enabled then
        task.wait(Config.ReturnBase_Delay)
        RunReturnBase()
    end
end

function RunReturnBase()
    local myHRP = GetMyHRP()
    if not myHRP then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and IsBase(obj) then
            local owner = obj:GetAttribute("Owner") or obj:GetAttribute("Player") or obj:GetAttribute("UserId")
            if owner and tostring(owner) == tostring(LP.UserId) then
                pcall(function() myHRP.CFrame = CFrame.new(obj.Position + Vector3.new(0, 5, 0)) end)
                return
            end
        end
    end
end

-- ============================================================
-- COLLECT / DEPOSIT / HATCH / TREADMILL
-- ============================================================
local function RunCollectEgg()
    if not Config.CollectEgg_Enabled then return end
    local myHRP = GetMyHRP()
    if not myHRP then return end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and IsEgg(obj) then
            if (obj.Position - myHRP.Position).Magnitude <= Config.CollectEgg_Range then
                pcall(function() obj.CFrame = myHRP.CFrame end)
                FirePrompt(obj)
                pcall(function()
                    firetouchinterest(myHRP, obj, 0)
                    task.wait()
                    firetouchinterest(myHRP, obj, 1)
                end)
            end
        end
    end
end

local function RunDeposit()
    if not Config.Deposit_Enabled then return end
    local now = tick()
    if now - State.LastDeposit < Config.Deposit_Interval then return end
    State.LastDeposit = now
    for _, obj in ipairs(workspace:GetDescendants()) do
        local nm = obj.Name:lower()
        if nm:find("storage") or nm:find("deposit") or nm:find("pen") then
            FirePrompt(obj)
        end
    end
end

local function RunHatch()
    if not Config.Hatch_Enabled then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        local nm = obj.Name:lower()
        if nm:find("hatch") or nm:find("incubator") or nm:find("nest") then
            FirePrompt(obj)
        end
    end
end

local function RunFarmTreadmill()
    if not Config.FarmTreadmill_Enabled then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        local nm = obj.Name:lower()
        if nm:find("treadmill") or nm:find("farm") or nm:find("grind") then
            FirePrompt(obj)
        end
    end
end

-- ============================================================
-- AUTO
-- ============================================================
local function RunRebirth()
    if not Config.Rebirth_Enabled then return end
    local now = tick()
    if now - State.LastRebirth < Config.Rebirth_Interval then return end
    State.LastRebirth = now
    for _, obj in ipairs(workspace:GetDescendants()) do
        local nm = obj.Name:lower()
        if nm:find("rebirth") then FirePrompt(obj) end
    end
end

local function RunBuyEgg()
    if not Config.BuyEgg_Enabled then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        local nm = obj.Name:lower()
        if nm:find("shop") or nm:find("buy") then
            if Config.BuyEgg_Tier == "All" then
                FirePrompt(obj)
            else
                if GetEggTier(obj) == Config.BuyEgg_Tier then FirePrompt(obj) end
            end
        end
    end
end

local function RunUpgrade()
    if not Config.Upgrade_Enabled then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        local nm = obj.Name:lower()
        if nm:find("upgrade") then FirePrompt(obj) end
    end
end

local function RunClaimDaily()
    if not Config.ClaimDaily_Enabled then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        local nm = obj.Name:lower()
        if nm:find("daily") or nm:find("gift") or nm:find("reward") then
            FirePrompt(obj)
        end
    end
end

local function RunAutoEvent()
    if not Config.AutoEvent_Enabled then return end
    local myHRP = GetMyHRP()
    if not myHRP then return end

    for _, obj in ipairs(workspace:GetDescendants()) do
        local nm = obj.Name:lower()
        for _, kw in ipairs(EventKeywords) do
            if nm:find(kw) then
                if obj:IsA("BasePart") then
                    pcall(function() myHRP.CFrame = CFrame.new(obj.Position + Vector3.new(0, 8, 0)) end)
                end
                FirePrompt(obj)
                break
            end
        end
    end
end

local function RunAutoRift()
    if not Config.AutoRift_Enabled then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        local nm = obj.Name:lower()
        if nm:find("rift") or nm:find("portal") or nm:find("dimension") then
            FirePrompt(obj)
        end
    end
end

local function RunAutoMerged()
    if not Config.AutoMerged_Enabled then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        local nm = obj.Name:lower()
        if nm:find("merged") or (nm:find("angel") and nm:find("demon")) then
            FirePrompt(obj)
        end
    end
end

-- ============================================================
-- DEFENSE
-- ============================================================
local function RunGodMode()
    if not Config.GodMode_Enabled then return end
    local c, hrp, hum = GetChar(LP)
    if not c then return end
    pcall(function()
        if hum.Health < Config.GodMode_LockHP then hum.Health = Config.GodMode_LockHP end
        if hum.MaxHealth < Config.GodMode_LockHP then hum.MaxHealth = Config.GodMode_LockHP end
        hum.BreakJointsOnDeath = false
    end)
end

local function RunAntiGuardian()
    if not Config.AntiGuardian_Enabled then return end
    local c = LP.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Teleport guardian away / disable
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Humanoid") and obj.Parent ~= c then
            local nm = obj.Parent.Name:lower()
            if nm:find("guardian") or nm:find("monster") or nm:find("guard") then
                pcall(function() obj.Health = 0 end)
            end
        end
    end
end

local function RunAntiSteal()
    if not Config.AntiSteal_Enabled then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and IsEgg(obj) then
            local owner = obj:GetAttribute("Owner") or obj:GetAttribute("Player") or obj:GetAttribute("UserId")
            if owner and tostring(owner) == tostring(LP.UserId) then
                pcall(function() obj.Anchored = true end)
            end
        end
    end
end

-- ============================================================
-- KILL AURA (Premium)
-- ============================================================
local function RunKillAura()
    if not Config.KillAura_Enabled then return end
    if not IsPremiumOnly("Kill Aura") then Config.KillAura_Enabled = false; return end
    local c, hrp, hum = GetChar(LP)
    if not c or not hrp then return end

    local tool = c:FindFirstChildOfClass("Tool")
    if not tool then return end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Humanoid") and obj.Parent ~= c and obj.Health > 0 then
            local ehrp = obj.Parent:FindFirstChild("HumanoidRootPart")
            if ehrp then
                if (ehrp.Position - hrp.Position).Magnitude <= Config.KillAura_Range then
                    pcall(function() tool:Activate() end)
                end
            end
        end
    end
end

-- ============================================================
-- ESP
-- ============================================================
local function newLine()
    local l = Drawing.new("Line")
    l.Thickness = 1.5; l.Transparency = 1; l.Visible = false
    return l
end

-- Player ESP
local function CreatePlayerESP(plr)
    if State.ESP[plr] then return State.ESP[plr] end
    local e = {
        Top = newLine(), Bottom = newLine(), Left = newLine(), Right = newLine(),
        Name = Drawing.new("Text"), HP = Drawing.new("Text"), Dist = Drawing.new("Text"),
        Antena = newLine(),
    }
    e.Name.Size = 13; e.Name.Center = true; e.Name.Outline = true
    e.HP.Size = 11;   e.HP.Center = true;   e.HP.Outline = true
    e.Dist.Size = 11; e.Dist.Center = true; e.Dist.Outline = true
    State.ESP[plr] = e
    return e
end

local function RemovePlayerESP(plr)
    local e = State.ESP[plr]
    if not e then return end
    for _, o in pairs(e) do pcall(function() o:Remove() end) end
    State.ESP[plr] = nil
end

local function HidePlayerESP(e)
    e.Top.Visible, e.Bottom.Visible, e.Left.Visible, e.Right.Visible = false, false, false, false
    e.Name.Visible, e.HP.Visible, e.Dist.Visible = false, false, false
    e.Antena.Visible = false
end

local function SetLine(l, a, b, col)
    l.From = a; l.To = b; l.Color = col; l.Visible = true
end

local function UpdatePlayerESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        local e = State.ESP[plr]
        if not e then
            if Config.ESP_Player_Enabled or Config.ESP_Antena_Enabled then
                e = CreatePlayerESP(plr)
            else continue end
        end
        if not Config.ESP_Player_Enabled and not Config.ESP_Antena_Enabled then
            HidePlayerESP(e); continue
        end

        local c, hrp, hum = GetChar(plr)
        if not c then HidePlayerESP(e); continue end
        local head = c:FindFirstChild("Head")
        if not head then HidePlayerESP(e); continue end

        local topPos = head.Position + Vector3.new(0, 0.6, 0)
        local botPos = hrp.Position - Vector3.new(0, 3, 0)
        local topS = W2S(topPos)
        local botS = W2S(botPos)
        if not (topS and botS) then HidePlayerESP(e); continue end

        local height = math.abs(botS.Y - topS.Y)
        local width = height * 0.55
        local cx = topS.X
        local topX = cx - width * 0.5

        local tl = Vector2.new(topX, topS.Y)
        local tr = Vector2.new(topX + width, topS.Y)
        local bl = Vector2.new(topX, botS.Y)
        local br = Vector2.new(topX + width, botS.Y)
        local col = Color3.fromRGB(255, 80, 80)

        if Config.ESP_Player_Enabled then
            SetLine(e.Top, tl, tr, col); SetLine(e.Bottom, bl, br, col)
            SetLine(e.Left, tl, bl, col); SetLine(e.Right, tr, br, col)
            if Config.ESP_Player_Name then
                e.Name.Text = plr.Name
                e.Name.Position = Vector2.new(cx, tl.Y - 16)
                e.Name.Color = Color3.fromRGB(255, 255, 255)
                e.Name.Visible = true
            else e.Name.Visible = false end
            if Config.ESP_Player_HP then
                local hp = math.floor(hum.Health)
                local maxhp = math.floor(math.max(hum.MaxHealth, 1))
                local ratio = hp / maxhp
                e.HP.Text = tostring(hp) .. "/" .. tostring(maxhp)
                e.HP.Position = Vector2.new(cx, br.Y + 2)
                e.HP.Color = Color3.fromRGB(math.floor(255 * (1 - ratio)), math.floor(255 * ratio), 0)
                e.HP.Visible = true
            else e.HP.Visible = false end
            if Config.ESP_Player_Dist then
                local d = (Camera.CFrame.Position - hrp.Position).Magnitude
                e.Dist.Text = tostring(math.floor(d)) .. "m"
                e.Dist.Position = Vector2.new(cx, br.Y + 16)
                e.Dist.Color = Color3.fromRGB(200, 200, 200)
                e.Dist.Visible = true
            else e.Dist.Visible = false end
        else
            e.Top.Visible, e.Bottom.Visible, e.Left.Visible, e.Right.Visible = false, false, false, false
            e.Name.Visible, e.HP.Visible, e.Dist.Visible = false, false, false
        end

        if Config.ESP_Antena_Enabled then
            SetLine(e.Antena, Vector2.new(cx, tl.Y), Vector2.new(cx, tl.Y - Config.ESP_Antena_Height), col)
            e.Antena.Thickness = Config.ESP_Antena_Thickness
        else
            e.Antena.Visible = false
        end
    end
end

-- Egg ESP
local function UpdateEggESP()
    if not Config.ESP_Egg_Enabled then
        for _, tag in pairs(State.EggESP) do pcall(function() tag:Remove() end) end
        State.EggESP = {}
        return
    end

    local myHRP = GetMyHRP()
    if not myHRP then return end

    local seen = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and IsEgg(obj) then
            local d = (obj.Position - myHRP.Position).Magnitude
            if d <= Config.ESP_Egg_MaxDist then
                seen[obj] = true
                local tag = State.EggESP[obj]
                if not tag then
                    tag = Drawing.new("Text")
                    tag.Size = 12
                    tag.Center = true
                    tag.Outline = true
                    State.EggESP[obj] = tag
                end
                local sp = W2S(obj.Position)
                if sp then
                    local tier = GetEggTier(obj)
                    local parts = {}
                    if Config.ESP_Egg_ShowName then table.insert(parts, obj.Name) end
                    if Config.ESP_Egg_ShowTier then table.insert(parts, "[" .. tier .. "]") end
                    if Config.ESP_Egg_ShowDist then table.insert(parts, math.floor(d) .. "m") end
                    tag.Text = table.concat(parts, " ")
                    tag.Color = TierColor3(tier)
                    tag.Position = sp
                    tag.Visible = true
                else
                    tag.Visible = false
                end
            end
        end
    end
    for obj, tag in pairs(State.EggESP) do
        if not seen[obj] or not obj.Parent then
            pcall(function() tag:Remove() end)
            State.EggESP[obj] = nil
        end
    end
end

-- Base ESP
local function UpdateBaseESP()
    if not Config.ESP_Base_Enabled then
        for _, tag in pairs(State.BaseESP) do pcall(function() tag:Remove() end) end
        State.BaseESP = {}
        return
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        local c, hrp = GetChar(plr)
        if c then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and IsBase(obj) then
                    local owner = obj:GetAttribute("Owner") or obj:GetAttribute("Player") or obj:GetAttribute("UserId")
                    if owner and tostring(owner) == tostring(plr.UserId) then
                        local tag = State.BaseESP[obj]
                        if not tag then
                            tag = Drawing.new("Text")
                            tag.Size = 12
                            tag.Center = true
                            tag.Outline = true
                            tag.Color = Color3.fromRGB(255, 200, 50)
                            State.BaseESP[obj] = tag
                        end
                        local sp = W2S(obj.Position + Vector3.new(0, 5, 0))
                        if sp then
                            local d = (Camera.CFrame.Position - obj.Position).Magnitude
                            tag.Text = plr.Name .. "'s Base [" .. math.floor(d) .. "m]"
                            tag.Position = sp
                            tag.Visible = true
                        end
                        break
                    end
                end
            end
        end
    end
end

-- Biome ESP
local function UpdateBiomeESP()
    if not Config.ESP_Biome_Enabled then
        for _, tag in pairs(State.BiomeESP) do pcall(function() tag:Remove() end) end
        State.BiomeESP = {}
        return
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local nm = obj.Name:lower()
            for _, bio in ipairs(BiomeList) do
                if nm:find(bio:lower()) then
                    local pos = obj:IsA("BasePart") and obj.Position or (obj:FindFirstChild("HumanoidRootPart") and obj.HumanoidRootPart.Position)
                    if pos then
                        local tag = State.BiomeESP[obj]
                        if not tag then
                            tag = Drawing.new("Text")
                            tag.Size = 12
                            tag.Center = true
                            tag.Outline = true
                            tag.Color = Color3.fromRGB(100, 255, 255)
                            State.BiomeESP[obj] = tag
                        end
                        local sp = W2S(pos)
                        if sp then
                            local d = (Camera.CFrame.Position - pos).Magnitude
                            tag.Text = bio .. " [" .. math.floor(d) .. "m]"
                            tag.Position = sp
                            tag.Visible = true
                        end
                    end
                    break
                end
            end
        end
    end
end

-- Event ESP
local function UpdateEventESP()
    if not Config.ESP_Event_Enabled then
        for _, tag in pairs(State.EventESP) do pcall(function() tag:Remove() end) end
        State.EventESP = {}
        return
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local nm = obj.Name:lower()
            for _, kw in ipairs(EventKeywords) do
                if nm:find(kw) then
                    local pos = obj:IsA("BasePart") and obj.Position or (obj:FindFirstChild("HumanoidRootPart") and obj.HumanoidRootPart.Position)
                    if pos then
                        local tag = State.EventESP[obj]
                        if not tag then
                            tag = Drawing.new("Text")
                            tag.Size = 13
                            tag.Center = true
                            tag.Outline = true
                            tag.Color = Color3.fromRGB(255, 100, 255)
                            State.EventESP[obj] = tag
                        end
                        local sp = W2S(pos)
                        if sp then
                            local d = (Camera.CFrame.Position - pos).Magnitude
                            tag.Text = "[EVENT] " .. obj.Name .. " [" .. math.floor(d) .. "m]"
                            tag.Position = sp
                            tag.Visible = true
                        end
                    end
                    break
                end
            end
        end
    end
end

-- ============================================================
-- TELEPORT
-- ============================================================
local function TeleportToEgg()
    local myHRP = GetMyHRP()
    if not myHRP then return end
    local closest, cd = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and IsEgg(obj) then
            local d = (obj.Position - myHRP.Position).Magnitude
            if d < cd then cd = d; closest = obj end
        end
    end
    if closest then
        pcall(function() myHRP.CFrame = CFrame.new(closest.Position + Vector3.new(0, 5, 0)) end)
        Notify("Teleport", "Ke " .. closest.Name)
    else
        Notify("Teleport", "Gak ada egg")
    end
end

local function TeleportToBase()
    local myHRP = GetMyHRP()
    if not myHRP then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and IsBase(obj) then
            local owner = obj:GetAttribute("Owner") or obj:GetAttribute("Player") or obj:GetAttribute("UserId")
            if owner and tostring(owner) == tostring(LP.UserId) then
                pcall(function() myHRP.CFrame = CFrame.new(obj.Position + Vector3.new(0, 5, 0)) end)
                Notify("Teleport", "Ke Base")
                return
            end
        end
    end
    Notify("Teleport", "Base gak ketemu")
end

local function TeleportToPlayer(targetName)
    local myHRP = GetMyHRP()
    if not myHRP then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name == targetName then
            local c, hrp = GetChar(plr)
            if hrp then
                pcall(function() myHRP.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 5, 0)) end)
                Notify("Teleport", "Ke " .. targetName)
                return
            end
        end
    end
    Notify("Teleport", "Player gak ketemu")
end

-- ============================================================
-- MOVEMENT
-- ============================================================
local function RunSpeed()
    local c = LP.Character
    if not c then
        if State.SpeedBV then State.SpeedBV:Destroy(); State.SpeedBV = nil end
        return
    end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then
        if State.SpeedBV then State.SpeedBV:Destroy(); State.SpeedBV = nil end
        return
    end
    if not Config.Speed_Enabled and not Config.StealFly_Enabled then
        if State.SpeedBV then State.SpeedBV:Destroy(); State.SpeedBV = nil end
        return
    end

    if not State.SpeedBV or State.SpeedBV.Parent ~= hrp then
        if State.SpeedBV then State.SpeedBV:Destroy() end
        State.SpeedBV = Instance.new("BodyVelocity")
        State.SpeedBV.MaxForce = Vector3.new(1e5, 0, 1e5)
        State.SpeedBV.P = 1e4
        State.SpeedBV.Parent = hrp
    end

    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then
        local md = hum.MoveDirection
        local speed = Config.StealFly_Enabled and Config.StealFly_Speed or Config.Speed_Value
        if md.Magnitude > 0 then
            State.SpeedBV.Velocity = Vector3.new(md.X * speed, 0, md.Z * speed)
        else
            State.SpeedBV.Velocity = Vector3.new(0, 0, 0)
        end
    end
end

local function SetupInfJump()
    local conn = UIS.JumpRequest:Connect(function()
        if not Config.InfJump_Enabled then return end
        local c = LP.Character
        if not c then return end
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
    table.insert(State.Conns, conn)
end

local function StartFly()
    local c = LP.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if State.FlyBV then State.FlyBV:Destroy() end
    if State.FlyBG then State.FlyBG:Destroy() end

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = hrp
    State.FlyBV = bv

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bg.P, bg.D = 1000, 50
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp
    State.FlyBG = bg
end

local function StopFly()
    if State.FlyBV then State.FlyBV:Destroy(); State.FlyBV = nil end
    if State.FlyBG then State.FlyBG:Destroy(); State.FlyBG = nil end
end

local function UpdateFly()
    if not Config.Fly_Enabled then
        if State.FlyBV then StopFly() end
        return
    end
    if not State.FlyBV then StartFly() end

    local c = LP.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp or not State.FlyBV or not State.FlyBG then return end

    local dir = Vector3.new(0, 0, 0)
    if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end

    State.FlyBV.Velocity = dir * Config.Fly_Speed
    State.FlyBG.CFrame = Camera.CFrame
end

local function RunNoClip()
    if not Config.NoClip_Enabled then return end
    local c = LP.Character
    if not c then return end
    for _, part in ipairs(c:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
end

-- ============================================================
-- MISC
-- ============================================================
local function ApplyFullBright()
    if Config.FullBright_Enabled then
        Lighting.Ambient = Color3.fromRGB(255,255,255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
        Lighting.Brightness = 3
        Lighting.FogEnd = 1e6
        Lighting.GlobalShadows = false
    else
        Lighting.Ambient = State.OrigLight.Ambient
        Lighting.OutdoorAmbient = State.OrigLight.OutdoorAmbient
        Lighting.Brightness = State.OrigLight.Brightness
        Lighting.FogEnd = State.OrigLight.FogEnd
        Lighting.GlobalShadows = State.OrigLight.GlobalShadows
    end
end

local function SetupAntiAFK()
    local conn = LP.Idled:Connect(function()
        if not Config.AntiAFK_Enabled then return end
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
    table.insert(State.Conns, conn)
end

local function ServerHop()
    local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if not ok then return end
    local data = HttpService:JSONDecode(res)
    for _, srv in ipairs(data.data or {}) do
        if srv.playing and srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LP) end)
            return
        end
    end
end

local function CreateWatermark()
    local wm = Drawing.new("Text")
    wm.Text = Config.IsPremium and "Steal An Egg v2.0 | PREMIUM | joy" or "Steal An Egg v2.0 | BASIC"
    wm.Size = 14
    wm.Color = Config.IsPremium and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 255, 255)
    wm.Outline = true
    wm.Position = Vector2.new(14, 14)
    wm.Visible = true
    State.Watermark = wm
end

-- ============================================================
-- CUSTOM UI
-- ============================================================
local function CreateUI()
    if State.UI.ScreenGui then State.UI.ScreenGui:Destroy() end

    local parent = (gethui and gethui()) or CoreGui
    local sg = Instance.new("ScreenGui")
    sg.Name = "StealAnEggUI_" .. tostring(math.random(100000, 999999))
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = parent
    State.UI.ScreenGui = sg

    -- Tema
    local theme = {
        bg = Color3.fromRGB(15, 15, 20),
        bg2 = Color3.fromRGB(22, 22, 30),
        bg3 = Color3.fromRGB(30, 30, 42),
        accent = Color3.fromRGB(255, 80, 120),
        accent2 = Color3.fromRGB(120, 80, 255),
        text = Color3.fromRGB(240, 240, 240),
        textDim = Color3.fromRGB(160, 160, 170),
        premium = Color3.fromRGB(255, 200, 50),
        basic = Color3.fromRGB(80, 200, 255),
        toggleOn = Color3.fromRGB(0, 200, 100),
        toggleOff = Color3.fromRGB(60, 60, 70),
    }
    State.UI.Theme = theme

    -- === KEY SCREEN ===
    local keyFrame = Instance.new("Frame")
    keyFrame.Size = UDim2.new(0, 380, 0, 240)
    keyFrame.Position = UDim2.new(0.5, -190, 0.5, -120)
    keyFrame.BackgroundColor3 = theme.bg
    keyFrame.BorderSizePixel = 0
    keyFrame.Visible = true
    keyFrame.Parent = sg
    Instance.new("UICorner", keyFrame).CornerRadius = UDim.new(0, 12)
    local kStroke = Instance.new("UIStroke", keyFrame)
    kStroke.Color = theme.accent
    kStroke.Thickness = 2

    local kTitle = Instance.new("TextLabel")
    kTitle.Size = UDim2.new(1, 0, 0, 45)
    kTitle.BackgroundTransparency = 1
    kTitle.Text = "Steal An Egg v2.0"
    kTitle.TextColor3 = theme.accent
    kTitle.Font = Enum.Font.GothamBold
    kTitle.TextSize = 22
    kTitle.Parent = keyFrame

    local kSub = Instance.new("TextLabel")
    kSub.Size = UDim2.new(1, 0, 0, 20)
    kSub.Position = UDim2.new(0, 0, 0, 42)
    kSub.BackgroundTransparency = 1
    kSub.Text = "Masukkan Key Premium (ketik: Joy)"
    kSub.TextColor3 = theme.textDim
    kSub.Font = Enum.Font.Gotham
    kSub.TextSize = 13
    kSub.Parent = keyFrame

    local kBasicInfo = Instance.new("TextLabel")
    kBasicInfo.Size = UDim2.new(1, -40, 0, 40)
    kBasicInfo.Position = UDim2.new(0, 20, 0, 75)
    kBasicInfo.BackgroundTransparency = 1
    kBasicInfo.Text = "Kosong = Basic (free)\nJoy = Premium (semua fitur)"
    kBasicInfo.TextColor3 = theme.text
    kBasicInfo.Font = Enum.Font.Gotham
    kBasicInfo.TextSize = 13
    kBasicInfo.TextWrapped = true
    kBasicInfo.Parent = keyFrame

    local kBox = Instance.new("TextBox")
    kBox.Size = UDim2.new(1, -40, 0, 38)
    kBox.Position = UDim2.new(0, 20, 0, 125)
    kBox.BackgroundColor3 = theme.bg3
    kBox.BorderSizePixel = 0
    kBox.Text = ""
    kBox.PlaceholderText = "Ketik key..."
    kBox.TextColor3 = theme.text
    kBox.PlaceholderColor3 = theme.textDim
    kBox.Font = Enum.Font.Gotham
    kBox.TextSize = 14
    kBox.Parent = keyFrame
    Instance.new("UICorner", kBox).CornerRadius = UDim.new(0, 6)

    local kBtn = Instance.new("TextButton")
    kBtn.Size = UDim2.new(1, -40, 0, 40)
    kBtn.Position = UDim2.new(0, 20, 1, -55)
    kBtn.BackgroundColor3 = theme.accent
    kBtn.BorderSizePixel = 0
    kBtn.Text = "UNLOCK"
    kBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    kBtn.Font = Enum.Font.GothamBold
    kBtn.TextSize = 15
    kBtn.Parent = keyFrame
    Instance.new("UICorner", kBtn).CornerRadius = UDim.new(0, 8)

    kBtn.MouseButton1Click:Connect(function()
        local key = kBox.Text
        if key == "" then
            Config.IsPremium = false
            Notify("Basic Mode", "Basic unlocked. Fitur premium terkunci.")
        elseif key == "Joy" then
            Config.IsPremium = true
            Notify("Premium Mode", "Premium unlocked! Semua fitur terbuka.")
        else
            Config.IsPremium = false
            Notify("Invalid Key", "Key salah. masuk mode Basic.")
        end
        keyFrame.Visible = false
        State.UI.Main.Visible = true
        if State.Watermark then
            State.Watermark.Text = Config.IsPremium and "Steal An Egg v2.0 | PREMIUM | joy" or "Steal An Egg v2.0 | BASIC"
            State.Watermark.Color = Config.IsPremium and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 255, 255)
        end
        -- Refresh UI label
        if State.UI.RefreshGate then State.UI.RefreshGate() end
    end)

    -- === MAIN WINDOW ===
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 620, 0, 420)
    main.Position = UDim2.new(0.5, -310, 0.5, -210)
    main.BackgroundColor3 = theme.bg
    main.BorderSizePixel = 0
    main.Visible = false
    main.Parent = sg
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
    local mStroke = Instance.new("UIStroke", main)
    mStroke.Color = theme.accent
    mStroke.Thickness = 1.5
    State.UI.Main = main

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 36)
    titleBar.BackgroundColor3 = theme.bg2
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -80, 1, 0)
    titleLbl.Position = UDim2.new(0, 14, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "Steal An Egg v2.0 | joy"
    titleLbl.TextColor3 = theme.accent
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 15
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = titleBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -34, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.Parent = titleBar
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = false
    end)

    -- Tab bar (kiri)
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(0, 130, 1, -36)
    tabBar.Position = UDim2.new(0, 0, 0, 36)
    tabBar.BackgroundColor3 = theme.bg2
    tabBar.BorderSizePixel = 0
    tabBar.Parent = main

    -- Content area
    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -140, 1, -46)
    content.Position = UDim2.new(0, 130, 0, 36)
    content.BackgroundColor3 = theme.bg
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = theme.accent
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.Parent = main
    State.UI.Content = content

    -- Drag main window
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Helper: Tab button
    local function CreateTabButton(name, order)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 38)
        btn.Position = UDim2.new(0, 0, 0, (order - 1) * 40 + 6)
        btn.BackgroundColor3 = theme.bg2
        btn.BorderSizePixel = 0
        btn.Text = "  " .. name
        btn.TextColor3 = theme.text
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = tabBar
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        return btn
    end

    -- Helper: Section
    local function CreateSection(parent, title)
        local sec = Instance.new("Frame")
        sec.Size = UDim2.new(1, -20, 0, 30)
        sec.BackgroundTransparency = 1
        sec.Parent = parent

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = "◆ " .. title
        lbl.TextColor3 = theme.accent
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 14
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = sec

        local line = Instance.new("Frame")
        line.Size = UDim2.new(1, 0, 0, 1)
        line.Position = UDim2.new(0, 0, 1, -1)
        line.BackgroundColor3 = theme.accent
        line.BackgroundTransparency = 0.6
        line.BorderSizePixel = 0
        line.Parent = sec

        return sec
    end

    -- Helper: Toggle (dengan gate premium)
    local function CreateToggle(parent, name, flag, default, callback, isPremium, getValue)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -20, 0, 34)
        row.BackgroundColor3 = theme.bg2
        row.BorderSizePixel = 0
        row.Parent = parent
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -80, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = (isPremium and "[P] " or "") .. name
        lbl.TextColor3 = isPremium and theme.premium or theme.text
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local state = { value = getValue and getValue() or default }

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 44, 0, 22)
        btn.Position = UDim2.new(1, -54, 0.5, -11)
        btn.BackgroundColor3 = state.value and theme.toggleOn or theme.toggleOff
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.Parent = row
        Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 18, 0, 18)
        knob.Position = state.value and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.Parent = btn
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local function updateVisual(v)
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = v and theme.toggleOn or theme.toggleOff }):Play()
            TweenService:Create(knob, TweenInfo.new(0.15), { Position = v and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9) }):Play()
        end

        btn.MouseButton1Click:Connect(function()
            if isPremium and not Config.IsPremium then
                Notify("Premium Only", name .. " butuh key Premium 'Joy'")
                return
            end
            state.value = not state.value
            updateVisual(state.value)
            callback(state.value)
        end)

        return row
    end

    -- Helper: Slider
    local function CreateSlider(parent, name, min, max, default, suffix, flag, callback, isPremium)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -20, 0, 46)
        row.BackgroundColor3 = theme.bg2
        row.BorderSizePixel = 0
        row.Parent = parent
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -20, 0, 20)
        lbl.Position = UDim2.new(0, 12, 0, 2)
        lbl.BackgroundTransparency = 1
        lbl.Text = (isPremium and "[P] " or "") .. name .. "  [" .. tostring(default) .. (suffix or "") .. "]"
        lbl.TextColor3 = isPremium and theme.premium or theme.text
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -24, 0, 6)
        bar.Position = UDim2.new(0, 12, 0, 28)
        bar.BackgroundColor3 = theme.bg3
        bar.BorderSizePixel = 0
        bar.Parent = row
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = isPremium and theme.premium or theme.accent
        fill.BorderSizePixel = 0
        fill.Parent = bar
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 14, 0, 14)
        knob.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.Parent = bar
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local dragging = false
        local function updateFromMouse(x)
            local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * rel)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, -7, 0.5, -7)
            lbl.Text = (isPremium and "[P] " or "") .. name .. "  [" .. tostring(val) .. (suffix or "") .. "]"
            callback(val)
        end

        bar.InputBegan:Connect(function(input)
            if isPremium and not Config.IsPremium then
                Notify("Premium Only", name .. " butuh key Premium 'Joy'")
                return
            end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                updateFromMouse(input.Position.X)
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateFromMouse(input.Position.X)
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        return row
    end

    -- Helper: Dropdown
    local function CreateDropdown(parent, name, options, default, flag, callback, isPremium)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -20, 0, 34)
        row.BackgroundColor3 = theme.bg2
        row.BorderSizePixel = 0
        row.Parent = parent
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 200, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = (isPremium and "[P] " or "") .. name
        lbl.TextColor3 = isPremium and theme.premium or theme.text
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 140, 0, 24)
        btn.Position = UDim2.new(1, -150, 0.5, -12)
        btn.BackgroundColor3 = theme.bg3
        btn.BorderSizePixel = 0
        btn.Text = default
        btn.TextColor3 = theme.text
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.Parent = row
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

        local menu = Instance.new("Frame")
        menu.Size = UDim2.new(0, 140, 0, math.min(#options * 24 + 8, 200))
        menu.Position = UDim2.new(1, -150, 1, 4)
        menu.BackgroundColor3 = theme.bg3
        menu.BorderSizePixel = 0
        menu.Visible = false
        menu.ZIndex = 10
        menu.Parent = row
        Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 6)

        local menuList = Instance.new("ScrollingFrame")
        menuList.Size = UDim2.new(1, -8, 1, -8)
        menuList.Position = UDim2.new(0, 4, 0, 4)
        menuList.BackgroundTransparency = 1
        menuList.BorderSizePixel = 0
        menuList.ScrollBarThickness = 3
        menuList.CanvasSize = UDim2.new(0, 0, 0, #options * 24)
        menuList.Parent = menu

        for i, opt in ipairs(options) do
            local ob = Instance.new("TextButton")
            ob.Size = UDim2.new(1, 0, 0, 22)
            ob.Position = UDim2.new(0, 0, 0, (i - 1) * 24)
            ob.BackgroundTransparency = 1
            ob.Text = opt
            ob.TextColor3 = theme.text
            ob.Font = Enum.Font.Gotham
            ob.TextSize = 12
            ob.ZIndex = 11
            ob.Parent = menuList
            ob.MouseButton1Click:Connect(function()
                btn.Text = opt
                menu.Visible = false
                callback(opt)
            end)
        end

        btn.MouseButton1Click:Connect(function()
            if isPremium and not Config.IsPremium then
                Notify("Premium Only", name .. " butuh key Premium 'Joy'")
                return
            end
            menu.Visible = not menu.Visible
        end)

        return row
    end

    -- Helper: Button
    local function CreateButton(parent, name, callback, isPremium)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -20, 0, 34)
        btn.BackgroundColor3 = isPremium and theme.premium or theme.accent
        btn.BorderSizePixel = 0
        btn.Text = (isPremium and "[P] " or "") .. name
        btn.TextColor3 = isPremium and Color3.fromRGB(30, 20, 0) or Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.Parent = parent
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.MouseButton1Click:Connect(function()
            if isPremium and not Config.IsPremium then
                Notify("Premium Only", name .. " butuh key Premium 'Joy'")
                return
            end
            callback()
        end)
        return btn
    end

    -- === TAB SYSTEM ===
    local tabs = {}
    local currentTab

    local function CreateTabContent(tabName)
        local page = Instance.new("Frame")
        page.Size = UDim2.new(1, 0, 0, 0)
        page.AutomaticSize = Enum.AutomaticSize.Y
        page.BackgroundTransparency = 1
        page.Visible = false
        page.Parent = content

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 6)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = page

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 10)
        pad.PaddingLeft = UDim.new(0, 10)
        pad.PaddingRight = UDim.new(0, 10)
        pad.PaddingBottom = UDim.new(0, 10)
        pad.Parent = page

        return page
    end

    local function AddTab(name, order)
        local btn = CreateTabButton(name, order)
        local page = CreateTabContent(name)
        tabs[name] = { Btn = btn, Page = page }
        btn.MouseButton1Click:Connect(function()
            for _, t in pairs(tabs) do
                t.Page.Visible = false
                t.Btn.BackgroundColor3 = theme.bg2
            end
            page.Visible = true
            btn.BackgroundColor3 = theme.bg3
        end)
        return page
    end

    -- === TABS ===
    local tabESP = AddTab("ESP", 1)
    local tabSteal = AddTab("Steal", 2)
    local tabCollect = AddTab("Collect", 3)
    local tabAuto = AddTab("Auto", 4)
    local tabDefense = AddTab("Defense", 5)
    local tabMove = AddTab("Movement", 6)
    local tabEvent = AddTab("Event", 7)
    local tabMisc = AddTab("Misc", 8)

    -- ESP TAB
    CreateSection(tabESP, "Egg ESP (Unlimited Range)")
    CreateToggle(tabESP, "ESP Egg", "ESP_Egg", false, function(v) Config.ESP_Egg_Enabled = v end, false, function() return Config.ESP_Egg_Enabled end)
    CreateToggle(tabESP, "Show Name", "EggName", true, function(v) Config.ESP_Egg_ShowName = v end, false, function() return Config.ESP_Egg_ShowName end)
    CreateToggle(tabESP, "Show Tier", "EggTier", true, function(v) Config.ESP_Egg_ShowTier = v end, false, function() return Config.ESP_Egg_ShowTier end)
    CreateToggle(tabESP, "Show Distance", "EggDist", true, function(v) Config.ESP_Egg_ShowDist = v end, false, function() return Config.ESP_Egg_ShowDist end)

    CreateSection(tabESP, "Player ESP (Unlimited Range)")
    CreateToggle(tabESP, "ESP Player", "ESP_Player", false, function(v) Config.ESP_Player_Enabled = v end, false, function() return Config.ESP_Player_Enabled end)
    CreateToggle(tabESP, "Show Name", "PName", true, function(v) Config.ESP_Player_Name = v end, false, function() return Config.ESP_Player_Name end)
    CreateToggle(tabESP, "Show HP", "PHP", true, function(v) Config.ESP_Player_HP = v end, false, function() return Config.ESP_Player_HP end)
    CreateToggle(tabESP, "Show Distance", "PDist", true, function(v) Config.ESP_Player_Dist = v end, false, function() return Config.ESP_Player_Dist end)

    CreateSection(tabESP, "Base & Antena")
    CreateToggle(tabESP, "ESP Base", "ESP_Base", false, function(v) Config.ESP_Base_Enabled = v end, false, function() return Config.ESP_Base_Enabled end)
    CreateToggle(tabESP, "Antena FF", "Antena", false, function(v) Config.ESP_Antena_Enabled = v end, false, function() return Config.ESP_Antena_Enabled end)
    CreateSlider(tabESP, "Antena Height", 50, 600, 250, "px", "AntH", function(v) Config.ESP_Antena_Height = v end, false)
    CreateSlider(tabESP, "Antena Thickness", 1, 6, 2, "px", "AntT", function(v) Config.ESP_Antena_Thickness = v end, false)

    CreateSection(tabESP, "Biome & Event")
    CreateToggle(tabESP, "ESP Biome", "ESP_Biome", false, function(v) Config.ESP_Biome_Enabled = v end, false, function() return Config.ESP_Biome_Enabled end)
    CreateToggle(tabESP, "ESP Event", "ESP_Event", false, function(v) Config.ESP_Event_Enabled = v end, false, function() return Config.ESP_Event_Enabled end)

    -- STEAL TAB
    CreateSection(tabSteal, "Auto Steal Egg")
    CreateToggle(tabSteal, "Auto Steal", "Steal", false, function(v) Config.Steal_Enabled = v end, false, function() return Config.Steal_Enabled end)
    CreateDropdown(tabSteal, "Priority", {"Nearest", "Rarest", "LowestTier"}, "Nearest", "StealPrio", function(o) Config.Steal_Priority = o end, false)
    CreateDropdown(tabSteal, "Filter", {"All", "Priority"}, "All", "StealFilter", function(o) Config.Steal_Filter = o end, false)
    CreateDropdown(tabSteal, "Filter Tier", TierOrder, "Divine", "StealFilterName", function(o) Config.Steal_FilterName = o end, false)
    CreateSlider(tabSteal, "Steal Delay", 1, 30, 5, "x0.1s", "StealDelay", function(v) Config.Steal_Delay = v / 10 end, false)
    CreateToggle(tabSteal, "Auto Return Base", "Return", false, function(v) Config.ReturnBase_Enabled = v end, false, function() return Config.ReturnBase_Enabled end)

    CreateSection(tabSteal, "Premium Steal")
    CreateToggle(tabSteal, "Auto Steal Fly (Fast)", "StealFly", false, function(v) Config.StealFly_Enabled = v end, true, function() return Config.StealFly_Enabled end)
    CreateSlider(tabSteal, "Fly Speed", 60, 300, 120, "sp", "StealFlySpeed", function(v) Config.StealFly_Speed = v end, true)
    CreateToggle(tabSteal, "Silent Steal (Instan)", "SilentSteal", false, function(v) Config.SilentSteal_Enabled = v end, true, function() return Config.SilentSteal_Enabled end)
    CreateToggle(tabSteal, "Priority Divine/Secret", "PriorityDivine", false, function(v) Config.PriorityDivine_Enabled = v end, true, function() return Config.PriorityDivine_Enabled end)

    -- COLLECT TAB
    CreateSection(tabCollect, "Collect & Deposit")
    CreateToggle(tabCollect, "Auto Collect Egg", "CollectEgg", false, function(v) Config.CollectEgg_Enabled = v end, false, function() return Config.CollectEgg_Enabled end)
    CreateSlider(tabCollect, "Collect Range", 20, 500, 100, "m", "CollectRange", function(v) Config.CollectEgg_Range = v end, false)
    CreateToggle(tabCollect, "Auto Deposit", "Deposit", false, function(v) Config.Deposit_Enabled = v end, false, function() return Config.Deposit_Enabled end)

    CreateSection(tabCollect, "Hatch & Farm")
    CreateToggle(tabCollect, "Auto Hatch", "Hatch", false, function(v) Config.Hatch_Enabled = v end, false, function() return Config.Hatch_Enabled end)
    CreateToggle(tabCollect, "Auto Fast Farm (Treadmill)", "Farm", false, function(v) Config.FarmTreadmill_Enabled = v end, false, function() return Config.FarmTreadmill_Enabled end)

    -- AUTO TAB
    CreateSection(tabAuto, "Auto Rebirth / Buy / Upgrade")
    CreateToggle(tabAuto, "Auto Rebirth", "Rebirth", false, function(v) Config.Rebirth_Enabled = v end, false, function() return Config.Rebirth_Enabled end)
    CreateToggle(tabAuto, "Auto Buy Egg", "BuyEgg", false, function(v) Config.BuyEgg_Enabled = v end, false, function() return Config.BuyEgg_Enabled end)
    CreateToggle(tabAuto, "Auto Upgrade", "Upgrade", false, function(v) Config.Upgrade_Enabled = v end, false, function() return Config.Upgrade_Enabled end)
    CreateToggle(tabAuto, "Auto Claim Daily / Gift", "Claim", false, function(v) Config.ClaimDaily_Enabled = v end, false, function() return Config.ClaimDaily_Enabled end)

    -- DEFENSE TAB
    CreateSection(tabDefense, "Defense")
    CreateToggle(tabDefense, "God Mode", "God", false, function(v) Config.GodMode_Enabled = v end, false, function() return Config.GodMode_Enabled end)
    CreateSlider(tabDefense, "Lock HP", 100, 10000, 1000, "", "GodHP", function(v) Config.GodMode_LockHP = v end, false)
    CreateToggle(tabDefense, "Anti Guardian (Kill Monster)", "AntiGuard", false, function(v) Config.AntiGuardian_Enabled = v end, false, function() return Config.AntiGuardian_Enabled end)
    CreateToggle(tabDefense, "Anti Steal (Lock Egg Base)", "AntiSteal", false, function(v) Config.AntiSteal_Enabled = v end, true, function() return Config.AntiSteal_Enabled end)
    CreateToggle(tabDefense, "Kill Aura", "KillAura", false, function(v) Config.KillAura_Enabled = v end, true, function() return Config.KillAura_Enabled end)
    CreateSlider(tabDefense, "Kill Aura Range", 10, 100, 30, "m", "KillRange", function(v) Config.KillAura_Range = v end, true)

    -- MOVE TAB
    CreateSection(tabMove, "Movement")
    CreateToggle(tabMove, "Speed Boost", "Speed", false, function(v) Config.Speed_Enabled = v end, false, function() return Config.Speed_Enabled end)
    CreateSlider(tabMove, "Speed Value", 16, 300, 60, "", "SpeedVal", function(v) Config.Speed_Value = v end, false)
    CreateToggle(tabMove, "Infinite Jump", "InfJump", false, function(v) Config.InfJump_Enabled = v end, false, function() return Config.InfJump_Enabled end)
    CreateToggle(tabMove, "Fly", "Fly", false, function(v) Config.Fly_Enabled = v end, true, function() return Config.Fly_Enabled end)
    CreateSlider(tabMove, "Fly Speed", 10, 300, 50, "", "FlySpeed", function(v) Config.Fly_Speed = v end, true)
    CreateToggle(tabMove, "No Clip", "NoClip", false, function(v) Config.NoClip_Enabled = v end, false, function() return Config.NoClip_Enabled end)

    -- EVENT TAB
    CreateSection(tabEvent, "Auto Event")
    CreateToggle(tabEvent, "Auto Event (Semua)", "AutoEvent", false, function(v) Config.AutoEvent_Enabled = v end, false, function() return Config.AutoEvent_Enabled end)
    CreateToggle(tabEvent, "Auto Rift Event", "AutoRift", false, function(v) Config.AutoRift_Enabled = v end, false, function() return Config.AutoRift_Enabled end)
    CreateToggle(tabEvent, "Auto Merged Biome (Angel+Demon)", "AutoMerged", false, function(v) Config.AutoMerged_Enabled = v end, false, function() return Config.AutoMerged_Enabled end)

    -- MISC TAB
    CreateSection(tabMisc, "Teleport")
    CreateButton(tabMisc, "Teleport to Nearest Egg", function() TeleportToEgg() end, false)
    CreateButton(tabMisc, "Teleport to My Base", function() TeleportToBase() end, false)

    CreateSection(tabMisc, "Visual")
    CreateToggle(tabMisc, "Full Bright", "FB", false, function(v) Config.FullBright_Enabled = v; ApplyFullBright() end, false, function() return Config.FullBright_Enabled end)
    CreateToggle(tabMisc, "Anti-AFK", "AFK", true, function(v) Config.AntiAFK_Enabled = v end, false, function() return Config.AntiAFK_Enabled end)
    CreateButton(tabMisc, "Server Hop", function() ServerHop() end, false)

    CreateSection(tabMisc, "Info")
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -20, 0, 60)
    info.BackgroundColor3 = theme.bg2
    info.BorderSizePixel = 0
    info.Text = "Script  : Steal An Egg\nOwner   : joy\nVersion : 2.0.0\nKey     : " .. (Config.IsPremium and "PREMIUM" or "BASIC")
    info.TextColor3 = theme.text
    info.Font = Enum.Font.Gotham
    info.TextSize = 12
    info.TextWrapped = true
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.Parent = tabMisc
    Instance.new("UICorner", info).CornerRadius = UDim.new(0, 6)
    Instance.new("UIPadding", info).PaddingLeft = UDim.new(0, 8)

    CreateButton(tabMisc, "Unload Script", function()
        for _, c in ipairs(State.Conns) do pcall(function() c:Disconnect() end) end
        State.Conns = {}
        for _, e in pairs(State.ESP) do
            for _, o in pairs(e) do pcall(function() o:Remove() end) end
        end
        State.ESP = {}
        for _, tag in pairs(State.EggESP) do pcall(function() tag:Remove() end) end
        State.EggESP = {}
        for _, tag in pairs(State.BaseESP) do pcall(function() tag:Remove() end) end
        State.BaseESP = {}
        for _, tag in pairs(State.BiomeESP) do pcall(function() tag:Remove() end) end
        State.BiomeESP = {}
        for _, tag in pairs(State.EventESP) do pcall(function() tag:Remove() end) end
        State.EventESP = {}
        if State.Watermark then pcall(function() State.Watermark:Remove() end) end
        if State.SpeedBV then State.SpeedBV:Destroy(); State.SpeedBV = nil end
        StopFly()
        Lighting.Ambient = State.OrigLight.Ambient
        Lighting.OutdoorAmbient = State.OrigLight.OutdoorAmbient
        Lighting.Brightness = State.OrigLight.Brightness
        Lighting.FogEnd = State.OrigLight.FogEnd
        Lighting.GlobalShadows = State.OrigLight.GlobalShadows
        if State.UI.ScreenGui then State.UI.ScreenGui:Destroy() end
    end, false)

    -- Default buka tab ESP
    tabESP.Visible = true
    tabs["ESP"].Btn.BackgroundColor3 = theme.bg3

    return sg
end

-- ============================================================
-- INIT
-- ============================================================
SetupHooks()
SetupInfJump()
SetupAntiAFK()
CreateWatermark()
CreateUI()

State.Conns[#State.Conns + 1] = RunService.RenderStepped:Connect(function()
    if not Config.Enabled then return end
    pcall(RunStealEgg)
    pcall(RunCollectEgg)
    pcall(RunDeposit)
    pcall(RunHatch)
    pcall(RunFarmTreadmill)
    pcall(RunRebirth)
    pcall(RunBuyEgg)
    pcall(RunUpgrade)
    pcall(RunClaimDaily)
    pcall(RunAutoEvent)
    pcall(RunAutoRift)
    pcall(RunAutoMerged)
    pcall(RunGodMode)
    pcall(RunAntiGuardian)
    pcall(RunAntiSteal)
    pcall(RunKillAura)
    pcall(UpdatePlayerESP)
    pcall(UpdateEggESP)
    pcall(UpdateBaseESP)
    pcall(UpdateBiomeESP)
    pcall(UpdateEventESP)
    pcall(RunSpeed)
    pcall(UpdateFly)
    pcall(RunNoClip)
    pcall(RunBypassTick)
end)

State.Conns[#State.Conns + 1] = UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.T then
        TeleportToEgg()
    elseif input.KeyCode == Enum.KeyCode.B then
        TeleportToBase()
    end
end)

State.Conns[#State.Conns + 1] = Players.PlayerRemoving:Connect(function(plr)
    RemovePlayerESP(plr)
end)

Notify("Steal An Egg v2.0", "Loaded. Ketik key 'Joy' untuk Premium.")
print("[Steal An Egg v2.0] Loaded. Owner: joy")    S.config = deepCopy(DEFAULT)
    pcall(function()
        if _isfile and _isfile(CONFIG_FILE) then
            local data = Http:JSONDecode(_readfile(CONFIG_FILE))
            if type(data) == "table" then
                for k, v in pairs(data) do S.config[k] = v end
            end
        end
    end)
end

local function saveConfig()
    pcall(function()
        if _writefile then _writefile(CONFIG_FILE, Http:JSONEncode(S.config)) end
    end)
end

loadConfig()

-- Safe parent resolver
local function getParent()
    if _gethui then
        local ok, h = pcall(_gethui)
        if ok and h then return h end
    end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return LP:WaitForChild("PlayerGui")
end

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
    for _ = 1, 3 do discover(); task.wait(1) end
end

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

local function fireSteal(egg)
    local r = S.remotes.steal
    if not r then
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

local function workerHatch() while S.run do task.wait(1) if S.config.autoHatch then fireRemote("hatch") end end end
local function workerPlace() while S.run do task.wait(1.5) if S.config.autoPlace then fireRemote("place") end end end
local function workerSell() while S.run do task.wait(3) if S.config.autoSell then fireRemote("sell") end end end
local function workerTreadmill() while S.run do task.wait(3) if S.config.autoTreadmill then fireRemote("treadmill") end end end
local function workerUpgrade() while S.run do task.wait(5) if S.config.autoUpgrade then fireRemote("upgrade","upgrade") end end end
local function workerEvent() while S.run do task.wait(8) if S.config.autoEvent then fireRemote("event","claim") end end end
local function workerReward()
    while S.run do
        task.wait(10)
        if S.config.claimReward then
            for _, k in ipairs({"daily","season","index"}) do
                fireRemote("event","claim",k)
                task.wait(0.5)
            end
        end
    end
end

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

local function clearESP()
    for _, h in pairs(S.highlightCache) do pcall(function() h:Destroy() end) end
    for _, c in pairs(S.espCache) do pcall(function() c.bb:Destroy() end) end
    S.highlightCache = {}
    S.espCache = {}
end

local function getOrCreateHL(part, color)
    local id = part:GetDebugId()
    if S.highlightCache[id] then
        S.highlightCache[id].FillColor = color
        S.highlightCache[id].OutlineColor = color
        return S.highlightCache[id]
    end
    local h = Instance.new("Highlight")
    h.FillColor = color; h.OutlineColor = color
    h.FillTransparency = 0.75; h.OutlineTransparency = 0
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
    S.espCache[id] = {bb = bb, tl = tl}
    return S.espCache[id]
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
                        local color = Color3.fromRGB(255,120,120)
                        if rarity=="Secret" or rarity=="Eternal" or rarity=="Divine" then color = Color3.fromRGB(255,215,0)
                        elseif rarity=="Mythic" or rarity=="Cosmic" then color = Color3.fromRGB(200,100,255) end
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

            for id, h in pairs(S.highlightCache) do
                if not active[id] then pcall(function() h:Destroy() end); S.highlightCache[id] = nil end
            end
            for id, c in pairs(S.espCache) do
                if not active[id] then pcall(function() c.bb:Destroy() end); S.espCache[id] = nil end
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

-- UI Components
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

    local locked = premium and S.tier ~= "premium"
    if locked then
        local ov = Instance.new("Frame", row)
        ov.Size = UDim2.new(1, 0, 1, 0)
        ov.BackgroundColor3 = Color3.fromRGB(15,15,18)
        ov.BackgroundTransparency = 0.45
        ov.BorderSizePixel = 0
        ov.ZIndex = 10
        Instance.new("UICorner", ov).CornerRadius = UDim.new(0, 6)
        local c1 = Instance.new("Frame", ov)
        c1.Size = UDim2.new(1, 0, 0, 2)
        c1.Position = UDim2.new(0, 0, 0.5, -1)
        c1.BackgroundColor3 = Color3.fromRGB(255,60,60)
        c1.BorderSizePixel = 0; c1.Rotation = 6; c1.ZIndex = 11
        local c2 = Instance.new("Frame", ov)
        c2.Size = UDim2.new(1, 0, 0, 2)
        c2.Position = UDim2.new(0, 0, 0.5, -1)
        c2.BackgroundColor3 = Color3.fromRGB(255,60,60)
        c2.BorderSizePixel = 0; c2.Rotation = -6; c2.ZIndex = 11
    end

    b.MouseButton1Click:Connect(function()
        if locked then notify("Premium", "Fitur ini butuh tier atas"); return end
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
    local ok = pcall(function() screen.Parent = getParent() end)
    if not ok or not screen.Parent then screen.Parent = LP:WaitForChild("PlayerGui") end
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

    local side = Instance.new("Frame", main)
    side.Size = UDim2.new(0, 140, 1, -40)
    side.Position = UDim2.new(0, 0, 0, 40)
    side.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    side.BorderSizePixel = 0
    local sl = Instance.new("UIListLayout", side)
    sl.SortOrder = Enum.SortOrder.LayoutOrder; sl.Padding = UDim.new(0, 4)
    local sp = Instance.new("UIPadding", side)
    sp.PaddingTop = UDim.new(0, 8); sp.PaddingLeft = UDim.new(0, 8); sp.PaddingRight = UDim.new(0, 8)

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
    cl.SortOrder = Enum.SortOrder.LayoutOrder; cl.Padding = UDim.new(0, 5)

    local icon = Instance.new("TextButton", screen)
    icon.Size = UDim2.new(0, 44, 0, 44)
    icon.Position = UDim2.new(0, 20, 0.5, -22)
    icon.BackgroundColor3 = Color3.fromRGB(0, 200, 120)
    icon.Text = "B"
    icon.TextColor3 = Color3.fromRGB(255,255,255)
    icon.Font = Enum.Font.GothamBold; icon.TextSize = 20
    icon.BorderSizePixel = 0
    icon.Visible = false
    Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 8)

    local tabs = {}
    local function addTab(name)
        local b = Instance.new("TextButton", side)
        b.Size = UDim2.new(1, 0, 0, 32)
        b.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
        b.BackgroundTransparency = 1
        b.Text = "   " .. name
        b.TextColor3 = Color3.fromRGB(200,200,200)
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.Font = Enum.Font.GothamMedium; b.TextSize = 12
        b.BorderSizePixel = 0
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)

        local p = Instance.new("Frame", scroll)
        p.Size = UDim2.new(1, 0, 0, 0)
        p.AutomaticSize = Enum.AutomaticSize.Y
        p.BackgroundTransparency = 1
        p.Visible = false
        local pl = Instance.new("UIListLayout", p)
        pl.SortOrder = Enum.SortOrder.LayoutOrder; pl.Padding = UDim.new(0, 5)
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

    makeSection(tMain, "Info")
    local info = Instance.new("TextLabel", tMain)
    info.Size = UDim2.new(1, 0, 0, 80)
    info.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
    info.TextColor3 = Color3.fromRGB(220,220,220)
    info.Font = Enum.Font.Code; info.TextSize = 12
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.BorderSizePixel = 0
    Instance.new("UICorner", info).CornerRadius = UDim.new(0, 6)
    local t0 = tick()
    task.spawn(function()
        while S.run and screen.Parent do
            task.wait(1)
            info.Text = string.format("  Tier: %s\n  Kicks blocked: %d\n  Executor: %s\n  Uptime: %ds",
                string.upper(S.tier), S.kickBlocked, tostring(({identifyexecutor()})[1] or "Unknown"), math.floor(tick()-t0))
        end
    end)

    makeSection(tSteal, "Auto Steal")
    makeToggle(tSteal, "Auto Steal", "autoSteal")
    makeSlider(tSteal, "Delay", "stealDelay", 0.1, 2.0)
    makeToggle(tSteal, "Big Egg", "stealBig")
    makeToggle(tSteal, "Secret Egg", "stealSecret")
    makeDropdown(tSteal, "Biome", "stealBiome",
        {"all","Forest","Lake","Desert","Jungle","Snow","Volcano","Abyss","Prehistoric","Cosmic","Cherry Blossom","Titan Temple","Angel","Daemon"})
    makeSlider(tSteal, "Weight Min", "stealWeightMin", 0, 100)

    makeSection(tAuto, "Auto")
    makeToggle(tAuto, "Auto Hatch", "autoHatch")
    makeToggle(tAuto, "Auto Place", "autoPlace")
    makeToggle(tAuto, "Auto Sell", "autoSell")
    makeToggle(tAuto, "Auto Treadmill", "autoTreadmill")
    makeToggle(tAuto, "Auto Upgrade", "autoUpgrade")
    makeToggle(tAuto, "Auto Event", "autoEvent")
    makeToggle(tAuto, "Claim Reward", "claimReward")

    makeSection(tESP, "ESP — Unlimited Range")
    makeToggle(tESP, "ESP Egg", "espEgg")
    makeToggle(tESP, "ESP Guardian", "espGuardian")
    makeToggle(tESP, "ESP Player", "espPlayer", true)

    makeSection(tMove, "Movement")
    makeToggle(tMove, "Speed Boost", "speedBoost")
    makeSlider(tMove, "Speed Value", "speedValue", 16, 300)
    makeToggle(tMove, "Infinite Jump", "infiniteJump")
    makeToggle(tMove, "Noclip", "noclip")

    makeSection(tPrem, "Premium Only")
    makeToggle(tPrem, "Fly", "fly", true)
    makeDropdown(tPrem, "Fly Mode", "flyMode", {"CFrame","BodyVelocity"})
    makeSlider(tPrem, "Fly Speed", "flySpeed", 20, 400)
    makeToggle(tPrem, "Guardian Bypass", "guardianBypass", true)
    makeToggle(tPrem, "Advanced Steal", "advancedSteal", true)

    makeSection(tSet, "Anti-Ban / Bypass")
    makeToggle(tSet, "Anti-Ban", "antiBan")
    makeToggle(tSet, "Anti-Kick", "antiKick")
    makeToggle(tSet, "Anti-Rob", "antiRob")
    makeToggle(tSet, "Auto Rejoin", "autoRejoin")

    local function hideAll() main.Visible = false; icon.Visible = true end
    local function showAll() main.Visible = true; icon.Visible = false end
    closeB.MouseButton1Click:Connect(hideAll)
    minB.MouseButton1Click:Connect(hideAll)
    icon.MouseButton1Click:Connect(showAll)

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

local function showAuth()
    local screen = Instance.new("ScreenGui")
    screen.Name = "Config"
    screen.ResetOnSpawn = false
    screen.DisplayOrder = 999
    local ok = pcall(function() screen.Parent = getParent() end)
    if not ok or not screen.Parent then screen.Parent = LP:WaitForChild("PlayerGui") end

    local f = Instance.new("Frame", screen)
    f.Size = UDim2.new(0, 300, 0, 160)
    f.Position = UDim2.new(0.5, -150, 0.5, -80)
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

    b.MouseButton1Click:Connect(function()
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
    end)

    tb.FocusLost:Connect(function(enter) if enter then b.MouseButton1Click:Fire() end end)
end

-- BOOT
task.spawn(function()
    local ok, err = pcall(showAuth)
    if not ok then
        warn("[BAZZ] showAuth error:", err)
    end
end)    fly = false, flyMode = "CFrame", flySpeed = 80,
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
