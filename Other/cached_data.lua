--// Cached Data Module
local cloneref = cloneref or function(...)
    return ...
end

local httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
local setclip = setclipboard or (syn and syn.setclipboard) or (Clipboard and Clipboard.set)

local http_service = cloneref(game:GetService("HttpService"))
local uis = cloneref(game:GetService("UserInputService"))

--// Dynamic Values
local user_device    
if not uis.MouseEnabled and not uis.KeyboardEnabled and uis.TouchEnabled then
    user_device = "Mobile"
elseif uis.MouseEnabled and uis.KeyboardEnabled and not uis.TouchEnabled then
    user_device = "PC"
end

--// Fixed Values
local discord_invite_code = "/GSpmjtMSVA"
local discord_invite_url = "https://discord.com/invite/" .. discord_invite_code

local cached_data; cached_data = {
    main_loader_url = "https://raw.githubusercontent.com/petewar3/Peteware/refs/heads/main/Loader.lua",
    user_device = user_device,
    discord_invite_code = "/GSpmjtMSVA",
    discord_invite_url = discord_invite_url,
    JoinDiscord = function(self)
        setclip(self.discord_invite_url)

        if httprequest and self.user_device == "PC" then
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
                        args = { 
                            code = self.discord_invite_code
                        }
                    })
                })
            end)
        end
    end
}

return cached_data
