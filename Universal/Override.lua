--[[
    Override Script

    Description:
    Override is a universal Roblox script designed primarily for FPS games.
    It provides functionality for controller support specifcally and gameplay enhancements.
    
]]

--// Loading Handler
if not game:IsLoaded() then
    game.Loaded:Wait()
    task.wait(1)
end

if getgenv().Override then
    return game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Already Executed.",
        Text = "If you want to execute the script again you need to destroy the original script via the settings tab.",
        Icon = "rbxassetid://108052242103510",
        Duration = 3.5
    })
else
    getgenv().Override = true
end

httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
queueteleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
setclip = setclipboard or (syn and syn.setclipboard) or (Clipboard and Clipboard.set)
gethui = gethui or function()
    return game:GetService("CoreGui")
end

--// Services & Setup
local players = game:GetService("Players")
local player = players.LocalPlayer
local teleportService = game:GetService("TeleportService")
local httpService = game:GetService("HttpService") 
local replicatedStorage = game:GetService("ReplicatedStorage")
local starterGui = game:GetService("StarterGui")
local runService = game:GetService("RunService")
local virtualUser = game:GetService("VirtualUser")

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

    if httprequest then
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
local char, humanoid, hrp, camera

local function SetupCharacter()
    char = player.Character or player.CharacterAdded:Wait()
    humanoid = char:WaitForChild("Humanoid")
    hrp = char:WaitForChild("HumanoidRootPart")
end

SetupCharacter()
player.CharacterAdded:Connect(SetupCharacter)

camera = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    camera = workspace.CurrentCamera
end)

--// Exploits
local desynced = false

--// Combat
local aimbotSmoothness = 0.15
local aimbotFOV = 90
local deadCheck
local wallCheck
local friendCheck
local teamCheck

local characterParts = {
    Core = {
        "HumanoidRootPart",
        "Head",
    },

    R15 = {
        Torso = {
            "UpperTorso",
            "LowerTorso",
        },

        LeftArm = {
            "LeftUpperArm",
            "LeftLowerArm",
            "LeftHand",
        },

        RightArm = {
            "RightUpperArm",
            "RightLowerArm",
            "RightHand",
        },

        LeftLeg = {
            "LeftUpperLeg",
            "LeftLowerLeg",
            "LeftFoot",
        },

        RightLeg = {
            "RightUpperLeg",
            "RightLowerLeg",
            "RightFoot",
        },
    },

    R6 = {
        Torso = {
            "Torso",
        },

        LeftArm = {
            "Left Arm",
        },

        RightArm = {
            "Right Arm",
        },

        LeftLeg = {
            "Left Leg",
        },

        RightLeg = {
            "Right Leg",
        },
    },
}

local aimPartOptions = {}
local selectedAimParts = {"HumanoidRootPart"}

for _, part in ipairs(characterParts.Core) do
    table.insert(aimPartOptions, part)
end

for name, _ in pairs(characterParts.R15) do
    table.insert(aimPartOptions, name)
end

local lastTargetPartRequest = {}

local function FetchTargetPart(character, possibleTargets)
    if not lastTargetPartRequest[character.Name] then
        lastTargetPartRequest[character.Name] = {
            CurrentPart = nil,
            Expiry = 0
        }
    end
    
    local tracker = lastTargetPartRequest[character.Name]

    if tick() < tracker.Expiry and tracker.CurrentPart and tracker.CurrentPart.Parent then
        return tracker.CurrentPart
    end
    
    local targetParts = {}
    
    if not character then 
        return targetParts
    end

    local isR15 = character:FindFirstChild("UpperTorso") ~= nil
    local rigTable = isR15 and characterParts.R15 or characterParts.R6

    for _, selected in ipairs(selectedAimParts) do
        local corePart = character:FindFirstChild(selected)
        if corePart then
            if wallCheck and possibleTargets and possibleTargets[character] and table.find(possibleTargets[character], corePart) then
                table.insert(targetParts, corePart)
            elseif not wallCheck then
                table.insert(targetParts, corePart)
            end
        end

        local mappedParts = rigTable[selected]
        if mappedParts then
            for _, partName in ipairs(mappedParts) do
                local part = character:FindFirstChild(partName)
                if part then
                    table.insert(targetParts, part)
                end
            end
        end
    end
    
    if #targetParts == 0 then
        tracker.CurrentPart = nil
        tracker.Expiry = 0
        return nil
    end
    
    local targetPart = targetParts[math.random(1, #targetParts)]
    tracker.CurrentPart = targetPart
    
    tracker.Expiry = tick() + math.random(10, 15) / 10
    
    return targetPart
end

local function FetchPossibleTargets()
    local availablePlayers = {}
    local currentCharacters = {}
    local possibleTargets = {}
    
    for _, plr in ipairs(players:GetPlayers()) do
        local plr_char = plr.Character
        
        if not plr_char then
            continue
        end
        
        table.insert(currentCharacters, plr_char)
    end
    
    local cameraPos = camera.CFrame.Position
    
    for _, plr in ipairs(players:GetPlayers()) do
        if plr == player then
            continue
        end
        
        if friendCheck and player:IsFriendsWith(plr.UserId) then
            continue
        end
        
        if teamCheck and plr.Team and plr.Team == player.Team then
            continue
        end
            
        local plr_char = plr.Character
        if not plr_char then
            continue
        end
            
        local plr_humanoid = plr_char:WaitForChild("Humanoid")
        if deadCheck and plr_humanoid.Health <= 0 then
            continue
        end
            
        if wallCheck then
            local partsToCheck = {}

            for _, partName in ipairs(characterParts.Core) do
                local part = plr_char:FindFirstChild(partName)
                if part then
                    table.insert(partsToCheck, part)
                end
            end

            local isR15 = plr_char:FindFirstChild("UpperTorso") ~= nil
            local rigTable = isR15 and characterParts.R15 or characterParts.R6
            for _, names in pairs(rigTable) do
                for _, name in ipairs(names) do
                    local part = plr_char:FindFirstChild(name)
                    if part then
                        table.insert(partsToCheck, part)
                    end
                end
            end

            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.IgnoreWater = true
            params.FilterDescendantsInstances = currentCharacters

            local visibleParts = {}
            for _, part in ipairs(partsToCheck) do
                local result = workspace:Raycast(cameraPos, part.Position - cameraPos, params)
                if not result then
                    table.insert(visibleParts, part)
                end
            end

            if #visibleParts > 0 then
                table.insert(availablePlayers, plr)
                possibleTargets[plr_char] = visibleParts
            end
        else
            table.insert(availablePlayers, plr)
        end
    end
    
    return availablePlayers, possibleTargets
end

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Thickness = 2
FOVCircle.NumSides = 64
FOVCircle.Filled = false
FOVCircle.Transparency = 0.6
FOVCircle.Color = Color3.fromRGB(235, 235, 235)

local function UpdateFOVCircle()
    local viewport = camera.ViewportSize
    FOVCircle.Position = Vector2.new(viewport.X / 2, viewport.Y / 2)
    FOVCircle.Radius = aimbotFOV
end

local function FetchClosestTarget()
    local closestCharacter = nil
    local shortestDistance = math.huge

    local viewport = camera.ViewportSize
    local screenCenter = Vector2.new(viewport.X / 2, viewport.Y / 2)
    local fovRadius = aimbotFOV
    
    local possibleCharacters, possibleTargets = FetchPossibleTargets()

    for _, plr in ipairs(possibleCharacters) do
        local char = plr.Character
        if not char then continue end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
        if dist > fovRadius then continue end

        if dist < shortestDistance then
            shortestDistance = dist
            closestCharacter = char
        end
    end

    return closestCharacter, possibleTargets
end

local aimbotEnabled = false

local function ToggleAimbot()
    aimbotEnabled = not aimbotEnabled
end

--// Visuals
local Sense = loadstring(game:HttpGet('https://raw.githubusercontent.com/petewar3/Peteware/refs/heads/main/Other/Sense.lua'))()

--// Sense Configuration
local enemyESP = false
local teamESP = false

Sense.whitelist = {}

Sense.sharedSettings.useTeamColor = false

Sense.teamSettings.enemy.enabled = enemyESP
Sense.teamSettings.enemy.chams = true
Sense.teamSettings.enemy.chamsVisibleOnly = false
Sense.teamSettings.enemy.chamsFillColor = { Color3.new(0.2, 0.2, 0.2), 0.5 }
Sense.teamSettings.enemy.chamsOutlineColor = { Color3.new(1, 0, 0), 0 }

Sense.teamSettings.friendly.enabled = teamESP
Sense.teamSettings.friendly.chams = true
Sense.teamSettings.friendly.chamsVisibleOnly = false
Sense.teamSettings.friendly.chamsFillColor = { Color3.new(0.2, 0.2, 0.2), 0.5 }
Sense.teamSettings.friendly.chamsOutlineColor = { Color3.new(1, 0, 0), 0 }

--// ESP Load
task.wait(1)
Sense.Load()

--// UI locals
local keepPeteware = true
local teleportConnection = false
local confirmDestroy = false

--// Main UI
local Window = Rayfield:CreateWindow({
   Name = "Override | Peteware v1.0.0",
   Icon = 0, 
   LoadingTitle = "Override | Peteware",
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
      Enabled = true,
      FolderName = "Peteware/Universal", 
      FileName = "Override"
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

Notify("When you destroy the UI destroy it via the settings tab.", 10)

local Tab = Window:CreateTab("Home", "layout-dashboard")

local Section = Tab:CreateSection("Welcome!")

--[[
[/] feature
[+] feature
[-] feature
]]

local Paragraph = Tab:CreateParagraph({Title = "What's new and improved", Content = [[
    [+] Added Feature
    [/] Fixed Feature
    [-] Removed Feature
    Please consider joining the server and suggesting more features.
    Please report any bugs to our discord server by creating a ticket.]]})

local discordButton = Tab:CreateButton({
   Name = "Join Discord",
   Callback = function()
       JoinDiscord()
   end,
})

local Tab = Window:CreateTab("Main", "gem")

if server_desync then
    local Section = Tab:CreateSection("Exploits")

    local ServerDesyncKeybindToggle = Tab:CreateKeybind({
        Name = "Server Desync",
        CurrentKeybind = "DPadLeft",
        HoldToInteract = false,
        Flag = "ServerDesyncKeybindToggle",
        Callback = function(Keybind)
            desynced = not desynced
            server_desync(desynced)
            Notify(desynced and "Server Desync Enabled" or "Server Desync Disabled.", 1.5)
        end,
    })

    local Divider = Tab:CreateDivider()
end

local Section = Tab:CreateSection("Combat")

local AimbotKeybindToggle = Tab:CreateKeybind({
   Name = "Aimbot",
   CurrentKeybind = "DPadRight",
   HoldToInteract = false,
   Flag = "AimbotKeybindToggle", 
   Callback = function(Keybind)
       ToggleAimbot()Notify(aimbotEnabled and "Aimbot Enabled" or "Aimbot Disabled.", 1.5)
   end,
})

local Section = Tab:CreateSection("Combat Configuration")

local AimbotPartsDropdown = Tab:CreateDropdown({
   Name = "Aimbot Target Parts",
   Options = aimPartOptions,
   CurrentOption = selectedAimParts,
   MultipleOptions = true,
   Flag = "AimbotPartsDropdown", 
   Callback = function(Options)
       selectedAimParts = Options
   end,
})

local AimbotSmoothnessSlider = Tab:CreateSlider({
   Name = "Aimbot Smoothness",
   Range = {0, 1},
   Increment = 0.01,
   Suffix = "Smoothness",
   CurrentValue = 0.15,
   Flag = "AimbotSmoothnessSlider", 
   Callback = function(Value)
       aimbotSmoothness = Value
   end,
})

local AimbotFOVSlider = Tab:CreateSlider({
   Name = "Aimbot FOV",
   Range = {30, 300},
   Increment = 3,
   Suffix = "°",
   CurrentValue = 90,
   Flag = "AimbotFOVSlider", 
   Callback = function(Value)
       aimbotFOV = Value
   end,
})

local AimbotWallCheckToggle = Tab:CreateToggle({
   Name = "Aimbot Wall Check",
   CurrentValue = false,
   Flag = "AimbotWallCheckToggle",
   Callback = function(Value)
       wallCheck = Value
   end,
})

local AimbotFriendCheckToggle = Tab:CreateToggle({
   Name = "Aimbot Friend Check",
   CurrentValue = false,
   Flag = "AimbotFriendCheckToggle",
   Callback = function(Value)
       friendCheck = Value
   end,
})

local AimbotTeamCheckToggle = Tab:CreateToggle({
   Name = "Aimbot Team Check",
   CurrentValue = false,
   Flag = "AimbotTeamCheckToggle",
   Callback = function(Value)
       teamCheck = Value
   end,
})

local AimbotDeadCheckToggle = Tab:CreateToggle({
   Name = "Aimbot Dead Check",
   CurrentValue = false,
   Flag = "AimbotDeadCheckToggle",
   Callback = function(Value)
       deadCheck = Value
   end,
})

AimbotDeadCheckToggle:Set(true)

local Divider = Tab:CreateDivider()

local Section = Tab:CreateSection("Visuals")

local EnemyESPToggle = Tab:CreateToggle({
   Name = "Enemy ESP",
   CurrentValue = false,
   Flag = "EnemyESPToggle", 
   Callback = function(Value)
       enemyESP = Value
       if enemyESP then
           task.wait()
           Sense.teamSettings.enemy.enabled = enemyESP
           Notify("Enemy ESP Enabled. Highlights all enemies in a rendering radius.", 2.5)
       else
           task.wait()
           Sense.teamSettings.enemy.enabled = enemyESP
           Notify("Enemy ESP Disabled.", 1.5)
       end
   end,
})

local TeamESPToggle = Tab:CreateToggle({
   Name = "Team ESP",
   CurrentValue = false,
   Flag = "TeamESPToggle", 
   Callback = function(Value)
       teamESP = Value
       if teamESP then
           task.wait()
           Sense.teamSettings.friendly.enabled = teamESP
           Notify("Team ESP Enabled. Highlights all teammates in a rendering radius.", 2.5)
       else
           task.wait()
           Sense.teamSettings.friendly.enabled = teamESP
           Notify("Team ESP Disabled.", 1.5)
       end
   end,
})

local Tab = Window:CreateTab("Misc", "circle-ellipsis")

local Section = Tab:CreateSection("Other Scripts")

local FPSBoosterButton = Tab:CreateButton({
    Name = "FPS Booster",
    Callback = function()
        -- Made by RIP#6666
        getgenv().FPS_Booster_Settings = {
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
        loadstring(game:HttpGet("https://raw.githubusercontent.com/petewar3/Developer-Toolbox/refs/heads/main/Backups/FPS-Booster-Backup.lua"))()
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

local onTeleport

local KeepPetewareToggle = Tab:CreateToggle({
    Name = "Keep Peteware On Server Hop/Rejoin",
    CurrentValue = false,
    Flag = "KeepPetewareToggle",
    Callback = function(Value)
        if Value then
            Notify("Whenever you teleport, the script will automatically execute aswel.")

            keepPeteware = true
            teleportCheck = false

            onTeleport = player.OnTeleport:Connect(function(State)
                if keepPeteware and not teleportCheck and queueteleport then
                    teleportCheck = true
                    queueteleport([[
                    if not game:IsLoaded() then
                        game.Loaded:Wait()
                        task.wait(1)
                    end
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/petewar3/Peteware/refs/heads/main/Universal/Override.lua"))()
                    ]])
                end
            end)
        else
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
            pcall(function()
                DisconnectScripts()
            end)
            
            pcall(function()
                Rayfield:Destroy()
            end)
        end
    end,
})

Rayfield:LoadConfiguration()

FOVCircle.Visible = true

--// Events
local events = {
    aimbotConnUpdate = runService.RenderStepped:Connect(function()
        UpdateFOVCircle()
        if aimbotEnabled then
            local targetCharacter, possibleTargets = FetchClosestTarget()
            if targetCharacter then
                local targetPart = FetchTargetPart(targetCharacter, possibleTargets)
                if targetPart then
                    local camCFrame = camera.CFrame
                    local direction = (targetPart.Position - camCFrame.Position).Unit
                    local t = 1 - aimbotSmoothness
                    local newLookVector = camCFrame.LookVector:Lerp(direction, t)
                    camera.CFrame = CFrame.new(camCFrame.Position, camCFrame.Position + newLookVector)
                end
            end
        end
    end),
    onTeleport
}

--// Disconnect Script Features
function DisconnectScript()
    getgenv().Override = nil
    keepPeteware = false
    
    for event in ipairs(events) do
        event:Disconnect()
        event = nil
    end
    
    Sense.Unload()
    
    FOVCircle:Destroy()
end

--[[
// Credits
Infinite Yield: Server Hop and Anti-AFK
Infinite Yield Discord Server: https://discord.gg/78ZuWSq
RIP#6666: FPS Booster
RIP#6666 Discord Server: https://discord.gg/rips
]]
