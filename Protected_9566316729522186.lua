-- Load libraries and services
local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/skeptica4/Fluentvv/refs/heads/main/fluent.lua "))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua "))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua "))()

local Players, UserInputService, RunService = game:GetService("Players"), game:GetService("UserInputService"), game:GetService("RunService")
local LocalPlayer, camera = Players.LocalPlayer, workspace.CurrentCamera

-- Configuration
local config = getgenv().config or {
    teleportScriptEnabled = false, destroyLandmines = false, mercyKillEnabled = false,
    mercyKillMouseEnabled = false, bolterCoinHit = false, teleportHandlingEnabled = false,
    fastReloadEnabled = false, autoReloadEnabled = false, smartReloadEnabled = false
}
getgenv().config = config

-- Constants
local EXCLUDED_NPCS = {
    Landmine = true, Man = true, Turret = true, Stonehedge = true, Sprayer = true, 
    Sentinel = true, Refugee = true, PDC = true, MADS = true, Lifeline = true, 
    Hallucinator = true, Governor = true, FAST_point = true, Barrier = true, 
    Platform = true, Administrator = true
}

-- Generate dead guy entries
for i = 1, 11 do
    if i ~= 8 then EXCLUDED_NPCS["dead guy " .. i] = true end
end

local ALLOWED_GUNS = {"Akimbo", "Voltaic Impact", "Gunslingers", "Burst Rifle", "Stonewall",
    "Steelforge", "DMR", "Gift of Fire", "Armour Peeler", "Medical Bow", "Recurve", 
    "Vitabow", "Rifle", "Bolter", "Harpoon Gun", "RPG", "Rocket Stormer", "Shockwave Device", 
    "Shotgun", "Hallsweeper", "Sprinter's Streak", "SMG", "Loose Trigger", "Twinface", 
    "Mastermind's Rifle", "Shovel", "Overcharger", "Rallying Cry", "Machete", "Handaxes", "Torqueblade"}

-- Variables
local showAutoDetectNotif, firerateValue, bulletSpeedValue, spreadValue = true, 500, 9999, 0
local lastWpn, reloadCooldown = nil, 0

-- Utility Functions
local notify = function(title, content, duration)
    Fluent:Notify({Title = title, Content = content, Duration = duration or 5})
end

local getHRP = function()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local getMousePos = function()
    local mouseLocation = UserInputService:GetMouseLocation()
    local result = workspace:Raycast(camera.CFrame.Position, 
        camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y).Direction * 1000)
    return result and result.Position
end

local getWpn = function()
    local char = LocalPlayer.Character
    if not char then return end
    for _, item in pairs(char:GetChildren()) do
        if item:IsA("Tool") and table.find(ALLOWED_GUNS, item.Name) then return item.Name end
    end
end

-- Gun Functions
local getCurrentAmmo = function(tool)
    for _, obj in pairs({tool, unpack(tool:GetDescendants())}) do
        for name, value in pairs(obj:GetAttributes()) do
            if name:lower():find("ammo") and typeof(value) == "number" then
                return value, obj, name
            end
        end
    end
end

local getMaxAmmo = function(obj, attrName)
    local attrs = obj:GetAttributes()
    return attrs["Max" .. attrName] or attrs[attrName .. "Max"] or attrs["MaxAmmo"] or 30
end

local fastReload = function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or tick() - reloadCooldown < 0.1 then return end
    reloadCooldown = tick()
    
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or not table.find(ALLOWED_GUNS, tool.Name) then return end
    
    -- Fill ammo via attributes
    for _, obj in pairs({tool, unpack(tool:GetDescendants())}) do
        for name, value in pairs(obj:GetAttributes()) do
            if name:lower():find("ammo") and typeof(value) == "number" then
                obj:SetAttribute(name, getMaxAmmo(obj, name))
            end
        end
    end
    
    -- Stop reload animations
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            if track.Name:lower():find("reload") then
                track:Stop()
                track.TimePosition = track.Length
            end
        end
    end
    
    if config.fastReloadEnabled then notify("Fast Reload", "Weapon reloaded", 1) end
end

local smartReload = function()
    local char = LocalPlayer.Character
    if not char then return end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or not table.find(ALLOWED_GUNS, tool.Name) then return end
    
    local currentAmmo, obj, attrName = getCurrentAmmo(tool)
    if currentAmmo and currentAmmo <= math.floor(getMaxAmmo(obj, attrName) * 0.3) then
        fastReload()
    end
end

local modifyGun = function(mode)
    local char = LocalPlayer.Character
    if not lastWpn or not char or not char:FindFirstChild(lastWpn) then
        notify("Error", "No weapon detected", 3)
        return
    end
    
    local gun = char[lastWpn]
    local stats = {
        infinite = {firerate = firerateValue, ammo = 999, reload = 0.1},
        fast_reload = {firerate = math.min(firerateValue, 150), reload = 0.1},
        balanced = {firerate = math.min(firerateValue, 100), reload = 0.5},
        custom = {firerate = firerateValue}
    }
    
    local setting = stats[mode] or stats.custom
    
    gun:SetAttribute("Firerate", setting.firerate)
    gun:SetAttribute("BulletSpeed", bulletSpeedValue)
    gun:SetAttribute("Spread", spreadValue)
    
    if setting.ammo then
        gun:GetAttributeChangedSignal("Ammo"):Connect(function() gun:SetAttribute("Ammo", setting.ammo) end)
        gun:SetAttribute("Ammo", setting.ammo)
    end
    
    if setting.reload then gun:SetAttribute("ReloadTime", setting.reload) end
    
    if mode == "fast_reload" or mode == "balanced" then
        config.fastReloadEnabled = true
        if mode == "balanced" then config.smartReloadEnabled = true end
    end
    
    notify("Gun Modified", "Modified " .. lastWpn .. " (" .. mode .. ")", 3)
end

-- Core Functions
local teleportNPCs = function()
    local hrp = getHRP()
    if not hrp then return end
    
    local playerPos, playerForward = hrp.Position, hrp.CFrame.LookVector
    
    for _, npc in ipairs(workspace:GetChildren()) do
        if npc:IsA("Model") and not EXCLUDED_NPCS[npc.Name] and not Players:GetPlayerFromCharacter(npc) then
            local humanoid = npc:FindFirstChildOfClass("Humanoid")
            local primaryPart = npc.PrimaryPart or npc:FindFirstChild("HumanoidRootPart")
            
            if humanoid and primaryPart and humanoid.Health > 0 then
                local distance = npc.Name == "Tank" and 13 or 5.7
                npc:SetPrimaryPartCFrame(CFrame.new(playerPos + playerForward * distance) * CFrame.Angles(0, hrp.Orientation.Y, 0))
            end
        end
    end
end

local destroyLandmines = function()
    local landmine = workspace:FindFirstChild("Landmine")
    if landmine then
        landmine:Destroy()
        notify("System", "Landmine removed", 4)
    end
end

-- Event Handlers
local setupMercyKillMouse = function()
    local isSemicolonDown, throttle = false, 0
    
    local function onInputBegan(input)
        if input.KeyCode == Enum.KeyCode.Semicolon then isSemicolonDown = true end
    end
    
    local function onInputEnded(input)
        if input.KeyCode == Enum.KeyCode.Semicolon then isSemicolonDown = false end
    end
    
    UserInputService.InputBegan:Connect(onInputBegan)
    UserInputService.InputEnded:Connect(onInputEnded)
    
    RunService.Heartbeat:Connect(function(deltaTime)
        if not config.mercyKillMouseEnabled or not isSemicolonDown then return end
        
        throttle = throttle + deltaTime
        if throttle < 0.1 then return end
        throttle = 0
        
        local position = getMousePos()
        local mercyKill = LocalPlayer.Backpack:FindFirstChild("Mercy Kill") or 
                         (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Mercy Kill"))
        
        if position and mercyKill then mercyKill.VerifyHit:FireServer(nil, position) end
    end)
end

local setupBolterCoinHit = function()
    local isQDown = false
    
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Q then isQDown = true end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Q then isQDown = false end
    end)
    
    RunService.Heartbeat:Connect(function()
        if not config.bolterCoinHit or not isQDown then return end
        
        local position = getMousePos()
        local luxsncc = workspace:FindFirstChild("luxsncc")
        local bolter = luxsncc and luxsncc:FindFirstChild("Bolter")
        
        if position and bolter and bolter:FindFirstChild("VerifyCoinHit") then
            bolter.VerifyCoinHit:FireServer(position)
        end
    end)
end

local initWeaponDetection = function()
    getgenv().AutoDetectWeapon_Fluent = true
    task.spawn(function()
        while getgenv().AutoDetectWeapon_Fluent do
            local newWpn = getWpn()
            if newWpn ~= lastWpn then
                lastWpn = newWpn
                if showAutoDetectNotif then
                    notify("Weapon Detected", "Current: " .. (lastWpn or "None"), 2)
                end
            end
            task.wait(1)
        end
    end)
end

local startMainLoop = function()
    local teleportThrottle, landmineThrottle = 0, 0
    
    RunService.Heartbeat:Connect(function(deltaTime)
        if config.teleportScriptEnabled and config.teleportHandlingEnabled then
            teleportThrottle = teleportThrottle + deltaTime
            if teleportThrottle >= 0.1 then
                teleportThrottle = 0
                teleportNPCs()
            end
        end
        
        if config.destroyLandmines then
            landmineThrottle = landmineThrottle + deltaTime
            if landmineThrottle >= 0.5 then
                landmineThrottle = 0
                destroyLandmines()
            end
        end
        
        if config.autoReloadEnabled then smartReload() end
    end)
end

-- Input Handler
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F1 then
        config.teleportHandlingEnabled = not config.teleportHandlingEnabled
        notify("System", "Teleport handling " .. (config.teleportHandlingEnabled and "enabled" or "disabled"), 3)
        
    elseif input.KeyCode == Enum.KeyCode.R and config.fastReloadEnabled then
        fastReload()
        
    elseif input.KeyCode == Enum.KeyCode.Semicolon and config.mercyKillEnabled and not config.mercyKillMouseEnabled then
        local hrp = getHRP()
        local mercyKill = LocalPlayer.Backpack:FindFirstChild("Mercy Kill")
        if hrp and mercyKill then
            for i = 1, 3 do
                mercyKill.VerifyHit:FireServer(nil, hrp.Position)
                task.wait(0.17)
            end
        end
    end
end)

-- UI Setup
local Window = Fluent:CreateWindow({
    Title = "Fluent " .. Fluent.Version, SubTitle = "by dawid", TabWidth = 160,
    Size = UDim2.fromOffset(580, 460), Acrylic = false, Theme = "Aqua", MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "code-2" }),
    GunMod = Window:AddTab({ Title = "Gun Mod", Icon = "target" }),
    Misc = Window:AddTab({ Title = "Miscellaneous", Icon = "plus-circle" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- Configure SaveManager
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- UI Helper Functions
local addToggle = function(tab, name, title, default, callback)
    return tab:AddToggle(name, {Title = title, Default = default or false}):OnChanged(callback)
end

local addButton = function(tab, title, desc, callback)
    tab:AddButton({Title = title, Description = desc, Callback = callback})
end

-- Main Tab UI
addToggle(Tabs.Main, "TeleportNPCsToggle", "Teleport NPCs", false, 
    function(val) config.teleportScriptEnabled = val end)

addToggle(Tabs.Main, "MercyKillToggle", "Enable Mercy Kill", false, function(val)
    config.mercyKillEnabled = val
    if val and config.mercyKillMouseEnabled then
        config.mercyKillMouseEnabled = false
        Tabs.Main:SetValue("MouseMercyKillToggle", false)
    end
end)

addToggle(Tabs.Main, "MouseMercyKillToggle", "Enable Mouse Mercy Kill", false, function(val)
    config.mercyKillMouseEnabled = val
    if val then
        if config.mercyKillEnabled then
            config.mercyKillEnabled = false
            Tabs.Main:SetValue("MercyKillToggle", false)
        end
        notify("Mercy Kill Mouse", "Hold semicolon to fire at mouse", 4)
    end
end)

-- Gun Mod Tab UI
Tabs.GunMod:AddSection("Weapon Detection")
addToggle(Tabs.GunMod, "AutoDetectNotifToggle", "Show Auto-Detect Notifications", true,
    function(val) showAutoDetectNotif = val end)

Tabs.GunMod:AddSection("Weapon Configuration")

local inputs = {
    {name = "FirerateInput", title = "Firerate", default = firerateValue, var = "firerateValue"},
    {name = "BulletSpeedInput", title = "Bullet Speed", default = bulletSpeedValue, var = "bulletSpeedValue"},
    {name = "SpreadInput", title = "Spread", default = spreadValue, var = "spreadValue"}
}

for _, input in pairs(inputs) do
    Tabs.GunMod:AddInput(input.name, {
        Title = input.title, Default = tostring(input.default), Numeric = true, Placeholder = "Enter " .. input.title
    }):OnChanged(function(val)
        local num = tonumber(val)
        if num then
            if input.var == "firerateValue" then firerateValue = num
            elseif input.var == "bulletSpeedValue" then bulletSpeedValue = num
            elseif input.var == "spreadValue" then spreadValue = num end
        end
    end)
end

Tabs.GunMod:AddSection("Reload System")
addToggle(Tabs.GunMod, "FastReloadToggle", "Enable Fast Reload (Press R)", false, function(val) 
    config.fastReloadEnabled = val
    if val then notify("Fast Reload", "Press R to reload", 3) end
end)

addToggle(Tabs.GunMod, "AutoReloadToggle", "Enable Smart Auto-Reload", false, function(val) 
    config.autoReloadEnabled = val
    if val then notify("Auto Reload", "Auto-reload when low", 3) end
end)

Tabs.GunMod:AddSection("Gun Modification")

local gunMods = {
    {"Infinite Ammo Mode", "Full infinite ammo + high firerate (SUSPICIOUS)", "infinite"},
    {"Fast Reload Mode", "Balanced stats + fast reload (RECOMMENDED)", "fast_reload"},
    {"Balanced Mode", "Conservative stats + smart features", "balanced"},
    {"Custom Stats Only", "Apply custom stats without ammo changes", "custom"}
}

for _, mod in pairs(gunMods) do
    addButton(Tabs.GunMod, mod[1], mod[2], function() modifyGun(mod[3]) end)
end

addButton(Tabs.GunMod, "InfAmmo Only", "Only enable infinite ammo", function()
    local char = LocalPlayer.Character
    if not lastWpn or not char or not char:FindFirstChild(lastWpn) then
        notify("Error", "No weapon found", 3)
        return
    end
    
    local gun = char[lastWpn]
    gun:GetAttributeChangedSignal("Ammo"):Connect(function() gun:SetAttribute("Ammo", 999) end)
    gun:SetAttribute("Ammo", 999)
    notify("InfAmmo Enabled", "Infinite Ammo for " .. lastWpn, 3)
end)

-- Misc Tab UI
addToggle(Tabs.Misc, "LandmineToggle", "Destroy Landmine", false, function(val) config.destroyLandmines = val end)
addToggle(Tabs.Misc, "BolterCoinToggle", "Bolter Coin Hit", false, function(val) config.bolterCoinHit = val end)

Tabs.Misc:AddSection("Teleportation")

local teleports = {
    {"Teleport to Lobby", "Teleports to lobby ingame", function()
        local hrp = getHRP()
        if hrp then
            hrp.CFrame = CFrame.new(-3, -101.5, -12.5)
            notify("System", "Teleported to lobby", 4)
        end
    end},
    {"Teleport to Map", "Teleports player to map", function()
        local char = LocalPlayer.Character
        if char then
            local hrp = char:WaitForChild("HumanoidRootPart")
            hrp.CFrame = workspace.Map.PlayerSpawns.SpawnLocation.CFrame + Vector3.new(0, 3, 0)
            notify("System", "Teleported to map", 4)
        end
    end}
}

for _, tp in pairs(teleports) do
    addButton(Tabs.Misc, tp[1], tp[2], tp[3])
end

Tabs.Misc:AddSection("Utility")
addButton(Tabs.Misc, "Dev Tools", "Developer tools and utilities", function()
    Window:Dialog({
        Title = "Developer Tools",
        Buttons = {
            {Title = "Dark Dex", Callback = function() 
                loadstring(game:HttpGet("https://raw.githubusercontent.com/skeptica4/aaaaaaaaaaaaaa/main/darkdex "))() 
            end},
            {Title = "Remote Spy", Callback = function() 
                loadstring(game:HttpGet("https://github.com/exxtremestuffs/SimpleSpySource/raw/master/SimpleSpy.lua "))() 
            end},
            {Title = "Close", Callback = function() end}
        }
    })
end)

-- Initialize
notify("Fluent", "Script loaded with Fast Reload system", 5)
Window:SelectTab(1)
startMainLoop()
setupBolterCoinHit()
setupMercyKillMouse()
initWeaponDetection()
SaveManager:LoadAutoloadConfig()
