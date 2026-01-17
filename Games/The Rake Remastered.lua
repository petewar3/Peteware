--// Loading Handler
if not game:IsLoaded() then
    game.Loaded:Wait()
    task.wait(1)
end

if getgenv().Peteware then
    return game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Already Executed.",
        Text = "If you want to execute the script again you need to destroy the original script via the settings tab.",
        Icon = "rbxassetid://108052242103510",
        Duration = 3.5
    })
else
    getgenv().Peteware = true
end

httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
queueteleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
setclip = setclipboard or (syn and syn.setclipboard) or (Clipboard and Clipboard.set)

--// Services & Setup
local players = game:GetService("Players")
local player = players.LocalPlayer
local workspace = game:GetService("Workspace")
local teleportService = game:GetService("TeleportService")
local httpService = game:GetService("HttpService") 
local uis = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local virtualUser = game:GetService("VirtualUser")

local playerGui = player:WaitForChild("PlayerGui")

--// Rayfield Initialisation
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()

--// Notify
local function Notify(content, duration)
    Rayfield:Notify({
        Title = "Peteware",
        Content = content or "Notify Content not specified!",
        Duration = typeof(duration) == "number" and duration or 3.5,
        Image = "bell-ring",
    })
end

--// Anti-AFK
player.Idled:Connect(function()
    virtualUser:CaptureController()
    virtualUser:ClickButton2(Vector2.new())
    wait(2)
end)

--// Device Detection
local deviceUser        
if not uis.MouseEnabled and not uis.KeyboardEnabled and uis.TouchEnabled then
    deviceUser = "Mobile"
elseif uis.MouseEnabled and uis.KeyboardEnabled and not uis.TouchEnabled then
    deviceUser = "PC"
else
    deviceUser = "Unknown"
end

--// Join Discord
local inviteCode = loadstring(game:HttpGet("https://raw.githubusercontent.com/Petewar3/Peteware/refs/heads/main/Other/discord.lua"))()
local inviteURL = 'https://discord.com/invite/' .. inviteCode

local function JoinDiscord()
    if setclip then
        setclip(inviteURL)
        Notify("Discord invite copied to clipboard.")
    else
        Notify("Missing setclipboard function.")
        task.delay(1, function()
            Notify("Discord Invite: " .. inviteURL)
        end)
    end

    if httprequest and deviceUser == "PC" then
        pcall(function()
            httprequest({
                Url = 'http://127.0.0.1:6463/rpc?v=1',
                Method = 'POST',
                Headers = {
                    ['Content-Type'] = 'application/json',
                    Origin = 'https://discord.com'
                },
                Body = httpService:JSONEncode({
                    cmd = 'INVITE_BROWSER',
                    nonce = httpService:GenerateGUID(false),
                    args = { code = inviteCode }
                })
            })
        end)
    end
end

--// Character Auto Setup
local char, humanoid, hrp

local function SetupCharacter()
    char = player.Character or player.CharacterAdded:Wait()
    humanoid = char:WaitForChild("Humanoid")
    hrp = char:WaitForChild("HumanoidRootPart")
end

if player.Character then
    SetupCharacter()
end

player.CharacterAdded:Connect(SetupCharacter)

--// In-Game Variables
local traps = workspace:WaitForChild("Debris"):WaitForChild("Traps")
local scraps = workspace:WaitForChild("Filter"):WaitForChild("ScrapSpawns")
local rake = workspace:FindFirstChild("Rake")
local flareGun = workspace:FindFirstChild("FlareGunPickUp") and workspace:FindFirstChild("FlareGunPickUp"):FindFirstChild("FlareGun")

--// Events
local events = {}

--// Combat

--// Character
local infStamina = false
local antiTrap = false

local function ToggleInfStamina(boolean, notify)
    if boolean then
        if notify then
            Notify("Infinite Stamina Enabled.", 2)
        end
        
        for _, tbl in ipairs(getgc(true)) do
            if typeof(tbl) == "table" then
                local max = rawget(tbl, "MAX_STAMINA")
                if typeof(max) == "number" then
                    rawset(tbl, "STAMINA_TAKE", 0)
                    rawset(tbl, "JUMP_STAMINA", 0)
                end
            end
        end
    else
        if notify then
            Notify("InfiniteStamina Disabled.", 1.5)
        end
        
        for _, tbl in ipairs(getgc(true)) do
            if typeof(tbl) == "table" then
                local max = rawget(tbl, "MAX_STAMINA")
                if typeof(max) == "number" then
                    rawset(tbl, "STAMINA_TAKE", 0)
                    rawset(tbl, "JUMP_STAMINA", 0)
                end
            end
        end
    end
end

local function ToggleAntiTrap(boolean, notify)
    if boolean then
        if notify then
            Notify("Anti-Trap Enabled. Traps can no longer affect you.")
        end
        
        for _, trap in ipairs(traps:GetChildren()) do
            if trap.Name == "RakeTrapModel" then
                local hitbox = trap:FindFirstChild("Hitbox")
                if hitbox then
                    hitbox.CanTouch = false
                end
            end
        end
        
        events.antiTrapsConn = traps.ChildAdded:Connect(function(child)
            if child.Name == "RakeTrapModel" then
                local hitbox = child:FindFirstChild("Hitbox")
                if hitbox then
                    hitbox.CanTouch = false
                end
            end
        end)
    else
        if notify then
            Notify("Anti-Trap Disabled.", 1.5)
        end
        
        for _, trap in ipairs(traps:GetChildren()) do
            if trap.Name == "RakeTrapModel" then
                local hitbox = trap:FindFirstChild("Hitbox")
                if hitbox then
                    hitbox.CanTouch = true
                end
            end
        end
        
        if typeof(events.antiTrapConn) == "RBXScriptConnection" then
            events.antiTrapConn:Disconnect()
            events.antiTrapConn = nil
        end
    end
end

events.onPlay = playerGui.ChildRemoved:Connect(function(child)
    if child.Name == "IntroGUI" then
        ToggleInfStamina(infStamina, false)
    end
end)

--// Visuals
local Sense = loadstring(game:HttpGet('https://raw.githubusercontent.com/petewar3/Peteware/refs/heads/main/Other/Sense.lua'))()

--// Visual Utility Functions
local function FetchData(instance, data)
    if typeof(instance) ~= "Instance" or not instance.Parent then
        return nil
    end
    
    if data == "Distance" then
        if instance:IsA("Model") then
            local cframe, _ = instance:GetBoundingBox()
            
            if cframe and hrp then
                return (hrp.Position - cframe.Position).Magnitude
            else
                return nil
            end
            
        elseif instance:IsA("BasePart") then
            if hrp then
                return(hrp.Position - instance.Position).Magnitude
            else
                return nil
            end
        else
            return nil
        end
    elseif data == "Health" then
        if instance.Name ~= "Rake" then
            return
        end
        
        local rakeHumanoid = instance:FindFirstChildWhichIsA("Humanoid")
        
        if rakeHumanoid then
            return tostring(rakeHumanoid.Health) .. "/" .. tostring(rakeHumanoid.MaxHealth)
        else
            return nil
        end
    elseif data == "Level" then
        if not instance.Name:find("Scrap") then
            return
        end
        
        local level = instance.Parent:FindFirstChild("LevelVal")
        
        if level then
            return level.Value
        else
            return nil
        end
    end
end

--// Sense Configuration
local rakeESP = false
local scrapESP = false
local flareGunESP = false

local ESPData = {}

local function CreateESP(instance, instanceType, instanceText, instanceTextColour, instanceTextColourOutline)
    for _, esp in ipairs(ESPData) do
        if esp.instance == instance then
            return
        end
    end
    
    local instanceEnabled = false
    if instanceType == "Rake" then
        instanceEnabled = rakeESP
    elseif instanceType == "Scrap" then
        instanceEnabled = scrapESP
    elseif instanceType == "Flare Gun" then
        instanceEnabled = flareGunESP
    end
    
    local data = {
        instanceClass = instanceType,
        enabled = instanceEnabled,
        text = instanceText,
        textColor = instanceTextColour,
        instanceOutline = true,
        instanceOutlineColor = instanceTextColourOutline,
        textSize = 17,
        textFont = 2,
        limitDistance = false
    }
    
    local ESPInstance = Sense.AddInstance(instance, data)
    ESPInstance.instanceClass = instanceType
    ESPInstance.instance = instance
    
    table.insert(ESPData, ESPInstance)
end

local function ModifyESP(className, key, value)
    for _, esp in ipairs(ESPData) do
        if esp.instanceClass == className then
            if esp.options[key] ~= nil then
                esp.options[key] = value
            end
        end
    end
end

if typeof(rake) == "Instance" and rake.Parent then
    local distance = FetchData(rake, "Distance")
    local health = FetchData(rake, "Health")
    CreateESP(rake, "Rake", "Rake\nDistance: " .. (distance and tostring(math.floor(distance)) .. "m" or "N/A") .. "\nHealth: " .. (health or "N/A"), { Color3.fromRGB(255, 0, 0), 1}, Color3.fromRGB(10, 10, 10))
end

if typeof(flareGun) == "Instance" and flareGun.Parent then
    local distance = FetchData(flareGun, "Distance")
    CreateESP(flareGun, "Flare Gun", "Flare Gun\nDistance: " .. (distance and tostring(math.floor(distance)) .. "m" or "N/A"), { Color3.fromRGB(0, 200, 255), 1 }, Color3.fromRGB(10, 10, 10))
end

local scrapIndex = 1
for _, scrapSpawn in ipairs(scraps:GetChildren()) do
    if #scrapSpawn:GetChildren() > 0 then
        for _, scrapModel in ipairs(scrapSpawn:GetChildren()) do
            local scrap = scrapModel:WaitForChild("Scrap")
            
            local distance = FetchData(scrap, "Distance")
            local level = FetchData(scrap, "Level")
            CreateESP(scrap, "Scrap", "Scrap\nDistance: " .. (distance and tostring(math.floor(distance)) .. "m" or "N/A") .. "\nLevel: " .. (level or "N/A"), { Color3.fromRGB(255, 225, 0), 1 }, Color3.fromRGB(15, 15, 15))
        end
    end
    
    events["scrapESPUpdate" .. scrapIndex] = scrapSpawn.ChildAdded:Connect(function(scrapModel)
        local scrap = scrapModel:WaitForChild("Scrap")

        local distance = FetchData(scrap, "Distance")
        local level = FetchData(scrap, "Level")
        CreateESP(scrap, "Scrap", "Scrap\nDistance: " .. (distance and tostring(math.floor(distance)) .. "m" or "N/A") .. "\nLevel: " .. (level or "N/A"), { Color3.fromRGB(255, 225, 0), 1 }, Color3.fromRGB(15, 15, 15))
    end)
    
    scrapIndex = scrapIndex + 1
end

events.rakeSetup = workspace.ChildAdded:Connect(function(child)
    if child.Name == "Rake" then
        rake = child
        local distance = FetchData(rake, "Distance")
        local health = FetchData(rake, "Health")
        CreateESP(rake, "Rake", "Rake\nDistance: " .. (distance and tostring(math.floor(distance)) .. "m" or "N/A") .. "\nHealth: " .. (health or "N/A"), { Color3.fromRGB(255, 0, 0), 1}, Color3.fromRGB(10, 10, 10))
    end
end)

events.flareGunESPUpdate = workspace.ChildAdded:Connect(function(child)
    if child.Name == "FlareGunPickUp" then
        flareGun = child:WaitForChild("FlareGun")
        local distance = FetchData(flareGun, "Distance")
        CreateESP(flareGun, "Flare Gun", "Flare Gun\nDistance: " .. (distance and tostring(math.floor(distance)) .. "m" or "N/A"), { Color3.fromRGB(0, 200, 255), 1 }, Color3.fromRGB(10, 10, 10))
    end
end)

events.updateESP = runService.Heartbeat:Connect(function()
    for _, esp in ipairs(ESPData) do
        if esp.instance then
            local distance = FetchData(esp.instance, "Distance")
            local text = esp.instanceClass .. "\nDistance: " .. (distance and tostring(math.floor(distance)) .. "m" or "N/A")

            if esp.instanceClass == "Rake" then
                local health = FetchData(esp.instance, "Health")
                text = text .. "\nHealth: " .. (health or "N/A")
            elseif esp.instanceClass == "Scrap" then
                local level = FetchData(esp.instance, "Level")
                text = text .. "\nLevel: " .. (level or "N/A")
            end

            esp.options.text = text
        end
    end
end)

--// ESP Load
task.wait(1)
Sense.Load()

--// UI locals
local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local keepPeteware = true
local teleportConnection = false
local confirmDestroy = false

--// Main UI
local Window = Rayfield:CreateWindow({
   Name = gameName .. " Peteware v1.0.0",
   Icon = 0, 
   LoadingTitle = gameName .. " | Peteware",
   LoadingSubtitle = "Developed by Peteware",
   Theme = {
       TextColor = Color3.fromRGB(235, 235, 235),
       
       Background = Color3.fromRGB(18, 18, 18),
       Topbar = Color3.fromRGB(28, 28, 30),
       Shadow = Color3.fromRGB(10, 10, 10),
       
       NotificationBackground = Color3.fromRGB(24, 24, 24),
       NotificationActionsBackground = Color3.fromRGB(50, 50, 50),
       
       TabBackground = Color3.fromRGB(45, 45, 45),
       TabStroke = Color3.fromRGB(60, 60, 60),
       TabBackgroundSelected = Color3.fromRGB(255, 140, 0),
       TabTextColor = Color3.fromRGB(200, 200, 200),
       SelectedTabTextColor = Color3.fromRGB(15, 15, 15),
       
       ElementBackground = Color3.fromRGB(28, 28, 28),
       ElementBackgroundHover = Color3.fromRGB(38, 38, 38),
       SecondaryElementBackground = Color3.fromRGB(20, 20, 20),
       ElementStroke = Color3.fromRGB(55, 55, 55),
       SecondaryElementStroke = Color3.fromRGB(45, 45, 45),
       
       SliderBackground = Color3.fromRGB(255, 120, 0),
       SliderProgress = Color3.fromRGB(255, 140, 0),
       SliderStroke = Color3.fromRGB(255, 160, 40),
       
       ToggleBackground = Color3.fromRGB(22, 22, 22),
       ToggleEnabled = Color3.fromRGB(255, 140, 0),
       ToggleDisabled = Color3.fromRGB(90, 90, 90),
       ToggleEnabledStroke = Color3.fromRGB(255, 160, 40),
       ToggleDisabledStroke = Color3.fromRGB(110, 110, 110),
       ToggleEnabledOuterStroke = Color3.fromRGB(100, 60, 0),
       ToggleDisabledOuterStroke = Color3.fromRGB(50, 50, 50),
       
       DropdownSelected = Color3.fromRGB(36, 36, 36),
       DropdownUnselected = Color3.fromRGB(26, 26, 26),
       
       InputBackground = Color3.fromRGB(30, 30, 30),
       InputStroke = Color3.fromRGB(60, 60, 60),
       PlaceholderColor = Color3.fromRGB(170, 130, 100)
   },

   DisableRayfieldPrompts = true,
   DisableBuildWarnings = true, 

   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil, 
      FileName = nil
   },

   Discord = {
      Enabled = true, 
      Invite = "4UjSNcPCdh", 
      RememberJoins = true 
   },

   KeySystem = false, 
   KeySettings = {
      Title = "Peteware Key System",
      Subtitle = "Complete the key system for access",
      Note = "Discord copied to clipboard, ", 
      FileName = "PetewareKey", 
      SaveKey = false, 
      GrabKeyFromSite = false, 
      Key = {"PetewareOnTop"}
   }
})

if deviceUser == "PC" then
    Notify("When you destroy the UI destroy it via the settings tab.", 10)
else
    Notify("When you destroy the UI destroy it via the settings tab.", 3)
end

local Tab = Window:CreateTab("Home", "layout-dashboard")

local Section = Tab:CreateSection("Welcome!")

--[[
[/] feature
[+] feature
[-] feature
]]

local Paragraph = Tab:CreateParagraph({Title = "What's new and improved", Content = [[
    [+] The Rake Remastered Release!
    [+] Rake ESP
    [+] Infinite Stamina
    
    Please consider joining the server and suggesting more features.
    Please report any bugs to our discord server by creating a ticket.]]})

local discordButton = Tab:CreateButton({
   Name = "Join Discord",
   Callback = function()
       JoinDiscord()
   end,
})

local Tab = Window:CreateTab("Main", "gem")

local Section = Tab:CreateSection("Visuals")

local RakeESPToggle = Tab:CreateToggle({
   Name = "Rake ESP",
   CurrentValue = false,
   Flag = "RakeESPToggle", 
   Callback = function(Value)
       rakeESP = Value
       ModifyESP("Rake", "enabled", rakeESP)
       if rakeESP then
           Notify("Rake ESP Enabled.", 2)
       else
           Notify("Rake ESP Disabled.", 1.5)
       end
   end,
})

local ScrapESPToggle = Tab:CreateToggle({
   Name = "Scrap ESP",
   CurrentValue = false,
   Flag = "ScrapESPToggle", 
   Callback = function(Value)
       scrapESP = Value
       ModifyESP("Scrap", "enabled", scrapESP)
       if scrapESP then
           Notify("Scrap ESP Enabled.", 2)
       else
           Notify("Scrap ESP Disabled.", 1.5)
       end
   end,
})

local FlareGunESPToggle = Tab:CreateToggle({
   Name = "Flare Gun ESP",
   CurrentValue = false,
   Flag = "FlareGunESPToggle", 
   Callback = function(Value)
       flareGunESP = Value
       ModifyESP("Flare Gun", "enabled", flareGunESP)
       if flareGunESP then
           Notify("Flare Gun ESP Enabled.", 2)
       else
           Notify("Flare Gun ESP Disabled.", 1.5)
       end
   end,
})

local Tab = Window:CreateTab("Teleports", "user")

local Tab = Window:CreateTab("Misc", "circle-ellipsis")

local Section = Tab:CreateSection("Character")

local InfStaminaToggle = Tab:CreateToggle({
   Name = "Infinite Stamina",
   CurrentValue = false,
   Flag = "InfStaminaToggle", 
   Callback = function(Value)
        infStamina = Value
        if not getgc then
            return Notify("Incompatible exploit (missing getgc)")
        end
        
        ToggleInfStamina(infStamina, true)
   end,
})

local AntiTrapToggle = Tab:CreateToggle({
   Name = "Anti-Trap",
   CurrentValue = false,
   Flag = "AntiTrapToggle", 
   Callback = function(Value)
        antiTrap = Value
        ToggleAntiTrap(antiTrap, true)
   end,
})

local Divider = Tab:CreateDivider()

local Section = Tab:CreateSection("Other Scripts")

local FPSBoosterButton = Tab:CreateButton({
    Name = "FPS Booster",
    Callback = function()
        -- Made by RIP#6666
        getgenv().FPS_Booster.Settings = {
            Players = {
                ["Ignore Me"] = true, -- Ignore your Character
                ["Ignore Others"] = true -- Ignore other Characters
                },
            Meshes = {
                Destroy = false, -- Destroy Meshes
                LowDetail = true -- Low detail meshes (NOT SURE IT DOES ANYTHING)
                },
            Images = {
                Invisible = true, -- Invisible Images
                LowDetail = false, -- Low detail images (NOT SURE IT DOES ANYTHING)
                Destroy = false, -- Destroy Images
                },
            ["No Particles"] = true, -- Disables all ParticleEmitter, Trail, Smoke, Fire and Sparkles
            ["No Camera Effects"] = true, -- Disables all PostEffect's (Camera/Lighting Effects)
            ["No Explosions"] = true, -- Makes Explosion's invisible
            ["No Clothes"] = true, -- Removes Clothing from the game
            ["Low Water Graphics"] = true, -- Removes Water Quality
            ["No Shadows"] = true, -- Remove Shadows
            ["Low Rendering"] = true, -- Lower Rendering
            ["Low Quality Parts"] = true -- Lower quality parts
            }
        loadstring(game:HttpGet("https://raw.githubusercontent.com/petewar3/Developer-Toolbox/refs/heads/main/FPS-Booster-Backup.lua"))()
    end,
})

local InfYieldAdminButton = Tab:CreateButton({
   Name = "Infinite Yield Admin",
   Callback = function()
       loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
   end,
})

local Tab = Window:CreateTab("Background Tasks", "clipboard-list")

local Paragraph = Tab:CreateParagraph({Title = "Background Tasks", Content = [[
    Anti-AFK]]})

local Tab = Window:CreateTab("Settings", "settings")

local RejoinButton = Tab:CreateButton({
   Name = "Rejoin",
   Callback = function()
       Notify("Attemping to Rejoin Server.")
       task.wait(1)
       teleportService:TeleportToPlaceInstance(game.placeId, game.jobId)
   end,
})

local KeepPetewareToggle = Tab:CreateToggle({
    Name = "Keep Peteware On Server Hop/Rejoin",
    CurrentValue = false,
    Flag = "KeepPetewareToggle",
    Callback = function(Value)
        if Value then
            Notify("Whenever you teleport, the script will automatically execute aswel.")

            keepPeteware = true
            teleportCheck = false

            events.onTeleport = player.OnTeleport:Connect(function(State)
                if keepPeteware and not teleportCheck and queueteleport then
                    teleportCheck = true
                    queueteleport([[
                    if not game:IsLoaded() then
                        game.Loaded:Wait()
                        task.wait(1)
                    end
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/petewar3/Peteware/refs/heads/main/Games/The%20Rake%20Remastered.lua"))()
                    ]])
                end
            end)
        else
            if typeof(events.onTeleport) == "RBXScriptConnection" then
                events.onTeleport:Disconnect()
                events.onTeleport = nil
            end
            
            Notify("The script wont automatically execute on serverhop or rejoin.")
            keepPeteware = false
            teleportCheck = false
        end
    end,
})

KeepPetewareToggle:Set(true)

--// Initialise DisconnectScripts function
local function DisconnectScripts() end

local DestroyUIButton = Tab:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        if not confirmDestroy then
            confirmDestroy = true
            Rayfield:Notify({
                Title = "Confirm UI Destruction",
                Content = "Click 'Destroy UI' again to confirm.",
                Duration = 3,
                Image = "bell-ring",
            })
            task.delay(3.5, function()
                confirmDestroy = false
            end)
        else
            DisconnectScripts()
            
            task.delay(0.2, function()
                pcall(function()
                    Rayfield:Destroy()
                end)
            end)
        end
    end,
})

--// Disconnect Script Features
function DisconnectScripts()
    getgenv().Peteware = nil
    keepPeteware = false
    
    for key, event in pairs(events) do
        if typeof(event) == "RBXScriptConnection" then
            event:Disconnect()
        end
        events[key] = nil
    end
    
    Sense.Unload()
    ToggleInfStamina(false, false)
    ToggleAntiTrap(false, false)
end

--[[
// Credits
Infinite Yield: Server Hop and Anti-AFK
Infinite Yield Discord Server: https://discord.gg/78ZuWSq
RIP#6666: FPS Booster
RIP#6666 Discord Server: https://discord.gg/rips
]]
