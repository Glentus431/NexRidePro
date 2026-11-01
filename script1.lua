
-- NEXRIDE AUTO SNIPER V4
-- Delta iPhone - experimental screen tapper
-- Uses visible GUI elements, not purchase remotes

local Players = game:GetService("Players")
local VIM = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

if _G.NexRideStop then
    _G.NexRideStop()
end

local alive = true
local enabled = false
local busy = false
local attempts = 0
local token = 0

local gui = Instance.new("ScreenGui")
gui.Name = "NexRideSniperV4"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = pg

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(290, 335)
frame.Position = UDim2.new(0.5,-145,0.2,0)
frame.BackgroundColor3 = Color3.fromRGB(22,25,35)
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local function round(o)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,10)
    c.Parent = o
end
round(frame)

local function label(s,y,h)
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1,-20,0,h)
    t.Position = UDim2.fromOffset(10,y)
    t.BackgroundTransparency = 1
    t.TextColor3 = Color3.new(1,1,1)
    t.TextScaled = true
    t.TextWrapped = true
    t.Text = s
    t.Parent = frame
    return t
end

label("NEXRIDE AUTO SNIPER V4",10,30)

local function input(s,y)
    local b = Instance.new("TextBox")
    b.Size = UDim2.new(1,-30,0,38)
    b.Position = UDim2.fromOffset(15,y)
    b.BackgroundColor3 = Color3.fromRGB(42,46,60)
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = s
    b.ClearTextOnFocus = false
    b.Parent = frame
    round(b)
    return b
end

local minimum = input("1000",50)
local maximum = input("12000",95)
local delayBox = input("0.5",140)

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(1,-30,0,46)
toggle.Position = UDim2.fromOffset(15,190)
toggle.BackgroundColor3 = Color3.fromRGB(30,160,85)
toggle.TextColor3 = Color3.new(1,1,1)
toggle.TextScaled = true
toggle.Text = "START AUTO BUYER"
toggle.Parent = frame
round(toggle)

local status = label("Status: OFF",245,30)
local priceLabel = label("Cheapest: --",278,25)
local countLabel = label("Attempts: 0",307,20)

local function active(o)
    if not o or not o:IsA("GuiObject") then
        return false
    end

    if o:IsDescendantOf(gui) then
        return false
    end

    local p = o
    while p and p ~= pg do
        if p:IsA("GuiObject") and not p.Visible then
            return false
        end
        p = p.Parent
    end

    return o.AbsoluteSize.X > 0
       and o.AbsoluteSize.Y > 0
end

local function tap(o)
    if not active(o) then return false end

    local p = o.AbsolutePosition
    local s = o.AbsoluteSize
    local x = p.X + s.X/2
    local y = p.Y + s.Y/2

    local ok = pcall(function()
        VIM:SendMouseButtonEvent(
            x,y,0,true,game,0
        )
        task.wait(0.04)
        VIM:SendMouseButtonEvent(
            x,y,0,false,game,0
        )
    end)

    if not ok then
        status.Text = "Screen taps unsupported"
    end

    return ok
end

local function textObjects()
    local result = {}

    for _,o in ipairs(pg:GetDescendants()) do
        if (o:IsA("TextLabel")
            or o:IsA("TextButton"))
            and active(o) then
            table.insert(result,o)
        end
    end

    return result
end

local function findText(word)
    word = word:lower()

    for _,o in ipairs(textObjects()) do
        if o.Text:lower() == word then
            return o
        end
    end
end

local function findBuy()
    for _,o in ipairs(textObjects()) do
        if o.Text:lower():find("buy for",1,true) then
            return o
        end
    end
end

local function parsePrice(s)
    local n = s:match("%$([%d,]+)")
    if not n then return nil end
    return tonumber((n:gsub(",","")))
end

local function findCheapest(lo,hi)
    local best = nil

    for _,o in ipairs(textObjects()) do
        local n = parsePrice(o.Text)

        if n and n >= lo and n <= hi then
            -- Ignore buttons displaying purchase totals
            if not o.Text:lower():find("buy") then
                if not best or n < best.price then
                    best = {
                        price = n,
                        object = o
                    }
                end
            end
        end
    end

    return best
end

local function findCard(o)
    local p = o.Parent

    for i=1,5 do
        if not p then break end

        if p:IsA("GuiButton") and active(p) then
            return p
        end

        for _,child in ipairs(p:GetDescendants()) do
            if child:IsA("GuiButton")
                and active(child) then
                return child
            end
        end

        p = p.Parent
    end

    return nil
end

local function refresh()
    status.Text = "Refreshing..."

    local electric = findText("Electric")
    if not electric then
        status.Text = "Electric tab not found"
        return false
    end

    if not tap(electric) then return false end
    task.wait(0.15)

    local all = findText("All")
    if not all then
        status.Text = "All tab not found"
        return false
    end

    if not tap(all) then return false end
    task.wait(0.15)

    return true
end

local function purchase(candidate,lo,hi,id)
    if not enabled or token ~= id then return end

    busy = true
    status.Text = "Opening cheapest bike..."

    local card = findCard(candidate.object)

    if not card or not tap(card) then
        status.Text = "Cannot open bike card"
        busy = false
        return
    end

    task.wait(0.2)
    if not enabled or token ~= id then
        busy = false
        return
    end

    local buy = findBuy()
    local displayed = buy and parsePrice(buy.Text)

    -- Never buy if the displayed price differs
    if not displayed
        or displayed ~= candidate.price
        or displayed < lo
        or displayed > hi then

        status.Text = "Price verification failed"
        busy = false
        return
    end

    status.Text = "Opening confirmation..."

    if not tap(buy) then
        busy = false
        return
    end

    task.wait(0.2)

    if not enabled or token ~= id then
        busy = false
        return
    end

    local confirm = findBuy()
    local finalPrice = confirm
        and parsePrice(confirm.Text)

    if finalPrice ~= displayed then
        status.Text = "Confirmation price mismatch"
        busy = false
        return
    end

    if tap(confirm) then
        attempts += 1
        countLabel.Text = "Attempts: "..attempts
        status.Text = "Purchase attempted"
    end

    task.wait(0.4)
    busy = false
end

local function stop()
    enabled = false
    token += 1
    toggle.Text = "START AUTO BUYER"
    toggle.BackgroundColor3 =
        Color3.fromRGB(30,160,85)
    status.Text = "Status: OFF"
end

toggle.MouseButton1Click:Connect(function()
    if enabled then
        stop()
        return
    end

    local lo = tonumber(minimum.Text)
    local hi = tonumber(maximum.Text)
    local interval = tonumber(delayBox.Text)

    if not lo or not hi or lo < 0
        or lo > hi or not interval
        or interval < 0.2 then
        status.Text = "Invalid settings"
        return
    end

    enabled = true
    token += 1
    local id = token

    toggle.Text = "STOP AUTO BUYER"
    toggle.BackgroundColor3 =
        Color3.fromRGB(200,55,65)

    task.spawn(function()
        while alive and enabled and token == id do
            if not busy then
                status.Text = "Scanning All..."

                local candidate = findCheapest(lo,hi)

                if candidate then
                    priceLabel.Text =
                        "Detected: $"..candidate.price

                    purchase(candidate,lo,hi,id)
                else
                    priceLabel.Text = "Cheapest: --"
                    refresh()
                end
            end

            task.wait(interval)
        end
    end)
end)

_G.NexRideStop = function()
    alive = false
    stop()
    gui:Destroy()
end
