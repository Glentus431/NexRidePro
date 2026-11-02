
-- NEXRIDE AUTO SNIPER V6
-- Delta iPhone - Experimental
-- One purchase attempt per activation

local Players = game:GetService("Players")
local VIM = game:GetService("VirtualInputManager")
local pg = Players.LocalPlayer:WaitForChild("PlayerGui")

if _G.NexRideStop then
    pcall(_G.NexRideStop)
end

local previous = pg:FindFirstChild("NexSniperV6")
if previous then previous:Destroy() end

local running = false
local serial = 0
local attempted = false

local gui = Instance.new("ScreenGui")
gui.Name = "NexSniperV6"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.Parent = pg

local function create(class,parent,properties)
    local object = Instance.new(class)
    for k,v in pairs(properties) do
        object[k] = v
    end
    object.Parent = parent
    return object
end

local panel = create("Frame",gui,{
    Size = UDim2.fromOffset(300,340),
    Position = UDim2.new(.5,-150,.18,0),
    BackgroundColor3 = Color3.fromRGB(17,22,35),
    Active = true,
    Draggable = true
})

create("UICorner",panel,{
    CornerRadius = UDim.new(0,15)
})

local function label(value,y,height,size)
    return create("TextLabel",panel,{
        Position = UDim2.fromOffset(14,y),
        Size = UDim2.new(1,-28,0,height),
        BackgroundTransparency = 1,
        Text = value,
        TextSize = size or 14,
        TextColor3 = Color3.fromRGB(235,240,255),
        Font = Enum.Font.GothamMedium,
        TextWrapped = true
    })
end

label("NEXRIDE SNIPER V6",10,30,21)
label("CHEAPEST BIKE / ONE PURCHASE",42,20,11)

local function field(title,y,value)
    label(title,y,18,12)

    local box = create("TextBox",panel,{
        Position = UDim2.fromOffset(15,y+19),
        Size = UDim2.new(1,-30,0,35),
        BackgroundColor3 = Color3.fromRGB(35,43,61),
        TextColor3 = Color3.new(1,1,1),
        Text = value,
        TextSize = 17,
        ClearTextOnFocus = false
    })

    create("UICorner",box,{
        CornerRadius = UDim.new(0,8)
    })

    return box
end

local minimum = field("MINIMUM PRICE",68,"1000")
local maximum = field("MAXIMUM PRICE",128,"12000")

local toggle = create("TextButton",panel,{
    Position = UDim2.fromOffset(15,193),
    Size = UDim2.new(1,-30,0,47),
    BackgroundColor3 = Color3.fromRGB(30,165,100),
    TextColor3 = Color3.new(1,1,1),
    Text = "START AUTO BUYER",
    TextSize = 17,
    Font = Enum.Font.GothamBold
})

create("UICorner",toggle,{
    CornerRadius = UDim.new(0,10)
})

local status = label("Status: OFF",250,36,13)
local detected = label("Cheapest: --",287,25,14)
local details = label("Waiting for NexMarket",313,20,11)

local function update(message)
    status.Text = "Status: "..message
end

local function stop(message)
    running = false
    serial += 1

    toggle.Text = "START AUTO BUYER"
    toggle.BackgroundColor3 =
        Color3.fromRGB(30,165,100)

    update(message or "OFF")
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

local function priceOf(s)
    local number = s:match("%$%s*([%d,]+)")
    if not number then return nil end
    return tonumber((number:gsub(",","")))
end

local function tap(o)
    if not visible(o) then return false end

    local p = o.AbsolutePosition
    local s = o.AbsoluteSize

    local x = p.X+s.X/2
    local y = p.Y+s.Y/2

    local ok = pcall(function()
        VIM:SendMouseButtonEvent(
            x,y,0,true,game,0
        )
        task.wait(.04)
        VIM:SendMouseButtonEvent(
            x,y,0,false,game,0
        )
    end)

    if not ok then
        update("iPhone tap unsupported")
    end

    return ok
end

local function findExact(word)
    for _,o in ipairs(pg:GetDescendants()) do
        if visible(o)
            and textOf(o):lower() == word then
            return o
        end
    end
end

local function ancestorButton(o)
    local p = o

    for i=1,4 do
        if not p then break end

        if p:IsA("GuiButton")
            and visible(p) then
            return p
        end

        p = p.Parent
    end
end

local function marketRoot()
    local all = findExact("all")
    local electric = findExact("electric")

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
        if ancestors[p]
            and p:IsA("GuiObject") then
            return p
        end
        p = p.Parent
    end
end

local function scan(root,lo,hi)
    local best = nil
    local seen = {}

    for _,o in ipairs(root:GetDescendants()) do
        if visible(o)
            and (o:IsA("TextLabel")
            or o:IsA("TextButton")) then

            local text = textOf(o)
            local lower = text:lower()
            local n = priceOf(text)

            if n and n >= lo and n <= hi
                and not lower:find("buy",1,true)
                and not lower:find("balance",1,true)
                and not lower:find("cash",1,true) then

                local button = ancestorButton(o)

                if button then
                    local name = button.Name:lower()
                    local buttonText = textOf(button):lower()

                    local blocked =
                        name:find("shop",1,true)
                        or name:find("store",1,true)
                        or buttonText:find("shop",1,true)

                    if not blocked
                        and not seen[button] then

                        seen[button] = true

                        if not best or n < best.price then
                            best = {
                                price = n,
                                button = button
                            }
                        end
                    end
                end
            end
        end
    end

    return best
end

local function findBuy(expected)
    for _,o in ipairs(pg:GetDescendants()) do
        if visible(o) then
            local s = textOf(o):lower()

            if s:find("buy",1,true)
                and priceOf(s) == expected then

                local b = ancestorButton(o)
                if b then return b end
            end
        end
    end
end

local function valid(id)
    return running and serial == id
end

local function waitFor(seconds,id)
    local deadline = os.clock()+seconds

    while os.clock()<deadline do
        if not valid(id) then return false end
        task.wait(.03)
    end

    return valid(id)
end

local function refresh(id)
    local electric = findExact("electric")
    if not electric then
        stop("Electric tab missing")
        return false
    end

    local eb = ancestorButton(electric)
    if not eb or not tap(eb) then
        stop("Cannot tap Electric")
        return false
    end

    if not waitFor(.2,id) then return false end

    local all = findExact("all")
    local ab = all and ancestorButton(all)

    if not ab or not tap(ab) then
        stop("Cannot return to All")
        return false
    end

    return waitFor(.25,id)
end

local function run(lo,hi,id)
    while valid(id) and not attempted do
        local root = marketRoot()

        if not root then
            stop("Open NexMarket Browse")
            return
        end

        update("Scanning cheapest listings")

        local best = scan(root,lo,hi)

        if best then
            detected.Text = "Cheapest: $"..best.price
            details.Text = "Opening selected bike"

            if not tap(best.button) then
                stop("Listing tap failed")
                return
            end

            if not waitFor(.3,id) then return end

            local first = findBuy(best.price)

            if not first then
                stop("Listing price not verified")
                return
            end

            update("Opening purchase confirmation")

            if not tap(first) then
                stop("Buy tap failed")
                return
            end

            if not waitFor(.3,id) then return end

            local confirm = findBuy(best.price)

            -- Do not tap the original Buy button twice.
            if not confirm or confirm == first then
                stop("Confirmation not verified")
                return
            end

            update("Confirming purchase")

            attempted = true

            local clicked = tap(confirm)

            if clicked then
                details.Text =
                    "Attempted $"..best.price
                stop("One purchase attempted")
            else
                stop("Confirmation tap failed")
            end

            return
        end

        detected.Text = "Cheapest: --"
        details.Text = "Refreshing Electric > All"

        if not refresh(id) then return end
        if not waitFor(.15,id) then return end
    end
end

toggle.MouseButton1Click:Connect(function()
    if running then
        stop("Stopped manually")
        return
    end

    local lo = tonumber(minimum.Text)
    local hi = tonumber(maximum.Text)

    if not lo or not hi
        or lo < 0 or lo > hi then
        update("Invalid price range")
        return
    end

    attempted = false
    running = true
    serial += 1

    local id = serial

    toggle.Text = "STOP AUTO BUYER"
    toggle.BackgroundColor3 =
        Color3.fromRGB(205,60,70)

    task.spawn(function()
        local ok,err = pcall(function()
            run(lo,hi,id)
        end)

        if not ok then
            stop("Error")
            details.Text = tostring(err):sub(1,65)
        end
    end)
end)

_G.NexRideStop = function()
    stop("Closed")
    gui:Destroy()
end
