
-- NEXRIDE AUTO SNIPER V9
-- Main file: script.lua
-- Continuous ON/OFF, lowest-price selection
-- Shop and top navigation protection
-- Experimental: game GUI structure is unverified

local Players = game:GetService("Players")
local VIM = game:GetService("VirtualInputManager")

local pg = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Close older versions when possible
for _, key in ipairs({
    "NexRideStop",
    "NexSniperV7Stop",
    "NexV9Stop"
}) do
    if type(_G[key]) == "function" then
        pcall(_G[key])
    end
end

for _, name in ipairs({
    "NexSniperV5",
    "NexSniperV6",
    "NexSniperV7",
    "NexSniperV9"
}) do
    local old = pg:FindFirstChild(name)
    if old then old:Destroy() end
end

local running = false
local token = 0
local scanNumber = 0
local purchaseAttempted = false

local REFRESH_DELAY = 0.5
local SCAN_DELAY = 0.4

-- Extra protected area at the top of the screen.
-- Coordinates are pixels, not percentages.
local SAFE_TOP = 150

local gui = Instance.new("ScreenGui")
gui.Name = "NexSniperV9"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.Parent = pg

local function new(class, parent, props)
    local o = Instance.new(class)
    for k, v in pairs(props) do
        o[k] = v
    end
    o.Parent = parent
    return o
end

local panel = new("Frame", gui, {
    Size = UDim2.fromOffset(305, 345),
    Position = UDim2.new(0.5, -152, 0.2, 0),
    BackgroundColor3 = Color3.fromRGB(19, 24, 37),
    Active = true,
    Draggable = true
})

new("UICorner", panel, {
    CornerRadius = UDim.new(0, 14)
})

local function label(text, y, height, size)
    return new("TextLabel", panel, {
        Position = UDim2.fromOffset(12, y),
        Size = UDim2.new(1, -24, 0, height),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamMedium,
        TextSize = size or 13,
        TextWrapped = true
    })
end

label("NEXRIDE AUTO SNIPER V9", 8, 32, 19)
label("CONTINUOUS MARKET SCANNER", 39, 19, 11)

local function field(title, y, value)
    label(title, y, 19, 12)

    local box = new("TextBox", panel, {
        Position = UDim2.fromOffset(15, y + 20),
        Size = UDim2.new(1, -30, 0, 35),
        BackgroundColor3 = Color3.fromRGB(38, 46, 65),
        TextColor3 = Color3.new(1, 1, 1),
        Text = value,
        TextSize = 17,
        ClearTextOnFocus = false
    })

    new("UICorner", box, {
        CornerRadius = UDim.new(0, 8)
    })

    return box
end

local minBox = field("MINIMUM PRICE", 64, "1000")
local maxBox = field("MAXIMUM PRICE", 124, "12000")

local toggle = new("TextButton", panel, {
    Position = UDim2.fromOffset(15, 187),
    Size = UDim2.new(1, -30, 0, 45),
    BackgroundColor3 = Color3.fromRGB(34, 170, 100),
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 17,
    Text = "START AUTO BUYER"
})

new("UICorner", toggle, {
    CornerRadius = UDim.new(0, 9)
})

local status = label("Status: OFF", 239, 30, 13)
local priceLabel = label("Cheapest: --", 273, 25, 14)
local scanLabel = label("Scans: 0", 300, 20, 12)
local info = label("Waiting for NexMarket", 321, 20, 11)

local function setStatus(s)
    status.Text = "Status: " .. s
end

local function stop(s)
    running = false
    token += 1

    toggle.Text = "START AUTO BUYER"
    toggle.BackgroundColor3 =
        Color3.fromRGB(34, 170, 100)

    setStatus(s or "OFF")
end

local function active(id)
    return running
        and token == id
        and gui.Parent ~= nil
end

local function pause(seconds, id)
    local deadline = os.clock() + seconds

    while os.clock() < deadline do
        if not active(id) then return false end
        task.wait(0.04)
    end

    return active(id)
end

local function visible(o)
    if not o or not o:IsA("GuiObject")
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

local function textOf(o)
    if o:IsA("TextLabel")
        or o:IsA("TextButton")
        or o:IsA("TextBox") then
        return o.Text
    end
    return ""
end

local function lower(o)
    return textOf(o):lower()
end

local function priceOf(s)
    local n = s:match("%$%s*([%d,]+)")
    if not n then return nil end

    return tonumber((n:gsub(",", "")))
end

local blockedWords = {
    "shop",
    "store",
    "garage",
    "inventory",
    "toolbar",
    "topbar",
    "navbar",
    "dropdown",
    "customize",
    "upgrade"
}

local function blocked(o)
    local p = o

    while p and p ~= pg do
        local name = p.Name:lower()
        local text = lower(p)

        for _, word in ipairs(blockedWords) do
            if name:find(word, 1, true)
                or text:find(word, 1, true) then
                return true
            end
        end

        p = p.Parent
    end

    return false
end

local function containsPoint(o, x, y)
    local p = o.AbsolutePosition
    local s = o.AbsoluteSize

    return x >= p.X
        and x <= p.X + s.X
        and y >= p.Y
        and y <= p.Y + s.Y
end

-- Reject any touch coordinate that overlaps
-- a visible Shop or top-navigation button.
local function protectedPoint(x, y)
    if y < SAFE_TOP then
        return true
    end

    for _, o in ipairs(pg:GetDescendants()) do
        if visible(o) and o:IsA("GuiButton") then
            local name = o.Name:lower()
            local text = lower(o)

            local forbidden =
                name:find("shop", 1, true)
                or text:find("shop", 1, true)
                or name:find("topbar", 1, true)
                or name:find("toolbar", 1, true)

            if forbidden and containsPoint(o, x, y) then
                return true
            end
        end
    end

    return false
end

local function buttonFor(o, boundary)
    local p = o

    while p and p ~= boundary do
        if blocked(p) then
            return nil
        end

        if p:IsA("GuiButton") and visible(p) then
            return p
        end

        p = p.Parent
    end

    return nil
end

local function tap(button, boundary)
    if not button
        or not button:IsA("GuiButton")
        or not visible(button)
        or blocked(button) then
        return false
    end

    if boundary
        and not button:IsDescendantOf(boundary) then
        return false
    end

    local p = button.AbsolutePosition
    local s = button.AbsoluteSize

    -- Reject oversized panels and whole-row controls.
    if s.X > 350 or s.Y > 100 then
        return false
    end

    local x = p.X + s.X / 2
    local y = p.Y + s.Y / 2

    if protectedPoint(x, y) then
        setStatus("Protected Shop/top row")
        return false
    end

    local ok = pcall(function()
        VIM:SendMouseButtonEvent(
            x, y, 0, true, game, 0
        )

        task.wait(0.05)

        VIM:SendMouseButtonEvent(
            x, y, 0, false, game, 0
        )
    end)

    if not ok then
        setStatus("Touch input unsupported")
    end

    return ok
end

local function findExact(root, value)
    for _, o in ipairs(root:GetDescendants()) do
        if visible(o) and lower(o) == value then
            return o
        end
    end
end

local function findMarket()
    local all = findExact(pg, "all")
    local electric = findExact(pg, "electric")

    if not all or not electric then
        return nil
    end

    local ancestors = {}
    local p = all

    while p and p ~= pg do
        ancestors[p] = true
        p = p.Parent
    end

    p = electric

    while p and p ~= pg do
        if ancestors[p] and p:IsA("GuiObject") then
            -- Must be larger than a simple tab bar.
            if p.AbsoluteSize.X >= 220
                and p.AbsoluteSize.Y >= 250 then
                return p
            end
        end

        p = p.Parent
    end
end

local function findCheapest(root, lo, hi)
    local best = nil
    local seen = {}

    for _, o in ipairs(root:GetDescendants()) do
        if visible(o)
            and (o:IsA("TextLabel")
            or o:IsA("TextButton")) then

            local text = lower(o)
            local price = priceOf(text)

            if price
                and price >= lo
                and price <= hi
                and not text:find("buy", 1, true)
                and not text:find("balance", 1, true)
                and not text:find("cash", 1, true) then

                local b = buttonFor(o, root)

                if b and not seen[b] then
                    seen[b] = true

                    local p = b.AbsolutePosition
                    local s = b.AbsoluteSize

                    local x = p.X + s.X / 2
                    local y = p.Y + s.Y / 2

                    if s.X <= 350
                        and s.Y <= 100
                        and not protectedPoint(x, y) then

                        if not best or price < best.price then
                            best = {
                                price = price,
                                button = b
                            }
                        end
                    end
                end
            end
        end
    end

    return best
end

local function findBuy(expected, excluded)
    for _, o in ipairs(pg:GetDescendants()) do
        if visible(o) then
            local text = lower(o)

            if text:find("buy", 1, true)
                and priceOf(text) == expected then

                local b = buttonFor(o, pg)

                if b and b ~= excluded then
                    return b
                end
            end
        end
    end
end

local function refresh(root, id)
    local electric = findExact(root, "electric")
    local electricButton =
        electric and buttonFor(electric, root)

    if not electricButton then
        setStatus("Electric tab not found")
        return false
    end

    if not tap(electricButton, root) then
        return false
    end

    if not pause(REFRESH_DELAY, id) then
        return false
    end

    root = findMarket()
    if not root then return false end

    local all = findExact(root, "all")
    local allButton = all and buttonFor(all, root)

    if not allButton then
        setStatus("All tab not found")
        return false
    end

    if not tap(allButton, root) then
        return false
    end

    return pause(REFRESH_DELAY, id)
end

local function tryBuy(best, id)
    setStatus("Opening cheapest listing")

    if not tap(best.button) then
        return false
    end

    if not pause(0.4, id) then
        return false
    end

    local first = findBuy(best.price)

    if not first then
        setStatus("Price verification failed")
        return false
    end

    if not tap(first) then
        return false
    end

    if not pause(0.4, id) then
        return false
    end

    local confirm = findBuy(best.price, first)

    if not confirm then
        setStatus("Confirmation not verified")
        return false
    end

    if not active(id) then
        return false
    end

    -- Stop after one confirmation attempt.
    purchaseAttempted = true

    local clicked = tap(confirm)

    if clicked then
        info.Text = "Attempted purchase: $" .. best.price
        stop("Purchase attempted")
    else
        stop("Confirmation tap blocked")
    end

    return clicked
end

local function scanLoop(lo, hi, id)
    while active(id) and not purchaseAttempted do
        scanNumber += 1
        scanLabel.Text = "Scans: " .. scanNumber

        local root = findMarket()

        if root then
            setStatus("Checking All listings")

            local best = findCheapest(root, lo, hi)

            if best then
                priceLabel.Text =
                    "Cheapest: $" .. best.price

                local ok = tryBuy(best, id)

                if ok or not active(id) then
                    return
                end

                -- Do not repeatedly tap an uncertain
                -- listing or purchase screen.
                -- Wait for a safe return to Browse.
                setStatus("Waiting for Browse screen")
                pause(1, id)
            else
                priceLabel.Text = "Cheapest: --"
                setStatus("Refreshing Electric > All")
                refresh(root, id)
            end
        else
            setStatus("Open NexMarket Browse")
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
        setStatus("Invalid price range")
        return
    end

    running = true
    purchaseAttempted = false
    token += 1

    local id = token

    toggle.Text = "STOP AUTO BUYER"
    toggle.BackgroundColor3 =
        Color3.fromRGB(205, 60, 75)

    setStatus("ON - scanning")

    task.spawn(function()
        local ok, err = pcall(function()
            scanLoop(lo, hi, id)
        end)

        if not ok and active(id) then
            info.Text = tostring(err):sub(1, 45)
            stop("Scanner error")
        end
    end)
end)

_G.NexV9Stop = function()
    stop("Closed")
    gui:Destroy()
end

_G.NexRideStop = _G.NexV9Stop
