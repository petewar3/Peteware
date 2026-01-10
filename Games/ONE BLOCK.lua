--[[
    Open-Source Script
    Brought to you by 584h / Petah
    Game: ONE BLOCK
    Game-Link: https://www.roblox.com/games/87124461329967/ONE-BLOCK
    Description: Item Spawner and Commands. Easy to use with set up
    instructions via notifications on execution.
    Usage: Paste this script into your executor and press execute.
    Version: 1.0

    Dependencies / Requirements:
    None
]]

--// Loading Handler
if not game:IsLoaded() then
    game.Loaded:Wait()
    task.wait(1)
end

--// Services & Setup
local players = game:GetService("Players")
local player = players.LocalPlayer
local workspace = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local cas = game:GetService("ContextActionService")
local virtualUser = game:GetService("VirtualUser")
local soundService = game:GetService("SoundService")
local runService = game:GetService("RunService")

--// Function Addons
local function toboolean(str)
    if typeof(str) ~= "string" then
        return nil
    end
    
    str = str:lower()
    if str == "true" then
        return true
    elseif str == "false" then
        return false
    else
        return nil
    end
end

--// Anti-AFK
player.Idled:Connect(function()
    virtualUser:CaptureController()
    virtualUser:ClickButton2(Vector2.new())
    wait(2)
end)

--// Character Auto Setup
local char, humanoid, hrp, backpack

local function GetCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

local function SetupCharacter()
    char = GetCharacter()
    humanoid = char:WaitForChild("Humanoid")
    hrp = char:WaitForChild("HumanoidRootPart")
    backpack = player:WaitForChild("Backpack")
end

SetupCharacter()
player.CharacterAdded:Connect(function()
    SetupCharacter()
end)

--// Notification Sender
local guiParent = gethui and gethui() or game:GetService("CoreGui")

local containerGui = guiParent:FindFirstChild("PetewareNotificationsScreenGui")
if not containerGui then
    containerGui = Instance.new("ScreenGui")
    containerGui.Name = "PetewareNotificationsScreenGui"
    containerGui.ResetOnSpawn = false
    containerGui.IgnoreGuiInset = true
    containerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    containerGui.Parent = guiParent
end

local frameHolder = containerGui:FindFirstChild("FrameHolder")
if not frameHolder then
    frameHolder = Instance.new("Frame")
    frameHolder.Name = "FrameHolder"
    frameHolder.AnchorPoint = Vector2.new(1, 1)
    frameHolder.Position = UDim2.new(1, -20, 1, -20)
    frameHolder.Size = UDim2.new(0, 340, 1, 0)
    frameHolder.BackgroundTransparency = 1
    frameHolder.BorderSizePixel = 0
    frameHolder.ClipsDescendants = false
    frameHolder.Parent = containerGui

    local layout = Instance.new("UIListLayout")
    layout.Name = "NotificationLayout"
    layout.Parent = frameHolder
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
end

local notifications = {}

local function RearrangeNotifications()
    for i, notif in ipairs(notifications) do
        local yOffset = -((notif.AbsoluteSize.Y + 10) * (i - 1))
        tweenService:Create(notif, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0.5, 0, 1, yOffset)
        }):Play()
    end
end

local function Notify(title, description)
    task.spawn(function()
        local notif = Instance.new("Frame")
        notif.Name = "notification"
        notif.AnchorPoint = Vector2.new(0.5, 1)
        notif.Position = UDim2.new(0.5, 0, 1, 100)
        notif.Size = UDim2.new(0, 320, 0, 0)
        notif.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        notif.BackgroundTransparency = 0.9
        notif.BorderSizePixel = 0
        notif.ZIndex = 9999
        notif.ClipsDescendants = true
        notif.Parent = frameHolder

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = notif

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(61, 116, 198)
        stroke.Transparency = 1
        stroke.Parent = notif

        local icon = Instance.new("ImageLabel")
        icon.BackgroundTransparency = 1
        icon.Image = "rbxassetid://108052242103510"
        icon.ImageTransparency = 1
        icon.Size = UDim2.new(0, 26, 0, 26)
        icon.Position = UDim2.new(0, 12, 0, 12)
        icon.ZIndex = 10000
        icon.Parent = notif

        local titleLabel = Instance.new("TextLabel")
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title or "Notification"
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.Font = Enum.Font.GothamSemibold
        titleLabel.TextSize = 16
        titleLabel.TextTransparency = 1
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Position = UDim2.new(0, 50, 0, 8)
        titleLabel.Size = UDim2.new(1, -60, 0, 20)
        titleLabel.ZIndex = 10000
        titleLabel.Parent = notif

        local descLabel = Instance.new("TextLabel")
        descLabel.BackgroundTransparency = 1
        descLabel.Text = description or ""
        descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextSize = 14
        descLabel.TextWrapped = true
        descLabel.TextYAlignment = Enum.TextYAlignment.Top
        descLabel.TextTransparency = 1
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Position = UDim2.new(0, 50, 0, 30)
        descLabel.Size = UDim2.new(1, -60, 0, 100)
        descLabel.ZIndex = 10000
        descLabel.Parent = notif

        local dismiss = Instance.new("TextButton")
        dismiss.BackgroundTransparency = 1
        dismiss.Size = UDim2.new(1, 0, 1, 0)
        dismiss.Text = ""
        dismiss.ZIndex = 10001
        dismiss.Parent = notif

        task.wait()
        local textHeight = math.max(20, descLabel.TextBounds.Y)
        local finalHeight = math.clamp(textHeight + 60, 60, 220)

        table.insert(notifications, 1, notif)
        RearrangeNotifications()

        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://255881176"
        sound.Volume = 1
        sound.PlayOnRemove = true
        sound.Parent = containerGui
        sound:Destroy()

        tweenService:Create(notif, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {
            Size = UDim2.new(0, 320, 0, finalHeight),
            BackgroundTransparency = 0.15
        }):Play()
        tweenService:Create(stroke, TweenInfo.new(0.35), {Transparency = 0.5}):Play()
        task.wait(0.06)
        tweenService:Create(icon, TweenInfo.new(0.35), {ImageTransparency = 0}):Play()
        tweenService:Create(titleLabel, TweenInfo.new(0.35), {TextTransparency = 0}):Play()
        tweenService:Create(descLabel, TweenInfo.new(0.35), {TextTransparency = 0.15}):Play()

        RearrangeNotifications()

        local waitTime = math.clamp(#tostring(descLabel.Text) * 0.08 + 2.5, 2.5, 10)
        local dismissed = false

        dismiss.MouseButton1Click:Connect(function()
            if dismissed then return end
            dismissed = true
            tweenService:Create(notif, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, 0, 1, 100),
                BackgroundTransparency = 1
            }):Play()
            task.wait(0.4)
            notif:Destroy()
            table.remove(notifications, table.find(notifications, notif))
            RearrangeNotifications()
        end)

        task.wait(waitTime)
        if dismissed then return end

        tweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, 1, 100),
            BackgroundTransparency = 1
        }):Play()
        task.wait(0.45)
        notif:Destroy()
        table.remove(notifications, table.find(notifications, notif))
        RearrangeNotifications()
    end)
end

--// Device Detection
local device
local platform = uis:GetPlatform()
if platform == Enum.Platform.Windows or platform == Enum.Platform.OSX or platform == Enum.Platform.Linux then
    device = "PC"
else
    device = "Mobile"
end

--// Item Data
local commandData = {
    ["PurchaseGeneral"] = {
        -- Magnets
        "Magnet",
        "Copper Magnet",
        "Iron Magnet",
        "Gold Magnet",
        "Diamond Magnet",
        "Infinity Magnet",
        
        -- Healing
        "Bandage",
        "Medkit",
        
        -- Buildings
        "Farm Stand",
        "Wood Cutter",
        "Stone Smelter",
        "Cooking Pot",
        "Botanist Workbench",
        "Platform Workbench",
        "General Workbench",
        "Forge Workbench",
        "Loom Workbench",
        "Carpenter Workbench",
        "Glass Blower Workbench",
        "Lightkeeper Workbench",
        "Animal Station",
        "Drill",
        
        -- Miscellaneous
        "PickupTool"
    },

    ["PurchaseTool"] = {
        "Oak Platform",
        "Birch Platform",
        "Cherry Platform",
        "Bloodwood Platform",
        "Acacia Platform",
        "Grass Platform",
        "Stone Platform",
        "Granite Platform",
        "Diorite Platform",
        "Blackstone Platform"
    },

    ["PurchaseFarmStand"] = {
        "Farm Plot",
        "Strawberry Seeds",
        "Peach Seeds",
        "Orange Seeds",
        "Banana Seeds",
        "Watermelon Seeds"
    },

    ["PurchaseWoodCutter"] = {
        -- Oak
        "Oak Block",
        "Oak Slab",
        "Oak Stairs",
        "Oak Stairs Corner",
        "Oak Wall",
        "Oak Wall Corner",

        -- Birch
        "Birch Block",
        "Birch Slab",
        "Birch Stairs",
        "Birch Stairs Corner",
        "Birch Wall",
        "Birch Wall Corner",

        -- Cherry
        "Cherry Block",
        "Cherry Slab",
        "Cherry Stairs",
        "Cherry Stairs Corner",
        "Cherry Wall",
        "Cherry Wall Corner",

        -- Bloodwood
        "Bloodwood Block",
        "Bloodwood Slab",
        "Bloodwood Stairs",
        "Bloodwood Stairs Corner",
        "Bloodwood Wall",
        "Bloodwood Wall Corner",

        -- Acacia
        "Acacia Block",
        "Acacia Slab",
        "Acacia Stairs",
        "Acacia Stairs Corner",
        "Acacia Wall",
        "Acacia Wall Corner"
    },

    ["PurchaseStoneSmelter"] = {
        -- Stone
        "Stone Block",
        "Stone Slab",
        "Stone Stairs",
        "Stone Stairs Corner",
        "Stone Wall",
        "Stone Wall Corner",

        -- Granite
        "Granite Block",
        "Granite Slab",
        "Granite Stairs",
        "Granite Stairs Corner",
        "Granite Wall",
        "Granite Wall Corner",

        -- Diorite
        "Diorite Block",
        "Diorite Slab",
        "Diorite Stairs",
        "Diorite Stairs Corner",
        "Diorite Wall",
        "Diorite Wall Corner",

        -- Blackstone
        "Blackstone Block",
        "Blackstone Slab",
        "Blackstone Stairs",
        "Blackstone Stairs Corner",
        "Blackstone Wall",
        "Blackstone Wall Corner"
    },

    ["PurchaseBotanist"] = {
        "Grass Block",
        "Birch Sapling",
        "Oak Sapling",
        "Cherry Sapling",
        "Acacia Sapling",
        "Bloodwood Sapling"
    },

    ["PurchaseForge"] = {
        -- Stone Tier
        "Stone Pickaxe",
        "Stone Axe",
        "Stone Shovel",
        "Stone Sword",
        "Stone Spear",
        "Stone Hammer",
        "Stone Trident",
        
        -- Iron Tier
        "Iron Pickaxe",
        "Iron Axe",
        "Iron Shovel",
        "Iron Sword",
        "Iron Spear",
        "Iron Hammer",
        "Iron Trident",
        
        -- Gold Tier
        "Gold Pickaxe",
        "Gold Axe",
        "Gold Shovel",
        "Gold Sword",
        "Gold Spear",
        "Gold Hammer",
        "Gold Trident",
        
        -- Diamond Tier
        "Diamond Pickaxe",
        "Diamond Axe",
        "Diamond Shovel",
        "Diamond Sword",
        "Diamond Spear",
        "Diamond Hammer",
        "Diamond Trident"
    },

    ["PurchaseLoom"] = {
        "Red Wool Platform",
        "Blue Wool Platform",
        "Yellow Wool Platform",
        "Purple Wool Platform",
        "Orange Wool Platform",
        "Green Wool Platform"
    },

    ["PurchaseCarpenter"] = {
        -- Shelfs
        "Red Shelf",
        "Blue Shelf",
        "White Shelf",
        
        -- Beds
        "Red Bed",
        "Blue Bed",
        "White Bed",
        
        -- Seats
        "Red Seat",
        "Blue Seat",
        "White Seat",
        
        -- Chairs
        "Red Chair",
        "Blue Chair",
        "White Chair"
    },

    ["PurchaseGlassBlower"] = {
        "Glass",
        "Blue Glass",
        "Green Glass",
        "Orange Glass",
        "Pink Glass",
        "Red Glass",
        "Yellow Glass"
    },

    ["PurchaseLightkeeper"] = {
        "Lantern",
        "Lantern Stand",
        "Lantern Pole",
        "Double Lantern Pole"
    },

    ["PurchaseAnimal"] = {
        "Chicken Pen",
        "Pig Pen",
        "Sheep Pen",
        "Cow Pen"
    },

    ["CustomCommands"] = {
        "UnlockBlueprints",
        "SendAnnouncement",
        "ScareServer",
        "AutoMine",
        "GenerateFurnaceBase",
        "AdvancedMagnet",
        "FreezeCharacter",
        "AutoHeal",
        "PlantAccelerator",
        "SpawnMoneyBlocks"
    }
}

local foodData = {
    "WatermelonMODEL",
    "BananaMODEL",
    "OrangeMODEL",
    "PeachMODEL",
    "StrawberryMODEL"
}

--// Item Type Fetcher
local function FetchItemType(item)
    for type, items in pairs(commandData) do
        for _, name in ipairs(items) do
            if name == item then
                return type
            end
        end
    end
    return nil 
end

--// Asset Ids
local axeId = "rbxassetid://96101344191937"
local pickaxeId = "rbxassetid://113939170676272"
local shovelId = "rbxassetid://128935722146837"

--// Item Spawner
local function SpawnItem(item, quantity, customCommand)
    quantity = quantity or 1
    if typeof(item) ~= "string" or quantity <= 0 then
        return
    end
    
    local leaderstats = player:FindFirstChild("leaderstats")
    
    local _, cashAmount = pcall(function()
        local cash = player.PlayerGui.CashCounter.Frame.TextLabel.Text
        local cleanCash = cash:gsub(",", ""):gsub("%$", "")
        return tonumber(cleanCash)
    end)

    if quantity > cashAmount then
        local deficit = quantity - cashAmount
        if quantity == 1 then
            Notify("You need 1$ more to buy the " .. item)
        else
            Notify("You need " .. deficit .. "$ more to buy x" .. quantity .. " " .. item .. "s")
        end
        return  
    end
    
    local remote = FetchItemType(item) or "PurchaseGeneral"
    
    for _ = 1, quantity do
        local args = {
            item,
            1
        }
        rs:WaitForChild(remote):FireServer(unpack(args))
        task.wait(0.1)
    end
    
    if not customCommand then
        Notify("Item Spawned", "Spawned x" .. quantity .. " '" .. item .. "'.")
    end
end

--// Custom Commands
local function UnlockBlueprints()
    local blueprints = {
        "Wood Cutter",
        "Stone Smelter",
        "Cooking Pot",
        "Botanist Workbench",
        "Platform Workbench",
        "General Workbench",
        "Forge Workbench"
    }

    for _, blueprint in ipairs(blueprints) do
        SpawnItem("Copper Magnet", 1, true)
        local args = {
            blueprint,
            backpack:WaitForChild("Copper Magnet")
        }
        rs:WaitForChild("ConsumeBlueprint"):FireServer(unpack(args))
        task.wait(0.15)
    end

    Notify("Blueprints Unlocked", "All blueprints have been unlocked.")
end

local function SendAnnouncement(message, customCommand)
    SpawnItem("Copper Magnet", 1, true)

    local args = {
        message,
        backpack:WaitForChild("Copper Magnet")
    }

    rs:WaitForChild("ConsumeBlueprint"):FireServer(unpack(args))
    if not customCommand then
        Notify("Annoucement Sent!", "Message: " .. message)
    end
end

local function GenerateBinaryLines()
    local lines = {}
    for i = 1, 20 do
        local line = {}
        for j = 1, 80 do
            line[j] = math.random(0, 1)
        end
        lines[i] = table.concat(line)
    end
    return table.concat(lines, "\n")
end

local hackGameValue = false

local function ScareServer(boolean)
    hackGameValue = boolean
    if hackGameValue then
        Notify("Started Scare Server", "Scare Server has been enabled, script will now start sending annoucements with binary.")
        task.spawn(function()
            while hackGameValue do
                SendAnnouncement(GenerateBinaryLines(), true)
                task.wait(1)
            end
        end)
    else
        Notify("Stopped Scare Server", "Scare Server has been disabled, script will no longer send announcements with binary.")
    end
end

local function FetchOneBlock()
    for _, instance in ipairs (workspace:GetChildren()) do
        local healthBar = instance:FindFirstChild("HealthBar")
        if healthBar and healthBar:IsA("BillboardGui") then
            local imageLabel = healthBar:FindFirstChild("Frame"):FindFirstChild("ImageLabel")
            if imageLabel and imageLabel:IsA("ImageLabel") then
                if imageLabel.Image == axeId or imageLabel.Image == pickaxeId or imageLabel.Image == shovelId then
                    return instance
                end
            end
        end
    end
    
    return nil
end 

local function FetchTool(toolName, equip, wait)
    local tool = char:FindFirstChild(toolName)
	
	if not tool or not tool:IsA("Tool") then
	    tool = backpack:FindFirstChild(toolName)
	    if tool and equip then
	        humanoid:EquipTool(tool)
	    end
	end
	
	return tool
end

local autoMineValue = false
local autoMineConn

local function ValidNPC(npc, debug)
    if typeof(npc) == "string" then
		npc = workspace:FindFirstChild(npc) or rs:FindFirstChild(npc)
	end

	if not npc or not npc:IsA("Instance") then
		if debug then
		    warn("Invalid NPC passed to ValidNPC:", npc) -- debugging usage
	    end
		return
	end
	
	local validNPC = npc:GetAttribute("NPC_ID")
	
	if not validNPC then
	    return false
	end
	
	return true
end

local function GenerateNPCEntry(npc, debug)
    if not ValidNPC(npc) then return nil end

    local humanoid = npc:FindFirstChild("Humanoid")
    local rootPart = npc:FindFirstChild("HumanoidRootPart")

    if not humanoid or not rootPart then
        if debug then
            warn("NPC missing Humanoid or HumanoidRootPart:", npc.Name)
        end
        return nil
    end
    
    if humanoid.Health <= 0 then
        return nil
    end

    local entry = {
        isNPC = true,
        character = npc,
        health = humanoid.Health,
        maxHealth = humanoid.MaxHealth,
        position = Vector3.new(rootPart.Position.X, rootPart.Position.Y, rootPart.Position.Z),
        humanoid = humanoid,
        humanoidRootPart = rootPart
    }

    return entry
end

local function GenerateNPCData()
    local npcData = {}
    for _, obj in ipairs(workspace:GetChildren()) do
        if ValidNPC(obj) then
            local entry = GenerateNPCEntry(obj)
            if entry then
                table.insert(npcData, {entry}) 
            end
        end
    end
    return npcData
end

local function GenerateHitArgs(block, hammerName)
    local blockData = {
        {
            blockInfoFolder = block:WaitForChild("BlockInfo"),
            health = block:WaitForChild("BlockInfo"):WaitForChild("Health").Value,
            hardness = "Hard",
            object = block,
            maxHealthValue = block:WaitForChild("BlockInfo"):WaitForChild("MaxHealth"),
            position = Vector3.new(0.0000019073486328125, 6.000082015991211, 0), -- example
            healthBarGui = block:WaitForChild("HealthBar"),
            maxHealth = block:WaitForChild("BlockInfo"):WaitForChild("MaxHealth").Value,
            healthValue = block:WaitForChild("BlockInfo"):WaitForChild("Health")
        }
    }

    local npcData = GenerateNPCData()

    local args = { blockData, hammerName }

    for _, npcEntry in ipairs(npcData) do
        table.insert(args, npcEntry)
    end

    return args
end

local function MineBlock(block, debug)
    if typeof(block) == "string" then
		block = workspace:FindFirstChild(block) or rs:FindFirstChild(block)
	end

	if not block or not block:IsA("Instance") then
	    if debug then
		    warn("Invalid block passed to MineBlock:", block) -- debugging usage
	    end
		return
	end
	
	local hammerType = "Diamond"
	local hammerName = hammerType .. " Hammer"
	local hammer = FetchTool(hammerName, true)
	
	if not hammer then
	    autoMineValue = false
	    if autoMineConn and typeof(autoMineConn) == "RBXScriptConnection" then
            autoMineConn:Disconnect()
            autoMineConn = nil
        end
	    return Notify("Failed to find a " .. hammerName .. " while mining " .. block.Name)
	end
	
	if autoMineValue ~= true then
	    return
	end
	
	local args = GenerateHitArgs(block, hammerName)
    hammer:WaitForChild("ToolHit"):FireServer(unpack(args))
end

local function AutoMine(boolean)
    task.spawn(function()
        autoMineValue = boolean
        if boolean then
            Notify("Started Auto Mine", "Auto Mine has been enabled, script will now start auto mining the one block.")
            autoMineConn = workspace.ChildAdded:Connect(function(child)
                task.wait()
                oneBlock = FetchOneBlock()
                if oneBlock then
                    repeat
                        task.wait(0.45)
                        MineBlock(oneBlock)
                        if autoMineValue ~= true then
                            return
                        end
                    until not oneBlock
                end
            end)
        
            local oneBlock = FetchOneBlock()
            if oneBlock then
                repeat
                    if not oneBlock or not oneBlock.Parent then
                        break
                    end
                
                    MineBlock(oneBlock)
                    task.wait(0.45)
                until not oneBlock
            end
        else
            Notify("Stopped Auto Mine", "Auto Mine has been disabled, script will no longer auto mine the one block.")
            if autoMineConn and typeof(autoMineConn) == "RBXScriptConnection" then
                autoMineConn:Disconnect()
                autoMineConn = nil
            end
        end
    end)
end

local function ValidItem(item, debug)
    if typeof(item) == "string" then
		item = workspace:FindFirstChild(item) or rs:FindFirstChild(item)
	end

	if not item or not item:IsA("Instance") then
		if debug then
		    warn("Invalid block passed to MineBlock:", block) -- debugging usage
	    end
		return
	end
	
	local validItem = item:GetAttribute("UUID") or item:GetAttribute("Dropped") or false
	
	if not validItem then
	    return false
	end
	
	return true
end

local function PickupItem(item, debug)
    if typeof(item) == "string" then
		item = workspace:FindFirstChild(item) or rs:FindFirstChild(item)
	end

	if not item or not item:IsA("Instance") then
		if debug then
		    warn("Invalid block passed to MineBlock:", block) -- debugging usage
	    end
		return
	end
    
    local UUID = item:GetAttribute("UUID")
    
    pcall(function()
        if not UUID then
            if item and item:GetAttribute("Dropped") then
                if item.Parent == workspace.DroppedOres then
                    rs:WaitForChild("RequestLootPickup"):InvokeServer(item)
                else
                    rs:WaitForChild("RequestToolPickup"):InvokeServer(item)
                end
            end
        else
            rs:WaitForChild("RequestLootPickup"):InvokeServer(UUID)
        end
    end)
    
    if item:IsA("Instance") then
        local itemName = item.Name
        item:Destroy()
        if debug then
            warn(item.Name .. " has just been destroyed")
        end
    end
end

local advancedMagnetConn1
local advancedMagnetConn2

local function AdvancedMagnet(boolean)
    task.spawn(function()
        if boolean then
            Notify("Started Advanced Magnet", "Advanced Magnet has been enabled, script will now start picking all items up.")
            
            local droppedOres = workspace:FindFirstChild("DroppedOres")
            
            advancedMagnetConn1 = workspace.ChildAdded:Connect(function(child)
                task.wait()
                if not droppedOres and child.Name == "DroppedOres" then
                    droppedOres = child
                    advancedMagnetConn2 = droppedOres.ChildAdded:Connect(function(child)
                        task.wait()
                        if ValidItem(child) then
                            PickupItem(child)
                        end
                    end)
                    return
                end
                if ValidItem(child) then
                    PickupItem(child)
                end
            end)
            
            if droppedOres then
                advancedMagnetConn2 = droppedOres.ChildAdded:Connect(function(child)
                    task.wait()
                    if ValidItem(child) then
                        PickupItem(child)
                    end
                end)
            end
            
            for _, instance in ipairs(workspace:GetChildren()) do
                if ValidItem(instance) then
                    PickupItem(instance)
                end
            end
            
            if droppedOres then
                for _, instance in ipairs(droppedOres:GetChildren()) do
                    if ValidItem(instance) then
                        PickupItem(instance)
                    end
                end
            end
        else
            Notify("Stopped Advanced Magnet", "Advanced Magnet has been disabled, script will no longer pick up items.")
            if advancedMagnetConn1 and typeof(advancedMagnetConn1) == "RBXScriptConnection" then
                advancedMagnetConn1:Disconnect()
                advancedMagnetConn1 = nil
            end
            
            if advancedMagnetConn2 and typeof(advancedMagnetConn2) == "RBXScriptConnection" then
                advancedMagnetConn2:Disconnect()
                advancedMagnetConn2 = nil
            end
        end
    end)
end

local function FreezeCharacter(boolean)
    if boolean then
        hrp.Anchored = true
        Notify("Character Froze", "Your character has been frozen, you will now be unable to move and be unable to be moved.")
    else
        hrp.Anchored = false
        Notify("Character Unfroze", "Your character has been unfrozen, you will now be able to move and be able to be moved.")
    end
end

local function UseMedkit(debug)
    local oldTool = char:FindFirstChildWhichIsA("Tool")
    
    if oldTool then
        oldTool.Parent = backpack
    end
    
    local medkit = backpack:FindFirstChild("Medkit")
    
    SpawnItem("Medkit", 1, true)
    
    if not medkit or not medkit:IsA("Tool") then
        medkit = backpack:WaitForChild("Medkit")
    end
    
    if not medkit or not medkit:IsA("Tool") then
        if debug then
            warn("Medkit not found in backpack when call function: UseMedkit")
        return
        end
    end
    
    medkit.Parent = char
    
    char.ChildAdded:Once(function(child)
        if child == medkit then
            child:Activate()
            task.wait()
            child.Parent = backpack
            
            if oldTool and oldTool.Parent == backpack then
                oldTool.Parent = char
            end
        end
    end)
end

local autoHealConn

local function AutoHeal(boolean)
    if boolean then
        Notify("Auto Heal Enabled", "Auto Heal has been enabled, script will now automatically heal when you are low.")
        local health = humanoid.Health
        if health <= 70 then
            UseMedkit()
        end
        
        autoHealConn = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if humanoid.Health <= 70 then
                UseMedkit()
            end
        end)
    else
        Notify("Auto Heal Disabled", "Auto Heal has been disabled, script no longer heal when you are low.")
        if autoHealConn and typeof(autoHealConn) == "RBXScriptConnection" then
            autoHealConn:Disconnect()
            autoHealConn = nil
        end
    end
end

local function PlantAccelerator(boolean)
    local requiredFunctions = {
        "setreadonly",
        "getrawmetatable",
        "hookmetamethod",
        "getnamecallmethod",
        "checkcaller"
    }
    
    for _, func in ipairs(requiredFunctions) do
        if not func then
            return Notify("Incompatible Executor", "Your executor doesnt support this command (missing " .. func .. " )")
        end
    end
    
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local originalNamecall = mt.__namecall 
    setreadonly(mt, true)
    
    if boolean then
        Notify("Plant Accelerator Enabled", "Plant Accelerator has been enabled, plants will now grow at extreme speeds.")
        local FarmSeeds_PlantRF = rs:WaitForChild("FarmSeeds_PlantRF")
        local namecall; namecall = hookmetamethod(game, "__namecall", function(self, ...)
            local args = {...}
            local method = getnamecallmethod()
            
            if not checkcaller() and self == FarmSeeds_PlantRF and method == "InvokeServer" then
                args[3] = 0.5
                return namecall(self, unpack(args))
            end
            
            return namecall(self, ...) 
        end)
    else
        Notify("Plants Accelerator Disabled", "Plant Accelerator has been disabled, plants will no longer grow at extreme speeds.")
        setreadonly(mt, false)
        mt.__namecall = originalNamecall
        setreadonly(mt, true)
    end
end

local spawnMoneyBlocksValue = false

local function SpawnMoneyBlocks(boolean)
    task.spawn(function()
        spawnMoneyBlocksValue = boolean
        if spawnMoneyBlocksValue then
            Notify("Started Spawn Money Blocks", "Spawn Money Blocks has been enabled, script will now start spawning blocks with money.")
            while spawnMoneyBlocksValue do
                rs:WaitForChild("Tutorial_MagnetActivated"):FireServer()
                task.wait(1)
            end
        else
            Notify("Stopped Spawn Money Blocks", "Spawn Money Blocks has been disabled, script will no longer spawn blocks with money.")
        end
    end)
end

--// Remote Wrapper
local function PlaceBlock(block, X, Y, Z, key, type)
    local args = {
	    block,
	    X,
	    Y,
	    Z,
	    0,
	    type or "adjacent",
	    {
		    anchorJ = 0,
		    platformKey = "1|1|0",
		    anchorI = 0
	    }
    }
    rs:WaitForChild("Remotes"):WaitForChild("PlaceCube"):FireServer(unpack(args))
    task.wait(0.1)
end

local function GenerateFurnaceBase()
    SpawnItem("Grass Platform", 10, true)
    SpawnItem("Oak Platform", 28, true)
    SpawnItem("Oak Block", 24, true)
    SpawnItem("Drill", 4, true)
    SpawnItem("Farm Plot", 10, true)
    SpawnItem("Blackstone Block", 18, true)
    SpawnItem("Blackstone Slab", 56, true)
    SpawnItem("Orange Glass", 4, true)
    if true then
        return Notify("This feature isnt finished yet!")
    end
    PlaceBlock("BlackstoneBlock", 2, 1, -1, "platform")
    PlaceBlock("BlackstoneBlock", 1, 1, -2, "platform")
    PlaceBlock("BlackstoneBlock", -1, 1, -2, "platform")
    PlaceBlock("BlackstoneBlock", -2, 1, -1, "platform")
    PlaceBlock("BlackstoneBlock", -2, 1, 1, "platform")
    PlaceBlock("BlackstoneBlock", -1, 1, 2, "platform")
    PlaceBlock("BlackstoneBlock", 1, 1, 2, "platform")
    PlaceBlock("BlackstoneBlock", 2, 1, 1, "platform")
    PlaceBlock("BlackstoneSlab", 2, 2, 1)
    PlaceBlock("BlackstoneSlab", 2, 2, 0)
    PlaceBlock("BlackstoneSlab", 2, 2, -1)
end

--// UI
local oldUI = guiParent:FindFirstChild("Item Spawner Peteware")
if oldUI then 
    oldUI:Destroy()
end

local mainUI = Instance.new("ScreenGui")
mainUI.Name = "Item Spawner Peteware"
mainUI.ResetOnSpawn = false
mainUI.Parent = guiParent

local searchFrame = Instance.new("Frame")
searchFrame.Name = "searchFrame"
searchFrame.AnchorPoint = Vector2.new(0.5, 0.5)
searchFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
searchFrame.Size = UDim2.new(0, 480, 0, 0)
searchFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
searchFrame.BackgroundTransparency = 0.35
searchFrame.BorderSizePixel = 0
searchFrame.Visible = false
searchFrame.ZIndex = 2
searchFrame.Parent = mainUI

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(61, 116, 198))
})
gradient.Offset = Vector2.new(0, 2)
gradient.Rotation = 80
gradient.Parent = searchFrame

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 6)
frameCorner.Parent = searchFrame

local frameShadow = Instance.new("ImageLabel")
frameShadow.Name = "frameShadow"
frameShadow.BackgroundTransparency = 1
frameShadow.ZIndex = 1
frameShadow.Image = "rbxassetid://3523728077"
frameShadow.ScaleType = Enum.ScaleType.Slice
frameShadow.SliceCenter = Rect.new(10, 10, 118, 118)
frameShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
frameShadow.ImageTransparency = 0.7
frameShadow.Size = UDim2.new(1, 30, 1, 30)
frameShadow.Position = UDim2.new(0, -15, 0, -15)
frameShadow.Parent = searchFrame

local searchIcon = Instance.new("ImageLabel")
searchIcon.Name = "searchIcon"
searchIcon.Image = "rbxassetid://3605509925"
searchIcon.ImageColor3 = Color3.fromRGB(150, 150, 150)
searchIcon.ImageTransparency = 1
searchIcon.BackgroundTransparency = 1
searchIcon.Size = UDim2.new(0, 24, 0, 24)
searchIcon.Position = UDim2.new(0.04, 0, 0.5, -12)
searchIcon.ZIndex = 3
searchIcon.Parent = searchFrame

local searchBox = Instance.new("TextBox")
searchBox.Name = "searchBox"
searchBox.AnchorPoint = Vector2.new(0, 0.5)
searchBox.Position = UDim2.new(0.12, 0, 0.5, 0)
searchBox.Size = UDim2.new(0.85, 0, 1, 0)
searchBox.BackgroundTransparency = 1
searchBox.TextTransparency = 1
searchBox.PlaceholderText = "Search for items..."
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
searchBox.Font = Enum.Font.GothamSemibold
searchBox.TextSize = 16
searchBox.ZIndex = 3
searchBox.Parent = searchFrame

local resultsFrame = Instance.new("ScrollingFrame")
resultsFrame.Name = "resultsFrame"
resultsFrame.Size = UDim2.new(1, -10, 0, 200)
resultsFrame.Position = UDim2.new(0, 5, 1, 5)
resultsFrame.BackgroundTransparency = 1
resultsFrame.BorderSizePixel = 0
resultsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
resultsFrame.ScrollBarThickness = 6
resultsFrame.Parent = searchFrame

local resultsLayout = Instance.new("UIListLayout")
resultsLayout.SortOrder = Enum.SortOrder.LayoutOrder
resultsLayout.Padding = UDim.new(0, 3)
resultsLayout.Parent = resultsFrame

local allItems = {}
for _, categoryItems in pairs(commandData) do
    for _, itemName in ipairs(categoryItems) do
        table.insert(allItems, itemName)
    end
end

local function ParseItemInput(text)
    local name, quantity = text:match("^(.+)%s+x(%d+)$")
    if name then
        return name, tonumber(quantity)
    end

    name, quantity = text:match("^(.+)%s+(%d+)$")
    if name then
        return name, tonumber(quantity)
    end

    return text, 1
end

local function ParseCommandInput(text)
    text = text:match("^%s*(.-)%s*$") 
    local cmdName, arg = text:match("^(%S+)%s*(.*)$")
    return cmdName, arg ~= "" and arg or nil
end

local function HandleInput(text)
    local cmdName, cmdArg = ParseCommandInput(text)

    if commandData.CustomCommands then
        for _, command in ipairs(commandData.CustomCommands) do
            if command:lower():find(cmdName:lower()) then
                if command == "UnlockBlueprints" then
                    UnlockBlueprints()
                    return
                elseif command == "ScareServer" then
                    if not cmdArg then
                        Notify("Error: No Argument Provided", "ScareServer requires a boolean argument such as 'true' or 'false'.")
                        return
                    end
                    cmdArg = toboolean(cmdArg)
                    if typeof(cmdArg) ~= "boolean" then
                        Notify("Error: Invalid Argument", "ScareServer requires a boolean argument such as 'true' or 'false'.")
                        return
                    end
                    ScareServer(cmdArg)
                    return
                elseif command == "FreezeCharacter" then
                    if not cmdArg then
                        Notify("Error: No Argument Provided", "FreezeCharacter requires a boolean argument such as 'true' or 'false'.")
                        return
                    end
                    cmdArg = toboolean(cmdArg)
                    if typeof(cmdArg) ~= "boolean" then
                        Notify("Error: Invalid Argument", "FreezeCharacter requires a boolean argument such as 'true' or 'false'.")
                        return
                    end
                    FreezeCharacter(cmdArg)
                    return
                elseif command == "AutoHeal" then
                    if not cmdArg then
                        Notify("Error: No Argument Provided", "AutoHeal requires a boolean argument such as 'true' or 'false'.")
                        return
                    end
                    cmdArg = toboolean(cmdArg)
                    if typeof(cmdArg) ~= "boolean" then
                        Notify("Error: Invalid Argument", "AutoHeal requires a boolean argument such as 'true' or 'false'.")
                        return
                    end
                    AutoHeal(cmdArg)
                    return
                elseif command == "PlantAccelerator" then
                    if not cmdArg then
                        Notify("Error: No Argument Provided", "PlantAccelerator requires a boolean argument such as 'true' or 'false'.")
                        return
                    end
                    cmdArg = toboolean(cmdArg)
                    if typeof(cmdArg) ~= "boolean" then
                        Notify("Error: Invalid Argument", "PlantAccelerator requires a boolean argument such as 'true' or 'false'.")
                        return
                    end
                    PlantAccelerator(cmdArg)
                    return
                elseif command == "SpawnMoneyBlocks" then
                    if not cmdArg then
                        Notify("Error: No Argument Provided", "SpawnMoneyBlocks requires a boolean argument such as 'true' or 'false'.")
                        return
                    end
                    cmdArg = toboolean(cmdArg)
                    if typeof(cmdArg) ~= "boolean" then
                        Notify("Error: Invalid Argument", "SpawnMoneyBlocks requires a boolean argument such as 'true' or 'false'.")
                        return
                    end
                    SpawnMoneyBlocks(cmdArg)
                    return
                elseif command == "SendAnnouncement" then
                    if not cmdArg then
                        Notify("Error: No Argument Provided", "SendAnnouncement requires a message argument.")
                        return
                    end
                    SendAnnouncement(cmdArg)
                    return
                elseif command == "AutoMine" then
                    if not cmdArg then
                        Notify("Error: No Argument Provided", "AutoMine requires a boolean argument such as 'true' or 'false'.")
                        return
                    end
                    cmdArg = toboolean(cmdArg)
                    if typeof(cmdArg) ~= "boolean" then
                        Notify("Error: Invalid Argument", "AutoMine requires a boolean argument such as 'true' or 'false'.")
                        return
                    end
                    AutoMine(cmdArg)
                    return
                elseif command == "AdvancedMagnet" then
                    if not cmdArg then
                        Notify("Error: No Argument Provided", "AdvancedMagnet requires a boolean argument such as 'true' or 'false'.")
                        return
                    end
                    cmdArg = toboolean(cmdArg)
                    if typeof(cmdArg) ~= "boolean" then
                        Notify("Error: Invalid Argument", "AdvancedMagnet requires a boolean argument such as 'true' or 'false'.")
                        return
                    end
                    AdvancedMagnet(cmdArg)
                    return
                elseif command == "GenerateFurnaceBase" then
                    GenerateFurnaceBase()
                    return
                end
            end
        end
    end

    local itemName, quantity = ParseItemInput(text)
    for _, name in ipairs(allItems) do
        if name:lower():find(itemName:lower()) then
            SpawnItem(name, quantity)
            return
        end
    end

    Notify("Error: Not Found", "No item or command matched: " .. text)
end

local function GetFilteredItems(query)
    local filteredItems = {}
    for _, itemName in ipairs(allItems) do
        local isCommand = false
        if commandData.CustomCommands then
            for _, cmdName in ipairs(commandData.CustomCommands) do
                if itemName == cmdName then
                    isCommand = true
                    break
                end
            end
        end
        if not isCommand and itemName:lower():find(query:lower()) then
            table.insert(filteredItems, itemName)
        end
    end
    return filteredItems
end

local function GetFilteredCommands(query)
    local filteredCommands = {}
    
    for _, commandName in ipairs(commandData.CustomCommands) do
        if commandName:lower():find(query:lower()) then
            table.insert(filteredCommands, commandName)
        end
    end
    
    return filteredCommands
end

local function UpdateResults(query)
    for _, child in ipairs(resultsFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    if query == "" then
        resultsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        return
    end

    local yOffset = 0
    local filteredItems = GetFilteredItems(query)
    local filteredCommands = GetFilteredCommands(query)

    table.sort(filteredItems, function(a, b) return a:lower() < b:lower() end)
    table.sort(filteredCommands, function(a, b) return a:lower() < b:lower() end)

    for _, commandName in ipairs(filteredCommands) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -10, 0, 30)
        button.Position = UDim2.new(0, 5, 0, yOffset)
        button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Font = Enum.Font.GothamSemibold
        button.TextSize = 15
        if commandName == "SendAnnouncement" then
            button.Text = commandName .. " [Message]"
        elseif commandName == "ScareServer" or commandName == "AutoMine" or commandName == "AdvancedMagnet" or commandName == "FreezeCharacter" or commandName == "AutoHeal" or commandName == "PlantAccelerator" or commandName == "SpawnMoneyBlocks" then
            button.Text = commandName .. " [Value]"
        else
            button.Text = commandName
        end
        button.AutoButtonColor = false
        button.Parent = resultsFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = button

        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 120, 200))
        })
        gradient.Rotation = 90
        gradient.Parent = button

        button.MouseEnter:Connect(function()
            tweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
        end)
        button.MouseLeave:Connect(function()
            tweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}):Play()
        end)

        button.MouseButton1Click:Connect(function()
            local cleanText = button.Text:gsub("%s*%[.*%]$", "")
            task.delay(0.1, CloseSearch)
            HandleInput(cleanText)
        end)

        yOffset = yOffset + 35
    end

    for _, itemName in ipairs(filteredItems) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -10, 0, 30)
        button.Position = UDim2.new(0, 5, 0, yOffset)
        button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Font = Enum.Font.GothamSemibold
        button.TextSize = 15
        button.Text = itemName .. " [Amount]"
        button.AutoButtonColor = false
        button.Parent = resultsFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = button

        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 120, 200))
        })
        gradient.Rotation = 90
        gradient.Parent = button

        button.MouseEnter:Connect(function()
            tweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
        end)
        button.MouseLeave:Connect(function()
            tweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}):Play()
        end)

        button.MouseButton1Click:Connect(function()
            local cleanText = button.Text:gsub("%s*%[.*%]$", "")
            task.delay(0.1, CloseSearch)
            HandleInput(cleanText)
        end)

        yOffset = yOffset + 35
    end

    resultsFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    UpdateResults(searchBox.Text)
end)

local debounce = false

local function OpenSearch()
    if debounce or searchFrame.Visible then 
        return 
    end
    
    debounce = true
    searchFrame.Visible = true
    searchBox.Text = ""
    tweenService:Create(searchFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 580, 0, 43),
        BackgroundTransparency = 0.1
    }):Play()
    tweenService:Create(searchIcon, TweenInfo.new(0.4), {ImageTransparency = 0}):Play()
    tweenService:Create(searchBox, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
    task.wait(0.4)
    searchBox:CaptureFocus()
    debounce = false
end

local function CloseSearch()
    if debounce or not searchFrame.Visible then 
        return 
    end
    
    debounce = true
    searchBox:ReleaseFocus()

    for _, child in ipairs(resultsFrame:GetChildren()) do
        if child:IsA("TextButton") then
            tweenService:Create(child, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                BackgroundTransparency = 1,
                TextTransparency = 1,
                Size = UDim2.new(1, -10, 0, 0)
            }):Play()
        end
    end

    tweenService:Create(resultsFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
        CanvasSize = UDim2.new(0, 0, 0, 0)
    }):Play()

    tweenService:Create(searchFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {
        Size = UDim2.new(0, 480, 0, 0),
        BackgroundTransparency = 0.35
    }):Play()
    tweenService:Create(searchIcon, TweenInfo.new(0.3), {ImageTransparency = 1}):Play()
    tweenService:Create(searchBox, TweenInfo.new(0.3), {TextTransparency = 1}):Play()

    task.wait(0.4)

    for _, child in ipairs(resultsFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    searchFrame.Visible = false
    debounce = false
end

searchBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local firstResult = resultsFrame:FindFirstChildWhichIsA("TextButton")
        if firstResult then
            local cleanText = firstResult.Text:gsub("%s*%[.*%]$", "")
            task.delay(0.1, CloseSearch)
            HandleInput(cleanText)
        elseif searchBox.Text ~= "" then
            task.delay(0.1, CloseSearch)
            HandleInput(searchBox.Text)
        end
    else
        CloseSearch()
    end
end)

uis.InputBegan:Connect(function(input, processed)
	if searchBox:IsFocused() then
		return
	end

	if input.KeyCode == Enum.KeyCode.T and not processed and not debounce then
		if searchFrame.Visible then
			CloseSearch()
		else
			OpenSearch()
		end
	end
end)

if device == "PC" then
    Notify("Item Spawner Loaded.", "To open and use the item spawner, please press T then search the item you are looking for in the format 'ItemName Amount' or 'ItemName xAmount' or just 'ItemName' if you only want 1.")
else
    local toggleButton = Instance.new("ImageButton")
    toggleButton.Name = "SearchToggleButton"
    toggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
    toggleButton.Position = UDim2.new(0.5, 8, 0, 0)
    toggleButton.Size = UDim2.new(0, 40, 0, 40)
    toggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    toggleButton.BackgroundTransparency = 0.35
    toggleButton.BorderSizePixel = 0
    toggleButton.Image = "rbxassetid://3605509925"
    toggleButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.ZIndex = 4
    toggleButton.Parent = mainUI

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = toggleButton

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 120, 200))
    })
    gradient.Rotation = 90
    gradient.Parent = toggleButton

    local debounceButton = false
    toggleButton.MouseButton1Click:Connect(function()
        if debounceButton then return end
        debounceButton = true
        if searchFrame.Visible then
            CloseSearch()
        else
            OpenSearch()
        end
        task.wait(0.3)
        debounceButton = false
    end)

    Notify("Item Spawner Loaded.", "To open and use the item spawner, please press the magnification button then search the item you are looking for in the format 'ItemName xAmount' or just 'ItemName' if you only want 1.")
end
