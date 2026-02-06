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
local discord_invite_code = "rm9SQaNJ5m"
local discord_invite_url = "https://discord.com/invite/" .. discord_invite_code

local cached_data; cached_data = {
    main_loader_url = "https://api.luarmor.net/files/v4/loaders/2813836d650c6fc88ba179fd86254d25.lua",
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
