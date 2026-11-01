-- NexMarketPRO iPhone / Delta-friendly UI
-- Local GUI only. Does not claim to fetch private marketplace data.
local Players = game:GetService('Players')
local UIS = game:GetService('UserInputService')
local player = Players.LocalPlayer
local pg = player:WaitForChild('PlayerGui')
local previous = pg:FindFirstChild('NexMarketPRO_iPhone')
if previous then previous:Destroy() end
local gui = Instance.new('ScreenGui')
gui.Name = 'NexMarketPRO_iPhone'
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = pg
local function make(kind, parent, properties)
    local o = Instance.new(kind)
    for k,v in pairs(properties) do o[k] = v end
    o.Parent = parent
    return o
end
local function corners(o, radius)
    make('UICorner',o,{CornerRadius=UDim.new(0,radius)})
end
local gold=Color3.fromRGB(244,180,57)
local bg=Color3.fromRGB(17,20,27)
local tile=Color3.fromRGB(31,36,47)
local white=Color3.fromRGB(245,246,249)
local launcher=make('TextButton',gui,{
    Name='Launcher',Size=UDim2.fromOffset(58,58),
    Position=UDim2.new(0,14,0.5,-29),BackgroundColor3=gold,
    Text='N',TextColor3=bg,TextSize=29,Font=Enum.Font.GothamBold,
    Active=true,AutoButtonColor=true,ZIndex=5
})
corners(launcher,16)
local window=make('Frame',gui,{
    Name='Window',AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(360,470),
    BackgroundColor3=bg,Visible=false,Active=true,ZIndex=10
})
corners(window,18)
make('UIStroke',window,{Color=gold,Thickness=1,Transparency=0.45})
local scaler=make('UIScale',window,{Scale=1})
local function resize()
    local cam=workspace.CurrentCamera
    if cam then
        local s=cam.ViewportSize
        scaler.Scale=math.max(0.4,math.min(1,(s.X-24)/360,(s.Y-40)/470))
    end
end
resize()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(resize)
end
make('TextLabel',window,{
    BackgroundTransparency=1,Position=UDim2.fromOffset(18,12),
    Size=UDim2.fromOffset(275,40),Text='NEXMARKET PRO',
    TextColor3=white,Font=Enum.Font.GothamBold,TextSize=20,
    TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11
})
local close=make('TextButton',window,{
    Position=UDim2.new(1,-53,0,13),Size=UDim2.fromOffset(38,38),
    BackgroundColor3=tile,Text='X',TextColor3=white,
    Font=Enum.Font.GothamBold,TextSize=18,ZIndex=11
})
corners(close,10)
make('TextLabel',window,{
    Position=UDim2.fromOffset(18,55),Size=UDim2.fromOffset(315,26),
    BackgroundTransparency=1,Text='Select bikes to monitor',
    TextColor3=gold,Font=Enum.Font.Gotham,TextSize=13,
    TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11
})
local scroll=make('ScrollingFrame',window,{
    Position=UDim2.fromOffset(15,88),Size=UDim2.fromOffset(330,250),
    BackgroundColor3=tile,BorderSizePixel=0,ScrollBarThickness=4,
    CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
    ZIndex=11
})
corners(scroll,12)
make('UIPadding',scroll,{PaddingTop=UDim.new(0,6),PaddingBottom=UDim.new(0,6),PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6)})
make('UIListLayout',scroll,{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder})
local selected={}
local models={'ZOOTIO','NXR K10','ZORAN LIGHT X','ZORAN ULTRA HP X','RAZE 250F','RYVEN 250','ZORAN MX','STARKEN'}
for i,name in ipairs(models) do
    local b=make('TextButton',scroll,{
        LayoutOrder=i,Size=UDim2.new(1,-4,0,40),BackgroundColor3=bg,
        Text='+  '..name,TextColor3=white,TextSize=14,
        Font=Enum.Font.GothamMedium,ZIndex=12
    })
    corners(b,9)
    b.Activated:Connect(function()
        selected[name]=not selected[name]
        b.Text=(selected[name] and '✓  ' or '+  ')..name
        b.BackgroundColor3=selected[name] and Color3.fromRGB(83,65,35) or bg
    end)
end
local status=make('TextLabel',window,{
    Position=UDim2.fromOffset(16,346),Size=UDim2.fromOffset(328,36),
    BackgroundTransparency=1,Text='Ready. Select a bike.',
    TextColor3=white,TextSize=13,TextWrapped=true,
    Font=Enum.Font.Gotham,ZIndex=11
})
local scan=make('TextButton',window,{
    Position=UDim2.fromOffset(15,392),Size=UDim2.fromOffset(330,56),
    BackgroundColor3=gold,Text='START 5-SECOND SCAN',
    TextColor3=bg,TextSize=15,Font=Enum.Font.GothamBold,ZIndex=11
})
corners(scan,12)
launcher.Activated:Connect(function()
    window.Visible=not window.Visible
end)
close.Activated:Connect(function()
    window.Visible=false
end)
local busy=false
scan.Activated:Connect(function()
    if busy then return end
    local count=0
    for _,yes in pairs(selected) do if yes then count=count+1 end end
    if count==0 then status.Text='Select at least one bike first.' return end
    busy=true
    for i=5,1,-1 do
        status.Text='Scan timer: '..i..' seconds remaining'
        scan.Text='SCANNING...'
        task.wait(1)
    end
    status.Text='UI works. Connect actual marketplace-reading logic to show prices.'
    scan.Text='START 5-SECOND SCAN'
    busy=false
end)
-- Optional drag via title button-like launcher, touch and mouse supported.
local dragInput, dragStart, originalPosition
launcher.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
        dragInput=input
        dragStart=input.Position
        originalPosition=launcher.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragInput and (input==dragInput or (dragInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement)) then
        local d=input.Position-dragStart
        launcher.Position=UDim2.new(originalPosition.X.Scale,originalPosition.X.Offset+d.X,originalPosition.Y.Scale,originalPosition.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input==dragInput then dragInput=nil end
end)
print('[NexMarketPRO] Mobile UI loaded successfully')
