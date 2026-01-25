--// Loading Handler
if not game:IsLoaded() then
    game.Loaded:Wait()
    task.wait(1)
end

local cloneref = cloneref or function(...)
    return ...
end

local global_env = getgenv() or shared

if global_env.Peteware then
    return cloneref(game:GetService("StarterGui")):SetCore("SendNotification", {
        Title = "Already Executed.",
        Text = "If you want to execute the script again you need to destroy the original script via the settings tab.",
        Icon = "rbxassetid://108052242103510",
        Duration = 3.5
    })
else
    global_env.Peteware = true
end

local httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
local queueteleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
local setclip = setclipboard or (syn and syn.setclipboard) or (Clipboard and Clipboard.set)
local fireproximityprompt = fireproximityprompt

--// Services & Setup
local players = cloneref(game:GetService("Players"))
local player = cloneref(players.LocalPlayer)
local teleport_service = cloneref(game:GetService("TeleportService"))
local http_service = cloneref(game:GetService("HttpService")) 
local uis = cloneref(game:GetService("UserInputService"))
local replicated_storage = cloneref(game:GetService("ReplicatedStorage"))
local run_service = cloneref(game:GetService("RunService"))
local virtual_user = cloneref(game:GetService("VirtualUser"))
local proximity_prompt_service = cloneref(game:GetService("ProximityPromptService"))

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
    virtual_user:CaptureController()
    virtual_user:ClickButton2(Vector2.new())
    wait(2)
end)

--// Device Detection
local device_user        
if not uis.MouseEnabled and not uis.KeyboardEnabled and uis.TouchEnabled then
    device_user = "Mobile"
elseif uis.MouseEnabled and uis.KeyboardEnabled and not uis.TouchEnabled then
    device_user = "PC"
else
    device_user = "Unknown"
end

--// Join Discord
local invite_code = loadstring(game:HttpGet("https://raw.githubusercontent.com/Petewar3/Peteware/refs/heads/main/Other/discord.lua"))()
local invite_url = 'https://discord.com/invite/' .. invite_code

local function JoinDiscord()
    if setclip then
        setclip(invite_url)
        Notify("Discord invite copied to clipboard.")
    else
        Notify("Missing setclipboard function.")
        task.delay(1, function()
            Notify("Discord Invite: " .. invite_url)
        end)
    end

    if httprequest and device_user == "PC" then
        pcall(function()
            httprequest({
                Url = 'http://127.0.0.1:6463/rpc?v=1',
                Method = 'POST',
                Headers = {
                    ['Content-Type'] = 'application/json',
                    Origin = 'https://discord.com'
                },
                Body = http_service:JSONEncode({
                    cmd = 'INVITE_BROWSER',
                    nonce = http_service:GenerateGUID(false),
                    args = { code = invite_code }
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

SetupCharacter()
player.CharacterAdded:Connect(SetupCharacter)

--// Data Loader
local main_folder = "Peteware"

if not isfolder(main_folder) then
    makefolder(main_folder)
end

--// Server Hop
local server_hop_data = main_folder .. "/server-hop-data-temp.json"

local server_ids = {}
local found_any_servers = ""
local actual_hour = os.date("!*t").hour

if isfile(server_hop_data) then
    server_ids = http_service:JSONDecode(readfile(server_hop_data))
end

if typeof(server_ids) ~= "table" or #server_ids == 0 then
    server_ids = { actual_hour }
    writefile(server_hop_data, http_service:JSONEncode(server_ids))
end

local function ServerHop()
    Notify("Attempting to Server Hop")
    local function AttemptServerHop()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"

        if found_any_servers ~= "" then
            url = url .. "&cursor=" .. found_any_servers
        end

        local success, site = pcall(function()
            return http_service:JSONDecode(game:HttpGet(url))
        end)

        if not success or not site or not site.data then
            return
        end

        if site.nextPageCursor then
            found_any_servers = site.nextPageCursor
        end

        for _, v in pairs(site.data) do
            if v.playing < v.maxPlayers then
                local server_id = tostring(v.id)
                local can_server_hop = true

                for i, existing in pairs(server_ids) do
                    if i == 1 and existing ~= actual_hour then
                        if delfile then
                            delfile(server_hop_data)
                        end
                        server_ids = { actual_hour }
                        break
                    end

                    if server_id == tostring(existing) then
                        can_server_hop = false
                        break
                    end
                end

                if can_server_hop then
                    table.insert(server_ids, server_id)
                    writefile(server_hop_data, http_service:JSONEncode(server_ids))
                    teleport_service:TeleportToPlaceInstance(game.PlaceId, server_id)
                    task.wait(4)
                    return
                end
            end
        end
    end

    while task.wait(1) do
        pcall(AttemptServerHop)

        if found_any_servers ~= "" then
            pcall(AttemptServerHop)
        end
    end
end

--// Events Initialisation
local events = {}

--// Threads Initialisation
local threads = {}

--// Automation
local bases = workspace:WaitForChild("Bases")

--// Base Finder
local base
for _, plot in pairs(bases:GetChildren()) do
    if plot:GetAttribute("Holder") == player.UserId then
        base = plot
        break
    end
end

--// Base Function Utilities
local slots = cloneref(base:WaitForChild("Slots"))

local function FetchSlots()
    return slots:GetChildren()
end

local function FetchTakenSlots()
    local taken_slots = {}
    
    for _, slot in pairs(slots:GetChildren()) do
        local collect_money_gui = cloneref(slot:WaitForChild("Collect"):WaitForChild("CollectMoneyGui"))
        if collect_money_gui.Enabled then
            table.insert(taken_slots, slot)
        end
    end
    
    return taken_slots
end

local function FetchOpenSlots()
    local open_slots = {}
    
    for _, slot in pairs(slots:GetChildren()) do
        local collect_money_gui = cloneref(slot:WaitForChild("Collect"):WaitForChild("CollectMoneyGui"))
        if not collect_money_gui.Enabled then
            table.insert(open_slots, slot)
        end
    end
    
    return open_slots
end

local plot_action = cloneref(replicated_storage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RF/Plot.PlotAction"))

local function CollectMoney(slot_index)
    print(base.Name)
    local args = {
	    "Collect Money",
	    base.Name,
	    tostring(slot_index)
    }
    
    plot_action:InvokeServer(unpack(args))
end

local auto_collect_money = true

--// Visuals
local Sense = loadstring(game:HttpGet('https://raw.githubusercontent.com/petewar3/Peteware/refs/heads/main/Other/Sense.lua'))()

--// Sense Configuration
local classes = { -- modify classes, add and remove them
    ["Custom"] = true
}

local esp_data = {}

local function CreateESP(instance, instance_type, instance_text, instance_text_colour, instance_text_colour_outline)
    for _, esp in ipairs(esp_data) do
        if esp.instance == instance then
            return
        end
    end
    
    local instance_enabled = classes[instance_type] or false
    
    local data = {
        instanceClass = instance_type,
        enabled = instance_enabled,
        text = instance_text,
        textColor = instance_text_colour,
        instanceOutline = true,
        instanceOutlineColor = instance_text_colour_outline,
        textSize = 17,
        textFont = 2,
        limitDistance = false
    }
    
    local ESPInstance = Sense.AddInstance(instance, data)
    ESPInstance.instanceClass = instance_type
    ESPInstance.instance = instance
    
    table.insert(esp_data, ESPInstance)
end

local function ModifyESP(class_name, key, value)
    for _, esp in ipairs(esp_data) do
        if esp.instanceClass == class_name then
            if esp.options[key] ~= nil then
                esp.options[key] = value
            end
        end
    end
end

Sense.whitelist = {}

Sense.sharedSettings.limitDistance = true
Sense.sharedSettings.maxDistance = 600
Sense.sharedSettings.useTeamColor = false

--// ESP Load
task.wait(1)
Sense.Load()

--// UI locals
local game_name = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local keep_peteware = true
local confirm_destroy = false

--// Main UI
local Window = Rayfield:CreateWindow({
   Name = game_name .. " Peteware v1.0.0",
   Icon = 0, 
   LoadingTitle = game_name .. " | Peteware",
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

if device_user == "PC" then
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
    [+] Added Feature
    [/] Fixed Feature
    [-] Removed Feature
    Please consider joining the server and suggesting more features.
    Please report any bugs to our discord server by creating a ticket.]]})

local discord_button = Tab:CreateButton({
   Name = "Join Discord",
   Callback = function()
       JoinDiscord()
   end,
})

local Tab = Window:CreateTab("Main", "gem")

local Section = Tab:CreateSection("Automation")

local auto_collect_money_toggle = Tab:CreateToggle({
   Name = "Auto Collect Money",
   CurrentValue = false,
   Flag = "auto_collect_money_toggle", 
   Callback = function(value)
        auto_collect_money = value
        if value then
            Notify("Auto Collect Money Enabled.", 2)
            
            task.spawn(function()
                while auto_collect_money do
                    print("wow")
                    local slots = FetchTakenSlots()
                    print(#slots)
                    for _, slot in ipairs(slots) do
                        local slot_index = slot.Name:gsub("Slot", "")
                        CollectMoney(slot_index)
                    end
    
                    task.wait(1)
                end
            end)
        else
            Notify("Auto Collect Money Disabled.", 1.5)
        end
   end,
})

local Tab = Window:CreateTab("Teleports", "user")

local Tab = Window:CreateTab("Misc", "circle-ellipsis")

local Section = Tab:CreateSection("Character")

local infinite_jump_toggle = Tab:CreateToggle({
   Name = "Infinite Jump",
   CurrentValue = false,
   Flag = "infinite_jump_toggle", 
   Callback = function(value)
        if value then
            Notify("Infinite Jump Enabled.", 2)
            events.infinte_jump = uis.JumpRequest:Connect(function()
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end)
        else
            Notify("Infinite Jump Disabled.", 1.5)
            if typeof(events.infinite_jump) == "RBXScriptConnection" then
                events.infinite_jump:Disconnect()
                events.infinite_jump = nil
            end
        end
   end,
})

local default_ws = humanoid.WalkSpeed
local custom_ws = false
local current_ws = humanoid.WalkSpeed

local ws_slider = Tab:CreateSlider({
   Name = "WalkSpeed",
   Range = {0, 1000},
   Increment = 10,
   Suffix = "WalkSpeed",
   CurrentValue = default_ws,
   Flag = "walk_speed_slider", 
   Callback = function(value)
       if value ~= default_ws then
            custom_ws = true
            current_ws = value
            if humanoid.WalkSpeed ~= value then
                humanoid.WalkSpeed = value
            end
        end
    end,
})

local default_ujp = humanoid.UseJumpPower
local default_jp = humanoid.JumpPower
local custom_jp = false
local current_jp = humanoid.JumpPower

local jp_slider = Tab:CreateSlider({
   Name = "JumpPower",
   Range = {0, 100},
   Increment = 1,
   Suffix = "JumpPower",
   CurrentValue = default_jp,
   Flag = "jump_power_slider", 
   Callback = function(value)
       if value ~= default_jp then
            custom_jp = true
            current_jp = value
            if humanoid.JumpPower ~= value then
                current_jp = value
                humanoid.JumpPower = value
            end
        end
    end,
})

--// Initialise ResetStats function
local function ResetStats()
    custom_ws = false
    wsUpdate = true
    current_ws = default_ws

    humanoid.WalkSpeed = default_ws
    ws_slider:Set(default_ws)
        
    custom_jp = false
    jpUpdate = true
    current_jp = default_jp

    humanoid.JumpPower = default_jp
    humanoid.UseJumpPower = default_ujp
    jp_slider:Set(default_jp)   
end

local reset_stats_button = Tab:CreateButton({
    Name = "Reset Stats",
    Callback = ResetStats,
})

local Divider = Tab:CreateDivider()

local Section = Tab:CreateSection("Exploits")

local instant_prompts_toggle; instant_prompts_toggle = Tab:CreateToggle({
   Name = "Instant Prompts",
   CurrentValue = false,
   Flag = "instant_prompts_toggle",
   Callback = function(value)
        if typeof(fireproximityprompt) ~= "function" then
            Notify("Incompatible Exploit. Your exploit does not support this feature (missing fireproximityprompt)")
        end
        
        if value then
            Notify("Instant Prompts Enabled.", 2)
            events.instant_prompts = proximity_prompt_service.PromptButtonHoldBegan:Connect(function(prompt)
                if prompt.HoldDuration > 0 then
                    fireproximityprompt(prompt)
                end
            end)
        else
            Notify("Instant Prompts Disabled.", 1.5)
            if typeof(events.instant_prompts) == "RBXScriptConnection" then
                events.instant_prompts:Disconnect()
                events.instant_prompts = nil
            end
        end
   end,
})

local Divider = Tab:CreateDivider()

local Section = Tab:CreateSection("Other Scripts")

local fps_booster_button = Tab:CreateButton({
    Name = "FPS Booster",
    Callback = function()
        -- Made by RIP#6666
        global_env.FPS_Booster.Settings = {
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

local infinite_yield_button = Tab:CreateButton({
   Name = "Infinite Yield Admin",
   Callback = function()
       loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
   end,
})

local Tab = Window:CreateTab("Background Tasks", "clipboard-list")

local Paragraph = Tab:CreateParagraph({Title = "Background Tasks", Content = [[
    Anti-AFK]]})

local Tab = Window:CreateTab("Settings", "settings")

local rejoin_server_button = Tab:CreateButton({
   Name = "Rejoin Server",
   Callback = function()
        Notify("Attemping to Rejoin Server.")
        task.delay(1, function()
            teleport_service:TeleportToPlaceInstance(game.PlaceId, game.JobId)
        end)
   end,
})

local server_hop_button = Tab:CreateButton({
   Name = "Rejoin Server",
   Callback = ServerHop,
})

local keep_peteware_toggle = Tab:CreateToggle({
    Name = "Keep Peteware On Server Hop/Rejoin",
    CurrentValue = false,
    Flag = "keep_peteware_toggle",
    Callback = function(value)
        if value then
            Notify("Whenever you teleport, the script will automatically execute aswel.")

            keep_peteware = true
            
            local valid_teleport_states = {
                Enum.TeleportState.Started,
                Enum.TeleportState.InProgress,
                Enum.TeleportState.WaitingForServer
            }

            events.on_teleport = player.OnTeleport:Connect(function(state)
                if table.find(valid_teleport_states, state) and keep_peteware and queueteleport then
                    queueteleport([[
                    if not game:IsLoaded() then
                        game.Loaded:Wait()
                        task.wait(1)
                    end
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/petewar3/Peteware/refs/heads/main/Games/Escape%20Tsunami%20For%20Brainrot.lua"))()
                    ]])
                end
            end)
        else
            if typeof(events.on_teleport) == "RBXScriptConnection" then
                events.on_teleport:Disconnect()
                events.on_teleport = nil
            end
            
            Notify("The script wont automatically execute on serverhop or rejoin.")
            keep_peteware = false
            teleportCheck = false
        end
    end,
})

keep_peteware_toggle:Set(true)

--// Initialise DisconnectScripts function
local function DisconnectScripts() end

local destroy_ui_button = Tab:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        if not confirm_destroy then
            confirm_destroy = true
            Rayfield:Notify({
                Title = "Confirm UI Destruction",
                Content = "Click 'Destroy UI' again to confirm.",
                Duration = 3,
                Image = "bell-ring",
            })
            task.delay(3.5, function()
                confirm_destroy = false
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

--// Static Events
events.stats_conn = player.CharacterAdded:Connect(function()
    task.wait(1)
    humanoid.WalkSpeed = current_ws
    humanoid.UseJumpPower = (custom_jp and true) or default_ujp
    humanoid.JumpPower = current_jp
end)

events.stats_conn_updater_ws = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
    if not custom_ws then
        ws_slider:Set(humanoid.WalkSpeed)
        return
    end

    if humanoid.WalkSpeed ~= current_ws then
        humanoid.WalkSpeed = current_ws
    end

    ws_slider:Set(humanoid.WalkSpeed)
end)

events.stats_conn_updater_ujp = humanoid:GetPropertyChangedSignal("UseJumpPower"):Connect(function()
    if not custom_jp then
        return
    end

    if not humanoid.UseJumpPower then
        humanoid.UseJumpPower = true
    end
end)

events.stats_conn_updater_jp = humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
    if not custom_jp then
        jp_slider:Set(humanoid.JumpPower)
        return
    end

    if humanoid.JumpPower ~= current_jp then
        humanoid.JumpPower = current_jp
    end

    jp_slider:Set(humanoid.JumpPower)
end)

--// Disconnect Script Features
function DisconnectScripts()
    global_env.Peteware = nil
    keep_peteware = false
    
    for key, event in pairs(events) do
        if typeof(event) == "RBXScriptConnection" then
            event:Disconnect()
        end
        events[key] = nil
    end
    
    for key, thread in pairs(threads) do
        if typeof(thread) == "thread" then
            task.cancel(thread)
        end
        threads[key] = nil
    end
    
    Sense.Unload()
end

--[[
// Credits
Infinite Yield: Server Hop and Anti-AFK
Infinite Yield Discord Server: https://discord.gg/78ZuWSq
RIP#6666: FPS Booster
RIP#6666 Discord Server: https://discord.gg/rips
]]
