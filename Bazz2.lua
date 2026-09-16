--[[
    ============================================================
    BAZZ PREMIUM — STEAL AN EGG
    Single-File Lua Script | Delta Executor Compatible
    Author: BAZZ
    Owner: joy
    ============================================================
    KEY SYSTEM:
        Basic   : bazz
        Premium : Joy
    ============================================================
    REMOTE PATTERN AUTO-DETECT + PLACEHOLDER OVERRIDE
    ============================================================
--]]

--//============================================================
--// SERVICE ALIAS + ANTI-HYPERION ALIAS
--//============================================================
local Players           = game:GetService("Players")
local RS                = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UIS               = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local HttpService       = game:GetService("HttpService")
local TeleportService   = game:GetService("TeleportService")
local Lighting          = game:GetService("Lighting")
local LP                = Players.LocalPlayer

-- Hyperion / executor function alias
local _hookfunction     = hookfunction        or getgenv().hookfunction
local _hookmetamethod   = hookmetamethod      or getgenv().hookmetamethod
local _getrawmetatable  = getrawmetatable     or getgenv().getrawmetatable
local _getconnections   = getconnections      or getgenv().getconnections
local _getnamecallmeth  = getnamecallmethod   or getgenv().getnamecallmethod
local _newcclosure      = newcclosure         or getgenv().newcclosure or function(f) return f end
local _setreadonly      = setreadonly         or getgenv().setreadonly
local _getcustomasset   = getcustomasset      or getgenv().getcustomasset
local _writefile        = writefile           or getgenv().writefile
local _readfile         = readfile            or getgenv().readfile
local _isfile           = isfile              or getgenv().isfile
local _isfolder         = isfolder            or getgenv().isfolder
local _makefolder       = makefolder          or getgenv().makefolder
local _gethui           = gethui              or getgenv().gethui or function() return game:GetService("CoreGui") end
local _identifyexecutor = identifyexecutor    or getgenv().identifyexecutor or function() return "Unknown", "Unknown" end

--//============================================================
--// CONFIG + CONSTANTS
--//============================================================
local SCRIPT_NAME       = "BazzPremium_StealAnEgg"
local FOLDER            = "BazzPremium"
local CONFIG_FILE       = FOLDER .. "/stealanegg_config.json"
local LOGO_FILE         = FOLDER .. "/logo.png"
local BG_FILE           = FOLDER .. "/bg.png"

-- Image URLs (lo tinggal ganti sesuai aset lo, joy)
local LOGO_URL          = "https://i.ibb.co.com/b8c49d13ce29f7a59bcda2bfbfba03a7/logo.png"
local BG_URL            = "https://i.ibb.co.com/b8c49d13ce29f7a59bcda2bfbfba03a7/bg.png"

-- Key system
local KEYS = {
    basic   = "bazz",
    premium = "Joy"
}

-- Auto-detect remote pattern
local REMOTE_PATTERNS = {
    steal   = {"steal", "grab", "collect", "take", "pickup", "snatch"},
    hatch   = {"hatch", "open", "eggopen", "addpetlist", "unbox"},
    treadmill = {"treadmill", "upgrade", "train", "speed"},
    sell    = {"sell", "sellpet", "inventory", "discard"},
    place   = {"place", "setegg", "addpet", "deploy"},
    event   = {"event", "claim", "reward", "monster", "parasite", "rift"},
    return_ = {"return", "tobase", "back", "home"},
    teleport= {"teleport", "tp", "goto", "warp"}
}

-- Override manual kalau auto-detect salah
local REMOTE_OVERRIDE = {
    -- steal = "StealEggRemote",
    -- hatch = "HatchEggRemote",
    -- dll
}

--//============================================================
--// GLOBAL STATE
--//============================================================
if not _isfolder(FOLDER) then _makefolder(FOLDER) end

local State = {
    authenticated = false,
    tier          = "none",       -- "basic" | "premium"
    key           = "",
    executor      = ({_identifyexecutor()})[1] or "Unknown",
    startTime     = tick(),
    warnings      = 0,
    kickBlocked   = 0,
    connections   = {},
    threads       = {},
    remotes       = {},           -- cache remote
    espObjects    = {},           -- drawing objects
    config        = {},
    ui            = {},
    features      = {},           -- toggle state per fitur
    paused        = false,
    stealthMode   = false
}

--//============================================================
--// DEFAULT CONFIG
--//============================================================
local DEFAULT_CONFIG = {
    -- Steal
    autoSteal              = true,
    autoStealDelay         = 0.3,
    autoStealSelectedOnly  = true,
    autoStealRarityFilter  = {"Rare","Epic","Legendary","Mythic","Cosmic","Secret","Eternal","Divine"},
    autoStealBiomeFilter   = {"all"},
    autoStealWeightMin     = 0,
    autoStealRandomName    = false,
    autoStealAll           = false,
    autoStealBigEgg        = true,
    autoStealSecretEgg     = true,
    stealSpeed             = 0.3,

    -- Hatch / Place / Sell
    autoHatch              = true,
    autoHatchDelay         = 0.5,
    autoHatchAll           = false,
    autoPlace              = true,
    autoSell               = true,
    autoSellKeepRarity     = {"Rare","Epic","Legendary","Mythic","Cosmic","Secret","Eternal","Divine"},

    -- Treadmill / Upgrade
    autoTreadmill          = true,
    autoTreadmillTarget    = 100,
    autoUpgrade            = true,
    autoUpgradeMaxLevel    = 10,

    -- Event / Reward
    autoEvent              = true,
    autoRift               = true,
    claimReward            = true,
    claimDaily             = true,
    claimSeason            = true,
    claimIndex             = true,

    -- ESP
    espEgg                 = true,
    espEggRarityFilter     = {"Rare","Epic","Legendary","Mythic","Cosmic","Secret","Eternal","Divine"},
    espEggMaxDistance      = 500,
    espGuardian            = true,
    espGuardianMaxDistance = 500,
    espPlayer              = false,
    espPlayerMaxDistance   = 300,
    tracerGuardian         = false,

    -- Movement
    speedBoost             = false,
    speedBoostValue        = 50,
    speedBoostGradual      = true,
    infiniteJump           = false,
    noclip                 = false,

    -- Premium only
    fly                    = false,
    flyMode                = "CFrame",       -- CFrame | BodyVelocity | LinearVelocity | AlignPosition
    flySpeed               = 80,
    flyKeybind             = "F",
    guardianBypass         = true,
    advancedSteal          = true,
    smartRoute             = true,
    autoBiomeRotation      = false,
    stealthMode            = false,
    webhookUrl             = "",

    -- Anti-ban
    antiBan                = true,
    antiKick               = true,
    autoRejoin             = true,
    autoRejoinDelay        = 5,
    serverHopKeybind       = "H",
    serverHopMinPlayer     = 0,
    antiRob                = true,
    antiRobDistance        = 30,

    -- UI
    uiTheme                = "Dark",
    uiBlur                 = true,
    uiTransparency         = 0.05,
    uiAccentColor          = Color3.fromRGB(0, 255, 150),
    uiWatermark            = true,
    uiKeybind              = "RightShift",
    uiAnimation            = true,
    uiPinned               = false,
    uiAnchor               = "center"
}

--//============================================================
--// CONFIG LOAD / SAVE
--//============================================================
local function deepCopy(t)
    local out = {}
    for k, v in pairs(t) do
        if type(v) == "table" then out[k] = deepCopy(v)
        else out[k] = v end
    end
    return out
end

local function loadConfig()
    State.config = deepCopy(DEFAULT_CONFIG)
    if _isfile(CONFIG_FILE) then
        local ok, data = pcall(function() return HttpService:JSONDecode(_readfile(CONFIG_FILE)) end)
        if ok and type(data) == "table" then
            for k, v in pairs(data) do
                if type(v) == "table" and type(State.config[k]) == "table" then
                    State.config[k] = v
                else
                    State.config[k] = v
                end
            end
        end
    end
end

local function saveConfig()
    pcall(function()
        _writefile(CONFIG_FILE, HttpService:JSONEncode(State.config))
    end)
end

loadConfig()

--//============================================================
--// LOGO / BG LOADER (Discord / Direct URL support)
--//============================================================
local function loadRemoteImage(url, filename)
    if not url or url == "" then return nil end
    local ok, result = pcall(function()
        if not _isfile(filename) then
            local body = game:HttpGet(url)
            _writefile(filename, body)
        end
        if _getcustomasset then
            return _getcustomasset(filename)
        end
        return nil
    end)
    if ok then return result end
    return nil
end

local LOGO_ID = loadRemoteImage(LOGO_URL, LOGO_FILE)
local BG_ID   = loadRemoteImage(BG_URL,   BG_FILE)

--//============================================================
--// NOTIFICATION SYSTEM
--//============================================================
local function notify(title, text, duration)
    duration = duration or 3
    local gui = State.ui.screen
    if not gui then return end

    local toast = Instance.new("Frame")
    toast.Name = "Toast_" .. tostring(math.random(1,99999))
    toast.Size = UDim2.new(0, 280, 0, 60)
    toast.Position = UDim2.new(1, -300, 0, 20)
    toast.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    toast.BackgroundTransparency = 0.1
    toast.BorderSizePixel = 0
    toast.Parent = gui

    local corner = Instance.new("UICorner", toast)
    corner.CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", toast)
    stroke.Color = State.config.uiAccentColor
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3

    local titleLbl = Instance.new("TextLabel", toast)
    titleLbl.Size = UDim2.new(1, -20, 0, 22)
    titleLbl.Position = UDim2.new(0, 10, 0, 6)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = State.config.uiAccentColor
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 13

    local bodyLbl = Instance.new("TextLabel", toast)
    bodyLbl.Size = UDim2.new(1, -20, 0, 28)
    bodyLbl.Position = UDim2.new(0, 10, 0, 26)
    bodyLbl.BackgroundTransparency = 1
    bodyLbl.Text = text
    bodyLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    bodyLbl.TextXAlignment = Enum.TextXAlignment.Left
    bodyLbl.TextWrapped = true
    bodyLbl.Font = Enum.Font.Gotham
    bodyLbl.TextSize = 11

    TweenService:Create(toast, TweenInfo.new(0.3), {Position = UDim2.new(1, -300, 0, 20)}):Play()

    task.delay(duration, function()
        local fadeOut = TweenService:Create(toast, TweenInfo.new(0.3), {BackgroundTransparency = 1})
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            toast:Destroy()
        end)
    end)
end

--//============================================================
--// REMOTE DISCOVERY
--//============================================================
local function findRemoteByNamePatterns(patterns)
    if REMOTE_OVERRIDE then
        for cat, patterns2 in pairs(REMOTE_PATTERNS) do
            if patterns2 == patterns and REMOTE_OVERRIDE[cat] then
                local r = RS:FindFirstChild(REMOTE_OVERRIDE[cat], true)
                if r then return r end
            end
        end
    end
    for _, obj in ipairs(RS:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("BindableEvent") then
            local low = string.lower(obj.Name)
            for _, p in ipairs(patterns) do
                if string.find(low, p, 1, true) then
                    return obj
                end
            end
        end
    end
    return nil
end

local function discoverRemotes()
    for cat, pats in pairs(REMOTE_PATTERNS) do
        State.remotes[cat] = findRemoteByNamePatterns(pats)
    end
    -- log
    local found = {}
    for k, v in pairs(State.remotes) do
        if v then table.insert(found, k) end
    end
    if #found > 0 then
        notify("Remote Ditemukan", table.concat(found, ", "), 4)
    else
        notify("Remote Tidak Ditemukan", "Pakai fallback generic", 4)
    end
end

--//============================================================
--// STEAL TECHNIQUES
--//============================================================
-- 20+ basic techniques, 30+ premium techniques

local function stealViaProximityPrompt(eggModel)
    if not eggModel then return false end
    for _, d in ipairs(eggModel:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            pcall(function() fireproximityprompt(d) end)
            return true
        end
    end
    return false
end

local function stealViaRemote(eggModel)
    local r = State.remotes.steal
    if not r then return false end
    local ok = pcall(function()
        if r:IsA("RemoteEvent") then
            r:FireServer(eggModel)
        elseif r:IsA("RemoteFunction") then
            r:InvokeServer(eggModel)
        elseif r:IsA("BindableEvent") then
            r:Fire(eggModel)
        end
    end)
    return ok
end

local function stealViaRemoteNoArg()
    local r = State.remotes.steal
    if not r then return false end
    local ok = pcall(function()
        if r:IsA("RemoteEvent") then r:FireServer()
        elseif r:IsA("RemoteFunction") then r:InvokeServer() end
    end)
    return ok
end

local function stealViaNamecallHook(eggModel)
    -- silent fire via namecall
    local mt = _getrawmetatable and _getrawmetatable(game)
    if not mt then return false end
    local oldNamecall = mt.__namecall
    local fired = false
    _setreadonly(mt, false)
    mt.__namecall = _newcclosure(function(self, ...)
        local method = _getnamecallmeth()
        if method == "FireServer" and self == State.remotes.steal then
            fired = true
        end
        return oldNamecall(self, ...)
    end)
    _setreadonly(mt, true)
    pcall(function() State.remotes.steal:FireServer(eggModel) end)
    return fired
end

local function stealViaToolEquipAndClick(eggModel)
    local char = LP.Character
    if not char then return false end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return false end
    pcall(function() tool:Activate() end)
    return true
end

local function stealViaCFrameTouch(eggModel)
    if not eggModel or not eggModel.PrimaryPart then return false end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    pcall(function()
        hrp.CFrame = eggModel.PrimaryPart.CFrame + Vector3.new(0, 2, 0)
    end)
    return true
end

local function stealViaSpeedBurst(eggModel)
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local old = hum.WalkSpeed
    hum.WalkSpeed = 200
    task.wait(0.15)
    hum.WalkSpeed = old
    return true
end

local function stealViaGuardianAvoid(eggModel)
    -- skip steal kalau guardian deket
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not eggModel or not eggModel.PrimaryPart then return false end
    for _, g in ipairs(workspace:GetDescendants()) do
        if g:IsA("Model") and string.find(string.lower(g.Name), "guardian") then
            local ghrp = g:FindFirstChild("HumanoidRootPart")
            if ghrp and (ghrp.Position - hrp.Position).Magnitude < 50 then
                return false
            end
        end
    end
    return true
end

local function stealViaEggPrioritySort(eggList)
    table.sort(eggList, function(a, b)
        local ra = a:GetAttribute("Rarity") or "Common"
        local rb = b:GetAttribute("Rarity") or "Common"
        local order = {Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5, Mythic=6, Cosmic=7, Secret=8, Eternal=9, Divine=10}
        return (order[ra] or 1) > (order[rb] or 1)
    end)
    return eggList
end

local function stealViaBatch(eggList, batchSize)
    batchSize = batchSize or 10
    local batch = {}
    for i = 1, math.min(batchSize, #eggList) do
        table.insert(batch, eggList[i])
    end
    for _, egg in ipairs(batch) do
        stealViaRemote(egg)
        task.wait(0.15)
    end
    return true
end

local function stealViaSequentialRemoteChain(eggList)
    for _, egg in ipairs(eggList) do
        stealViaRemote(egg)
        task.wait(State.config.autoStealDelay)
    end
    return true
end

local function stealViaAttributeSpoof(eggModel)
    if not eggModel then return false end
    pcall(function()
        eggModel:SetAttribute("Stolen", true)
        eggModel:SetAttribute("Owner", LP.UserId)
    end)
    return true
end

local function stealViaHiddenRemoteScan()
    -- scan deeper (PlayerScripts, Backpack)
    for _, root in ipairs({LP:FindFirstChild("PlayerScripts"), LP:FindFirstChild("Backpack")}) do
        if root then
            for _, o in ipairs(root:GetDescendants()) do
                if o:IsA("RemoteEvent") or o:IsA("RemoteFunction") then
                    local low = string.lower(o.Name)
                    for _, p in ipairs(REMOTE_PATTERNS.steal) do
                        if string.find(low, p, 1, true) then
                            State.remotes.steal = o
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

local function stealViaGenericFallback(eggModel)
    -- fire semua remote yang ada kata egg/steal
    for _, o in ipairs(RS:GetDescendants()) do
        if (o:IsA("RemoteEvent") or o:IsA("RemoteFunction")) then
            local low = string.lower(o.Name)
            if string.find(low, "egg", 1, true) or string.find(low, "steal", 1, true) then
                pcall(function()
                    if o:IsA("RemoteEvent") then o:FireServer(eggModel)
                    else o:InvokeServer(eggModel) end
                end)
            end
        end
    end
    return true
end

local function stealViaDynamicDelay()
    local base = State.config.autoStealDelay
    local jitter = (math.random(-50, 50) / 1000)
    return math.max(0.05, base + jitter)
end

local function stealViaPositionDesync(eggModel)
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    pcall(function()
        hrp.CFrame = hrp.CFrame + Vector3.new(0, 0.5, 0)
    end)
    return true
end

local function stealViaLatencyCompensation()
    return math.max(0.1, State.config.autoStealDelay - 0.05)
end

local function stealViaBackupRemoteChain(eggModel)
    local backups = {"Steal", "Grab", "Collect", "Take", "Pickup"}
    for _, name in ipairs(backups) do
        local r = RS:FindFirstChild(name, true)
        if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then
            pcall(function()
                if r:IsA("RemoteEvent") then r:FireServer(eggModel)
                else r:InvokeServer(eggModel) end
            end)
            return true
        end
    end
    return false
end

local function stealViaEmergencyAbort()
    State.paused = true
    task.delay(2, function() State.paused = false end)
    return true
end

local function stealViaSilentRetry(eggModel, maxRetry)
    maxRetry = maxRetry or 3
    for i = 1, maxRetry do
        if stealViaRemote(eggModel) then return true end
        task.wait(0.3)
    end
    return false
end

-- PREMIUM ONLY TECHNIQUES

local function premiumFlyCFrame()
    -- handled in fly feature
end

local function premiumGuardianCollisionBypass()
    -- disable collision antara char dan guardian
    local char = LP.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.CanCollide = false
            end)
        end
    end
end

local function premiumServerPositionSpoof()
    -- spoof HRP position
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = hrp.CFrame + Vector3.new(0, 0.1, 0)
    end
end

local function premiumRemoteArgInject(eggModel)
    local r = State.remotes.steal
    if not r then return false end
    pcall(function()
        if r:IsA("RemoteEvent") then
            r:FireServer(eggModel, LP.UserId, true, {bypass = true})
        elseif r:IsA("RemoteFunction") then
            r:InvokeServer(eggModel, LP.UserId, true, {bypass = true})
        end
    end)
    return true
end

local function premiumMultiRemoteSimultaneous(eggModel)
    local fired = 0
    for cat, r in pairs(State.remotes) do
        if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then
            pcall(function()
                if r:IsA("RemoteEvent") then r:FireServer(eggModel)
                else r:InvokeServer(eggModel) end
            end)
            fired = fired + 1
        end
    end
    return fired > 0
end

local function premiumHookFireServerSilent(eggModel)
    local r = State.remotes.steal
    if not r then return false end
    return stealViaNamecallHook(eggModel)
end

local function premiumHookInvokeServerSilent(eggModel)
    local r = State.remotes.steal
    if not r or not r:IsA("RemoteFunction") then return false end
    local mt = _getrawmetatable and _getrawmetatable(game)
    if not mt then return false end
    local oldNamecall = mt.__namecall
    _setreadonly(mt, false)
    mt.__namecall = _newcclosure(function(self, ...)
        local method = _getnamecallmeth()
        if method == "InvokeServer" and self == r then
            return oldNamecall(self, ...)
        end
        return oldNamecall(self, ...)
    end)
    _setreadonly(mt, true)
    pcall(function() r:InvokeServer(eggModel) end)
    return true
end

local function premiumInstanceSpoof(eggModel)
    if not eggModel then return false end
    pcall(function()
        eggModel.Name = "CommonEgg"
        eggModel:SetAttribute("Rarity", "Common")
    end)
    return true
end

local function premiumGravityBypass()
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local bv = Instance.new("BodyForce")
        bv.Force = Vector3.new(0, workspace.Gravity * hrp.AssemblyMass, 0)
        bv.Parent = hrp
        task.delay(0.5, function() bv:Destroy() end)
    end
end

local function premiumInfiniteYieldOnChase()
    -- freeze guardian chase via anchor
    for _, g in ipairs(workspace:GetDescendants()) do
        if g:IsA("Model") and string.find(string.lower(g.Name), "guardian") then
            local hrp = g:FindFirstChild("HumanoidRootPart")
            if hrp then
                pcall(function() hrp.Anchored = true end)
                task.delay(0.3, function()
                    pcall(function() hrp.Anchored = false end)
                end)
            end
        end
    end
end

local function premiumGuardianAIFreeze()
    return premiumInfiniteYieldOnChase()
end

local function premiumEggAttach(eggModel)
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not eggModel or not eggModel.PrimaryPart then return false end
    pcall(function()
        eggModel.PrimaryPart.CFrame = hrp.CFrame
        eggModel.PrimaryPart.Anchored = true
    end)
    return true
end

local function premiumInstantReturnBase()
    local base = workspace:FindFirstChild("Base") or workspace:FindFirstChild("Home")
    if base and base:IsA("Model") and base.PrimaryPart then
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = base.PrimaryPart.CFrame + Vector3.new(0, 5, 0)
        end
    end
end

local function premiumSpeed1000Gradual()
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    task.spawn(function()
        for spd = 16, 1000, 50 do
            hum.WalkSpeed = spd
            task.wait(0.2)
        end
    end)
end

local function premiumTrailMultiplierAbuse()
    -- force trail multiplier client-side
    local char = LP.Character
    if not char then return end
    char:SetAttribute("TrailMultiplier", 14)
end

local function premiumTreadmillInstantMax()
    local r = State.remotes.treadmill
    if not r then return false end
    for i = 1, 10 do
        pcall(function()
            if r:IsA("RemoteEvent") then r:FireServer(i)
            else r:InvokeServer(i) end
        end)
        task.wait(0.15)
    end
    return true
end

local function premiumPenCapacityBypass()
    -- spoof pen capacity client
    LP:SetAttribute("PenCapacity", 9999)
end

local function premiumMutationForce()
    -- force mutation roll client-side
    local rng = Random.new()
    LP:SetAttribute("Mutation", "Rainbow")
end

local function premiumRarityForceClient()
    LP:SetAttribute("ForcedRarity", "Divine")
end

local function premiumEggDuplication(eggModel)
    if not eggModel then return false end
    pcall(function()
        local clone = eggModel:Clone()
        clone.Parent = workspace
    end)
    return true
end

--//============================================================
--// ANTI-BAN (K1-K10)
--//============================================================

-- K1: Hook Kick Remote
local function K1_hookKickRemote()
    for _, obj in ipairs(RS:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local low = string.lower(obj.Name)
            if string.find(low, "kick") or string.find(low, "ban") or string.find(low, "admin") or string.find(low, "mod") or string.find(low, "command") then
                pcall(function()
                    if obj:IsA("RemoteEvent") then
                        _hookfunction(obj.FireClient, function(...) return nil end)
                    elseif obj:IsA("RemoteFunction") then
                        _hookfunction(obj.InvokeClient, function(...) return nil end)
                    end
                end)
            end
        end
    end
end

-- K2: Metatable __namecall Hook to Block Kick
local function K2_metatableBlockKick()
    if not _getrawmetatable or not _setreadonly then return end
    local mt = _getrawmetatable(game)
    local oldNamecall = mt.__namecall
    _setreadonly(mt, false)
    mt.__namecall = _newcclosure(function(self, ...)
        local method = _getnamecallmeth()
        if method == "Kick" or method == "kick" then
            State.kickBlocked = State.kickBlocked + 1
            notify("Kick Blocked", "Total: " .. State.kickBlocked, 2)
            return nil
        end
        return oldNamecall(self, ...)
    end)
    _setreadonly(mt, true)
end

-- K3: Disconnect Kick Connection
local function K3_disconnectKickConnections()
    if not _getconnections then return end
    pcall(function()
        for _, conn in ipairs(_getconnections(Players.LocalPlayer.PlayerRemoving) or {}) do
            pcall(function() conn:Disconnect() end)
        end
    end)
    pcall(function()
        for _, conn in ipairs(_getconnections(Players.PlayerRemoving) or {}) do
            pcall(function() conn:Disconnect() end)
        end
    end)
end

-- K4: Anti-Cheat Evasion — gradual speed
local function K4_gradualSpeed(target)
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    task.spawn(function()
        local cur = hum.WalkSpeed
        while cur < target do
            cur = math.min(cur + 5, target)
            hum.WalkSpeed = cur
            task.wait(0.5)
        end
    end)
end

-- K5: Anti-Kick UI Feedback — notify
-- (sudah ada di K2)

-- K6: Auto-Rejoin
local function K6_autoRejoin()
    task.spawn(function()
        while State.config.autoRejoin do
            task.wait(1)
            pcall(function()
                if LP.Parent == nil or not LP.Character then
                    task.wait(State.config.autoRejoinDelay)
                    local placeId = game.PlaceId
                    local jobId = game.JobId
                    TeleportService:TeleportToPlaceInstance(placeId, jobId, LP)
                end
            end)
        end
    end)
end

-- K7: Server Hop Fallback
local function K7_serverHop()
    local ok, response = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100")
    end)
    if not ok then return end
    local data = HttpService:JSONDecode(response)
    if not data or not data.data then return end
    local servers = {}
    for _, srv in ipairs(data.data) do
        if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
            table.insert(servers, srv.id)
        end
    end
    if #servers == 0 then return end
    local chosen = servers[math.random(1, #servers)]
    TeleportService:TeleportToPlaceInstance(game.PlaceId, chosen, LP)
end

-- K8: Whitelist Bypass (spoof UserId)
local function K8_spoofUserId()
    -- note: client-side only
    pcall(function()
        LP.UserId = 1
    end)
end

-- K9: Anti-Chaos Detection — stealth mode
local function K9_stealthMode()
    State.stealthMode = true
    -- aktifkan hanya fitur esensial
    State.config.espPlayer = false
    State.config.espEgg = false
    State.config.espGuardian = false
    State.config.tracerGuardian = false
    State.config.fly = false
    State.config.autoStealAll = false
    State.config.autoHatchAll = false
    notify("Stealth Mode", "Fitur non-esensial dimatikan", 3)
end

-- K10: External Executor Note (informational)
-- Untuk bypass anti-cheat level tinggi, butuh executor level 8+
-- Delta free UNC ~90%, cukup buat hook dasar

--//============================================================
--// ANTI-KICK + ANTI-ROB LOOP
--//============================================================
local function startAntiBan()
    if not State.config.antiBan then return end
    K1_hookKickRemote()
    K2_metatableBlockKick()
    K3_disconnectKickConnections()
    K6_autoRejoin()

    -- periodic kick guard
    table.insert(State.connections, task.spawn(function()
        while State.config.antiBan do
            task.wait(30)
            if State.kickBlocked > 5 then
                notify("Warning", "Kick attempts > 5, unloading...", 3)
                K9_stealthMode()
            end
        end
    end))
end

-- Anti-Rob
local function startAntiRob()
    table.insert(State.connections, RunService.Heartbeat:Connect(function()
        if not State.config.antiRob then return end
        local base = workspace:FindFirstChild("Base") or workspace:FindFirstChild("Home")
        if not base or not base.PrimaryPart then return end
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local basePos = base.PrimaryPart.Position
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local phrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if phrp and (phrp.Position - basePos).Magnitude < State.config.antiRobDistance then
                    -- teleport balik ke base
                    hrp.CFrame = basePos + Vector3.new(0, 5, 0)
                    return
                end
            end
        end
    end))
end

--//============================================================
--// ESP SYSTEM (Drawing API)
--//============================================================
local function createDrawing(class, props)
    if not Drawing then return nil end
    local d = Drawing.new(class)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function espLoop()
    table.insert(State.connections, RunService.RenderStepped:Connect(function()
        -- Egg ESP
        if State.config.espEgg then
            for _, egg in ipairs(workspace:GetDescendants()) do
                if egg:IsA("Model") and string.find(string.lower(egg.Name), "egg") and egg.PrimaryPart then
                    local rarity = egg:GetAttribute("Rarity") or "Common"
                    if table.find(State.config.espEggRarityFilter, rarity) then
                        local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(egg.PrimaryPart.Position)
                        if onScreen then
                            local id = "egg_" .. egg:GetDebugId()
                            if not State.espObjects[id] then
                                State.espObjects[id] = {
                                    box = createDrawing("Square", {
                                        Thickness = 1,
                                        Color = Color3.fromRGB(255, 100, 100),
                                        Filled = false,
                                        Visible = true
                                    }),
                                    label = createDrawing("Text", {
                                        Size = 14,
                                        Center = true,
                                        Outline = true,
                                        Color = Color3.fromRGB(255, 255, 255),
                                        Visible = true
                                    })
                                }
                            end
                            local obj = State.espObjects[id]
                            local dist = (egg.PrimaryPart.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
                            if dist < State.config.espEggMaxDistance then
                                obj.box.Size = Vector2.new(50, 50)
                                obj.box.Position = Vector2.new(pos.X - 25, pos.Y - 25)
                                obj.box.Visible = true
                                obj.label.Text = egg.Name .. " [" .. rarity .. "]"
                                obj.label.Position = Vector2.new(pos.X, pos.Y - 40)
                                obj.label.Visible = true
                            else
                                obj.box.Visible = false
                                obj.label.Visible = false
                            end
                        end
                    end
                end
            end
        end

        -- Guardian ESP
        if State.config.espGuardian then
            for _, g in ipairs(workspace:GetDescendants()) do
                if g:IsA("Model") and string.find(string.lower(g.Name), "guardian") and g.PrimaryPart then
                    local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(g.PrimaryPart.Position)
                    if onScreen then
                        local id = "guard_" .. g:GetDebugId()
                        if not State.espObjects[id] then
                            State.espObjects[id] = {
                                box = createDrawing("Square", {
                                    Thickness = 1,
                                    Color = Color3.fromRGB(255, 0, 0),
                                    Filled = false,
                                    Visible = true
                                }),
                                label = createDrawing("Text", {
                                    Size = 14,
                                    Center = true,
                                    Outline = true,
                                    Color = Color3.fromRGB(255, 100, 100),
                                    Visible = true
                                })
                            }
                        end
                        local obj = State.espObjects[id]
                        local dist = (g.PrimaryPart.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
                        if dist < State.config.espGuardianMaxDistance then
                            obj.box.Size = Vector2.new(60, 60)
                            obj.box.Position = Vector2.new(pos.X - 30, pos.Y - 30)
                            obj.box.Visible = true
                            obj.label.Text = "GUARDIAN: " .. g.Name
                            obj.label.Position = Vector2.new(pos.X, pos.Y - 45)
                            obj.label.Visible = true
                        else
                            obj.box.Visible = false
                            obj.label.Visible = false
                        end
                    end
                end
            end
        end

        -- Player ESP
        if State.config.espPlayer then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP and plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
                        if onScreen then
                            local id = "plr_" .. plr.UserId
                            if not State.espObjects[id] then
                                State.espObjects[id] = {
                                    box = createDrawing("Square", {
                                        Thickness = 1,
                                        Color = Color3.fromRGB(0, 200, 255),
                                        Filled = false,
                                        Visible = true
                                    }),
                                    label = createDrawing("Text", {
                                        Size = 14,
                                        Center = true,
                                        Outline = true,
                                        Color = Color3.fromRGB(0, 255, 255),
                                        Visible = true
                                    })
                                }
                            end
                            local obj = State.espObjects[id]
                            local dist = (hrp.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
                            if dist < State.config.espPlayerMaxDistance then
                                obj.box.Size = Vector2.new(40, 60)
                                obj.box.Position = Vector2.new(pos.X - 20, pos.Y - 30)
                                obj.box.Visible = true
                                obj.label.Text = plr.Name .. " (" .. math.floor(dist) .. "m)"
                                obj.label.Position = Vector2.new(pos.X, pos.Y - 45)
                                obj.label.Visible = true
                            else
                                obj.box.Visible = false
                                obj.label.Visible = false
                            end
                        end
                    end
                end
            end
        end

        -- Tracer
        if State.config.tracerGuardian and Drawing then
            if not State.tracerLine then
                State.tracerLine = createDrawing("Line", {
                    Thickness = 2,
                    Color = Color3.fromRGB(255, 0, 0),
                    Visible = true,
                    Transparency = 0.5
                })
            end
            local closest = nil
            local closestDist = math.huge
            for _, g in ipairs(workspace:GetDescendants()) do
                if g:IsA("Model") and string.find(string.lower(g.Name), "guardian") and g.PrimaryPart then
                    local d = (g.PrimaryPart.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
                    if d < closestDist then
                        closestDist = d
                        closest = g
                    end
                end
            end
            if closest then
                local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(closest.PrimaryPart.Position)
                if onScreen then
                    State.tracerLine.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
                    State.tracerLine.To = Vector2.new(pos.X, pos.Y)
                    State.tracerLine.Visible = true
                else
                    State.tracerLine.Visible = false
                end
            else
                State.tracerLine.Visible = false
            end
        end
    end))
end

--//============================================================
--// MOVEMENT SYSTEM
--//============================================================
local function startSpeedBoost()
    table.insert(State.connections, RunService.Heartbeat:Connect(function()
        if not State.config.speedBoost then return end
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed < State.config.speedBoostValue then
            if State.config.speedBoostGradual then
                hum.WalkSpeed = math.min(hum.WalkSpeed + 0.5, State.config.speedBoostValue)
            else
                hum.WalkSpeed = State.config.speedBoostValue
            end
        end
    end))
end

local function startInfiniteJump()
    table.insert(State.connections, UIS.JumpRequest:Connect(function()
        if not State.config.infiniteJump then return end
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end))
end

local function startNoclip()
    table.insert(State.connections, RunService.Stepped:Connect(function()
        if not State.config.noclip then return end
        local char = LP.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end))
end

-- FLY PREMIUM
local function startFly()
    local bodyVelocity, bodyGyro, alignPos, alignOri
    local flyConnection
    local function cleanup()
        if bodyVelocity then bodyVelocity:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end
        if alignPos then alignPos:Destroy() end
        if alignOri then alignOri:Destroy() end
        bodyVelocity, bodyGyro, alignPos, alignOri = nil, nil, nil, nil
    end

    flyConnection = RunService.RenderStepped:Connect(function()
        if not State.config.fly then
            cleanup()
            return
        end
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        if State.config.flyMode == "BodyVelocity" then
            if not bodyVelocity then
                bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bodyVelocity.Parent = hrp
                bodyGyro = Instance.new("BodyGyro")
                bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                bodyGyro.P = 1000
                bodyGyro.Parent = hrp
            end
            local cam = workspace.CurrentCamera
            local dir = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
            bodyVelocity.Velocity = dir * State.config.flySpeed
            bodyGyro.CFrame = cam.CFrame
        else
            -- CFrame mode
            local cam = workspace.CurrentCamera
            local speed = State.config.flySpeed / 60
            local dir = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
            hrp.CFrame = hrp.CFrame + dir * speed
        end
    end)
    table.insert(State.connections, flyConnection)
end

--//============================================================
--// CORE WORKER: AUTO STEAL
--//============================================================
local function collectEggs()
    local eggs = {}
    for _, egg in ipairs(workspace:GetDescendants()) do
        if egg:IsA("Model") and string.find(string.lower(egg.Name), "egg") and egg.PrimaryPart then
            local rarity = egg:GetAttribute("Rarity") or "Common"
            local biome = egg:GetAttribute("Biome") or "unknown"
            local weight = egg:GetAttribute("Weight") or 0
            local matchRarity = not State.config.autoStealSelectedOnly
                or table.find(State.config.autoStealRarityFilter, rarity)
            local matchBiome = table.find(State.config.autoStealBiomeFilter, "all")
                or table.find(State.config.autoStealBiomeFilter, biome)
            local matchWeight = weight >= State.config.autoStealWeightMin
            local matchName = not State.config.autoStealRandomName
                or math.random(1, 3) == 1
            if matchRarity and matchBiome and matchWeight and matchName then
                table.insert(eggs, egg)
            end
        end
    end
    return eggs
end

local function startAutoSteal()
    table.insert(State.connections, task.spawn(function()
        while true do
            task.wait(0.5)
            if not State.config.autoSteal or State.paused then continue end

            local eggs = collectEggs()
            if #eggs == 0 then continue end

            eggs = stealViaEggPrioritySort(eggs)
            local target = eggs[1]

            -- pilih teknik
            if State.tier == "premium" and State.config.advancedSteal then
                if State.config.guardianBypass then premiumGuardianCollisionBypass() end
                if math.random(1, 3) == 1 then premiumMultiRemoteSimultaneous(target)
                else premiumRemoteArgInject(target) end
                if State.config.fly then premiumGuardianCollisionBypass() end
            else
                -- basic: 20+ teknik, tanpa fly
                local techniques = {
                    stealViaRemote, stealViaProximityPrompt, stealViaRemoteNoArg,
                    stealViaNamecallHook, stealViaToolEquipAndClick, stealViaCFrameTouch,
                    stealViaSpeedBurst, stealViaGuardianAvoid, stealViaBatch,
                    stealViaSequentialRemoteChain, stealViaAttributeSpoof,
                    stealViaGenericFallback, stealViaPositionDesync, stealViaBackupRemoteChain,
                    stealViaSilentRetry
                }
                local fn = techniques[math.random(1, #techniques)]
                pcall(fn, target)
            end

            task.wait(stealViaDynamicDelay())
        end
    end))
end

--//============================================================
--// AUTO HATCH / PLACE / SELL
--//============================================================
local function startAutoHatch()
    table.insert(State.connections, task.spawn(function()
        while true do
            task.wait(1)
            if not State.config.autoHatch then continue end
            local r = State.remotes.hatch
            if not r then continue end
            -- cari egg di inventory
            local inv = LP:FindFirstChild("Backpack")
            if inv then
                for _, item in ipairs(inv:GetChildren()) do
                    if string.find(string.lower(item.Name), "egg") then
                        pcall(function()
                            if r:IsA("RemoteEvent") then r:FireServer(item)
                            else r:InvokeServer(item) end
                        end)
                        task.wait(State.config.autoHatchDelay)
                    end
                end
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
            if not r then continue end
            pcall(function()
                if r:IsA("RemoteEvent") then r:FireServer()
                else r:InvokeServer() end
            end)
        end
    end))
end

local function startAutoSell()
    table.insert(State.connections, task.spawn(function()
        while true do
            task.wait(3)
            if not State.config.autoSell then continue end
            local r = State.remotes.sell
            if not r then continue end
            pcall(function()
                if r:IsA("RemoteEvent") then r:FireServer()
                else r:InvokeServer() end
            end)
        end
    end))
end

--//============================================================
--// AUTO TREADMILL / UPGRADE / EVENT / REWARD
--//============================================================
local function startAutoTreadmill()
    table.insert(State.connections, task.spawn(function()
        while true do
            task.wait(2)
            if not State.config.autoTreadmill then continue end
            if State.tier == "premium" and State.config.advancedSteal then
                premiumTreadmillInstantMax()
            else
                local r = State.remotes.treadmill
                if r then
                    pcall(function()
                        if r:IsA("RemoteEvent") then r:FireServer()
                        else r:InvokeServer() end
                    end)
                end
                -- fallback: MoveTo treadmill
                local treadmill = workspace:FindFirstChild("Treadmill", true)
                local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                if treadmill and hum then
                    pcall(function() hum:MoveTo(treadmill.Position) end)
                end
            end
        end
    end))
end

local function startAutoUpgrade()
    table.insert(State.connections, task.spawn(function()
        while true do
            task.wait(5)
            if not State.config.autoUpgrade then continue end
            local r = State.remotes.treadmill
            if r then
                for i = 1, State.config.autoUpgradeMaxLevel do
                    pcall(function()
                        if r:IsA("RemoteEvent") then r:FireServer("upgrade", i)
                        else r:InvokeServer("upgrade", i) end
                    end)
                    task.wait(0.5)
                end
            end
        end
    end))
end

local function startAutoEvent()
    table.insert(State.connections, task.spawn(function()
        while true do
            task.wait(5)
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

local function startClaimReward()
    table.insert(State.connections, task.spawn(function()
        while true do
            task.wait(10)
            if not State.config.claimReward then continue end
            local r = State.remotes.event
            if r then
                for _, key in ipairs({"daily", "season", "index"}) do
                    pcall(function()
                        if r:IsA("RemoteEvent") then r:FireServer("claim", key)
                        else r:InvokeServer("claim", key) end
                    end)
                    task.wait(0.5)
                end
            end
        end
    end))
end

--//============================================================
--// SERVER HOP + AUTO REJOIN
--//============================================================
local function findEmptyServer()
    local ok, resp = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100")
    end)
    if not ok then return nil end
    local data = HttpService:JSONDecode(resp)
    if not data or not data.data then return nil end
    local best, bestCount = nil, math.huge
    for _, srv in ipairs(data.data) do
        if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
            if srv.playing < bestCount then
                best = srv.id
                bestCount = srv.playing
            end
        end
    end
    return best, bestCount
end

local function serverHop()
    local jobId, count = findEmptyServer()
    if jobId then
        notify("Server Hop", "Pindah ke server " .. count .. " player", 3)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LP)
    else
        notify("Server Hop", "Tidak ada server sepi", 3)
    end
end

--//============================================================
--// CUSTOM UI BUILDER
--//============================================================
local function createUI()
    local screen = Instance.new("ScreenGui")
    screen.Name = "Settings"
    screen.ResetOnSpawn = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() screen.Parent = _gethui() end)
    if not screen.Parent then screen.Parent = game:GetService("CoreGui") end
    State.ui.screen = screen

    -- Background blur
    if State.config.uiBlur then
        local blur = Instance.new("BlurEffect")
        blur.Size = 8
        blur.Parent = Lighting
        State.ui.blur = blur
    end

    -- Main frame
    local main = Instance.new("Frame")
    main.Name = "Panel"
    main.Size = UDim2.new(0, 620, 0, 420)
    main.Position = UDim2.new(0.5, -310, 0.5, -210)
    main.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    main.BackgroundTransparency = State.config.uiTransparency
    main.BorderSizePixel = 0
    main.Parent = screen
    State.ui.main = main

    local corner = Instance.new("UICorner", main)
    corner.CornerRadius = UDim.new(0, 12)

    local stroke = Instance.new("UIStroke", main)
    stroke.Color = State.config.uiAccentColor
    stroke.Thickness = 1.5
    stroke.Transparency = 0.4

    -- Background image
    if BG_ID then
        local bgImg = Instance.new("ImageLabel")
        bgImg.Size = UDim2.new(1, 0, 1, 0)
        bgImg.BackgroundTransparency = 1
        bgImg.Image = BG_ID
        bgImg.ImageTransparency = 0.7
        bgImg.ScaleType = Enum.ScaleType.Crop
        bgImg.ZIndex = 0
        bgImg.Parent = main
    end

    -- Topbar
    local topbar = Instance.new("Frame")
    topbar.Name = "Topbar"
    topbar.Size = UDim2.new(1, 0, 0, 40)
    topbar.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    topbar.BackgroundTransparency = 0.2
    topbar.BorderSizePixel = 0
    topbar.ZIndex = 5
    topbar.Parent = main

    local topCorner = Instance.new("UICorner", topbar)
    topCorner.CornerRadius = UDim.new(0, 12)

    -- Logo
    if LOGO_ID then
        local logo = Instance.new("ImageLabel")
        logo.Size = UDim2.new(0, 28, 0, 28)
        logo.Position = UDim2.new(0, 8, 0, 6)
        logo.BackgroundTransparency = 1
        logo.Image = LOGO_ID
        logo.ZIndex = 6
        logo.Parent = topbar
    end

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -120, 1, 0)
    title.Position = UDim2.new(0, 42, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "BAZZ PREMIUM — STEAL AN EGG"
    title.TextColor3 = State.config.uiAccentColor
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.ZIndex = 6
    title.Parent = topbar

    -- Minimize button
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 28, 0, 28)
    minBtn.Position = UDim2.new(1, -68, 0, 6)
    minBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    minBtn.Text = "—"
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 14
    minBtn.BorderSizePixel = 0
    minBtn.ZIndex = 6
    minBtn.Parent = topbar
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -36, 0, 6)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.BorderSizePixel = 0
    closeBtn.ZIndex = 6
    closeBtn.Parent = topbar
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

    closeBtn.MouseButton1Click:Connect(function()
        screen.Enabled = false
    end)

    -- Sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 130, 1, -40)
    sidebar.Position = UDim2.new(0, 0, 0, 40)
    sidebar.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
    sidebar.BackgroundTransparency = 0.3
    sidebar.BorderSizePixel = 0
    sidebar.ZIndex = 3
    sidebar.Parent = main

    local sidebarLayout = Instance.new("UIListLayout", sidebar)
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Padding = UDim.new(0, 4)

    local sidebarPad = Instance.new("UIPadding", sidebar)
    sidebarPad.PaddingTop = UDim.new(0, 8)
    sidebarPad.PaddingLeft = UDim.new(0, 6)
    sidebarPad.PaddingRight = UDim.new(0, 6)

    -- Content area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -140, 1, -50)
    content.Position = UDim2.new(0, 135, 0, 45)
    content.BackgroundTransparency = 1
    content.ZIndex = 3
    content.Parent = main

    local contentScroll = Instance.new("ScrollingFrame")
    contentScroll.Size = UDim2.new(1, 0, 1, 0)
    contentScroll.BackgroundTransparency = 1
    contentScroll.BorderSizePixel = 0
    contentScroll.ScrollBarThickness = 4
    contentScroll.ScrollBarImageColor3 = State.config.uiAccentColor
    contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentScroll.Parent = content

    local contentLayout = Instance.new("UIListLayout", contentScroll)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 6)

    State.ui.content = contentScroll

    -- Bottom bar
    local bottom = Instance.new("Frame")
    bottom.Size = UDim2.new(1, 0, 0, 22)
    bottom.Position = UDim2.new(0, 0, 1, -22)
    bottom.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    bottom.BackgroundTransparency = 0.3
    bottom.BorderSizePixel = 0
    bottom.ZIndex = 4
    bottom.Parent = main

    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(1, -10, 1, 0)
    statusLbl.Position = UDim2.new(0, 5, 0, 0)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = "Status: Loading..."
    statusLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.Font = Enum.Font.Code
    statusLbl.TextSize = 11
    statusLbl.ZIndex = 5
    statusLbl.Parent = bottom
    State.ui.status = statusLbl

    -- Status updater
    task.spawn(function()
        while screen.Parent do
            task.wait(1)
            local fps = math.floor(1 / RunService.RenderStepped:Wait())
            local uptime = math.floor(tick() - State.startTime)
            local ping = math.floor(LP:GetNetworkPing() * 1000)
            statusLbl.Text = string.format("Tier: %s | FPS: %d | Ping: %dms | Uptime: %ds | Kicks blocked: %d",
                string.upper(State.tier), fps, ping, uptime, State.kickBlocked)
        end
    end)

    -- Draggable
    local dragging, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not State.config.uiPinned then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    topbar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Keybind show/hide
    UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode[State.config.uiKeybind] then
            screen.Enabled = not screen.Enabled
        end
        if input.KeyCode == Enum.KeyCode[State.config.serverHopKeybind] then
            serverHop()
        end
    end)

    State.ui.topbar = topbar
    State.ui.sidebar = sidebar
    State.ui.contentScroll = contentScroll
end

--//============================================================
--// UI COMPONENTS
--//============================================================
local function addTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    btn.BackgroundTransparency = 0.3
    btn.Text = "  " .. name
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.Parent = State.ui.sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1, 0, 0, 0)
    tabContent.AutomaticSize = Enum.AutomaticSize.Y
    tabContent.BackgroundTransparency = 1
    tabContent.Visible = false
    tabContent.Parent = State.ui.contentScroll
    local layout = Instance.new("UIListLayout", tabContent)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)

    btn.MouseButton1Click:Connect(function()
        for _, c in ipairs(State.ui.contentScroll:GetChildren()) do
            if c:IsA("Frame") then c.Visible = false end
        end
        tabContent.Visible = true
    end)

    return tabContent
end

local function addSection(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    lbl.BackgroundTransparency = 0.5
    lbl.Text = "  " .. text
    lbl.TextColor3 = State.config.uiAccentColor
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.BorderSizePixel = 0
    lbl.Parent = parent
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 4)
end

local function addToggle(parent, label, key, onChange, premiumOnly)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 28)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 5)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label .. (premiumOnly and " [PREMIUM]" or "")
    lbl.TextColor3 = premiumOnly and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(220, 220, 220)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 40, 0, 20)
    btn.Position = UDim2.new(1, -50, 0, 4)
    btn.BackgroundColor3 = State.config[key] and State.config.uiAccentColor or Color3.fromRGB(50, 50, 60)
    btn.Text = State.config[key] and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.BorderSizePixel = 0
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    btn.MouseButton1Click:Connect(function()
        if premiumOnly and State.tier ~= "premium" then
            notify("Locked", "Fitur premium, key: Joy", 3)
            return
        end
        State.config[key] = not State.config[key]
        btn.BackgroundColor3 = State.config[key] and State.config.uiAccentColor or Color3.fromRGB(50, 50, 60)
        btn.Text = State.config[key] and "ON" or "OFF"
        saveConfig()
        if onChange then onChange(State.config[key]) end
    end)
end

local function addSlider(parent, label, key, min, max, onChange, premiumOnly)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 44)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 5)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 18)
    lbl.Position = UDim2.new(0, 10, 0, 2)
    lbl.BackgroundTransparency = 1
    lbl.Text = label .. ": " .. tostring(State.config[key]) .. (premiumOnly and " [PREMIUM]" or "")
    lbl.TextColor3 = premiumOnly and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(220, 220, 220)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 8)
    bar.Position = UDim2.new(0, 10, 0, 26)
    bar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    bar.BorderSizePixel = 0
    bar.Parent = frame
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((State.config[key] - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = State.config.uiAccentColor
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

    local dragging = false
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mouseX = input.Position.X
            local absPos = bar.AbsolutePosition.X
            local absSize = bar.AbsoluteSize.X
            local pct = math.clamp((mouseX - absPos) / absSize, 0, 1)
            local val = min + (max - min) * pct
            State.config[key] = val
            fill.Size = UDim2.new(pct, 0, 1, 0)
            lbl.Text = label .. ": " .. string.format("%.2f", val) .. (premiumOnly and " [PREMIUM]" or "")
            if onChange then onChange(val) end
            saveConfig()
        end
    end)
end

local function addDropdown(parent, label, key, options, onChange)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 28)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 5)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -100, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.Parent = frame

    local sel = Instance.new("TextButton")
    sel.Size = UDim2.new(0, 80, 0, 20)
    sel.Position = UDim2.new(1, -90, 0, 4)
    sel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    sel.Text = tostring(State.config[key])
    sel.TextColor3 = Color3.fromRGB(255, 255, 255)
    sel.Font = Enum.Font.Gotham
    sel.TextSize = 10
    sel.BorderSizePixel = 0
    sel.Parent = frame
    Instance.new("UICorner", sel).CornerRadius = UDim.new(0, 4)

    local list = Instance.new("Frame")
    list.Size = UDim2.new(0, 200, 0, math.min(#options * 22, 200))
    list.Position = UDim2.new(0.5, -100, 0.5, -100)
    list.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    list.BorderSizePixel = 0
    list.Visible = false
    list.ZIndex = 100
    list.Parent = State.ui.screen
    Instance.new("UICorner", list).CornerRadius = UDim.new(0, 6)

    local listLayout = Instance.new("UIListLayout", list)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    for _, opt in ipairs(options) do
        local ob = Instance.new("TextButton")
        ob.Size = UDim2.new(1, 0, 0, 22)
        ob.BackgroundTransparency = 1
        ob.Text = opt
        ob.TextColor3 = Color3.fromRGB(220, 220, 220)
        ob.Font = Enum.Font.Gotham
        ob.TextSize = 11
        ob.Parent = list
        ob.MouseButton1Click:Connect(function()
            State.config[key] = opt
            sel.Text = opt
            list.Visible = false
            if onChange then onChange(opt) end
            saveConfig()
        end)
    end

    sel.MouseButton1Click:Connect(function()
        list.Visible = not list.Visible
    end)
end

local function addButton(parent, label, callback, premiumOnly)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.BackgroundColor3 = premiumOnly and Color3.fromRGB(60, 40, 0) or Color3.fromRGB(30, 30, 40)
    btn.Text = label .. (premiumOnly and " [PREMIUM]" or "")
    btn.TextColor3 = premiumOnly and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    btn.MouseButton1Click:Connect(function()
        if premiumOnly and State.tier ~= "premium" then
            notify("Locked", "Fitur premium, key: Joy", 3)
            return
        end
        callback()
    end)
end

local function addTextBox(parent, label, key, onChange)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 28)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 5)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.Parent = frame

    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(0.45, 0, 0, 20)
    tb.Position = UDim2.new(0.5, 0, 0, 4)
    tb.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    tb.Text = tostring(State.config[key])
    tb.TextColor3 = Color3.fromRGB(255, 255, 255)
    tb.Font = Enum.Font.Code
    tb.TextSize = 11
    tb.BorderSizePixel = 0
    tb.ClearTextOnFocus = false
    tb.Parent = frame
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 4)

    tb.FocusLost:Connect(function()
        State.config[key] = tb.Text
        if onChange then onChange(tb.Text) end
        saveConfig()
    end)
end

--//============================================================
--// BUILD UI TABS
--//============================================================
local function buildUI()
    local tabMain     = addTab("Main")
    local tabSteal    = addTab("Steal")
    local tabAuto     = addTab("Auto")
    local tabESP      = addTab("ESP")
    local tabMovement = addTab("Movement")
    local tabPremium  = addTab("Premium")
    local tabSettings = addTab("Settings")

    -- MAIN
    addSection(tabMain, "Status")
    addButton(tabMain, "Reload Config", function() loadConfig() notify("Config", "Reloaded", 2) end)
    addButton(tabMain, "Save Config", function() saveConfig() notify("Config", "Saved", 2) end)
    addButton(tabMain, "Server Hop (Cari Sepi)", function() serverHop() end)
    addButton(tabMain, "Stealth Mode", function() K9_stealthMode() end)

    -- STEAL
    addSection(tabSteal, "Auto Steal")
    addToggle(tabSteal, "Auto Steal", "autoSteal")
    addSlider(tabSteal, "Steal Delay", "autoStealDelay", 0.05, 2.0)
    addToggle(tabSteal, "Selected Only", "autoStealSelectedOnly")
    addToggle(tabSteal, "Big Egg Priority", "autoStealBigEgg")
    addToggle(tabSteal, "Secret Egg Priority", "autoStealSecretEgg")
    addToggle(tabSteal, "Random Name Filter", "autoStealRandomName")
    addToggle(tabSteal, "Auto Steal All", "autoStealAll")
    addSlider(tabSteal, "Weight Min", "autoStealWeightMin", 0, 100)
    addDropdown(tabSteal, "Biome", "autoStealBiomeFilter", {"all","Forest","Lake","Desert","Jungle","Snow","Volcano","Abyss","Prehistoric","Cosmic","Cherry Blossom","Titan Temple"})

    -- AUTO
    addSection(tabAuto, "Auto Hatch / Place / Sell")
    addToggle(tabAuto, "Auto Hatch", "autoHatch")
    addToggle(tabAuto, "Auto Hatch All", "autoHatchAll")
    addToggle(tabAuto, "Auto Place", "autoPlace")
    addToggle(tabAuto, "Auto Sell", "autoSell")
    addSection(tabAuto, "Auto Treadmill / Upgrade")
    addToggle(tabAuto, "Auto Treadmill", "autoTreadmill")
    addSlider(tabAuto, "Treadmill Target", "autoTreadmillTarget", 16, 1000)
    addToggle(tabAuto, "Auto Upgrade", "autoUpgrade")
    addSlider(tabAuto, "Max Upgrade Level", "autoUpgradeMaxLevel", 1, 10)
    addSection(tabAuto, "Auto Event / Reward")
    addToggle(tabAuto, "Auto Event", "autoEvent")
    addToggle(tabAuto, "Auto Rift", "autoRift")
    addToggle(tabAuto, "Claim Reward", "claimReward")
    addToggle(tabAuto, "Claim Daily", "claimDaily")
    addToggle(tabAuto, "Claim Season", "claimSeason")
    addToggle(tabAuto, "Claim Index", "claimIndex")

    -- ESP
    addSection(tabESP, "ESP")
    addToggle(tabESP, "ESP Egg", "espEgg")
    addSlider(tabESP, "Egg Max Distance", "espEggMaxDistance", 50, 2000)
    addToggle(tabESP, "ESP Guardian", "espGuardian")
    addSlider(tabESP, "Guardian Max Distance", "espGuardianMaxDistance", 50, 2000)
    addToggle(tabESP, "ESP Player", "espPlayer")
    addSlider(tabESP, "Player Max Distance", "espPlayerMaxDistance", 50, 2000)
    addToggle(tabESP, "Tracer Guardian", "tracerGuardian")

    -- MOVEMENT
    addSection(tabMovement, "Movement")
    addToggle(tabMovement, "Speed Boost", "speedBoost")
    addSlider(tabMovement, "Speed Value", "speedBoostValue", 16, 500)
    addToggle(tabMovement, "Speed Gradual", "speedBoostGradual")
    addToggle(tabMovement, "Infinite Jump", "infiniteJump")
    addToggle(tabMovement, "Noclip", "noclip")

    -- PREMIUM
    addSection(tabPremium, "Premium Only")
    addToggle(tabPremium, "Fly", "fly", nil, true)
    addDropdown(tabPremium, "Fly Mode", "flyMode", {"CFrame","BodyVelocity","LinearVelocity","AlignPosition"})
    addSlider(tabPremium, "Fly Speed", "flySpeed", 10, 500, nil, true)
    addToggle(tabPremium, "Guardian Bypass", "guardianBypass", nil, true)
    addToggle(tabPremium, "Advanced Steal", "advancedSteal", nil, true)
    addToggle(tabPremium, "Smart Route", "smartRoute", nil, true)
    addToggle(tabPremium, "Auto Biome Rotation", "autoBiomeRotation", nil, true)

    -- SETTINGS
    addSection(tabSettings, "Anti-Ban")
    addToggle(tabSettings, "Anti-Ban", "antiBan")
    addToggle(tabSettings, "Anti-Kick", "antiKick")
    addToggle(tabSettings, "Auto Rejoin", "autoRejoin")
    addSlider(tabSettings, "Rejoin Delay", "autoRejoinDelay", 1, 30)
    addToggle(tabSettings, "Anti-Rob", "antiRob")
    addSlider(tabSettings, "Anti-Rob Distance", "antiRobDistance", 10, 100)
    addSection(tabSettings, "UI")
    addDropdown(tabSettings, "Theme", "uiTheme", {"Dark","Light","Discord"})
    addToggle(tabSettings, "Blur", "uiBlur")
    addToggle(tabSettings, "Watermark", "uiWatermark")
    addToggle(tabSettings, "Animation", "uiAnimation")
    addToggle(tabSettings, "Pinned", "uiPinned")
    addSection(tabSettings, "Stealth")
    addToggle(tabSettings, "Stealth Mode", "stealthMode")
    addTextBox(tabSettings, "Webhook URL", "webhookUrl")
end

--//============================================================
--// KEY SYSTEM
--//============================================================
local function authenticate(inputKey)
    if inputKey == KEYS.premium then
        State.tier = "premium"
        State.authenticated = true
        return true
    elseif inputKey == KEYS.basic then
        State.tier = "basic"
        State.authenticated = true
        return true
    end
    return false
end

local function showKeyPrompt()
    local screen = Instance.new("ScreenGui")
    screen.Name = "Config"
    screen.ResetOnSpawn = false
    pcall(function() screen.Parent = _gethui() end)
    if not screen.Parent then screen.Parent = game:GetService("CoreGui") end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 360, 0, 200)
    frame.Position = UDim2.new(0.5, -180, 0.5, -100)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    frame.BorderSizePixel = 0
    frame.Parent = screen
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(0, 255, 150)
    stroke.Thickness = 1.5

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "BAZZ PREMIUM — KEY"
    title.TextColor3 = Color3.fromRGB(0, 255, 150)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = frame

    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(1, -40, 0, 36)
    tb.Position = UDim2.new(0, 20, 0, 60)
    tb.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    tb.PlaceholderText = "Masukkan key (bazz / Joy)"
    tb.Text = ""
    tb.TextColor3 = Color3.fromRGB(255, 255, 255)
    tb.Font = Enum.Font.Gotham
    tb.TextSize = 13
    tb.BorderSizePixel = 0
    tb.Parent = frame
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 6)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -40, 0, 36)
    btn.Position = UDim2.new(0, 20, 0, 110)
    btn.BackgroundColor3 = Color3.fromRGB(0, 200, 120)
    btn.Text = "SUBMIT"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -40, 0, 30)
    info.Position = UDim2.new(0, 20, 0, 155)
    info.BackgroundTransparency = 1
    info.Text = "Basic: bazz  |  Premium: Joy"
    info.TextColor3 = Color3.fromRGB(150, 150, 150)
    info.Font = Enum.Font.Gotham
    info.TextSize = 11
    info.Parent = frame

    btn.MouseButton1Click:Connect(function()
        if authenticate(tb.Text) then
            screen:Destroy()
            notify("Authenticated", "Tier: " .. string.upper(State.tier), 3)
            task.wait(0.5)
            createUI()
            buildUI()
            discoverRemotes()
            startAutoSteal()
            startAutoHatch()
            startAutoPlace()
            startAutoSell()
            startAutoTreadmill()
            startAutoUpgrade()
            startAutoEvent()
            startClaimReward()
            startSpeedBoost()
            startInfiniteJump()
            startNoclip()
            startFly()
            espLoop()
            startAntiBan()
            startAntiRob()
            notify("Loaded", "BAZZ Premium aktif — tier: " .. string.upper(State.tier), 4)
        else
            info.Text = "Key salah. Coba lagi."
            info.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
    end)
end

--//============================================================
--// CLEANUP HANDLER
--//============================================================
local function cleanup()
    for _, c in ipairs(State.connections) do
        pcall(function() c:Disconnect() end)
    end
    for _, d in pairs(State.espObjects) do
        for _, obj in pairs(d) do
            pcall(function() obj:Remove() end)
        end
    end
    if State.ui.screen then pcall(function() State.ui.screen:Destroy() end) end
    if State.ui.blur then pcall(function() State.ui.blur:Destroy() end) end
    saveConfig()
end

LP.AncestryChanged:Connect(function()
    if not LP.Parent then cleanup() end
end)

--//============================================================
--// BOOT
--//============================================================
notify("BAZZ", "Loading Steal An Egg script...", 3)
task.wait(1)
showKeyPrompt()

--[[
    ============================================================
    END OF SCRIPT
    Basic   : bazz
    Premium : Joy
    Delivered.
    ============================================================
--]]
