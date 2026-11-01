-- NexMarketPRO Reselling Finder - best effort, mobile compatible
-- Scans GUI text visible to the client. No fabricated market prices.
local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local player=Players.LocalPlayer
local pg=player:WaitForChild('PlayerGui')
local old=pg:FindFirstChild('NexMarketPRO_Reselling'); if old then old:Destroy() end
local gui=Instance.new('ScreenGui');gui.Name='NexMarketPRO_Reselling';gui.ResetOnSpawn=false;gui.DisplayOrder=1000;gui.Parent=pg
local function make(cls,par,props)
 local o=Instance.new(cls);for k,v in pairs(props or {}) do o[k]=v end;o.Parent=par;return o
end
local function rounded(o,r) make('UICorner',o,{CornerRadius=UDim.new(0,r)}) end
local gold=Color3.fromRGB(246,188,70);local bg=Color3.fromRGB(17,20,28);local tile=Color3.fromRGB(32,37,49);local white=Color3.fromRGB(242,244,248)
local function label(par,text,pos,size,fontSize)
 return make('TextLabel',par,{Text=text,Position=pos,Size=size,TextColor3=white,BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=fontSize or 13,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left})
end
local function button(par,text,pos,size,color)
 local b=make('TextButton',par,{Text=text,Position=pos,Size=size,BackgroundColor3=color or tile,TextColor3=white,Font=Enum.Font.GothamBold,TextSize=14,AutoButtonColor=true});rounded(b,10);return b
end
local launcher=button(gui,'N',UDim2.new(0,12,0.45,0),UDim2.fromOffset(55,55),gold);launcher.TextColor3=bg;launcher.TextSize=25
local main=make('Frame',gui,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(370,520),BackgroundColor3=bg,Visible=false,Active=true});rounded(main,15)
local scale=make('UIScale',main,{Scale=1})
local function fit()
 local cam=workspace.CurrentCamera;if cam then local v=cam.ViewportSize;scale.Scale=math.max(.45,math.min(1,(v.X-16)/370,(v.Y-30)/520)) end
end
fit();workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(fit)
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(fit) end
label(main,'NEXMARKET PRO',UDim2.fromOffset(16,12),UDim2.fromOffset(275,32),21).Font=Enum.Font.GothamBold
local close=button(main,'X',UDim2.new(1,-47,0,10),UDim2.fromOffset(34,34))
label(main,'Find low-priced bikes • estimate gross spread',UDim2.fromOffset(16,45),UDim2.fromOffset(338,25),12).TextColor=gold
local status=label(main,'Open NEXMARKET Browse, search for a bike, then scan.',UDim2.fromOffset(16,76),UDim2.fromOffset(338,42),12)
local bikes={'ZOOTIO','NXR K10','ZORAN LIGHT X','ZORAN ULTRA HP X','RAZE 250F','RYVEN 250','ZORAN MX','STARKEN'}
local selected={}
local bikeFrame=make('ScrollingFrame',main,{Position=UDim2.fromOffset(16,122),Size=UDim2.fromOffset(338,133),BackgroundColor3=tile,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.fromOffset(0,#bikes*39+8)});rounded(bikeFrame,9)
for i,name in ipairs(bikes) do
 local b=button(bikeFrame,'+  '..name,UDim2.fromOffset(5,(i-1)*39+5),UDim2.fromOffset(320,35),bg)
 b.Activated:Connect(function() selected[name]=not selected[name];b.Text=(selected[name] and '✓  ' or '+  ')..name;b.BackgroundColor3=selected[name] and Color3.fromRGB(77,65,37) or bg end)
end
local scan=button(main,'SCAN VISIBLE MARKET',UDim2.fromOffset(16,266),UDim2.fromOffset(338,44),gold);scan.TextColor3=bg
local hint=label(main,'Tip: Search a selected model in the game phone and choose Lowest Price first.',UDim2.fromOffset(16,316),UDim2.fromOffset(338,38),11)
local output=make('ScrollingFrame',main,{Position=UDim2.fromOffset(16,357),Size=UDim2.fromOffset(338,147),BackgroundColor3=tile,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.fromOffset(0,0)});rounded(output,9)
local outText=label(output,'No scan yet.',UDim2.fromOffset(10,8),UDim2.fromOffset(315,120),12);outText.TextYAlignment=Enum.TextYAlignment.Top
local function show(lines)
 outText.Text=table.concat(lines,'\n');local count=0;for _ in outText.Text:gmatch('\n') do count=count+1 end
 local h=math.max(130,(count+2)*19);outText.Size=UDim2.fromOffset(315,h);output.CanvasSize=UDim2.fromOffset(0,h+14)
end
launcher.Activated:Connect(function()main.Visible=not main.Visible end)
close.Activated:Connect(function()main.Visible=false end)
-- Prices are extracted only from nearby GUI labels, never from unrelated distant text.
local function visible(o)
 local p=o
 while p and p~=pg do
  if p:IsA('GuiObject') and (not p.Visible or p.AbsoluteSize.X<1 or p.AbsoluteSize.Y<1) then return false end
  p=p.Parent
 end
 return true
end
local function priceOf(s)
 if type(s)~='string' then return nil end
 local t=s:match('%$%s*([%d,]+)')
 if not t then return nil end
 local n=tonumber(t:gsub(',',''))
 if n and n>=100 and n<=10000000 then return n end
end
local function readTexts(root)
 local arr={}
 for _,o in ipairs(root:GetDescendants()) do
  if (o:IsA('TextLabel') or o:IsA('TextButton') or o:IsA('TextBox')) and visible(o) then
   local s=o.Text
   if s and #s>0 and #s<300 then arr[#arr+1]={o=o,text=s,upper=s:upper()} end
  end
 end
 return arr
end
local function collect()
 local all=readTexts(pg);local entries={};local seen={}
 for _,item in ipairs(all) do
  if not item.o:IsDescendantOf(gui) then
   local model=nil
   for _,b in ipairs(bikes) do if item.upper:find(b,1,true) then model=b;break end end
   if model then
    local ancestor=item.o.Parent
    for depth=1,3 do
     if not ancestor or ancestor==pg then break end
     local matches={};local ptexts=readTexts(ancestor)
     for _,x in ipairs(ptexts) do
      if not x.o:IsDescendantOf(gui) then
       local n=priceOf(x.text)
       if n then matches[n]=true end
      end
     end
     local prices={};for p in pairs(matches) do prices[#prices+1]=p end
     -- Exactly one price nearby avoids ambiguous listing associations.
     if #prices==1 then
      local key=model..':'..prices[1]..':'..tostring(ancestor)
      if not seen[key] then seen[key]=true;entries[#entries+1]={model=model,price=prices[1]} end
      break
     end
     ancestor=ancestor.Parent
    end
   end
  end
 end
 return entries
end
local function money(n) return '$'..string.format('%.0f',n):reverse():gsub('(%d%d%d)','%1,'):reverse():gsub('^,','') end
local busy=false
scan.Activated:Connect(function()
 if busy then return end
 busy=true;scan.Text='SCANNING...';status.Text='Reading visible marketplace UI...'
 task.wait(.25)
 local raw=collect();local grouped={};for _,b in ipairs(bikes) do if selected[b] then grouped[b]={} end end
 local chosen=0;for _ in pairs(grouped) do chosen=chosen+1 end
 if chosen==0 then status.Text='Select at least one bike.';show({'Choose a bike above, then try again.'});busy=false;scan.Text='SCAN VISIBLE MARKET';return end
 for _,r in ipairs(raw) do if grouped[r.model] then table.insert(grouped[r.model],r.price) end end
 local lines={};local total=0
 for _,b in ipairs(bikes) do
  local prices=grouped[b]
  if prices then
   table.sort(prices);local uniq={};local last=nil
   for _,p in ipairs(prices) do if p~=last then uniq[#uniq+1]=p;last=p end end
   total=total+#uniq;lines[#lines+1]='• '..b
   if #uniq==0 then lines[#lines+1]='  No unambiguous visible listing found.'
   else
    lines[#lines+1]='  Cheapest detected: '..money(uniq[1])
    local top={};for i=1,math.min(5,#uniq) do top[#top+1]=money(uniq[i]) end
    lines[#lines+1]='  Detected prices: '..table.concat(top,', ')
    if #uniq>=3 then
     local mid=uniq[math.floor((#uniq+1)/2)]
     local spread=mid-uniq[1]
     lines[#lines+1]='  Comparable median: '..money(mid)
     lines[#lines+1]='  Potential gross spread: '..money(spread)
     lines[#lines+1]='  Sale likelihood: insufficient sales data'
    else lines[#lines+1]='  Not enough comparable prices for resale estimate.' end
   end
   lines[#lines+1]=''
  end
 end
 status.Text='Found '..total..' distinct visible price(s). Results are not a full-market scan.'
 lines[#lines+1]='Estimates exclude fees; asking prices do not prove sales.'
 show(lines);scan.Text='SCAN VISIBLE MARKET';busy=false
end)
-- Mobile touch-friendly launcher dragging; taps still use Activated.
do
 local drag=false;local origin;local start;local activeInput
 launcher.InputBegan:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then drag=true;origin=input.Position;start=launcher.Position;activeInput=input end
 end)
 UIS.InputChanged:Connect(function(input)
  if not drag then return end
  if input==activeInput or (activeInput and activeInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement) then
   local d=input.Position-origin;launcher.Position=UDim2.new(start.X.Scale,start.X.Offset+d.X,start.Y.Scale,start.Y.Offset+d.Y)
  end
 end)
 UIS.InputEnded:Connect(function(input)if input==activeInput then drag=false;activeInput=nil end end)
end
print('[NexMarketPRO] Mobile finder loaded. Tap N to open.')
