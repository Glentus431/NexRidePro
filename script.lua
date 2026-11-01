-- NexMarketPRO | iPhone / Delta-compatible best-effort GUI reader
-- No purchases, no fabricated market results. Only visible loaded GUI data.
local Players = game:GetService('Players')
local UIS = game:GetService('UserInputService')
local player = Players.LocalPlayer
local pg = player:WaitForChild('PlayerGui')

local parent = pg
pcall(function()
    if type(gethui) == 'function' then
        local h = gethui()
        if typeof(h) == 'Instance' then parent = h end
    end
end)
for _,p in ipairs({pg,parent}) do
    local old=p:FindFirstChild('NexMarketPRO_Final')
    if old then old:Destroy() end
end
local function mk(typ,p,props)
    local o=Instance.new(typ)
    for k,v in pairs(props or {}) do o[k]=v end
    o.Parent=p
    return o
end
local C={bg=Color3.fromRGB(15,19,28),panel=Color3.fromRGB(29,35,47),gold=Color3.fromRGB(248,190,71),text=Color3.fromRGB(246,247,250),muted=Color3.fromRGB(173,182,195)}
local gui=mk('ScreenGui',parent,{Name='NexMarketPRO_Final',ResetOnSpawn=false,IgnoreGuiInset=false,DisplayOrder=100000,ZIndexBehavior=Enum.ZIndexBehavior.Global})
local function corner(o,r) mk('UICorner',o,{CornerRadius=UDim.new(0,r)}) end
local function label(p,t,x,y,w,h,sz,z)
    return mk('TextLabel',p,{Text=t,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundTransparency=1,TextColor3=C.text,TextSize=sz or 13,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=z or 22})
end
local function button(p,t,x,y,w,h,color,z)
    local b=mk('TextButton',p,{Text=t,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=color or C.panel,TextColor3=C.text,Font=Enum.Font.GothamBold,TextSize=14,AutoButtonColor=true,Active=true,ZIndex=z or 23})
    corner(b,10)
    return b
end
local launch=button(gui,'N',14,185,60,60,C.gold,50)
launch.TextSize=27
launch.TextColor3=C.bg
local window=mk('Frame',gui,{Name='Window',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(370,520),BackgroundColor3=C.bg,BorderSizePixel=0,Visible=false,Active=true,ZIndex=20})
corner(window,16)
local uiScale=mk('UIScale',window,{Scale=1})
local function fit()
    local cam=workspace.CurrentCamera
    if not cam then return end
    local v=cam.ViewportSize
    uiScale.Scale=math.max(.5,math.min(1,(v.X-16)/370,(v.Y-30)/520))
end
fit()
local viewportConn
local function watchCam()
    if viewportConn then viewportConn:Disconnect() end
    local cam=workspace.CurrentCamera
    if cam then viewportConn=cam:GetPropertyChangedSignal('ViewportSize'):Connect(fit) end
    fit()
end
workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(watchCam)
watchCam()
local heading=label(window,'NEXMARKET PRO',16,12,275,32,21)
heading.Font=Enum.Font.GothamBold
local close=button(window,'CLOSE',290,12,65,34,C.panel)
local sub=label(window,'Mobile resale finder • observed listings only',16,48,338,24,12)
sub.TextColor3=C.gold
local status=label(window,'Select a bike. Open the game market and sort Lowest Price.',16,76,338,43,12)
local bikeList=mk('ScrollingFrame',window,{Position=UDim2.fromOffset(16,125),Size=UDim2.fromOffset(338,142),BackgroundColor3=C.panel,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.fromOffset(0,324),ZIndex=21})
corner(bikeList,9)
local bikes={'ZOOTIO','NXR K10','ZORAN LIGHT X','ZORAN ULTRA HP X','RAZE 250F','RYVEN 250','ZORAN MX','STARKEN'}
local chosen={}
for i,name in ipairs(bikes) do
    local b=button(bikeList,'+  '..name,6,5+(i-1)*39,315,35,C.bg,24)
    b.Activated:Connect(function()
        chosen[name]=not chosen[name]
        b.Text=(chosen[name] and '✓  ' or '+  ')..name
        b.BackgroundColor3=chosen[name] and Color3.fromRGB(80,65,36) or C.bg
    end)
end
local scan=button(window,'SCAN MARKET',16,278,338,46,C.gold)
scan.TextColor3=C.bg
local note=label(window,'Search for your chosen bike in NEXMARKET, set Lowest Price, then scan. Scroll listings and scan again.',16,328,338,43,11)
note.TextColor3=C.muted
local results=mk('ScrollingFrame',window,{Position=UDim2.fromOffset(16,377),Size=UDim2.fromOffset(338,128),BackgroundColor3=C.panel,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.fromOffset(0,160),ZIndex=21})
corner(results,9)
local resultText=label(results,'No listings scanned yet.',10,8,310,150,12,23)
resultText.TextYAlignment=Enum.TextYAlignment.Top
local function show(lines)
    resultText.Text=table.concat(lines,'\n')
    local n=1
    for _ in resultText.Text:gmatch('\n') do n=n+1 end
    local h=math.max(135,n*19+20)
    resultText.Size=UDim2.fromOffset(310,h)
    results.CanvasSize=UDim2.fromOffset(0,h+16)
end
local function setOpen(v)
    window.Visible=v
    launch.Visible=not v
end
-- Use Activated for touch and mouse. Launcher is hidden while panel is open,
-- avoiding overlapping Z-index/input conflicts on iPhone.
launch.Activated:Connect(function() setOpen(true) end)
close.Activated:Connect(function() setOpen(false) end)
-- Backup touch handling for executor environments that fail to fire Activated.
local startPos, startTime
launch.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.Touch then
        startPos=input.Position
        startTime=os.clock()
    end
end)
launch.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.Touch and startPos then
        local d=(input.Position-startPos).Magnitude
        if d<24 and os.clock()-startTime<1 then setOpen(true) end
        startPos=nil
    end
end)
local function visible(o)
    local p=o
    while p and p~=pg and p~=parent do
        if p:IsA('GuiObject') and (not p.Visible or p.AbsoluteSize.X<=0 or p.AbsoluteSize.Y<=0) then return false end
        p=p.Parent
    end
    return true
end
local function money(n)
    local s=tostring(math.floor(n+0.5))
    return '$'..s:reverse():gsub('(%d%d%d)','%1,'):reverse():gsub('^,','')
end
local function priceOf(t)
    if type(t)~='string' then return nil end
    local raw=t:match('%$%s*([%d,]+)')
    if not raw then return nil end
    local n=tonumber((raw:gsub(',','')))
    if n and n>=100 and n<=10000000 then return n end
end
local function norm(t)
    return tostring(t or ''):upper():gsub('%s+',' ')
end
local function getVisibleTexts()
    local arr={}
    for _,o in ipairs(pg:GetDescendants()) do
        if (o:IsA('TextLabel') or o:IsA('TextButton') or o:IsA('TextBox')) and not o:IsDescendantOf(gui) and visible(o) then
            local t=o.Text
            if t and #t>0 and #t<250 then
                arr[#arr+1]={object=o,text=t,upper=norm(t)}
            end
        end
    end
    return arr
end
local function isModel(t,model)
    return t:find(model,1,true)~=nil
end
local function collect()
    local texts=getVisibleTexts()
    local found={}
    -- Associate prices only when one model and one price appear in a small card.
    -- Deduplicate by the card instance, not by price (different sellers can match).
    local visited={}
    for _,x in ipairs(texts) do
        for _,model in ipairs(bikes) do
            if chosen[model] and isModel(x.upper,model) then
                local ancestor=x.object.Parent
                for depth=1,3 do
                    if not ancestor or ancestor==pg then break end
                    local modelsHere,pricesHere={},{}
                    for _,y in ipairs(texts) do
                        if y.object:IsDescendantOf(ancestor) then
                            for _,b in ipairs(bikes) do
                                if isModel(y.upper,b) then modelsHere[b]=true end
                            end
                            local p=priceOf(y.text)
                            if p then pricesHere[p]=true end
                        end
                    end
                    local nModels,nPrices,picked=0,0,nil
                    for _ in pairs(modelsHere) do nModels=nModels+1 end
                    for p in pairs(pricesHere) do nPrices=nPrices+1;picked=p end
                    if nModels==1 and modelsHere[model] and nPrices==1 then
                        local key=tostring(ancestor)
                        if not visited[key] then
                            visited[key]=true
                            found[#found+1]={model=model,price=picked}
                        end
                        break
                    end
                    ancestor=ancestor.Parent
                end
            end
        end
    end
    return found
end
local busy=false
scan.Activated:Connect(function()
    if busy then return end
    local count=0
    for _,b in ipairs(bikes) do if chosen[b] then count=count+1 end end
    if count==0 then
        status.Text='Select at least one bike first.'
        return
    end
    busy=true
    scan.Text='SCANNING...'
    status.Text='Reading currently loaded visible marketplace cards...'
    task.wait(.15)
    local groups={}
    for _,b in ipairs(bikes) do if chosen[b] then groups[b]={} end end
    for _,entry in ipairs(collect()) do
        if groups[entry.model] then table.insert(groups[entry.model],entry.price) end
    end
    local lines,total={},0
    for _,b in ipairs(bikes) do
        if groups[b] then
            local prices=groups[b]
            table.sort(prices)
            total=total+#prices
            lines[#lines+1]=b
            if #prices==0 then
                lines[#lines+1]='  No confidently matched visible listings.'
            else
                lines[#lines+1]='  Cheapest detected: '..money(prices[1])
                local top={}
                for i=1,math.min(5,#prices) do top[#top+1]=money(prices[i]) end
                lines[#lines+1]='  Top detected: '..table.concat(top,', ')
                if #prices>=3 then
                    local med=prices[math.floor((#prices+1)/2)]
                    lines[#lines+1]='  Median asking price: '..money(med)
                    lines[#lines+1]='  Gross spread estimate: '..money(med-prices[1])
                else
                    lines[#lines+1]='  Resale estimate needs 3+ matched listings.'
                end
                lines[#lines+1]='  Sale chance: unknown (no sold-price data)'
            end
            lines[#lines+1]=''
        end
    end
    lines[#lines+1]='Only visible loaded cards; no guarantees or fees included.'
    show(lines)
    status.Text='Matched '..total..' visible listing card(s). Scroll market and rescan to check more.'
    scan.Text='SCAN MARKET'
    busy=false
end)
print('[NexMarketPRO] Ready. Tap the gold N button.')
