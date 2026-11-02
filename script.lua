
-- NEXRIDE AUTO BUYER V10
-- Main file: script.lua
-- Continuous scanning / ON-OFF
-- Cheapest qualifying visible listing
-- No Shop or top-row clicks
-- Experimental: NexRide UI may change

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local Camera = workspace.CurrentCamera

local pg = Players.LocalPlayer:WaitForChild("PlayerGui")

if type(_G.NexRideStop) == "function" then
    pcall(_G.NexRideStop)
end

for _, name in ipairs({
    "NexSniperV5",
    "NexSniperV6",
    "NexSniperV7",
    "NexSniperV9",
    "NexSniperV10"
}) do
    local old = pg:FindFirstChild(name)
    if old then old:Destroy() end
end

local running = false
local generation = 0
local scanCount = 0
local attempted = false

local SCAN_DELAY = 0.35
local REFRESH_DELAY = 0.4

local gui = Instance.new("ScreenGui")
gui.Name = "NexSniperV10"
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000
gui.Parent = pg

local function make(class, parent, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local panel = make("Frame", gui, {
    Size = UDim2.fromOffset(310, 365),
    Position = UDim2.new(0.25, 0, 0.15, 0),
    BackgroundColor3 = Color3.fromRGB(17, 23, 36),
    Active = true,
    Draggable = true
})

make("UICorner", panel, {
    CornerRadius = UDim.new(0, 13)
})

local function label(text, y, height, size)
    return make("TextLabel", panel, {
        Position = UDim2.fromOffset(12, y),
        Size = UDim2.new(1, -24, 0, height),
        BackgroundTransparency = 1,
        Text = text,
        TextSize = size or 13,
        TextWrapped = true,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamMedium
    })
end

label("NEXRIDE AUTO BUYER V10", 8, 32, 20)
label("CHEAPEST PRICE • AUTO REFRESH", 41, 19, 11)

local function field(title, y, value)
    label(title, y, 19, 12)

    local box = make("TextBox", panel, {
        Position = UDim2.fromOffset(15, y + 20),
        Size = UDim2.new(1, -30, 0, 36),
        BackgroundColor3 = Color3.fromRGB(39, 47, 67),
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 17,
        Text = value,
        ClearTextOnFocus = false
    })

    make("UICorner", box, {
        CornerRadius = UDim.new(0, 8)
    })

    return box
end

local minBox = field("MINIMUM PRICE", 66, "1000")
local maxBox = field("MAXIMUM PRICE", 126, "11500")

local toggle = make("TextButton", panel, {
    Position = UDim2.fromOffset(15, 190),
    Size = UDim2.new(1, -30, 0, 47),
    Text = "START AUTO BUYER",
    TextSize = 17,
    Font = Enum.Font.GothamBold,
    TextColor3 = Color3.new(1, 1, 1),
    BackgroundColor3 = Color3.fromRGB(25, 165, 100)
})

make("UICorner", toggle, {
    CornerRadius = UDim.new(0, 9)
})

local status = label("Status: OFF", 246, 29, 13)
local foundLabel = label("Listings detected: 0", 275, 22, 13)
local cheapestLabel = label("Cheapest: --", 298, 23, 14)
local scanLabel = label("Checks: 0", 324, 20, 12)
local detailLabel = label("Open NexMarket > Browse > All", 345, 18, 11)

local function statusText(s)
    status.Text = "Status: " .. s
end

local function stop(reason)
    running = false
    generation += 1

    toggle.Text = "START AUTO BUYER"
    toggle.BackgroundColor3 =
        Color3.fromRGB(25, 165, 100)

    statusText(reason or "OFF")
end

local function active(id)
    return running
        and generation == id
        and gui.Parent ~= nil
end

local function pause(seconds, id)
    local finish = os.clock() + seconds

    while os.clock() < finish do
        if not active(id) then
            return false
        end
        task.wait(0.03)
    end

    return active(id)
end

local function visible(obj)
    if not obj or not obj:IsA("GuiObject")
        or obj:IsDescendantOf(gui) then
        return false
    end

    local current = obj

    while current and current ~= pg do
        if current:IsA("GuiObject")
            and not current.Visible then
            return false
        end

        current = current.Parent
    end

    return obj.AbsoluteSize.X > 0
        and obj.AbsoluteSize.Y > 0
end

local function textOf(obj)
    if obj:IsA("TextLabel")
        or obj:IsA("TextButton")
        or obj:IsA("TextBox") then
        return obj.Text
    end

    return ""
end

local function priceOf(s)
    local raw = s:match("%$%s*([%d,]+)")
    if not raw then return nil end
    return tonumber((raw:gsub(",", "")))
end

local function center(obj)
    local p = obj.AbsolutePosition
    local s = obj.AbsoluteSize

    return p.X + s.X / 2,
           p.Y + s.Y / 2
end

local function within(obj, x, y)
    local p = obj.AbsolutePosition
    local s = obj.AbsoluteSize

    return x >= p.X
        and x <= p.X + s.X
        and y >= p.Y
        and y <= p.Y + s.Y
end

local function screen()
    local v = Camera.ViewportSize
    return v.X, v.Y
end

-- Locate the phone from NexMarket's visible text.
-- This avoids scanning the rest of the Roblox UI.

local function findPhone()
    local candidates = {}

    for _, obj in ipairs(pg:GetDescendants()) do
        if visible(obj)
            and textOf(obj):upper():find(
                "NEXMARKET", 1, true
            ) then
            table.insert(candidates, obj)
        end
    end

    local sw, sh = screen()

    for _, header in ipairs(candidates) do
        local p = header.Parent

        while p and p ~= pg do
            if p:IsA("GuiObject") then
                local s = p.AbsoluteSize
                local pos = p.AbsolutePosition

                if s.X >= sw * 0.13
                    and s.X <= sw * 0.55
                    and s.Y >= sh * 0.45
                    and pos.X > sw * 0.35 then

                    return p
                end
            end

            p = p.Parent
        end
    end

    return nil
end

local function phoneRect(phone)
    local p = phone.AbsolutePosition
    local s = phone.AbsoluteSize

    return p.X, p.Y, s.X, s.Y
end

local function inPhoneRegion(phone, x, y, region)
    local px, py, pw, ph = phoneRect(phone)

    if x < px or x > px + pw
        or y < py or y > py + ph then
        return false
    end

    local ry = (y - py) / ph

    if region == "list" then
        return ry >= 0.36 and ry <= 0.96
    elseif region == "tabs" then
        return ry >= 0.20 and ry <= 0.47
    elseif region == "purchase" then
        return ry >= 0.20 and ry <= 0.97
    end

    return false
end

local function blockedPoint(x, y, phone)
    if not inPhoneRegion(
        phone, x, y, "purchase"
    ) then
        return true
    end

    -- Never click a visible Shop control.
    for _, obj in ipairs(pg:GetDescendants()) do
        if visible(obj)
            and obj:IsA("GuiButton") then

            local name = obj.Name:lower()
            local txt = textOf(obj):lower()

            if name:find("shop", 1, true)
                or txt:find("shop", 1, true)
                or name:find("topbar", 1, true)
                or name:find("toolbar", 1, true) then

                if within(obj, x, y) then
                    return true
                end
            end
        end
    end

    return false
end

local function tapPoint(x, y, phone, region)
    if not inPhoneRegion(
        phone, x, y, region
    ) then
        return false
    end

    if blockedPoint(x, y, phone) then
        return false
    end

    local ok = pcall(function()
        VIM:SendMouseButtonEvent(
            x, y, 0, true, game, 0
        )
        task.wait(0.04)
        VIM:SendMouseButtonEvent(
            x, y, 0, false, game, 0
        )
    end)

    return ok
end

local function findTextInPhone(phone, value)
    value = value:lower()

    for _, obj in ipairs(phone:GetDescendants()) do
        if visible(obj)
            and textOf(obj):lower() == value then
            return obj
        end
    end
end

local function tapTab(phone, name)
    local obj = findTextInPhone(phone, name)

    if not obj then
        return false
    end

    local x, y = center(obj)

    return tapPoint(x, y, phone, "tabs")
end

-- Scan only price labels inside the phone's
-- visible listing area.
local function getListings(phone)
    local results = {}
    local used = {}

    for _, obj in ipairs(phone:GetDescendants()) do
        if visible(obj)
            and (obj:IsA("TextLabel")
            or obj:IsA("TextButton")) then

            local text = textOf(obj)
            local price = priceOf(text)
            local x, y = center(obj)

            if price
                and inPhoneRegion(
                    phone, x, y, "list"
                )
                and not text:lower():find(
                    "buy", 1, true
                ) then

                -- Deduplicate labels at the same location.
                local key =
                    math.floor(x / 8) .. ":" ..
                    math.floor(y / 8)

                if not used[key] then
                    used[key] = true

                    table.insert(results, {
                        price = price,
                        x = x,
                        y = y,
                        object = obj
                    })
                end
            end
        end
    end

    table.sort(results, function(a, b)
        return a.price < b.price
    end)

    return results
end

local function cheapestEligible(listings, lo, hi)
    for _, item in ipairs(listings) do
        if item.price >= lo
            and item.price <= hi then
            return item
        end
    end
end

-- Identify a visible Buy control whose displayed
-- price matches the selected listing.
local function buyButton(phone, expected, exclude)
    for _, obj in ipairs(phone:GetDescendants()) do
        if visible(obj) then
            local text = textOf(obj):lower()

            if text:find("buy", 1, true)
                and priceOf(text) == expected then

                local x, y = center(obj)

                if obj ~= exclude
                    and inPhoneRegion(
                        phone, x, y, "purchase"
                    )
                    and not blockedPoint(
                        x, y, phone
                    ) then

                    return obj
                end
            end
        end
    end
end

local function refresh(phone, id)
    statusText("Refreshing Electric > All")

    if not tapTab(phone, "Electric") then
        statusText("Electric tab unavailable")
        return false
    end

    if not pause(REFRESH_DELAY, id) then
        return false
    end

    phone = findPhone()
    if not phone then return false end

    if not tapTab(phone, "All") then
        statusText("All tab unavailable")
        return false
    end

    return pause(REFRESH_DELAY, id)
end

local function tryPurchase(phone, item, id)
    statusText("Opening $" .. item.price)

    -- Tap the price area of the chosen card,
    -- never an arbitrary parent button.
    if not tapPoint(
        item.x, item.y, phone, "list"
    ) then
        statusText("Listing tap blocked")
        return false
    end

    if not pause(0.35, id) then
        return false
    end

    phone = findPhone()
    if not phone then
        statusText("Phone screen changed")
        return false
    end

    local first = buyButton(
        phone, item.price, nil
    )

    if not first then
        statusText("Buy price not verified")
        return false
    end

    local bx, by = center(first)

    if not tapPoint(
        bx, by, phone, "purchase"
    ) then
        return false
    end

    if not pause(0.35, id) then
        return false
    end

    phone = findPhone()
    if not phone then
        statusText("Confirmation unavailable")
        return false
    end

    local confirm = buyButton(
        phone, item.price, first
    )

    if not confirm then
        statusText("Confirmation not verified")
        return false
    end

    local cx, cy = center(confirm)

    if not active(id) then
        return false
    end

    attempted = true

    local clicked = tapPoint(
        cx, cy, phone, "purchase"
    )

    if clicked then
        detailLabel.Text =
            "Attempted: $" .. item.price
        stop("Purchase attempted")
    else
        stop("Confirmation blocked")
    end

    return clicked
end

local function scanner(lo, hi, id)
    while active(id) and not attempted do
        local phone = findPhone()

        if not phone then
            foundLabel.Text =
                "Listings detected: 0"
            statusText("Waiting for NexMarket")

            if not pause(SCAN_DELAY, id) then
                return
            end
            continue
        end

        -- Only scan the Browse / All screen.
        local browse = findTextInPhone(
            phone, "Browse"
        )
        local all = findTextInPhone(
            phone, "All"
        )

        if not browse or not all then
            statusText("Waiting for Browse / All")

            if not pause(SCAN_DELAY, id) then
                return
            end
            continue
        end

        local listings = getListings(phone)

        scanCount += 1
        scanLabel.Text =
            "Checks: " .. scanCount

        foundLabel.Text =
            "Listings detected: " ..
            #listings

        local best = cheapestEligible(
            listings, lo, hi
        )

        if best then
            cheapestLabel.Text =
                "Cheapest: $" .. best.price

            detailLabel.Text =
                "Eligible bike detected"

            if tryPurchase(phone, best, id) then
                return
            end

            if not active(id) then return end

            -- Avoid hammering a listing screen
            -- when verification has failed.
            statusText("Waiting for Browse")
            pause(0.8, id)
        else
            if #listings > 0 then
                cheapestLabel.Text =
                    "Lowest seen: $" ..
                    listings[1].price
            else
                cheapestLabel.Text =
                    "Cheapest: --"
            end

            refresh(phone, id)
        end

        if not pause(SCAN_DELAY, id) then
            return
        end
    end
end

toggle.MouseButton1Click:Connect(function()
    if running then
        stop("OFF")
        return
    end

    local lo = tonumber(minBox.Text)
    local hi = tonumber(maxBox.Text)

    if not lo or not hi
        or lo < 0 or lo > hi then
        statusText("Invalid price range")
        return
    end

    running = true
    attempted = false
    generation += 1

    local id = generation

    toggle.Text = "STOP AUTO BUYER"
    toggle.BackgroundColor3 =
        Color3.fromRGB(205, 55, 75)

    statusText("ON")

    task.spawn(function()
        local ok, err = pcall(function()
            scanner(lo, hi, id)
        end)

        if not ok and active(id) then
            detailLabel.Text =
                tostring(err):sub(1, 55)
            stop("Scanner error")
        end
    end)
end)

_G.NexRideStop = function()
    stop("Closed")
    gui:Destroy()
end
