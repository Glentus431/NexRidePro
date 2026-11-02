
-- NEXRIDE V12
-- COMPLETE MARKET PRICE SCANNER
-- Main file: script.lua
-- No Shop taps / no automatic purchases

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

-- Stop an older script, if possible.
if type(_G.NexRideStop) == "function" then
    pcall(_G.NexRideStop)
end

local old = pg:FindFirstChild("NexRideV12")
if old then
    old:Destroy()
end

local running = false
local generation = 0
local checks = 0

local gui = Instance.new("ScreenGui")
gui.Name = "NexRideV12"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.Parent = pg

local function create(class, parent, props)
    local obj = Instance.new(class)

    for key, value in pairs(props) do
        obj[key] = value
    end

    obj.Parent = parent
    return obj
end

local panel = create("Frame", gui, {
    Size = UDim2.fromOffset(320, 365),
    Position = UDim2.new(0.25, 0, 0.15, 0),
    BackgroundColor3 = Color3.fromRGB(20, 26, 40),
    Active = true,
    Draggable = true
})

create("UICorner", panel, {
    CornerRadius = UDim.new(0, 12)
})

local function label(value, y, h, size)
    return create("TextLabel", panel, {
        Position = UDim2.fromOffset(12, y),
        Size = UDim2.new(1, -24, 0, h),
        BackgroundTransparency = 1,
        Text = value,
        TextSize = size or 13,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamMedium,
        TextWrapped = true
    })
end

label("NEXRIDE SCANNER V12", 8, 32, 20)
label("LIVE PRICE DETECTION", 39, 22, 12)

local function input(title, y, value)
    label(title, y, 18, 12)

    local box = create("TextBox", panel, {
        Position = UDim2.fromOffset(15, y + 20),
        Size = UDim2.new(1, -30, 0, 34),
        BackgroundColor3 = Color3.fromRGB(39, 47, 67),
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 16,
        Text = value,
        ClearTextOnFocus = false
    })

    create("UICorner", box, {
        CornerRadius = UDim.new(0, 8)
    })

    return box
end

local minBox = input("MINIMUM PRICE", 66, "1000")
local maxBox = input("MAXIMUM PRICE", 124, "11500")

local toggle = create("TextButton", panel, {
    Position = UDim2.fromOffset(15, 190),
    Size = UDim2.new(1, -30, 0, 46),
    BackgroundColor3 = Color3.fromRGB(30, 165, 100),
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 17,
    Text = "START SCANNING"
})

create("UICorner", toggle, {
    CornerRadius = UDim.new(0, 9)
})

local status = label("Status: OFF", 243, 27, 13)
local found = label("Prices detected: 0", 271, 23, 13)
local lowest = label("Lowest detected: --", 296, 24, 15)
local eligible = label("Cheapest in range: --", 321, 23, 13)
local counter = label("Checks: 0", 344, 18, 11)

local function setStatus(value)
    status.Text = "Status: " .. value
end

local function stop()
    running = false
    generation += 1

    toggle.Text = "START SCANNING"
    toggle.BackgroundColor3 =
        Color3.fromRGB(30, 165, 100)

    setStatus("OFF")
end

local function isVisible(obj)
    if not obj:IsA("GuiObject") then
        return false
    end

    if obj:IsDescendantOf(gui) then
        return false
    end

    local p = obj

    while p and p ~= pg do
        if p:IsA("GuiObject") and not p.Visible then
            return false
        end

        p = p.Parent
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

local function priceOf(value)
    local raw = value:match("%$%s*([%d,]+)")

    if not raw then
        return nil
    end

    return tonumber((raw:gsub(",", "")))
end

local function scan(lo, hi)
    local results = {}
    local seen = {}

    local camera = workspace.CurrentCamera

    if not camera then
        setStatus("Camera unavailable")
        return
    end

    local screenSize = camera.ViewportSize

    for _, obj in ipairs(pg:GetDescendants()) do
        if isVisible(obj)
            and (obj:IsA("TextLabel")
            or obj:IsA("TextButton")) then

            local text = textOf(obj)
            local lower = text:lower()
            local price = priceOf(text)

            if price then
                local p = obj.AbsolutePosition
                local s = obj.AbsoluteSize

                local x = p.X + s.X / 2
                local y = p.Y + s.Y / 2

                -- Focus on the right side where
                -- NexMarket appeared in your screenshot.
                local rightSide =
                    x >= screenSize.X * 0.5

                local notNavigation =
                    not lower:find("shop", 1, true)
                    and not lower:find("buy", 1, true)
                    and not lower:find("balance", 1, true)
                    and not lower:find("cash", 1, true)

                if rightSide and notNavigation then
                    local key =
                        tostring(price) .. ":" ..
                        math.floor(x / 10) .. ":" ..
                        math.floor(y / 10)

                    if not seen[key] then
                        seen[key] = true

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
    end

    table.sort(results, function(a, b)
        return a.price < b.price
    end)

    found.Text =
        "Prices detected: " .. #results

    if #results > 0 then
        lowest.Text =
            "Lowest detected: $" .. results[1].price
    else
        lowest.Text = "Lowest detected: --"
    end

    local best = nil

    for _, item in ipairs(results) do
        if item.price >= lo
            and item.price <= hi then

            best = item
            break
        end
    end

    if best then
        eligible.Text =
            "Cheapest in range: $" .. best.price
        setStatus("Eligible price detected")
    elseif #results > 0 then
        eligible.Text = "Cheapest in range: --"
        setStatus("No eligible price detected")
    else
        eligible.Text = "Cheapest in range: --"
        setStatus("No readable prices found")
    end
end

toggle.MouseButton1Click:Connect(function()
    if running then
        stop()
        return
    end

    local lo = tonumber(minBox.Text)
    local hi = tonumber(maxBox.Text)

    if not lo or not hi
        or lo < 0 or lo > hi then
        setStatus("Invalid price range")
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
            local ok, err = pcall(function()
                scan(lo, hi)
            end)

            if not ok then
                setStatus(
                    "Scan error: " ..
                    tostring(err):sub(1, 35)
                )
            end

            checks += 1
            counter.Text = "Checks: " .. checks

            task.wait(0.4)
        end
    end)
end)

_G.NexRideStop = function()
    stop()
    gui:Destroy()
end
