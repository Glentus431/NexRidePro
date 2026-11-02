
-- NEXRIDE V11 MARKET SCANNER
-- Main file: script.lua
-- Safe diagnostic mode: no purchases or taps

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

if type(_G.NexRideStop) == "function" then
    pcall(_G.NexRideStop)
end

local old = pg:FindFirstChild("NexV11")
if old then old:Destroy() end

local running = false
local generation = 0

local gui = Instance.new("ScreenGui")
gui.Name = "NexV11"
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000
gui.Parent = pg

local function make(class, parent, props)
    local o = Instance.new(class)
    for k, v in pairs(props) do
        o[k] = v
    end
    o.Parent = parent
    return o
end

local panel = make("Frame", gui, {
    Size = UDim2.fromOffset(320, 330),
    Position = UDim2.new(.3, 0, .15, 0),
    BackgroundColor3 = Color3.fromRGB(18, 24, 37),
    Active = true,
    Draggable = true
})

make("UICorner", panel, {
    CornerRadius = UDim.new(0, 12)
})

local function label(text, y, h, size)
    return make("TextLabel", panel, {
        Position = UDim2.fromOffset(12, y),
        Size = UDim2.new(1, -24, 0, h),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = size or 13,
        Font = Enum.Font.GothamMedium,
        TextWrapped = true
    })
end

label("NEXRIDE MARKET SCANNER V11", 10, 35, 19)
label("NO PURCHASES / NO SHOP TAPS", 45, 20, 12)

local toggle = make("TextButton", panel, {
    Position = UDim2.fromOffset(15, 78),
    Size = UDim2.new(1, -30, 0, 48),
    BackgroundColor3 = Color3.fromRGB(30, 165, 100),
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    Text = "START SCANNING"
})

make("UICorner", toggle, {
    CornerRadius = UDim.new(0, 9)
})

local status = label("Status: OFF", 140, 30, 14)
local market = label("Market: Unknown", 172, 25, 13)
local prices = label("Prices found: 0", 199, 25, 13)
local cheapest = label("Cheapest: --", 226, 30, 16)
local details = label("Waiting for scan", 260, 55, 12)

local function textOf(o)
    if o:IsA("TextLabel")
        or o:IsA("TextButton")
        or o:IsA("TextBox") then
        return o.Text
    end
    return ""
end

local function isVisible(o)
    if not o:IsA("GuiObject")
        or o:IsDescendantOf(gui) then
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

local function scan()
    local marketFound = false
    local priceList = {}
    local sourceNames = {}

    for _, o in ipairs(pg:GetDescendants()) do
        if isVisible(o) then
            local text = textOf(o)
            local lower = text:lower()

            if lower:find("nexmarket", 1, true) then
                marketFound = true
            end

            local raw = text:match("%$%s*([%d,]+)")

            if raw then
                local n = tonumber(
                    (raw:gsub(",", ""))
                )

                if n then
                    table.insert(priceList, n)
                    table.insert(
                        sourceNames,
                        o:GetFullName()
                    )
                end
            end
        end
    end

    table.sort(priceList)

    market.Text =
        "Market: " ..
        (marketFound and "Detected" or "Not found")

    prices.Text =
        "Prices found: " .. #priceList

    if #priceList > 0 then
        cheapest.Text =
            "Lowest GUI price: $" .. priceList[1]
    else
        cheapest.Text = "Cheapest: --"
    end

    details.Text =
        marketFound
        and "NexMarket title is accessible"
        or "NexMarket title not found in PlayerGui"

    return marketFound, #priceList
end

local function stop()
    running = false
    generation += 1

    toggle.Text = "START SCANNING"
    toggle.BackgroundColor3 =
        Color3.fromRGB(30, 165, 100)

    status.Text = "Status: OFF"
end

toggle.MouseButton1Click:Connect(function()
    if running then
        stop()
        return
    end

    running = true
    generation += 1
    local id = generation

    toggle.Text = "STOP SCANNING"
    toggle.BackgroundColor3 =
        Color3.fromRGB(205, 60, 75)

    task.spawn(function()
        while running and generation == id do
            status.Text = "Status: Scanning"

            local ok, err = pcall(scan)

            if not ok then
                details.Text =
                    tostring(err):sub(1, 75)
            end

            task.wait(0.5)
        end
    end)
end)

_G.NexRideStop = function()
    stop()
    gui:Destroy()
end
