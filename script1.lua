
-- NEXRIDE AUTO SNIPER V5
-- Delta iPhone | One purchase attempt
-- Experimental: NexMarket hierarchy not verified

local P = game:GetService("Players")
local VIM = game:GetService("VirtualInputManager")
local pg = P.LocalPlayer:WaitForChild("PlayerGui")

if _G.NexRideStop then
    pcall(_G.NexRideStop)
end

local old = pg:FindFirstChild("NexSniperV5")
if old then old:Destroy() end

local alive, running = true, false
local generation = 0
local attempts = 0

local ui = Instance.new("ScreenGui")
ui.Name = "NexSniperV5"
ui.ResetOnSpawn = false
ui.Parent = pg

local function make(class, parent, props)
    local o = Instance.new(class)
    for k,v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end

local panel = make("Frame",ui,{
    Size=UDim2.fromOffset(300,345),
    Position=UDim2.new(.5,-150,.22,0),
    BackgroundColor3=Color3.fromRGB(18,22,34),
    Active=true,
    Draggable=true
})

make("UICorner",panel,{
    CornerRadius=UDim.new(0,16)
})

local function text(s,y,h,size)
    return make("TextLabel",panel,{
        Position=UDim2.fromOffset(15,y),
        Size=UDim2.new(1,-30,0,h),
        BackgroundTransparency=1,
        Text=s,
        TextColor3=Color3.fromRGB(240,245,255),
        TextSize=size or 15,
        Font=Enum.Font.GothamMedium,
        TextWrapped=true
    })
end

text("NEXRIDE  /  SNIPER V5",12,32,20)
text("ONE PURCHASE MODE",44,22,12)

local function field(title,y,value)
    text(title,y,18,12)
    local b=make("TextBox",panel,{
        Position=UDim2.fromOffset(15,y+20),
        Size=UDim2.new(1,-30,0,34),
        BackgroundColor3=Color3.fromRGB(35,42,59),
        TextColor3=Color3.new(1,1,1),
        Text=value,
        TextSize=17,
        ClearTextOnFocus=false
    })
    make("UICorner",b,{
        CornerRadius=UDim.new(0,8)
    })
    return b
end

local minBox=field("MINIMUM PRICE",73,"1000")
local maxBox=field("MAXIMUM PRICE",135,"12000")

local toggle=make("TextButton",panel,{
    Position=UDim2.fromOffset(15,205),
    Size=UDim2.new(1,-30,0,46),
    BackgroundColor3=Color3.fromRGB(35,165,105),
    TextColor3=Color3.new(1,1,1),
    Text="START SNIPER",
    TextSize=17,
    Font=Enum.Font.GothamBold
})
make("UICorner",toggle,{
    CornerRadius=UDim.new(0,10)
})

local status=text("OFF",264,35,13)
local result=text("Waiting for NexMarket",302,30,12)

local function setStatus(s)
    status.Text=s
end

local function visible(o)
    if not o or not o:IsA("GuiObject")
        or o:IsDescendantOf(ui) then
        return false
    end
    local p=o
    while p and p~=pg do
        if p:IsA("GuiObject") and not p.Visible then
            return false
        end
        p=p.Parent
    end
    return o.AbsoluteSize.X>0
       and o.AbsoluteSize.Y>0
end

local function inside(o,root)
    return o==root or o:IsDescendantOf(root)
end

local function price(s)
    local n=s:match("%$%s*([%d,]+)")
    return n and tonumber((n:gsub(",","")))
end

local function getText(o)
    if o:IsA("TextLabel")
        or o:IsA("TextButton") then
        return o.Text
    end
    return ""
end

local function hasWord(root,word)
    for _,o in ipairs(root:GetDescendants()) do
        if visible(o) and
            getText(o):lower()==word then
            return true
        end
    end
    return false
end

-- Find a plausible market container, not Shop.
local function findMarket()
    local best,bestArea=nil,math.huge

    for _,o in ipairs(pg:GetDescendants()) do
        if o:IsA("GuiObject")
            and visible(o)
            and not o:IsDescendantOf(ui)
            and hasWord(o,"all")
            and hasWord(o,"electric") then

            local area=o.AbsoluteSize.X*
                o.AbsoluteSize.Y

            if area>20000 and area<bestArea then
                best,bestArea=o,area
            end
        end
    end

    return best
end

local function tap(o,root)
    if not visible(o) or not inside(o,root) then
        return false
    end

    local p=o.AbsolutePosition
    local s=o.AbsoluteSize
    local x=p.X+s.X/2
    local y=p.Y+s.Y/2

    -- Never tap outside the detected market.
    local r=root.AbsolutePosition
    local z=root.AbsoluteSize
    if x<r.X or x>r.X+z.X
        or y<r.Y or y>r.Y+z.Y then
        return false
    end

    local ok=pcall(function()
        VIM:SendMouseButtonEvent(
            x,y,0,true,game,0)
        task.wait(.04)
        VIM:SendMouseButtonEvent(
            x,y,0,false,game,0)
    end)
    return ok
end

local function tab(root,name)
    for _,o in ipairs(root:GetDescendants()) do
        if visible(o)
            and getText(o):lower()==name then
            if o:IsA("GuiButton") then
                return o
            end
            if o.Parent
                and o.Parent:IsA("GuiButton") then
                return o.Parent
            end
        end
    end
end

local function forbidden(o)
    local s=(o.Name.." "..getText(o)):lower()
    return s:find("shop",1,true)
        or s:find("store",1,true)
        or s:find("inventory",1,true)
        or s:find("garage",1,true)
end

local function findCard(o,root)
    local p=o.Parent

    while p and p~=root do
        if forbidden(p) then return nil end

        if p:IsA("GuiButton")
            and visible(p)
            and not forbidden(p) then
            return p
        end

        p=p.Parent
    end
    return nil
end

local function cheapest(root,lo,hi)
    local best=nil

    for _,o in ipairs(root:GetDescendants()) do
        if visible(o)
            and (o:IsA("TextLabel")
            or o:IsA("TextButton")) then

            local s=getText(o)
            local n=price(s)

            if n and n>=lo and n<=hi
                and not s:lower():find("buy") then

                local card=findCard(o,root)

                if card and
                    (not best or n<best.price) then
                    best={
                        price=n,
                        card=card
                    }
                end
            end
        end
    end
    return best
end

local function buyButton(root,n)
    for _,o in ipairs(root:GetDescendants()) do
        if visible(o) then
            local s=getText(o):lower()
            if s:find("buy for",1,true)
                and price(s)==n then

                if o:IsA("GuiButton") then
                    return o
                end
                if o.Parent
                    and o.Parent:IsA("GuiButton") then
                    return o.Parent
                end
            end
        end
    end
end

local function stop(message)
    running=false
    generation+=1
    toggle.Text="START SNIPER"
    toggle.BackgroundColor3=
        Color3.fromRGB(35,165,105)
    setStatus(message or "STOPPED")
end

local function waitActive(t,id)
    local finish=os.clock()+t
    while os.clock()<finish do
        if not running or generation~=id then
            return false
        end
        task.wait(.03)
    end
    return true
end

local function run(lo,hi,id)
    while running and generation==id do
        local root=findMarket()

        if not root then
            stop("NexMarket not identified")
            return
        end

        local all=tab(root,"all")
        local electric=tab(root,"electric")

        if not all or not electric then
            stop("Market tabs not identified")
            return
        end

        setStatus("Scanning All...")
        local candidate=cheapest(root,lo,hi)

        if candidate then
            result.Text="Lowest: $"..candidate.price
            setStatus("Opening listing...")

            if not tap(candidate.card,root) then
                stop("Listing tap failed")
                return
            end

            if not waitActive(.25,id) then return end

            -- Re-detect market after opening listing.
            root=findMarket()
            if not root then
                stop("Cannot verify bike details")
                return
            end

            local first=buyButton(root,candidate.price)
            if not first then
                stop("Buy price not verified")
                return
            end

            setStatus("Opening confirmation...")
            if not tap(first,root) then
                stop("Buy tap failed")
                return
            end

            if not waitActive(.3,id) then return end

            -- Fail closed unless a different
            -- confirmation button can be identified.
            root=findMarket()
            if not root then
                stop("Confirmation not identified")
                return
            end

            local confirm=buyButton(
                root,candidate.price
            )

            if not confirm or confirm==first then
                stop("Confirmation not verified")
                return
            end

            setStatus("Attempting purchase...")

            if tap(confirm,root) then
                attempts+=1
                result.Text=
                    "Purchase attempts: "..attempts
                stop("STOPPED - purchase attempted")
            else
                stop("Confirmation tap failed")
            end
            return
        end

        setStatus("Refreshing Electric > All")

        if not tap(electric,root) then
            stop("Electric tap failed")
            return
        end
        if not waitActive(.15,id) then return end

        root=findMarket()
        all=root and tab(root,"all")
        if not all or not tap(all,root) then
            stop("All tab tap failed")
            return
        end

        if not waitActive(.2,id) then return end
    end
end

toggle.MouseButton1Click:Connect(function()
    if running then
        stop("STOPPED")
        return
    end

    local lo=tonumber(minBox.Text)
    local hi=tonumber(maxBox.Text)

    if not lo or not hi or lo<0 or lo>hi then
        setStatus("Invalid price range")
        return
    end

    running=true
    generation+=1
    local id=generation

    toggle.Text="STOP SNIPER"
    toggle.BackgroundColor3=
        Color3.fromRGB(200,65,75)

    task.spawn(function()
        local ok,err=pcall(run,lo,hi,id)
        if not ok then
            stop("Error: "..tostring(err):sub(1,35))
        end
    end)
end)

_G.NexRideStop=function()
    alive=false
    stop("CLOSED")
    ui:Destroy()
end
