-- Nero | Garden Horizons developer automation panel
-- Client-side QA harness. All farming modules default to OFF.

local NERO_ENV=getgenv()
NERO_ENV.NeroLaunchSerial=(tonumber(NERO_ENV.NeroLaunchSerial) or 0)+1
local NERO_LAUNCH_ID=NERO_ENV.NeroLaunchSerial
local previousNero=getgenv().Nero
if previousNero then
    if type(previousNero.Destroy)=="function" and previousNero.alive then pcall(function() previousNero:Destroy() end) end
    previousNero.alive=false
    for _,c in ipairs(type(previousNero.conns)=="table" and previousNero.conns or {}) do pcall(function() c:Disconnect() end) end
    for _,thread in ipairs(type(previousNero.threads)=="table" and previousNero.threads or {}) do pcall(task.cancel,thread) end
    pcall(function() if previousNero.LoadingGui then previousNero.LoadingGui:Destroy() end end)
    pcall(function() if previousNero.PlayerControlsGui then previousNero.PlayerControlsGui:Destroy() end end)
    pcall(function() if previousNero.Gui then previousNero.Gui:Destroy() end end)
    getgenv().Nero=nil
end

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local VU = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local LP = Players.LocalPlayer
local Remotes = RS:WaitForChild("RemoteEvents")

local function inst(class, props, parent)
    local o=Instance.new(class)
    for k,v in pairs(props or {}) do o[k]=v end
    o.Parent=parent
    return o
end

local playerGui=LP:WaitForChild("PlayerGui")
if NERO_ENV.NeroLaunchSerial~=NERO_LAUNCH_ID then return end
for _,oldGui in ipairs(playerGui:GetChildren()) do if oldGui.Name=="Nero" or oldGui.Name=="NeroLoading" or oldGui.Name=="NeroPlayerControls" then oldGui:Destroy() end end
local Nero = {alive=true, launchId=NERO_LAUNCH_ID, started=os.clock(), stats={harvested=0, planted=0, sold=0}, conns={}, threads={}, selectionRevision={}}
getgenv().Nero = Nero

local NERO_DISPLAY_ORDER=2147483647
local loadingGui=inst("ScreenGui",{Name="NeroLoading",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=NERO_DISPLAY_ORDER,OnTopOfCoreBlur=true,ZIndexBehavior=Enum.ZIndexBehavior.Global},playerGui)
Nero.LoadingGui=loadingGui
local loadingRoot=inst("CanvasGroup",{Name="MagicLoading",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,GroupTransparency=0},loadingGui)
local loadingBackdrop=inst("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(12,4,27),BorderSizePixel=0},loadingRoot)
local loadingGradient=inst("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(14,5,35)),ColorSequenceKeypoint.new(.45,Color3.fromRGB(74,18,118)),ColorSequenceKeypoint.new(.72,Color3.fromRGB(40,17,99)),ColorSequenceKeypoint.new(1,Color3.fromRGB(9,5,28))}),Rotation=25},loadingBackdrop)
local loadingAuraData={
    {Color3.fromRGB(205,63,255),UDim2.fromOffset(420,420),UDim2.new(.12,-210,.16,-210)},
    {Color3.fromRGB(79,117,255),UDim2.fromOffset(520,520),UDim2.new(.82,-260,.32,-260)},
    {Color3.fromRGB(255,87,220),UDim2.fromOffset(470,470),UDim2.new(.5,-235,.92,-235)}
}
for i,v in ipairs(loadingAuraData) do
    local aura=inst("Frame",{Size=v[2],Position=v[3],BackgroundColor3=v[1],BackgroundTransparency=.58,BorderSizePixel=0},loadingRoot); inst("UICorner",{CornerRadius=UDim.new(1,0)},aura)
    inst("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.38),NumberSequenceKeypoint.new(.45,.68),NumberSequenceKeypoint.new(1,1)})},aura)
    TS:Create(aura,TweenInfo.new(3.2+i*.55,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true,i*.18),{Position=UDim2.new(v[3].X.Scale+(i==2 and -.1 or .1),v[3].X.Offset,v[3].Y.Scale-.08,v[3].Y.Offset),BackgroundTransparency=.76,Rotation=i%2==0 and -18 or 18}):Play()
end
local loadingCard=inst("Frame",{AnchorPoint=Vector2.new(.5,.5),Size=UDim2.new(.82,0,0,224),Position=UDim2.fromScale(.5,.5),BackgroundColor3=Color3.fromRGB(37,15,67),BackgroundTransparency=.08,BorderSizePixel=0},loadingRoot)
local loadingCardScale=inst("UIScale",{Scale=.88},loadingCard)
inst("UISizeConstraint",{MinSize=Vector2.new(285,210),MaxSize=Vector2.new(470,224)},loadingCard)
inst("UICorner",{CornerRadius=UDim.new(0,24)},loadingCard)
inst("UIStroke",{Color=Color3.fromRGB(218,129,255),Transparency=.08,Thickness=2},loadingCard)
inst("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(70,25,117)),ColorSequenceKeypoint.new(.5,Color3.fromRGB(36,15,69)),ColorSequenceKeypoint.new(1,Color3.fromRGB(46,22,97))}),Rotation=125},loadingCard)
local loadingTitle=inst("TextLabel",{Size=UDim2.new(1,-36,0,58),Position=UDim2.fromOffset(18,24),BackgroundTransparency=1,Text="NERO",Font=Enum.Font.GothamBlack,TextSize=42,TextColor3=Color3.fromRGB(255,241,255),TextStrokeColor3=Color3.fromRGB(160,60,255),TextStrokeTransparency=.45,ZIndex=2},loadingCard)
local loadingTitleGradient=inst("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,226,255)),ColorSequenceKeypoint.new(.42,Color3.fromRGB(224,132,255)),ColorSequenceKeypoint.new(.72,Color3.fromRGB(123,207,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,184,240))}),Rotation=0},loadingTitle)
inst("TextLabel",{Size=UDim2.new(1,-36,0,28),Position=UDim2.fromOffset(18,78),BackgroundTransparency=1,Text="G A R D E N   H O R I Z O N S",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.fromRGB(215,181,255),ZIndex=2},loadingCard)
local loadingStatus=inst("TextLabel",{Size=UDim2.new(1,-46,0,25),Position=UDim2.fromOffset(23,128),BackgroundTransparency=1,Text="Awakening the garden magic...",Font=Enum.Font.GothamMedium,TextSize=12,TextColor3=Color3.fromRGB(231,211,255),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=2},loadingCard)
local loadingTrack=inst("Frame",{Size=UDim2.new(1,-46,0,9),Position=UDim2.new(0,23,1,-43),BackgroundColor3=Color3.fromRGB(83,48,115),BackgroundTransparency=.2,BorderSizePixel=0,ZIndex=2},loadingCard); inst("UICorner",{CornerRadius=UDim.new(1,0)},loadingTrack)
local loadingFill=inst("Frame",{Size=UDim2.fromScale(.04,1),BackgroundColor3=Color3.fromRGB(208,104,255),BorderSizePixel=0,ZIndex=3},loadingTrack); inst("UICorner",{CornerRadius=UDim.new(1,0)},loadingFill)
local loadingFillGradient=inst("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(162,75,255)),ColorSequenceKeypoint.new(.5,Color3.fromRGB(255,129,234)),ColorSequenceKeypoint.new(1,Color3.fromRGB(113,218,255))})},loadingFill)
for i=1,15 do
    local size=3+(i%4)
    local star=inst("Frame",{Size=UDim2.fromOffset(size,size),Position=UDim2.fromScale(((i*37)%100)/100,((i*61)%100)/100),BackgroundColor3=({Color3.fromRGB(248,201,255),Color3.fromRGB(154,218,255),Color3.fromRGB(225,127,255)})[(i%3)+1],BackgroundTransparency=.2,BorderSizePixel=0,Rotation=45,ZIndex=1},loadingRoot); inst("UICorner",{CornerRadius=UDim.new(0,1)},star)
    TS:Create(star,TweenInfo.new(1.5+(i%5)*.38,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true,i*.08),{BackgroundTransparency=.92,Rotation=135,Position=UDim2.fromScale(((i*37)%100)/100,math.max(0,((i*61)%100)/100-.06))}):Play()
end
TS:Create(loadingGradient,TweenInfo.new(7,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Rotation=205}):Play()
TS:Create(loadingTitleGradient,TweenInfo.new(2.8,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Rotation=180}):Play()
TS:Create(loadingFillGradient,TweenInfo.new(1.8,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1,false),{Offset=Vector2.new(1,0)}):Play()
TS:Create(loadingCardScale,TweenInfo.new(.65,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()

local function spawnProcess(fn)
    local thread=task.spawn(function() if Nero.alive and NERO_ENV.NeroLaunchSerial==NERO_LAUNCH_ID then fn() end end)
    table.insert(Nero.threads,thread)
    return thread
end
local function delayProcess(seconds,fn)
    local thread=task.delay(seconds,function() if Nero.alive and NERO_ENV.NeroLaunchSerial==NERO_LAUNCH_ID then fn() end end)
    table.insert(Nero.threads,thread)
    return thread
end

local C = {
    Harvest=false, HarvestInterval=1, MutationMode="Harvest All", FavoriteProtection=true,
    MinFruitValue=0, MinWeight=0, AutoCollect=true, HarvestMethod="Direct Remote",
    Plant=false, SeedMode="Smart (Most Valuable)", SeedReserve=0, ReplantDelay=.5,
    AutoReplant=true, EmptyOnly=true, Sell=false, SellTrigger="After Each Harvest Cycle",
    SellTimer=2, SellThreshold=50000, MutationProtection=true, MinSellValue=0,
    TeleportSell=true, ReturnPosition="My Plot", BuySeeds=false, BuyGears=false,
    ClaimDaily=false, ClaimWeekly=false, QuestPoll=10, Refresh=false, MaxRefresh=10,
    QuestFocus="Any", Spin=false, PackPriority="Best First", Pity=true, StopPity=0,
    Water=false, WaterInterval=5, Sprinklers=false, SprinklerType="Best Available",
    ReplaceSprinklers=true, AntiAFK=true, RespawnReturn=true, Status=true, Log=true,
    LoginClaim=false, Speed="Normal", Sounds=false, WalkSpeed=16, JumpHeight=7.2,
    Fly=false, FlySpeed=50, Noclip=false,
    AutoSave=true, AutoLoad=true, ActiveConfig="default", ModeratorSafety=false, ModeratorAction="Leave",
    InterfaceSize="Normal", OrbSize="Normal", FontSize="Normal", ThemeHue=.775,
    SeedWhitelist={__ALL=true}, PlantSeedWhitelist={__ALL=true}, GearWhitelist={__ALL=true}, PlantWhitelist={__ALL=true}, RarityWhitelist={__ALL=true}, MutationWhitelist={__ALL=true},
    Ripeness="Doesn't Matter"
}

local Http=game:GetService("HttpService")
local PlantDefinitions=require(RS.Plants.Definitions.PlantDefinitions)
local MutationDefinitions=require(RS.Plants.Definitions.MutationDataDefinitions)
local SeedShopData=require(RS.Shop.ShopData.SeedShopData)
local GearShopData=require(RS.Shop.ShopData.GearShopData)
local GearDefinitions=require(RS.Gears.Definitions.GearDefinitions)
local ItemInventory=require(RS.Inventory.ItemInventory)
local FruitValueCalculator=require(RS.Economy.FruitValueCalculator)
local ReplicaClient=require(RS.ReplicaClient)
local GroupUtils=require(RS.Util.GroupUtils)
Nero.replica=nil
table.insert(Nero.conns,ReplicaClient.OnNew("PlayerData_"..LP.UserId,function(replica) Nero.replica=replica end))
local CONFIG_DIR="NeroConfigs"
local WHITELIST_KEYS={"SeedWhitelist","PlantSeedWhitelist","GearWhitelist","PlantWhitelist","RarityWhitelist","MutationWhitelist"}
local function normalizeConfig()
    for _,key in ipairs(WHITELIST_KEYS) do
        if type(C[key])~="table" then C[key]={__ALL=true}
        elseif next(C[key])==nil then C[key].__ALL=true
        elseif C[key].__ALL==nil then C[key].__ALL=false end
    end
    if type(C.ModeratorSafety)~="boolean" then C.ModeratorSafety=false end
    if type(C.Fly)~="boolean" then C.Fly=false end
    if type(C.Noclip)~="boolean" then C.Noclip=false end
    C.FlySpeed=math.clamp(tonumber(C.FlySpeed) or 50,5,300)
    if C.ModeratorAction~="Leave" and C.ModeratorAction~="Server Hop" then C.ModeratorAction="Leave" end
    if not table.find({"Tiny","Normal","Big"},C.InterfaceSize) then C.InterfaceSize="Normal" end
    if not table.find({"Tiny","Normal","Big"},C.OrbSize) then C.OrbSize="Normal" end
    if not table.find({"Small","Normal","Large"},C.FontSize) then C.FontSize="Normal" end
    C.ThemeHue=math.clamp(tonumber(C.ThemeHue) or .775,0,1)
    C.MaxSeedPrice=nil; C.MaxGearPrice=nil; C.BuyAll=nil; C.PollRate=nil; C.MinShopBalance=nil; C.ShopTeleport=nil; C.ShopReturn=nil
end
local function safeName(s) local clean=tostring(s or "default"):gsub("[^%w_%- ]",""):sub(1,32); return clean~="" and clean or "default" end
local function configPath(n) return CONFIG_DIR.."/"..safeName(n)..".json" end
local ACTIVE_CONFIG_PATH=CONFIG_DIR.."/active.txt"
local function ensureDir() if makefolder and isfolder and not isfolder(CONFIG_DIR) then pcall(makefolder,CONFIG_DIR) end end
local function rememberActive(n) if writefile then ensureDir(); pcall(writefile,ACTIVE_CONFIG_PATH,safeName(n)) end end
local function saveConfig(n)
    if not writefile then return false,"filesystem unavailable" end
    ensureDir(); n=safeName(n); C.ActiveConfig=n
    local ok,err=pcall(writefile,configPath(n),Http:JSONEncode(C)); if ok then rememberActive(n) end; return ok,err
end
local function loadConfig(n)
    if not (readfile and isfile) or not isfile(configPath(n)) then return false,"not found" end
    local ok,data=pcall(function() return Http:JSONDecode(readfile(configPath(n))) end)
    if ok and type(data)=="table" then for k,v in pairs(data) do C[k]=v end; C.ActiveConfig=safeName(n); normalizeConfig(); rememberActive(n) end
    return ok,data
end
local function listConfigs()
    local out={"default"}; ensureDir()
    if listfiles then for _,f in ipairs(listfiles(CONFIG_DIR)) do local n=f:match("([^/\\]+)%.json$"); if n and not table.find(out,n) then table.insert(out,n) end end end
    table.sort(out); return out
end
local startupConfig="default"
if isfile and readfile and isfile(ACTIVE_CONFIG_PATH) then local ok,name=pcall(readfile,ACTIVE_CONFIG_PATH); if ok then startupConfig=safeName(name) end end
if isfile and C.AutoLoad then
    if isfile(configPath(startupConfig)) then loadConfig(startupConfig)
    elseif isfile(configPath("default")) then loadConfig("default") end
end
normalizeConfig()
Nero.Config=C

if NERO_ENV.NeroLaunchSerial~=NERO_LAUNCH_ID then
    Nero.alive=false
    if loadingGui then loadingGui:Destroy() end
    return
end

local gui=inst("ScreenGui",{Name="Nero",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=NERO_DISPLAY_ORDER,OnTopOfCoreBlur=true,ZIndexBehavior=Enum.ZIndexBehavior.Global},playerGui)
Nero.Gui=gui
local playerControlsGui=inst("ScreenGui",{Name="NeroPlayerControls",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=NERO_DISPLAY_ORDER,OnTopOfCoreBlur=true,ZIndexBehavior=Enum.ZIndexBehavior.Global},playerGui)
Nero.PlayerControlsGui=playerControlsGui
local flightControls=inst("Frame",{Name="FlightTouchControls",AnchorPoint=Vector2.new(1,.5),Size=UDim2.fromOffset(76,150),Position=UDim2.new(1,-18,.55,0),BackgroundColor3=Color3.fromRGB(37,15,67),BackgroundTransparency=.12,BorderSizePixel=0,Visible=false,Active=true,ZIndex=200},playerControlsGui)
inst("UICorner",{CornerRadius=UDim.new(0,17)},flightControls)
inst("UIStroke",{Color=Color3.fromRGB(218,129,255),Transparency=.12,Thickness=2},flightControls)
inst("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(83,31,132)),ColorSequenceKeypoint.new(1,Color3.fromRGB(31,18,70))}),Rotation=110},flightControls)
inst("TextLabel",{Size=UDim2.new(1,0,0,27),BackgroundTransparency=1,Text="FLY",Font=Enum.Font.GothamBlack,TextSize=11,TextColor3=Color3.fromRGB(246,223,255),ZIndex=201},flightControls)
local flyUpButton=inst("TextButton",{Name="Ascend",Size=UDim2.fromOffset(60,50),Position=UDim2.fromOffset(8,27),BackgroundColor3=Color3.fromRGB(122,53,184),Text="UP",Font=Enum.Font.GothamBold,TextSize=13,TextColor3=Color3.fromRGB(255,241,255),AutoButtonColor=false,ZIndex=201},flightControls)
inst("UICorner",{CornerRadius=UDim.new(0,12)},flyUpButton); inst("UIStroke",{Color=Color3.fromRGB(232,159,255),Transparency=.35,Thickness=1},flyUpButton)
local flyDownButton=inst("TextButton",{Name="Descend",Size=UDim2.fromOffset(60,50),Position=UDim2.fromOffset(8,86),BackgroundColor3=Color3.fromRGB(76,45,133),Text="DOWN",Font=Enum.Font.GothamBold,TextSize=11,TextColor3=Color3.fromRGB(244,228,255),AutoButtonColor=false,ZIndex=201},flightControls)
inst("UICorner",{CornerRadius=UDim.new(0,12)},flyDownButton); inst("UIStroke",{Color=Color3.fromRGB(184,142,255),Transparency=.4,Thickness=1},flyDownButton)
local touchFlyUp,touchFlyDown=false,false
local function bindFlightHold(button,setter)
    table.insert(Nero.conns,button.InputBegan:Connect(function(inputObject)
        if inputObject.UserInputType==Enum.UserInputType.Touch or inputObject.UserInputType==Enum.UserInputType.MouseButton1 then setter(true) end
    end))
    table.insert(Nero.conns,button.InputEnded:Connect(function(inputObject)
        if inputObject.UserInputType==Enum.UserInputType.Touch or inputObject.UserInputType==Enum.UserInputType.MouseButton1 then setter(false) end
    end))
end
bindFlightHold(flyUpButton,function(active) touchFlyUp=active end)
bindFlightHold(flyDownButton,function(active) touchFlyDown=active end)
local camera=workspace.CurrentCamera
local responsiveScale=math.clamp(math.min(camera.ViewportSize.X/850,camera.ViewportSize.Y/570),.3,1)
local uiScale=inst("UIScale",{Scale=responsiveScale},gui)
local glow=inst("Frame",{Name="Glow",Size=UDim2.fromOffset(790,520),Position=UDim2.new(.5,-395,.5,-260),BackgroundColor3=Color3.fromRGB(169,58,255),BackgroundTransparency=.48,BorderSizePixel=0,Visible=false},gui)
inst("UICorner",{CornerRadius=UDim.new(0,24)},glow)
inst("UIStroke",{Color=Color3.fromRGB(230,146,255),Transparency=.5,Thickness=4},glow)
inst("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(224,72,255)),ColorSequenceKeypoint.new(.5,Color3.fromRGB(86,93,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,91,211))}),Rotation=20},glow)
local main=inst("Frame",{Name="Main",Size=UDim2.fromOffset(760,490),Position=UDim2.new(.5,-380,.5,-245),BackgroundColor3=Color3.fromRGB(19,8,38),BackgroundTransparency=.025,BorderSizePixel=0,ClipsDescendants=true,Visible=false},gui)
inst("UICorner",{CornerRadius=UDim.new(0,18)},main)
inst("UIStroke",{Color=Color3.fromRGB(211,119,255),Transparency=.08,Thickness=2},main)
local grad=inst("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(66,21,102)),ColorSequenceKeypoint.new(.35,Color3.fromRGB(30,13,65)),ColorSequenceKeypoint.new(.72,Color3.fromRGB(20,13,57)),ColorSequenceKeypoint.new(1,Color3.fromRGB(51,17,73))}),Rotation=135},main)
local aurora=inst("Frame",{Name="Aurora",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=0},main)
local ribbons={
    {Color3.fromRGB(215,67,255),UDim2.fromScale(.62,.31),UDim2.fromScale(-.17,.01),24},
    {Color3.fromRGB(89,104,255),UDim2.fromScale(.76,.25),UDim2.fromScale(.38,.39),-18},
    {Color3.fromRGB(255,93,220),UDim2.fromScale(.55,.21),UDim2.fromScale(.02,.76),12},
    {Color3.fromRGB(74,211,255),UDim2.fromScale(.46,.17),UDim2.fromScale(.68,.08),-9},
    {Color3.fromRGB(188,103,255),UDim2.fromScale(.43,.16),UDim2.fromScale(.3,.56),17}
}
for i,v in ipairs(ribbons) do
    local a=inst("Frame",{Name="Ribbon"..i,Size=v[2],Position=v[3],BackgroundColor3=v[1],BackgroundTransparency=.65,BorderSizePixel=0,Rotation=v[4],ZIndex=0},aurora); inst("UICorner",{CornerRadius=UDim.new(1,0)},a)
    inst("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.32,.1),NumberSequenceKeypoint.new(.68,.3),NumberSequenceKeypoint.new(1,1)})},a)
    spawnProcess(function() while Nero.alive do TS:Create(a,TweenInfo.new(4+i*.65,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Position=UDim2.new(v[3].X.Scale+.2,v[3].X.Offset,v[3].Y.Scale-.08,v[3].Y.Offset),Rotation=v[4]+12,BackgroundTransparency=.8}):Play(); task.wait(4+i*.65); TS:Create(a,TweenInfo.new(4+i*.65,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Position=v[3],Rotation=v[4],BackgroundTransparency=.61}):Play(); task.wait(4+i*.65) end end)
end
local magicDust=inst("Frame",{Name="MagicDust",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=0},main)
local dustColors={Color3.fromRGB(255,211,255),Color3.fromRGB(139,222,255),Color3.fromRGB(231,138,255)}
for i=1,18 do
    local size=2+(i%4)
    local x=((i*43)%96)/100+.02; local y=((i*67)%92)/100+.03
    local mote=inst("Frame",{Size=UDim2.fromOffset(size,size),Position=UDim2.fromScale(x,y),BackgroundColor3=dustColors[(i%3)+1],BackgroundTransparency=.15,BorderSizePixel=0,Rotation=45,ZIndex=0},magicDust); inst("UICorner",{CornerRadius=UDim.new(0,1)},mote)
    TS:Create(mote,TweenInfo.new(1.6+(i%6)*.36,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true,i*.06),{Position=UDim2.fromScale(x,math.max(.01,y-.055)),BackgroundTransparency=.9,Rotation=135}):Play()
end
local top=inst("Frame",{Name="DragHeader",Size=UDim2.new(1,0,0,58),BackgroundTransparency=1,Active=true},main)
local title=inst("TextLabel",{Size=UDim2.fromOffset(112,42),Position=UDim2.fromOffset(22,8),BackgroundTransparency=1,Text="NERO",Font=Enum.Font.GothamBlack,TextSize=29,TextColor3=Color3.fromRGB(255,235,255),TextStrokeColor3=Color3.fromRGB(164,67,255),TextStrokeTransparency=.58,TextXAlignment=Enum.TextXAlignment.Left},top)
local titleGradient=inst("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,226,255)),ColorSequenceKeypoint.new(.45,Color3.fromRGB(218,125,255)),ColorSequenceKeypoint.new(.72,Color3.fromRGB(119,217,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,174,233))}),Rotation=0},title)
local sub=inst("TextLabel",{Size=UDim2.fromOffset(310,22),Position=UDim2.fromOffset(130,19),BackgroundTransparency=1,Text="GARDEN HORIZONS",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.fromRGB(218,181,255),TextXAlignment=Enum.TextXAlignment.Left},top)
local headerLine=inst("Frame",{Size=UDim2.new(1,-34,0,2),Position=UDim2.fromOffset(17,56),BackgroundColor3=Color3.fromRGB(203,95,255),BackgroundTransparency=.2,BorderSizePixel=0},top); inst("UICorner",{CornerRadius=UDim.new(1,0)},headerLine)
local headerGradient=inst("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(99,83,255)),ColorSequenceKeypoint.new(.45,Color3.fromRGB(246,112,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(99,220,255))}),Offset=Vector2.new(-.7,0)},headerLine)
local stop=inst("TextButton",{Name="CloseNero",Size=UDim2.fromOffset(32,32),Position=UDim2.new(1,-82,0,13),BackgroundColor3=Color3.fromRGB(137,35,91),Text="×",Font=Enum.Font.GothamBold,TextSize=20,TextColor3=Color3.fromRGB(255,211,236),AutoButtonColor=false},top)
inst("UICorner",{CornerRadius=UDim.new(0,9)},stop)
inst("UIStroke",{Color=Color3.fromRGB(255,115,191),Transparency=.35,Thickness=1},stop)
local min=inst("TextButton",{Size=UDim2.fromOffset(32,32),Position=UDim2.new(1,-42,0,13),BackgroundColor3=Color3.fromRGB(79,42,113),Text="—",Font=Enum.Font.GothamBold,TextSize=16,TextColor3=Color3.fromRGB(238,217,255),AutoButtonColor=false},top)
inst("UICorner",{CornerRadius=UDim.new(0,9)},min)
inst("UIStroke",{Color=Color3.fromRGB(176,94,255),Transparency=.3,Thickness=1},min)
local orbGlow=inst("Frame",{Name="NeroOrbGlow",AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(66,66),Position=UDim2.new(0,51,.5,0),BackgroundColor3=Color3.fromRGB(190,70,255),BackgroundTransparency=.25,BorderSizePixel=0,ZIndex=90,Visible=false},gui); inst("UICorner",{CornerRadius=UDim.new(1,0)},orbGlow); inst("UIStroke",{Color=Color3.fromRGB(244,181,255),Thickness=2,Transparency=.22},orbGlow)
local orb=inst("TextButton",{Name="NeroOrb",Size=UDim2.fromOffset(54,54),Position=UDim2.fromOffset(6,6),BackgroundColor3=Color3.fromRGB(63,24,103),Text="N",Font=Enum.Font.GothamBlack,TextSize=25,TextColor3=Color3.fromRGB(255,239,255),TextStrokeColor3=Color3.fromRGB(164,65,255),TextStrokeTransparency=.55,AutoButtonColor=false,ZIndex=91},orbGlow); inst("UICorner",{CornerRadius=UDim.new(1,0)},orb); inst("UIStroke",{Color=Color3.fromRGB(234,159,255),Thickness=1.8,Transparency=.05},orb)
local og=inst("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(126,53,214)),ColorSequenceKeypoint.new(.4,Color3.fromRGB(228,82,244)),ColorSequenceKeypoint.new(.7,Color3.fromRGB(92,174,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(101,39,174))}),Rotation=0},orb)
TS:Create(og,TweenInfo.new(3,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1,false),{Rotation=360}):Play()

local nav=inst("ScrollingFrame",{Size=UDim2.fromOffset(168,370),Position=UDim2.fromOffset(14,64),BackgroundColor3=Color3.fromRGB(43,20,71),BackgroundTransparency=.42,BorderSizePixel=0,ScrollBarThickness=0,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.fromOffset(0,0)},main); inst("UICorner",{CornerRadius=UDim.new(0,13)},nav); inst("UIStroke",{Color=Color3.fromRGB(169,91,225),Transparency=.58,Thickness=1},nav)
inst("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},nav)
local pages=inst("Frame",{Size=UDim2.new(1,-196,1,-116),Position=UDim2.fromOffset(190,64),BackgroundTransparency=1},main)
local status=inst("TextLabel",{Size=UDim2.new(1,-28,0,34),Position=UDim2.new(0,14,1,-43),BackgroundColor3=Color3.fromRGB(46,20,76),BackgroundTransparency=.08,Text="   ◆  Nero ready • all automation is idle",Font=Enum.Font.GothamSemibold,TextSize=11,TextColor3=Color3.fromRGB(230,205,255),TextXAlignment=Enum.TextXAlignment.Left},main)
inst("UICorner",{CornerRadius=UDim.new(0,10)},status)
inst("UIStroke",{Color=Color3.fromRGB(184,102,255),Transparency=.48,Thickness=1},status)
inst("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(61,26,99)),ColorSequenceKeypoint.new(.5,Color3.fromRGB(38,23,82)),ColorSequenceKeypoint.new(1,Color3.fromRGB(67,29,94))}),Rotation=10},status)
TS:Create(titleGradient,TweenInfo.new(3.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Rotation=180}):Play()
TS:Create(headerGradient,TweenInfo.new(2.8,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Offset=Vector2.new(.7,0)}):Play()
TS:Create(grad,TweenInfo.new(8,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Rotation=220}):Play()

local tabs={"Info","Harvest","Plant","Sell","Shop","Quests","Packs","Water","Player","Customization","Misc"}
local icons={"◆","◆","✿","$","▣","✓","◆","≈","P","C","⚙"}
local current
local pageDescriptions={Info="Live garden intelligence",Harvest="Collect with precision",Plant="Shape your enchanted garden",Sell="Turn harvests into shillings",Shop="Follow every fresh restock",Quests="Claim completed rewards",Packs="Open seeds with style",Water="Keep every plant thriving",Player="Movement and character controls",Customization="Make every part of Nero yours",Misc="Safety, utilities and profiles"}
local function page(name)
    local p=inst("ScrollingFrame",{Name=name,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false,ScrollBarThickness=3,ScrollBarImageColor3=Color3.fromRGB(128,65,229),CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},pages)
    inst("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},p)
    local h=inst("Frame",{Name="PageHeader",Size=UDim2.new(1,-6,0,54),LayoutOrder=-100,BackgroundColor3=Color3.fromRGB(69,28,112),BackgroundTransparency=.06,BorderSizePixel=0},p); inst("UICorner",{CornerRadius=UDim.new(0,13)},h); inst("UIStroke",{Color=Color3.fromRGB(211,124,255),Transparency=.3,Thickness=1},h)
    inst("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(94,34,150)),ColorSequenceKeypoint.new(.55,Color3.fromRGB(52,27,111)),ColorSequenceKeypoint.new(1,Color3.fromRGB(85,36,125))}),Rotation=8},h)
    inst("TextLabel",{Size=UDim2.new(1,-58,0,25),Position=UDim2.fromOffset(15,6),BackgroundTransparency=1,Text="◆  "..name,Font=Enum.Font.FredokaOne,TextSize=16,TextColor3=Color3.fromRGB(255,236,255),TextXAlignment=Enum.TextXAlignment.Left},h)
    inst("TextLabel",{Size=UDim2.new(1,-58,0,18),Position=UDim2.fromOffset(17,30),BackgroundTransparency=1,Text=pageDescriptions[name] or "Nero garden magic",Font=Enum.Font.GothamMedium,TextSize=10,TextColor3=Color3.fromRGB(205,174,242),TextXAlignment=Enum.TextXAlignment.Left},h)
    local gem=inst("Frame",{Size=UDim2.fromOffset(17,17),Position=UDim2.new(1,-34,0,18),BackgroundColor3=Color3.fromRGB(218,117,255),BorderSizePixel=0,Rotation=45},h); inst("UICorner",{CornerRadius=UDim.new(0,4)},gem); inst("UIStroke",{Color=Color3.fromRGB(180,226,255),Transparency=.25,Thickness=1},gem)
    -- Keep the motion, but let the active palette own the gem color.
    TS:Create(gem,TweenInfo.new(2.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Rotation=135}):Play()
    return p
end
local P={}; for _,n in ipairs(tabs) do P[n]=page(n) end
local configRefreshers={}
local function addConfigRefresher(fn) table.insert(configRefreshers,fn); fn() end
local function persistConfigChange(force)
    if force or C.AutoSave then saveConfig(C.ActiveConfig) end
end
local function refreshConfigUI()
    local picker=gui:FindFirstChild("NeroPicker"); if picker then picker:Destroy() end
    for _,fn in ipairs(configRefreshers) do pcall(fn) end
    Nero.selectionRevision.SeedWhitelist=(Nero.selectionRevision.SeedWhitelist or 0)+1
    Nero.selectionRevision.GearWhitelist=(Nero.selectionRevision.GearWhitelist or 0)+1
    if Nero.ApplyCustomization then Nero.ApplyCustomization() end
end
Nero.RefreshConfigUI=refreshConfigUI
Nero.SaveConfig=saveConfig
Nero.LoadConfig=function(name)
    local ok,data=loadConfig(name)
    if ok then refreshConfigUI() end
    return ok,data
end
local function labelRow(p,title,desc)
    local r=inst("Frame",{Size=UDim2.new(1,-6,0,50),BackgroundColor3=Color3.fromRGB(42,23,67),BackgroundTransparency=.04,BorderSizePixel=0},p); inst("UICorner",{CornerRadius=UDim.new(0,11)},r)
    local stroke=inst("UIStroke",{Color=Color3.fromRGB(151,85,211),Transparency=.62,Thickness=1},r)
    inst("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(54,27,84)),ColorSequenceKeypoint.new(.55,Color3.fromRGB(39,23,72)),ColorSequenceKeypoint.new(1,Color3.fromRGB(51,27,75))}),Rotation=6},r)
    local accent=inst("Frame",{Size=UDim2.fromOffset(3,27),Position=UDim2.fromOffset(5,12),BackgroundColor3=Color3.fromRGB(207,101,255),BorderSizePixel=0},r); inst("UICorner",{CornerRadius=UDim.new(1,0)},accent); inst("UIGradient",{Color=ColorSequence.new(Color3.fromRGB(247,145,255),Color3.fromRGB(92,205,255)),Rotation=90},accent)
    inst("TextLabel",{Size=UDim2.new(1,-160,0,22),Position=UDim2.fromOffset(16,5),BackgroundTransparency=1,Text=title,Font=Enum.Font.GothamBold,TextSize=13,TextColor3=Color3.fromRGB(249,237,255),TextXAlignment=Enum.TextXAlignment.Left},r)
    inst("TextLabel",{Size=UDim2.new(1,-30,0,17),Position=UDim2.fromOffset(16,27),BackgroundTransparency=1,Text=desc or "",Font=Enum.Font.GothamMedium,TextSize=10,TextColor3=Color3.fromRGB(180,153,211),TextXAlignment=Enum.TextXAlignment.Left},r)
    local function animateHover(strokeTransparency,strokeColor,backgroundColor)
        local info=TweenInfo.new(.18)
        if Nero.ThemeTween then
            Nero.ThemeTween(stroke,info,{Transparency=strokeTransparency,Color=strokeColor})
            Nero.ThemeTween(r,info,{BackgroundColor3=backgroundColor})
        else
            TS:Create(stroke,info,{Transparency=strokeTransparency,Color=strokeColor}):Play()
            TS:Create(r,info,{BackgroundColor3=backgroundColor}):Play()
        end
    end
    r.MouseEnter:Connect(function() animateHover(.22,Color3.fromRGB(213,121,255),Color3.fromRGB(57,28,88)) end)
    r.MouseLeave:Connect(function() animateHover(.62,Color3.fromRGB(151,85,211),Color3.fromRGB(42,23,67)) end)
    return r
end
local TOGGLE_ON=Color3.fromRGB(177,73,255)
local TOGGLE_OFF=Color3.fromRGB(74,50,99)
local function toggle(p,title,key,desc)
    local r=labelRow(p,title,desc); local b=inst("TextButton",{Size=UDim2.fromOffset(50,25),Position=UDim2.new(1,-64,0,12),BackgroundColor3=C[key] and TOGGLE_ON or TOGGLE_OFF,Text="",AutoButtonColor=false},r); inst("UICorner",{CornerRadius=UDim.new(1,0)},b); inst("UIStroke",{Color=Color3.fromRGB(225,155,255),Transparency=.42,Thickness=1},b)
    local dot=inst("Frame",{Size=UDim2.fromOffset(19,19),Position=C[key] and UDim2.fromOffset(28,3) or UDim2.fromOffset(3,3),BackgroundColor3=Color3.fromRGB(255,244,255),BorderSizePixel=0},b); inst("UICorner",{CornerRadius=UDim.new(1,0)},dot); inst("UIStroke",{Color=Color3.fromRGB(189,132,255),Transparency=.4,Thickness=1},dot)
    b.MouseButton1Click:Connect(function()
        C[key]=not C[key]
        local color=C[key] and TOGGLE_ON or TOGGLE_OFF
        if Nero.ThemeTween then Nero.ThemeTween(b,TweenInfo.new(.2),{BackgroundColor3=color}) else TS:Create(b,TweenInfo.new(.2),{BackgroundColor3=color}):Play() end
        TS:Create(dot,TweenInfo.new(.2,Enum.EasingStyle.Back),{Position=C[key] and UDim2.fromOffset(28,3) or UDim2.fromOffset(3,3)}):Play()
        persistConfigChange(key=="AutoSave")
    end)
    addConfigRefresher(function()
        local on=C[key]==true; local color=on and TOGGLE_ON or TOGGLE_OFF
        if Nero.SetThemeBase then Nero.SetThemeBase(b,"BackgroundColor3",color) else b.BackgroundColor3=color end
        dot.Position=on and UDim2.fromOffset(28,3) or UDim2.fromOffset(3,3)
    end)
end
local function input(p,title,key,desc)
    local r=labelRow(p,title,desc); local b=inst("TextBox",{Size=UDim2.fromOffset(112,29),Position=UDim2.new(1,-126,0,10),BackgroundColor3=Color3.fromRGB(69,37,99),Text=tostring(C[key]),PlaceholderText="value",PlaceholderColor3=Color3.fromRGB(169,136,199),ClearTextOnFocus=false,Font=Enum.Font.GothamSemibold,TextSize=11,TextColor3=Color3.fromRGB(250,235,255)},r); inst("UICorner",{CornerRadius=UDim.new(0,8)},b); inst("UIStroke",{Color=Color3.fromRGB(187,108,241),Transparency=.45,Thickness=1},b)
    b.FocusLost:Connect(function() local n=tonumber(b.Text); C[key]=n or b.Text; persistConfigChange() end)
    addConfigRefresher(function() b.Text=tostring(C[key]) end)
end
local function dropdown(p,title,key,opts,desc)
    local r=labelRow(p,title,desc); local b=inst("TextButton",{Size=UDim2.fromOffset(160,29),Position=UDim2.new(1,-174,0,10),BackgroundColor3=Color3.fromRGB(69,37,99),Text=tostring(C[key]).."   ◆",Font=Enum.Font.GothamSemibold,TextSize=10,TextColor3=Color3.fromRGB(250,235,255),AutoButtonColor=false},r); inst("UICorner",{CornerRadius=UDim.new(0,8)},b); inst("UIStroke",{Color=Color3.fromRGB(187,108,241),Transparency=.45,Thickness=1},b)
    local i=table.find(opts,C[key]) or 1; b.MouseButton1Click:Connect(function() i=i%#opts+1; C[key]=opts[i]; b.Text=tostring(C[key]).."   ◆"; if Nero.ApplyCustomization then Nero.ApplyCustomization() end; persistConfigChange() end)
    addConfigRefresher(function() i=table.find(opts,C[key]) or 1; b.Text=tostring(C[key]).."   ◆" end)
end
local function gather(kind)
    local found={}
    local function add(v) if v and tostring(v)~="" then found[tostring(v)]=true end end
    if kind=="Plant" then for name in pairs(PlantDefinitions) do add(name) end
    elseif kind=="Rarity" then for _,v in pairs(PlantDefinitions) do if type(v)=="table" then add(v.Rarity or v.rarity) end end
    elseif kind=="Mutation" then for name in pairs(MutationDefinitions) do add(name) end
    elseif kind=="Seed" then for _,v in pairs(SeedShopData.ShopData) do if type(v)=="table" then add(v.Name) end end
    elseif kind=="PlantSeed" then
        for _,root in ipairs({LP:FindFirstChild("Backpack"),LP.Character}) do
            if root then for _,x in ipairs(root:GetChildren()) do if x:IsA("Tool") and x:GetAttribute("Type")=="Seeds" then add(x:GetAttribute("PlantType")) end end end
        end
    elseif kind=="Gear" then for key,v in pairs(GearShopData.ShopData) do add(type(v)=="table" and (v.Name or key) or key) end
    else
        local function scan(root)
            if not root then return end
            for _,x in ipairs(root:GetDescendants()) do
                if x:IsA("Tool") then
                    local typ=tostring(x:GetAttribute("Type") or "")
                    if (kind=="Seed" and (typ=="Seeds" or x.Name:lower():find("seed"))) or (kind=="Gear" and typ~="Seeds" and typ~="Plants") then add(x:GetAttribute("PlantType") or x.Name:gsub(" Seed$","")) end
                end
            end
        end
        scan(LP:FindFirstChild("Backpack")); scan(RS:FindFirstChild(kind=="Gear" and "Gears" or "Plants"))
    end
    local out={}; for n in pairs(found) do table.insert(out,n) end
    if kind=="Seed" or kind=="Gear" then
        local data=kind=="Seed" and SeedShopData.ShopData or GearShopData.ShopData
        local function layout(name)
            for key,v in pairs(data) do if key==name or (type(v)=="table" and v.Name==name) then return tonumber(v.LayoutOrder) or math.huge end end
            return math.huge
        end
        table.sort(out,function(a,b) local la,lb=layout(a),layout(b); return la==lb and a<b or la<lb end)
    else table.sort(out) end
    return out
end
local function whitelistSummary(map)
    if map.__ALL==true then return "All" end
    local n=0; for name,v in pairs(map) do if name~="__ALL" and v==true then n+=1 end end
    return n==0 and "None" or tostring(n).." selected"
end
local function multiSelect(p,title,key,kind,desc)
    local r=labelRow(p,title,desc); local b=inst("TextButton",{Size=UDim2.fromOffset(160,29),Position=UDim2.new(1,-174,0,10),BackgroundColor3=Color3.fromRGB(69,37,99),Text=whitelistSummary(C[key]).."   ◆",Font=Enum.Font.GothamSemibold,TextSize=10,TextColor3=Color3.fromRGB(250,235,255),AutoButtonColor=false},r); inst("UICorner",{CornerRadius=UDim.new(0,8)},b); inst("UIStroke",{Color=Color3.fromRGB(187,108,241),Transparency=.45,Thickness=1},b)
    addConfigRefresher(function() b.Text=whitelistSummary(C[key]).."   ◆" end)
    b.MouseButton1Click:Connect(function()
        local old=gui:FindFirstChild("NeroPicker"); if old then old:Destroy(); return end
        local pop=inst("Frame",{Name="NeroPicker",Size=UDim2.fromOffset(330,350),Position=UDim2.new(.5,-165,.5,-175),BackgroundColor3=Color3.fromRGB(43,18,73),BorderSizePixel=0,ZIndex=50},gui); inst("UICorner",{CornerRadius=UDim.new(0,16)},pop); inst("UIStroke",{Color=Color3.fromRGB(219,127,255),Transparency=.08,Thickness=2},pop); inst("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(75,28,119)),ColorSequenceKeypoint.new(.55,Color3.fromRGB(38,19,72)),ColorSequenceKeypoint.new(1,Color3.fromRGB(55,27,94))}),Rotation=120},pop)
        inst("TextLabel",{Size=UDim2.new(1,-50,0,42),Position=UDim2.fromOffset(14,0),BackgroundTransparency=1,Text="◆  "..title,Font=Enum.Font.FredokaOne,TextSize=15,TextColor3=Color3.fromRGB(255,235,255),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=51},pop)
        local close=inst("TextButton",{Size=UDim2.fromOffset(30,30),Position=UDim2.new(1,-38,0,6),BackgroundTransparency=1,Text="×",Font=Enum.Font.GothamBold,TextSize=20,TextColor3=Color3.fromRGB(180,150,220),ZIndex=51},pop); close.MouseButton1Click:Connect(function() pop:Destroy() end)
        local search=inst("TextBox",{Size=UDim2.new(1,-28,0,34),Position=UDim2.fromOffset(14,42),BackgroundColor3=Color3.fromRGB(75,40,106),PlaceholderText="Search by name...",PlaceholderColor3=Color3.fromRGB(190,157,218),Text="",ClearTextOnFocus=false,Font=Enum.Font.GothamMedium,TextSize=12,TextColor3=Color3.new(1,1,1),ZIndex=51},pop); inst("UICorner",{CornerRadius=UDim.new(0,9)},search); inst("UIStroke",{Color=Color3.fromRGB(198,119,244),Transparency=.35,Thickness=1},search)
        local list=inst("ScrollingFrame",{Size=UDim2.new(1,-28,1,-92),Position=UDim2.fromOffset(14,84),BackgroundTransparency=1,ScrollBarThickness=3,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ZIndex=51},pop); inst("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},list)
        local names=gather(kind)
        local function refreshTitle() b.Text=whitelistSummary(C[key]).."   ◆" end
        local function build(filter)
            for _,x in ipairs(list:GetChildren()) do if x:IsA("TextButton") then x:Destroy() end end
            local tokens={"__ALL"}; for _,name in ipairs(names) do table.insert(tokens,name) end
            for order,token in ipairs(tokens) do
                local label=token=="__ALL" and "All" or token
                if filter=="" or label:lower():find(filter:lower(),1,true) then
                    local chosen=C[key][token]==true
                    local row=inst("TextButton",{Size=UDim2.new(1,-4,0,30),LayoutOrder=order,BackgroundColor3=chosen and Color3.fromRGB(135,57,190) or Color3.fromRGB(55,31,76),Text=(chosen and "  ◆  " or "  ·  ")..label,Font=Enum.Font.GothamSemibold,TextSize=11,TextColor3=chosen and Color3.fromRGB(255,235,255) or Color3.fromRGB(215,195,235),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=52},list); inst("UICorner",{CornerRadius=UDim.new(0,7)},row); inst("UIStroke",{Color=Color3.fromRGB(183,104,226),Transparency=chosen and .35 or .72,Thickness=1},row)
                    row.MouseButton1Click:Connect(function() C[key][token]=not (C[key][token]==true); Nero.selectionRevision[key]=(Nero.selectionRevision[key] or 0)+1; build(search.Text); refreshTitle(); persistConfigChange() end)
                end
            end
            -- Rows are rebuilt after every selection/search. Re-theme the new
            -- instances immediately so they never flash back to base purple.
            if Nero.ApplyCustomizationTo then Nero.ApplyCustomizationTo(pop) end
        end
        search:GetPropertyChangedSignal("Text"):Connect(function() build(search.Text) end); build("")
    end)
end

local infoIdentity=labelRow(P.Info,"Player","Loading account information...")
local infoStats=labelRow(P.Info,"Session","Loading server and currency information...")
local function rowDescription(r) local best; for _,x in ipairs(r:GetChildren()) do if x:IsA("TextLabel") and x.Position.Y.Offset>20 then best=x end end; return best end
local infoIdentityText=rowDescription(infoIdentity)
local infoStatsText=rowDescription(infoStats)
local function infoBox(title)
    local r=inst("Frame",{Size=UDim2.new(1,-6,0,125),BackgroundColor3=Color3.fromRGB(46,23,75),BackgroundTransparency=.03,BorderSizePixel=0},P.Info); inst("UICorner",{CornerRadius=UDim.new(0,12)},r); inst("UIStroke",{Color=Color3.fromRGB(173,99,228),Transparency=.5,Thickness=1},r); inst("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(59,27,93)),ColorSequenceKeypoint.new(.5,Color3.fromRGB(38,23,72)),ColorSequenceKeypoint.new(1,Color3.fromRGB(56,29,81))}),Rotation=8},r)
    inst("TextLabel",{Size=UDim2.new(1,-28,0,24),Position=UDim2.fromOffset(14,7),BackgroundTransparency=1,Text="◆  "..title,Font=Enum.Font.GothamBold,TextSize=13,TextColor3=Color3.fromRGB(250,232,255),TextXAlignment=Enum.TextXAlignment.Left},r)
    return inst("TextLabel",{Size=UDim2.new(1,-28,1,-38),Position=UDim2.fromOffset(14,32),BackgroundTransparency=1,Text="Waiting for shop data...",Font=Enum.Font.GothamMedium,TextSize=10,TextColor3=Color3.fromRGB(199,171,229),TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true},r)
end
local seedStockInfo=infoBox("Current Seed Stock")
local gearStockInfo=infoBox("Current Gear Stock")

toggle(P.Harvest,"Enable Auto-Harvest","Harvest","Scans your plot for harvestable plants")
multiSelect(P.Harvest,"Plant Whitelist","PlantWhitelist","Plant","All plants enabled by default")
multiSelect(P.Harvest,"Rarity Whitelist","RarityWhitelist","Rarity","Filter by crop rarity")
multiSelect(P.Harvest,"Mutation Whitelist","MutationWhitelist","Mutation","Filter by mutation name")
dropdown(P.Harvest,"Ripeness","Ripeness",{"Doesn't Matter","Unripe","Ripened","Lush"},"Separate ripeness collection filter")
input(P.Harvest,"Minimum Weight","MinWeight","Only harvest at or above this weight")
dropdown(P.Harvest,"Harvest Method","HarvestMethod",{"Direct Remote","Harvest Bell"})
input(P.Harvest,"Harvest Interval","HarvestInterval","Seconds between scans")
dropdown(P.Harvest,"Mutation Filter","MutationMode",{"Harvest All","Only Mutated","Only Non-Mutated","Skip Mutated"})
toggle(P.Harvest,"Favorite Protection","FavoriteProtection","Never harvest favorited plants")
input(P.Harvest,"Minimum Fruit Value","MinFruitValue","Ignore fruit below this value")
toggle(P.Harvest,"Auto-Collect Drops","AutoCollect","Collect nearby physical drops")

toggle(P.Plant,"Enable Auto-Plant","Plant","Plant seeds on available dirt")
multiSelect(P.Plant,"Seeds to Plant","PlantSeedWhitelist","PlantSeed","Search owned seeds by plant name; All is enabled by default")
dropdown(P.Plant,"Seed Selection","SeedMode",{"Smart (Most Valuable)","Specific Seed","Rotation"})
input(P.Plant,"Seed Reserve","SeedReserve","Keep this many seeds in inventory")
input(P.Plant,"Replant Delay","ReplantDelay","Delay between planting requests")
toggle(P.Plant,"Auto-Replant on Harvest","AutoReplant")
toggle(P.Plant,"Empty Spots Only","EmptyOnly")

toggle(P.Sell,"Enable Auto-Sell","Sell")
dropdown(P.Sell,"Sell Trigger","SellTrigger",{"After Each Harvest Cycle","When Inventory Full","On Timer","When Value Exceeds X"})
input(P.Sell,"Timer Interval","SellTimer","Minutes")
input(P.Sell,"Value Threshold","SellThreshold")
toggle(P.Sell,"Mutation Protection","MutationProtection")
input(P.Sell,"Minimum Sell Value","MinSellValue")
toggle(P.Sell,"Teleport to Steve","TeleportSell")
dropdown(P.Sell,"Return Position","ReturnPosition",{"My Plot","Seed Shop","Stay at Steve"})

toggle(P.Shop,"Enable Seed Buying","BuySeeds")
multiSelect(P.Shop,"Seed Whitelist","SeedWhitelist","Seed","All is a selectable row; highlight it to buy every seed")
toggle(P.Shop,"Enable Gear Buying","BuyGears")
multiSelect(P.Shop,"Gear Whitelist","GearWhitelist","Gear","All is a selectable row; highlight it to buy every gear item")
labelRow(P.Shop,"Automatic Shop Travel","Seed Shop is handled first, then Gear Shop; Nero stays at the last active shop")

toggle(P.Quests,"Auto-Claim Dailies","ClaimDaily")
toggle(P.Quests,"Auto-Claim Weeklies","ClaimWeekly")
input(P.Quests,"Claim Poll Rate","QuestPoll","Seconds")

toggle(P.Packs,"Auto-Spin Packs","Spin")
dropdown(P.Packs,"Pack Priority","PackPriority",{"Best First","Worst First","Any Order"})
toggle(P.Packs,"Pity Tracker Display","Pity")
input(P.Packs,"Stop At Pity","StopPity","0 means never stop")

toggle(P.Water,"Auto-Water Plants","Water")
input(P.Water,"Water Interval","WaterInterval","Seconds")
toggle(P.Water,"Auto-Place Sprinklers","Sprinklers")
dropdown(P.Water,"Sprinkler Type","SprinklerType",{"Best Available","Basic Sprinkler","Turbo Sprinkler","Super Sprinkler"})
toggle(P.Water,"Replace Expired Sprinklers","ReplaceSprinklers")

input(P.Player,"Walk Speed","WalkSpeed","16 is Roblox default")
input(P.Player,"Jump Height","JumpHeight","7.2 is Roblox default")
toggle(P.Player,"Enable Fly","Fly","Uses WASD or the mobile thumbstick; Space/E or the touch UP button ascends")
input(P.Player,"Fly Speed","FlySpeed","Flight movement speed from 5 to 300")
toggle(P.Player,"Noclip","Noclip","Move through walls and other solid parts")
toggle(P.Player,"Auto-Respawn Return","RespawnReturn","Return to your plot after respawning")

local openColorWheel
dropdown(P.Customization,"Interface Size","InterfaceSize",{"Tiny","Normal","Big"},"Resize the complete Nero interface")
dropdown(P.Customization,"N Circle Size","OrbSize",{"Tiny","Normal","Big"},"Resize the movable N launcher without moving its center")
dropdown(P.Customization,"Font Size","FontSize",{"Small","Normal","Large"},"Resize every label, control and navigation title")
local themeRow=labelRow(P.Customization,"GUI Color Palette","Choose an accent from the touch-friendly color wheel")
local themePreview=inst("Frame",{Size=UDim2.fromOffset(28,28),Position=UDim2.new(1,-174,0,10),BackgroundColor3=Color3.fromHSV(C.ThemeHue,.75,1),BorderSizePixel=0},themeRow); themePreview:SetAttribute("NeroThemeIgnore",true); inst("UICorner",{CornerRadius=UDim.new(1,0)},themePreview); inst("UIStroke",{Color=Color3.fromRGB(255,238,255),Transparency=.18,Thickness=2},themePreview)
local themeButton=inst("TextButton",{Size=UDim2.fromOffset(124,29),Position=UDim2.new(1,-140,0,10),BackgroundColor3=Color3.fromRGB(69,37,99),Text="Open Color Wheel",Font=Enum.Font.GothamSemibold,TextSize=10,TextColor3=Color3.fromRGB(250,235,255),AutoButtonColor=false},themeRow); inst("UICorner",{CornerRadius=UDim.new(0,8)},themeButton); inst("UIStroke",{Color=Color3.fromRGB(187,108,241),Transparency=.45,Thickness=1},themeButton)
themeButton.Activated:Connect(function() if openColorWheel then openColorWheel() end end)

toggle(P.Misc,"Moderator Join Protection","ModeratorSafety","Off by default; only detects the game's verified staff ranks")
dropdown(P.Misc,"What to do when moderator joins","ModeratorAction",{"Leave","Server Hop"},"Choose whether Nero leaves or moves to another public server")
toggle(P.Misc,"Anti-AFK","AntiAFK")
toggle(P.Misc,"Status Display","Status")
toggle(P.Misc,"Activity Log","Log")
toggle(P.Misc,"Auto Login-Streak Claim","LoginClaim")
dropdown(P.Misc,"Script Speed","Speed",{"Safe","Normal","Fast"})
toggle(P.Misc,"Sound Notifications","Sounds")
toggle(P.Misc,"Autosave Config","AutoSave","Save the active profile after changes")
toggle(P.Misc,"Autoload Config","AutoLoad","Load the last/default profile on startup")
local cfgRow=labelRow(P.Misc,"Named Config","Save, load, rename, or delete a profile")
cfgRow.Size=UDim2.new(1,-6,0,88)
local cfgName=inst("TextBox",{Size=UDim2.new(1,-28,0,29),Position=UDim2.fromOffset(14,43),BackgroundColor3=Color3.fromRGB(69,37,99),Text=C.ActiveConfig,PlaceholderText="Profile name",PlaceholderColor3=Color3.fromRGB(169,136,199),ClearTextOnFocus=false,Font=Enum.Font.GothamSemibold,TextSize=10,TextColor3=Color3.fromRGB(250,235,255)},cfgRow); inst("UICorner",{CornerRadius=UDim.new(0,8)},cfgName); inst("UIStroke",{Color=Color3.fromRGB(187,108,241),Transparency=.45,Thickness=1},cfgName)
local cfgActions={
    {"Save",function() saveConfig(cfgName.Text) end},
    {"Load",function() if Nero.LoadConfig(cfgName.Text) then cfgName.Text=C.ActiveConfig; status.Text="  Loaded config: "..C.ActiveConfig end end},
    {"Rename",function() local old=C.ActiveConfig; if saveConfig(cfgName.Text) and old~=C.ActiveConfig and delfile and isfile and isfile(configPath(old)) then delfile(configPath(old)) end end},
    {"Delete",function() local target=safeName(cfgName.Text); if delfile and isfile and isfile(configPath(target)) then delfile(configPath(target)); if C.ActiveConfig==target then C.ActiveConfig="default"; cfgName.Text="default"; rememberActive("default") end end end}
}
for i,spec in ipairs(cfgActions) do local b=inst("TextButton",{Size=UDim2.fromOffset(52,24),Position=UDim2.new(1,-226+(i-1)*56,0,8),BackgroundColor3=Color3.fromRGB(112,51,157),Text=spec[1],Font=Enum.Font.GothamBold,TextSize=9,TextColor3=Color3.fromRGB(253,237,255)},cfgRow); inst("UICorner",{CornerRadius=UDim.new(0,7)},b); inst("UIStroke",{Color=Color3.fromRGB(216,132,255),Transparency=.38,Thickness=1},b); b.MouseButton1Click:Connect(spec[2]) end

local buttons={}
local function selectTab(name)
    if current==name then return end
    local old=current and P[current]
    current=name
    if old then TS:Create(old,TweenInfo.new(.13,Enum.EasingStyle.Quad),{Position=UDim2.fromOffset(-18,0),ScrollBarImageTransparency=1}):Play(); delayProcess(.13,function() if current~=old.Name then old.Visible=false end end) end
    local incoming=P[name]; incoming.Visible=true; incoming.Position=UDim2.fromOffset(24,0); incoming.ScrollBarImageTransparency=1
    TS:Create(incoming,TweenInfo.new(.24,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=UDim2.fromOffset(0,0),ScrollBarImageTransparency=0}):Play()
    for n,b in pairs(buttons) do
        local selected=n==name
        local goals={BackgroundTransparency=selected and .04 or 1,BackgroundColor3=selected and Color3.fromRGB(112,48,168) or Color3.fromRGB(68,35,101),TextColor3=selected and Color3.fromRGB(255,236,255) or Color3.fromRGB(185,157,211)}
        if Nero.ThemeTween then Nero.ThemeTween(b,TweenInfo.new(.18),goals) else TS:Create(b,TweenInfo.new(.18),goals):Play() end
        local stroke=b:FindFirstChild("MagicStroke"); if stroke then TS:Create(stroke,TweenInfo.new(.18),{Transparency=selected and .35 or 1}):Play() end
    end
end
for i,n in ipairs(tabs) do
    local b=inst("TextButton",{Size=UDim2.new(1,0,0,38),BackgroundColor3=Color3.fromRGB(68,35,101),BackgroundTransparency=1,Text="   "..icons[i].."    "..n,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.fromRGB(185,157,211),TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false},nav); inst("UICorner",{CornerRadius=UDim.new(0,10)},b); inst("UIStroke",{Name="MagicStroke",Color=Color3.fromRGB(216,125,255),Transparency=1,Thickness=1},b); buttons[n]=b; b.MouseButton1Click:Connect(function() selectTab(n) end)
end
selectTab("Info")

local DEFAULT_THEME_HUE=.775
local themeOriginals=setmetatable({}, {__mode="k"})
local fontOriginals=setmetatable({}, {__mode="k"})
local function themeIgnored(obj)
    local current=obj
    while current do
        if current:GetAttribute("NeroThemeIgnore") then return true end
        if current==gui or current==loadingGui then break end
        current=current.Parent
    end
    return false
end
local function shiftedColor(color)
    local h,s,v=color:ToHSV()
    if s<.08 then return color end
    return Color3.fromHSV((h+(C.ThemeHue-DEFAULT_THEME_HUE))%1,s,v)
end
local function shiftedSequence(sequence)
    local keypoints={}
    for _,point in ipairs(sequence.Keypoints) do table.insert(keypoints,ColorSequenceKeypoint.new(point.Time,shiftedColor(point.Value))) end
    return ColorSequence.new(keypoints)
end
local function rememberThemeBase(obj,property,value)
    local original=themeOriginals[obj] or {}
    themeOriginals[obj]=original
    original[property]=value
end
local function themedValue(obj,property,value)
    if typeof(value)=="Color3" then return shiftedColor(value) end
    if typeof(value)=="ColorSequence" and obj:IsA("UIGradient") and property=="Color" then return shiftedSequence(value) end
    return value
end
local function setThemeBase(obj,property,value)
    if not obj then return end
    if not themeIgnored(obj) then rememberThemeBase(obj,property,value) end
    obj[property]=themeIgnored(obj) and value or themedValue(obj,property,value)
end
local function themeTween(obj,info,goals)
    local themedGoals={}
    local ignored=themeIgnored(obj)
    for property,value in pairs(goals) do
        if not ignored and (typeof(value)=="Color3" or typeof(value)=="ColorSequence") then rememberThemeBase(obj,property,value) end
        themedGoals[property]=ignored and value or themedValue(obj,property,value)
    end
    local tween=TS:Create(obj,info,themedGoals)
    tween:Play()
    return tween
end
Nero.SetThemeBase=setThemeBase
Nero.ThemeTween=themeTween
local function applyThemeTo(root)
    if not root then return end
    local objects={root}; for _,obj in ipairs(root:GetDescendants()) do table.insert(objects,obj) end
    for _,obj in ipairs(objects) do
        if not themeIgnored(obj) then
            local original=themeOriginals[obj] or {}; themeOriginals[obj]=original
            if obj:IsA("GuiObject") then
                if original.BackgroundColor3==nil then original.BackgroundColor3=obj.BackgroundColor3 end
                obj.BackgroundColor3=shiftedColor(original.BackgroundColor3)
            end
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                if original.TextColor3==nil then original.TextColor3=obj.TextColor3; original.TextStrokeColor3=obj.TextStrokeColor3 end
                obj.TextColor3=shiftedColor(original.TextColor3); obj.TextStrokeColor3=shiftedColor(original.TextStrokeColor3)
            end
            if obj:IsA("TextBox") then
                if original.PlaceholderColor3==nil then original.PlaceholderColor3=obj.PlaceholderColor3 end
                obj.PlaceholderColor3=shiftedColor(original.PlaceholderColor3)
            end
            if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                if original.ImageColor3==nil then original.ImageColor3=obj.ImageColor3 end
                obj.ImageColor3=shiftedColor(original.ImageColor3)
            end
            if obj:IsA("ScrollingFrame") then
                if original.ScrollBarImageColor3==nil then original.ScrollBarImageColor3=obj.ScrollBarImageColor3 end
                obj.ScrollBarImageColor3=shiftedColor(original.ScrollBarImageColor3)
            end
            if obj:IsA("UIStroke") then
                if original.Color==nil then original.Color=obj.Color end
                obj.Color=shiftedColor(original.Color)
            elseif obj:IsA("UIGradient") then
                if original.Color==nil then original.Color=obj.Color end
                obj.Color=shiftedSequence(original.Color)
            end
        end
    end
end
local interfaceFactors={Tiny=.78,Normal=1,Big=1.16}
local fontFactors={Small=.86,Normal=1,Large=1.16}
local orbSizes={Tiny={48,40,4,19},Normal={66,54,6,25},Big={84,70,7,32}}
local function applyFontTo(root,fontFactor)
    if not root then return end
    local objects={root}; for _,obj in ipairs(root:GetDescendants()) do table.insert(objects,obj) end
    for _,obj in ipairs(objects) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) and obj~=orb then
            if fontOriginals[obj]==nil then fontOriginals[obj]=obj.TextSize end
            obj.TextSize=math.clamp(math.floor(fontOriginals[obj]*fontFactor+.5),8,48)
        end
    end
end
local function applyCustomizationTo(root)
    local fontFactor=fontFactors[C.FontSize] or 1
    applyFontTo(root,fontFactor)
    applyThemeTo(root)
end
local function applyCustomization()
    uiScale.Scale=responsiveScale*(interfaceFactors[C.InterfaceSize] or 1)
    local fontFactor=fontFactors[C.FontSize] or 1
    for _,root in ipairs({gui,loadingGui,playerControlsGui}) do
        applyFontTo(root,fontFactor)
    end
    local orbData=orbSizes[C.OrbSize] or orbSizes.Normal
    orbGlow.Size=UDim2.fromOffset(orbData[1],orbData[1])
    orb.Size=UDim2.fromOffset(orbData[2],orbData[2])
    orb.Position=UDim2.fromOffset(orbData[3],orbData[3])
    orb.TextSize=math.clamp(math.floor(orbData[4]*fontFactor+.5),15,40)
    applyThemeTo(gui); applyThemeTo(loadingGui); applyThemeTo(playerControlsGui)
    themePreview.BackgroundColor3=Color3.fromHSV(C.ThemeHue,.78,1)
end
Nero.ApplyCustomization=applyCustomization
Nero.ApplyThemeTo=applyThemeTo
Nero.ApplyCustomizationTo=applyCustomizationTo

openColorWheel=function()
    local old=gui:FindFirstChild("NeroColorWheel"); if old then old:Destroy(); return end
    local pop=inst("Frame",{Name="NeroColorWheel",AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(330,365),Position=UDim2.fromScale(.5,.5),BackgroundColor3=Color3.fromRGB(43,18,73),BorderSizePixel=0,ZIndex=120},gui); inst("UICorner",{CornerRadius=UDim.new(0,18)},pop); inst("UIStroke",{Color=Color3.fromRGB(224,139,255),Transparency=.08,Thickness=2},pop); inst("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(76,29,120)),ColorSequenceKeypoint.new(.55,Color3.fromRGB(38,19,72)),ColorSequenceKeypoint.new(1,Color3.fromRGB(57,26,93))}),Rotation=125},pop)
    inst("TextLabel",{Size=UDim2.new(1,-52,0,42),Position=UDim2.fromOffset(16,2),BackgroundTransparency=1,Text="◆  Color Palette",Font=Enum.Font.FredokaOne,TextSize=17,TextColor3=Color3.fromRGB(255,238,255),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=121},pop)
    local close=inst("TextButton",{Size=UDim2.fromOffset(32,32),Position=UDim2.new(1,-41,0,7),BackgroundColor3=Color3.fromRGB(91,43,121),Text="×",Font=Enum.Font.GothamBold,TextSize=19,TextColor3=Color3.fromRGB(255,230,255),AutoButtonColor=false,ZIndex=122},pop); inst("UICorner",{CornerRadius=UDim.new(0,9)},close); close.Activated:Connect(function() pop:Destroy() end)
    local ring=inst("Frame",{Name="HueRing",Size=UDim2.fromOffset(210,210),Position=UDim2.new(.5,-105,0,49),BackgroundTransparency=1,ZIndex=121},pop); ring:SetAttribute("NeroThemeIgnore",true)
    local center=Vector2.new(105,105); local radius=82; local segments=40
    local marker=inst("Frame",{AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(22,22),BackgroundTransparency=1,ZIndex=124},ring); inst("UICorner",{CornerRadius=UDim.new(1,0)},marker); inst("UIStroke",{Color=Color3.fromRGB(255,255,255),Transparency=0,Thickness=3},marker)
    local centerPreview=inst("Frame",{AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(88,88),Position=UDim2.fromOffset(center.X,center.Y),BackgroundColor3=Color3.fromHSV(C.ThemeHue,.78,1),BorderSizePixel=0,ZIndex=122},ring); inst("UICorner",{CornerRadius=UDim.new(1,0)},centerPreview); inst("UIStroke",{Color=Color3.fromRGB(255,255,255),Transparency=.25,Thickness=2},centerPreview)
    local hueLabel=inst("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.fromRGB(255,255,255),TextStrokeTransparency=.55,ZIndex=123},centerPreview)
    local function updateWheel(hue,save)
        C.ThemeHue=(hue%1+1)%1
        local angle=C.ThemeHue*math.pi*2-math.pi/2
        marker.Position=UDim2.fromOffset(center.X+math.cos(angle)*radius,center.Y+math.sin(angle)*radius)
        centerPreview.BackgroundColor3=Color3.fromHSV(C.ThemeHue,.78,1)
        hueLabel.Text=tostring(math.floor(C.ThemeHue*360+.5)).."°"
        applyCustomization()
        if save then persistConfigChange() end
    end
    for i=0,segments-1 do
        local hue=i/segments; local angle=hue*math.pi*2-math.pi/2
        local segment=inst("TextButton",{AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(23,23),Position=UDim2.fromOffset(center.X+math.cos(angle)*radius,center.Y+math.sin(angle)*radius),BackgroundColor3=Color3.fromHSV(hue,.86,1),BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=122},ring); inst("UICorner",{CornerRadius=UDim.new(1,0)},segment)
        segment.Activated:Connect(function() updateWheel(hue,true) end)
    end
    local hint=inst("TextLabel",{Size=UDim2.new(1,-32,0,28),Position=UDim2.fromOffset(16,263),BackgroundTransparency=1,Text="Tap any color • changes apply instantly",Font=Enum.Font.GothamMedium,TextSize=11,TextColor3=Color3.fromRGB(213,185,239),ZIndex=121},pop)
    local reset=inst("TextButton",{Size=UDim2.fromOffset(130,34),Position=UDim2.new(.5,-65,1,-52),BackgroundColor3=Color3.fromRGB(112,51,157),Text="Reset Purple",Font=Enum.Font.GothamBold,TextSize=11,TextColor3=Color3.fromRGB(255,238,255),AutoButtonColor=false,ZIndex=122},pop); inst("UICorner",{CornerRadius=UDim.new(0,10)},reset); inst("UIStroke",{Color=Color3.fromRGB(218,133,255),Transparency=.3,Thickness=1},reset); reset.Activated:Connect(function() updateWheel(DEFAULT_THEME_HUE,true) end)
    updateWheel(C.ThemeHue,false); applyCustomization()
end
Nero.OpenColorWheel=openColorWheel
applyCustomization()

local minimized=false
Nero.UIOpen=true
local clampGroupOnScreen
local function setOpen(open)
    open=open==true
    minimized=not open
    Nero.UIOpen=open
    if open then
        glow.Visible=true; main.Visible=true
        main.Size=UDim2.fromOffset(700,445); main.BackgroundTransparency=1
        glow.Size=UDim2.fromOffset(720,465); glow.BackgroundTransparency=1
        TS:Create(main,TweenInfo.new(.32,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(760,490),BackgroundTransparency=.025}):Play()
        TS:Create(glow,TweenInfo.new(.38,Enum.EasingStyle.Quad),{Size=UDim2.fromOffset(790,520),BackgroundTransparency=.48}):Play()
        delayProcess(.4,function() if clampGroupOnScreen then clampGroupOnScreen(main,glow) end end)
    else
        TS:Create(main,TweenInfo.new(.18,Enum.EasingStyle.Quad),{Size=UDim2.fromOffset(710,450),BackgroundTransparency=1}):Play()
        TS:Create(glow,TweenInfo.new(.18),{BackgroundTransparency=1}):Play()
        delayProcess(.2,function() if minimized then main.Visible=false; glow.Visible=false end end)
    end
end
min.MouseButton1Click:Connect(function() setOpen(false) end)
local function toggleUI() setOpen(minimized or not main.Visible) end
Nero.ToggleUI=toggleUI

local function makeDraggable(handle,target,companion)
    local state={dragging=false,moved=false,suppressUntil=0}
    local startInput,startPos,companionStart,startMin,startMax
    local function bounds()
        local aPos,aSize=target.AbsolutePosition,target.AbsoluteSize
        local minX,minY,maxX,maxY=aPos.X,aPos.Y,aPos.X+aSize.X,aPos.Y+aSize.Y
        if companion then
            local bPos,bSize=companion.AbsolutePosition,companion.AbsoluteSize
            minX=math.min(minX,bPos.X); minY=math.min(minY,bPos.Y)
            maxX=math.max(maxX,bPos.X+bSize.X); maxY=math.max(maxY,bPos.Y+bSize.Y)
        end
        return Vector2.new(minX,minY),Vector2.new(maxX,maxY)
    end
    local function moveFromStart(screenDelta)
        local viewport=(workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1920,1080)
        local minDX,maxDX=-startMin.X,viewport.X-startMax.X
        local minDY,maxDY=-startMin.Y,viewport.Y-startMax.Y
        if minDX>maxDX then minDX,maxDX=(minDX+maxDX)/2,(minDX+maxDX)/2 end
        if minDY>maxDY then minDY,maxDY=(minDY+maxDY)/2,(minDY+maxDY)/2 end
        local dx=math.clamp(screenDelta.X,minDX,maxDX)
        local dy=math.clamp(screenDelta.Y,minDY,maxDY)
        local scale=math.max(.01,uiScale.Scale)
        target.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+dx/scale,startPos.Y.Scale,startPos.Y.Offset+dy/scale)
        if companion and companionStart then
            companion.Position=UDim2.new(companionStart.X.Scale,companionStart.X.Offset+dx/scale,companionStart.Y.Scale,companionStart.Y.Offset+dy/scale)
        end
    end
    table.insert(Nero.conns,handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            state.dragging=true; state.moved=false; startInput=i.Position; startPos=target.Position; companionStart=companion and companion.Position or nil; startMin,startMax=bounds()
        end
    end))
    table.insert(Nero.conns,UIS.InputChanged:Connect(function(i)
        if state.dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-startInput
            if d.Magnitude>5 then state.moved=true end
            moveFromStart(d)
        end
    end))
    table.insert(Nero.conns,UIS.InputEnded:Connect(function(i)
        if state.dragging and (i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch) then
            state.dragging=false
            if state.moved then state.suppressUntil=os.clock()+.2 end
        end
    end))
    return state
end
clampGroupOnScreen=function(target,companion)
    if not (target and target.Parent) then return end
    local aPos,aSize=target.AbsolutePosition,target.AbsoluteSize
    local minX,minY,maxX,maxY=aPos.X,aPos.Y,aPos.X+aSize.X,aPos.Y+aSize.Y
    if companion and companion.Parent then
        local bPos,bSize=companion.AbsolutePosition,companion.AbsoluteSize
        minX=math.min(minX,bPos.X); minY=math.min(minY,bPos.Y)
        maxX=math.max(maxX,bPos.X+bSize.X); maxY=math.max(maxY,bPos.Y+bSize.Y)
    end
    local viewport=(workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1920,1080)
    local dx,dy=0,0
    if maxX-minX>viewport.X then dx=viewport.X/2-(minX+maxX)/2 elseif minX<0 then dx=-minX elseif maxX>viewport.X then dx=viewport.X-maxX end
    if maxY-minY>viewport.Y then dy=viewport.Y/2-(minY+maxY)/2 elseif minY<0 then dy=-minY elseif maxY>viewport.Y then dy=viewport.Y-maxY end
    if dx~=0 or dy~=0 then
        local scale=math.max(.01,uiScale.Scale)
        target.Position=UDim2.new(target.Position.X.Scale,target.Position.X.Offset+dx/scale,target.Position.Y.Scale,target.Position.Y.Offset+dy/scale)
        if companion and companion.Parent then companion.Position=UDim2.new(companion.Position.X.Scale,companion.Position.X.Offset+dx/scale,companion.Position.Y.Scale,companion.Position.Y.Offset+dy/scale) end
    end
end
local orbDragState=makeDraggable(orb,orbGlow)
makeDraggable(top,main,glow)
orb.Activated:Connect(function() if os.clock()>=orbDragState.suppressUntil then toggleUI() end end)
spawnProcess(function()
    local lastViewport=Vector2.zero
    while Nero.alive do
        local currentCamera=workspace.CurrentCamera
        local viewport=currentCamera and currentCamera.ViewportSize
        if viewport and viewport~=lastViewport then
            lastViewport=viewport
            responsiveScale=math.clamp(math.min(viewport.X/850,viewport.Y/570),.3,1)
            uiScale.Scale=responsiveScale*(interfaceFactors[C.InterfaceSize] or 1)
            task.wait()
            clampGroupOnScreen(main,glow); clampGroupOnScreen(orbGlow)
        end
        task.wait(.25)
    end
end)

spawnProcess(function()
    loadingStatus.Text="Weaving violet auroras..."
    TS:Create(loadingFill,TweenInfo.new(.74,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.fromScale(.3,1)}):Play(); task.wait(.78)
    loadingStatus.Text="Polishing enchanted controls..."
    TS:Create(loadingFill,TweenInfo.new(.8,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.fromScale(.64,1)}):Play(); task.wait(.84)
    loadingStatus.Text="Listening to the garden..."
    TS:Create(loadingFill,TweenInfo.new(.74,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.fromScale(.9,1)}):Play(); task.wait(.78)
    loadingStatus.Text="Garden Horizons is ready  ◆"
    TS:Create(loadingFill,TweenInfo.new(.55,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.fromScale(1,1)}):Play(); task.wait(.78)
    TS:Create(loadingRoot,TweenInfo.new(.42,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{GroupTransparency=1}):Play(); task.wait(.44)
    if loadingGui then loadingGui:Destroy(); loadingGui=nil end; Nero.LoadingGui=nil
    orbGlow.Visible=true
    setOpen(true)
end)

local function emergency()
    for k,v in pairs(C) do if typeof(v)=="boolean" and k~="AntiAFK" and k~="Status" and k~="Log" then C[k]=false end end
    status.Text="  EMERGENCY STOP • all automation disabled"
end
stop.Activated:Connect(function() Nero:Destroy() end)

local CollectionService=game:GetService("CollectionService")
Nero.replantQueue={}
local function mapAllows(map,name,alternate)
    return map.__ALL==true or (map.__ALL==nil and next(map)==nil) or map[name]==true or (alternate and map[alternate]==true)
end
local function mutationAllowed(value)
    if C.MutationWhitelist.__ALL==true or (C.MutationWhitelist.__ALL==nil and next(C.MutationWhitelist)==nil) then return true end
    for token in tostring(value or ""):gmatch("[^,]+") do if C.MutationWhitelist[token:match("^%s*(.-)%s*$") or token] then return true end end
    return false
end
local function harvestParts(prompt)
    local target=prompt and prompt.Parent
    if target and target:IsA("BasePart") then target=target.Parent end
    if not (target and target:IsA("Model")) then return end
    local root=target:GetAttribute("HarvestablePlant") and target or target.Parent
    if not (root and root:IsA("Model")) then return end
    return target,root
end
local function validHarvest(target,root)
    if not target:GetAttribute("FullyGrown") then return false end
    if root:GetAttribute("OwnerUserId")~=LP.UserId then return false end
    if C.FavoriteProtection and (target:GetAttribute("Favorited") or root:GetAttribute("Favorited")) then return false end
    local plant=tostring(target:GetAttribute("PlantType") or root:GetAttribute("PlantType") or root.Name)
    local def=PlantDefinitions[plant]
    local rarity=tostring((def and (def.Rarity or def.rarity)) or target:GetAttribute("Rarity") or root:GetAttribute("Rarity") or "")
    local mutation=tostring(target:GetAttribute("Mutation") or root:GetAttribute("Mutation") or "")
    local mutated=mutation~=""
    local stage=tostring(target:GetAttribute("RipenessStage") or root:GetAttribute("RipenessStage") or "Unripe")
    local wanted=C.Ripeness=="Ripened" and "Ripe" or C.Ripeness
    if wanted~="Doesn't Matter" and stage~=wanted then return false end
    if not mapAllows(C.PlantWhitelist,plant) or not mapAllows(C.RarityWhitelist,rarity) or not mutationAllowed(mutation) then return false end
    if tonumber(target:GetAttribute("Weight") or root:GetAttribute("Weight") or 0)<(tonumber(C.MinWeight) or 0) then return false end
    if C.MutationMode=="Only Mutated" and not mutated then return false end
    if (C.MutationMode=="Only Non-Mutated" or C.MutationMode=="Skip Mutated") and mutated then return false end
    if (tonumber(C.MinFruitValue) or 0)>0 then local ok,value=pcall(FruitValueCalculator.GetValue,target); if ok and tonumber(value) and value<C.MinFruitValue then return false end end
    return true
end
spawnProcess(function()
    while Nero.alive do
        if C.Harvest then
            local batch,positions={},{}
            for _,prompt in ipairs(CollectionService:GetTagged("HarvestPrompt")) do
                local target,root=harvestParts(prompt)
                if target and validHarvest(target,root) then
                    local uuid=root:GetAttribute("Uuid")
                    if uuid then
                        local entry={Uuid=uuid}; local anchor=target:GetAttribute("GrowthAnchorIndex"); if anchor then entry.GrowthAnchorIndex=anchor end
                        local ground=root:GetAttribute("PlantGroundPosition") or target:GetAttribute("PlantGroundPosition") or target:GetPivot().Position
                        table.insert(batch,entry); table.insert(positions,ground)
                    end
                end
            end
            if #batch>0 then
                if C.HarvestMethod=="Harvest Bell" then local seen={}; for _,entry in ipairs(batch) do if not seen[entry.Uuid] then seen[entry.Uuid]=true; Remotes.UseGear:FireServer("Harvest Bell",{targetUuid=entry.Uuid}); task.wait(.08) end end else Remotes.HarvestFruit:FireServer(batch) end
                Nero.stats.harvested+=#batch; if C.AutoReplant then for _,p in ipairs(positions) do table.insert(Nero.replantQueue,p) end end
            end
        end
        task.wait(math.max(.2,tonumber(C.HarvestInterval) or 1))
    end
end)
local function plantableParts()
    local out={}; local plots=workspace:FindFirstChild("Plots")
    if plots then
        for _,plot in ipairs(plots:GetChildren()) do
            local owner=plot:GetAttribute("Owner") or plot:GetAttribute("OwnerUserId")
            if plot:IsA("Model") and (tonumber(owner)==LP.UserId or owner==LP) then
                local area=plot:FindFirstChild("PlantableArea")
                if area then for _,p in ipairs(area:GetDescendants()) do if p:IsA("BasePart") then table.insert(out,p) end end end
            end
        end
    end
    return out
end
local function emptyAt(pos)
    if not C.EmptyOnly then return true end
    for _,m in ipairs(CollectionService:GetTagged("Plant")) do
        if m:IsA("Model") and m:GetAttribute("OwnerUserId")==LP.UserId then
            local p=m:GetAttribute("PlantGroundPosition") or m:GetPivot().Position
            if Vector2.new(p.X-pos.X,p.Z-pos.Z).Magnitude<3 then return false end
        end
    end
    return true
end
local function randomPlantPoint(part)
    -- PlantableArea uses a thin, rotated part. Its local X axis is the ground
    -- normal in the current map, so sampling local X/Z placed every request on
    -- an edge. Detect the thin axis and sample the other two dimensions.
    local size=part.Size
    local sizes={size.X,size.Y,size.Z}
    local normalIndex=1
    if sizes[2]<sizes[normalIndex] then normalIndex=2 end
    if sizes[3]<sizes[normalIndex] then normalIndex=3 end
    local axes={Vector3.new(1,0,0),Vector3.new(0,1,0),Vector3.new(0,0,1)}
    local coordinates={0,0,0}
    for i=1,3 do
        if i==normalIndex then
            local worldNormal=part.CFrame:VectorToWorldSpace(axes[i])
            coordinates[i]=(worldNormal.Y>=0 and 1 or -1)*sizes[i]/2
        else
            local half=math.max(0,sizes[i]/2-1.5)
            coordinates[i]=(math.random()*2-1)*half
        end
    end
    return part.CFrame:PointToWorldSpace(Vector3.new(coordinates[1],coordinates[2],coordinates[3]))
end
local function nextPlantPosition()
    if C.AutoReplant then
        while #Nero.replantQueue>0 do
            local queued=table.remove(Nero.replantQueue,1)
            if typeof(queued)=="Vector3" and emptyAt(queued) then return queued end
        end
    end
    local parts=plantableParts(); if #parts==0 then return end
    for _=1,80 do
        local pos=randomPlantPoint(parts[math.random(1,#parts)])
        if emptyAt(pos) then return pos end
    end
end
local function availableSeeds()
    local out={}
    local function shopSeedData(plant)
        local direct=SeedShopData.ShopData[plant]
        if type(direct)=="table" then return direct end
        for key,data in pairs(SeedShopData.ShopData) do if type(data)=="table" and (data.Name==plant or key==plant) then return data end end
    end
    local function scan(root)
        if not root then return end
        for _,tool in ipairs(root:GetChildren()) do
            if tool:IsA("Tool") then
                local plant=tool:GetAttribute("PlantType")
                local itemType=tool:GetAttribute("Type")
                local baseName=tool:GetAttribute("BaseName") or tool.Name:gsub("^x%d+%s+","")
                local allowed=plant and (mapAllows(C.PlantSeedWhitelist,tostring(plant),tostring(baseName)) or C.PlantSeedWhitelist[tool.Name]==true)
                if plant and (itemType==nil or itemType=="Seeds") and allowed then
                    local ok,count=pcall(ItemInventory.getItemCount,tool)
                    count=tonumber(ok and count) or tonumber(tool.Name:match("^x(%d+)")) or 1
                    if count>(tonumber(C.SeedReserve) or 0) then
                        local data=shopSeedData(tostring(plant))
                        table.insert(out,{Tool=tool,Plant=tostring(plant),Count=count,Price=tonumber(data and data.Price) or 0})
                    end
                end
            end
        end
    end
    scan(LP:FindFirstChild("Backpack")); scan(LP.Character)
    table.sort(out,function(a,b) if C.SeedMode=="Smart (Most Valuable)" then return a.Price>b.Price end return a.Plant<b.Plant end); return out
end
spawnProcess(function()
    local rotation=0
    while Nero.alive do
        if C.Plant then
            local seeds=availableSeeds(); local pos=nextPlantPosition()
            if #seeds>0 and pos then
                rotation=rotation%#seeds+1
                local seed=C.SeedMode=="Rotation" and seeds[rotation] or seeds[1]
                local char=LP.Character
                local hum=char and char:FindFirstChildOfClass("Humanoid")
                local previous=char and char:FindFirstChildOfClass("Tool")
                local equipped=hum and seed.Tool and seed.Tool.Parent and seed.Tool:IsDescendantOf(LP)
                if equipped and seed.Tool.Parent~=char then
                    hum:EquipTool(seed.Tool)
                    task.wait(.08)
                    equipped=seed.Tool.Parent==char
                end
                local ok,result
                if equipped then
                    ok,result=pcall(function() return Remotes.PlantSeed:InvokeServer(seed.Plant,pos) end)
                else
                    ok,result=false,"Selected seed could not be equipped"
                end
                if hum and previous and previous~=seed.Tool and previous.Parent then
                    hum:EquipTool(previous)
                end
                if ok and result~=false then
                    Nero.stats.planted+=1; Nero.stats.lastPlantError=nil
                else
                    Nero.stats.lastPlantError=tostring(result or "PlantSeed request failed")
                    if C.AutoReplant then table.insert(Nero.replantQueue,1,pos) end
                end
            elseif #seeds==0 then
                Nero.stats.lastPlantError="No selected seed is available above the reserve"
            elseif not pos then
                Nero.stats.lastPlantError="No empty plantable position was found"
            end
        end
        task.wait(math.max(.2,tonumber(C.ReplantDelay) or .5))
    end
end)
Nero.stockCache={SeedShop=nil,GearShop=nil}
local function refreshNativeShopUI(id,data)
    local pg=LP:FindFirstChild("PlayerGui"); local shopGui=pg and pg:FindFirstChild(id)
    if not shopGui then return end
    for _,card in ipairs(shopGui:GetDescendants()) do
        local name=card:GetAttribute("ShopItemName"); local stock=name and data.Items[name]
        if stock then
            local main=card:FindFirstChild("MainInfo"); local amount=tonumber(stock.Amount) or 0
            local text=main and main:FindFirstChild("StockText"); local empty=main and main:FindFirstChild("NoStock")
            if text then text.Text=amount>0 and tostring(amount).."x" or "NO STOCK" end
            if empty then empty.Visible=amount<=0 end
        end
    end
end
local function applyShopData(id,data)
    if type(data)~="table" or type(data.Items)~="table" then return end
    Nero.stockCache[id]=data
    pcall(refreshNativeShopUI,id,data)
end
local function fetchShop(id)
    local rf=Remotes:FindFirstChild("GetShopData"); if not rf then return end
    local ok,data=pcall(function() return rf:InvokeServer(id) end)
    if ok and type(data)=="table" and type(data.Items)=="table" then applyShopData(id,data); return data end
end
local function shopNpc(id)
    local shops=workspace:FindFirstChild("MapPhysical") and workspace.MapPhysical:FindFirstChild("Shops"); if not shops then return end
    if id=="SeedShop" then return shops:FindFirstChild("Seed Shop") and shops["Seed Shop"]:FindFirstChild("SeedNPC") end
    return shops:FindFirstChild("Gear Shop") and shops["Gear Shop"]:FindFirstChild("GearNPC")
end
local function shopDefinition(id,itemName)
    local data=id=="SeedShop" and SeedShopData.ShopData or GearShopData.ShopData
    for _,v in pairs(data) do if type(v)=="table" and v.Name==itemName then return v end end
    return data[itemName]
end
local function orderedShopNames(id,items)
    local names={}; for name in pairs(items or {}) do table.insert(names,name) end
    table.sort(names,function(a,b)
        local da,db=shopDefinition(id,a),shopDefinition(id,b)
        local oa=da and tonumber(da.LayoutOrder) or math.huge
        local ob=db and tonumber(db.LayoutOrder) or math.huge
        if oa~=ob then return oa<ob end
        return a<b
    end)
    return names
end
local shopBusy=false
local function shopEnabled(id) return Nero.alive and (id=="SeedShop" and C.BuySeeds==true or id=="GearShop" and C.BuyGears==true) end
local function shopWhitelist(id) return id=="SeedShop" and C.SeedWhitelist or C.GearWhitelist end
local function buyShop(id,data)
    if shopBusy then return end; shopBusy=true
    local char=LP.Character; local root=char and char:FindFirstChild("HumanoidRootPart"); local npc=shopNpc(id); local npcRoot=npc and npc:FindFirstChild("HumanoidRootPart")
    if not (root and npcRoot and shopEnabled(id)) then shopBusy=false; return end
    root.CFrame=npcRoot.CFrame*CFrame.new(0,0,-4); task.wait(.45)
    if not shopEnabled(id) then shopBusy=false; return end
    Nero.stats.shopCycles=(Nero.stats.shopCycles or 0)+1; Nero.stats.lastShop=id
    data=data or fetchShop(id); local purchase=Remotes:FindFirstChild("PurchaseShopItem")
    if data and purchase then
        for _,name in ipairs(orderedShopNames(id,data.Items)) do
            if not shopEnabled(id) then break end
            local stock=data.Items[name]; local amount=type(stock)=="table" and tonumber(stock.Amount) or 0
            local allowed=mapAllows(shopWhitelist(id),name,name:gsub(" Seed$",""))
            if allowed and amount>0 then
                for _=1,amount do
                    if not shopEnabled(id) or not mapAllows(shopWhitelist(id),name,name:gsub(" Seed$","")) then break end
                    local purchased=false
                    for attempt=1,2 do
                        local ok,result,reason=pcall(function() return purchase:InvokeServer(id,name) end)
                        if ok and type(result)=="table" and type(result.Items)=="table" then
                            applyShopData(id,result); data=result; Nero.stats.bought=(Nero.stats.bought or 0)+1; Nero.stats.lastBuyError=nil; purchased=true; break
                        end
                        Nero.stats.lastBuyError=tostring(reason or result or "Purchase failed")
                        if attempt==1 and Nero.stats.lastBuyError:lower():find("far",1,true) then task.wait(.3) else break end
                    end
                    if not purchased then break end
                end
            end
        end
    end
    shopBusy=false
end
spawnProcess(function()
    local wasEnabled={SeedShop=false,GearShop=false}
    local lastToken={SeedShop=nil,GearShop=nil}
    local lastRevision={SeedShop=0,GearShop=0}
    local lastFetch=-math.huge
    while Nero.alive do
        local seedOn,gearOn=C.BuySeeds==true,C.BuyGears==true
        local stateChanged=seedOn~=wasEnabled.SeedShop or gearOn~=wasEnabled.GearShop
        local seedRevision=Nero.selectionRevision.SeedWhitelist or 0
        local gearRevision=Nero.selectionRevision.GearWhitelist or 0
        local seedSelectionChanged=seedOn and seedRevision~=lastRevision.SeedShop
        local gearSelectionChanged=gearOn and gearRevision~=lastRevision.GearShop
        local now=os.clock()
        if stateChanged or seedSelectionChanged or gearSelectionChanged or now-lastFetch>=.5 then
            local seedData,gearData=fetchShop("SeedShop"),fetchShop("GearShop"); lastFetch=now
            local seedToken=seedData and seedData.Seed
            local gearToken=gearData and gearData.Seed
            local seedNeeded=seedOn and (not wasEnabled.SeedShop or seedToken~=lastToken.SeedShop or seedSelectionChanged)
            local gearNeeded=gearOn and (not wasEnabled.GearShop or gearToken~=lastToken.GearShop or gearSelectionChanged)
            if seedOn and gearOn and (seedNeeded or gearNeeded) then
                buyShop("SeedShop",seedData)
                buyShop("GearShop",gearData)
            elseif seedNeeded then
                buyShop("SeedShop",seedData)
            elseif gearNeeded then
                buyShop("GearShop",gearData)
            end
            if seedOn then lastToken.SeedShop=seedToken; lastRevision.SeedShop=seedRevision end
            if gearOn then lastToken.GearShop=gearToken; lastRevision.GearShop=gearRevision end
        end
        wasEnabled.SeedShop=seedOn; wasEnabled.GearShop=gearOn
        task.wait(.1)
    end
end)
local lastSellClock,lastHarvestSeen=0,0
local function sellableTools()
    local out,total={},0
    for _,tool in ipairs(LP.Backpack:GetChildren()) do if tool:IsA("Tool") then
        local ok,value=pcall(FruitValueCalculator.GetValue,tool); value=ok and tonumber(value) or 0
        local mutation=tostring(tool:GetAttribute("Mutation") or "")
        if value>0 and value>=(tonumber(C.MinSellValue) or 0) and not (C.MutationProtection and mutation~="") then table.insert(out,tool); total+=value end
    end end
    return out,total
end
local function shouldSell(total)
    if C.SellTrigger=="After Each Harvest Cycle" then return Nero.stats.harvested>lastHarvestSeen end
    if C.SellTrigger=="On Timer" then return os.clock()-lastSellClock>=(tonumber(C.SellTimer) or 2)*60 end
    if C.SellTrigger=="When Value Exceeds X" then return total>=(tonumber(C.SellThreshold) or 50000) end
    if C.SellTrigger=="When Inventory Full" then local n=0; for _,x in ipairs(LP.Backpack:GetChildren()) do if x:IsA("Tool") then n+=1 end end; return n>=300 end
    return false
end
local function sellCycle()
    local tools,total=sellableTools(); if #tools==0 or not shouldSell(total) then return end
    local char=LP.Character; local root=char and char:FindFirstChild("HumanoidRootPart"); local hum=char and char:FindFirstChildOfClass("Humanoid")
    local shops=workspace:FindFirstChild("MapPhysical") and workspace.MapPhysical:FindFirstChild("Shops"); local stand=shops and shops:FindFirstChild("Sell Stand"); local steve=stand and stand:FindFirstChild("Steve"); local npcRoot=steve and steve:FindFirstChild("HumanoidRootPart")
    if not (root and hum and npcRoot) then return end
    local returnCFrame=root.CFrame
    if C.TeleportSell then root.CFrame=npcRoot.CFrame*CFrame.new(0,0,-4); task.wait(.35) end
    for _,tool in ipairs(tools) do if tool.Parent then hum:EquipTool(tool); task.wait(.05); local ok,msg=pcall(function() return Remotes.SellItems:InvokeServer("SellSingle") end); if ok and type(msg)=="string" and msg:match("^Here's") then Nero.stats.sold+=1 end; task.wait(.08) end end
    hum:UnequipTools(); lastSellClock=os.clock(); lastHarvestSeen=Nero.stats.harvested
    if C.ReturnPosition=="My Plot" and returnCFrame then root.CFrame=returnCFrame elseif C.ReturnPosition=="Seed Shop" then local npc=shopNpc("SeedShop"); local nr=npc and npc:FindFirstChild("HumanoidRootPart"); if nr then root.CFrame=nr.CFrame*CFrame.new(0,0,-4) end end
end
spawnProcess(function() while Nero.alive do if C.Sell then pcall(sellCycle) end; task.wait(2) end end)
local function ownedGear(gearType,preferred)
    local best
    for _,tool in ipairs(LP.Backpack:GetChildren()) do if tool:IsA("Tool") then local name=tool:GetAttribute("GearName") or tool:GetAttribute("BaseName") or tool.Name:gsub("^x%d+%s+",""); local def=GearDefinitions.Gears[name]; if def and def.GearType==gearType and (not preferred or preferred=="Best Available" or name==preferred) then best=name end end end
    return best
end
spawnProcess(function()
    while Nero.alive do
        if C.Water then local gear=ownedGear("WateringCan"); if gear then local plants=CollectionService:GetTagged("Plant"); for _,m in ipairs(plants) do if m:GetAttribute("OwnerUserId")==LP.UserId then Remotes.UseGear:FireServer(gear,{position=m:GetPivot().Position}); break end end end end
        task.wait(math.max(2,tonumber(C.WaterInterval) or 5))
    end
end)
spawnProcess(function()
    while Nero.alive do
        if C.Sprinklers then
            local has=false; for _,s in ipairs(CollectionService:GetTagged("Sprinkler")) do if s:GetAttribute("OwnerUserId")==LP.UserId or s:GetAttribute("Owner")==LP.UserId then has=true break end end
            if not has then local gear=ownedGear("Sprinkler",C.SprinklerType); local parts=plantableParts(); if gear and parts[1] then Remotes.UseGear:FireServer(gear,{position=parts[1].Position}); task.wait(2) end end
        end
        task.wait(10)
    end
end)
local moderatorChecks={}
local moderatorResponding=false
local function findPublicServer()
    local cursor
    for _=1,4 do
        local url="https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100"
        if cursor and cursor~="" then url..="&cursor="..Http:UrlEncode(cursor) end
        local ok,body=pcall(function()
            local requestFn=request or http_request or (syn and syn.request)
            if requestFn then
                local response=requestFn({Url=url,Method="GET"})
                return response and (response.Body or response.body)
            end
            return game:HttpGet(url)
        end)
        if not ok or type(body)~="string" then return end
        local decodedOk,data=pcall(Http.JSONDecode,Http,body)
        if not decodedOk or type(data)~="table" then return end
        for _,server in ipairs(type(data.data)=="table" and data.data or {}) do
            if server.id and server.id~=game.JobId and tonumber(server.playing or 0)<tonumber(server.maxPlayers or 0) then return server.id end
        end
        cursor=data.nextPageCursor
        if not cursor then break end
    end
end
Nero.FindPublicServer=findPublicServer
local function respondToModerator(player)
    if not (Nero.alive and C.ModeratorSafety and player and player~=LP) or moderatorResponding then return end
    if moderatorChecks[player.UserId] then return end
    moderatorChecks[player.UserId]=true
    spawnProcess(function()
        local ok,isModerator=pcall(GroupUtils.IsGroupAdmin,player)
        if not (Nero.alive and C.ModeratorSafety and ok and isModerator) or moderatorResponding then return end
        moderatorResponding=true
        Nero.stats.moderator=player.Name
        local action=C.ModeratorAction=="Server Hop" and "Server Hop" or "Leave"
        status.Text="  MODERATOR DETECTED • @"..player.Name.." • "..action
        if action=="Server Hop" then
            local serverId=findPublicServer()
            local teleported=false
            if serverId then teleported=pcall(TeleportService.TeleportToPlaceInstance,TeleportService,game.PlaceId,serverId,LP) end
            if not teleported then pcall(TeleportService.Teleport,TeleportService,game.PlaceId,LP) end
        else
            LP:Kick("Nero: moderator detected (@"..player.Name..").")
        end
    end)
end
table.insert(Nero.conns,Players.PlayerAdded:Connect(respondToModerator))
spawnProcess(function()
    while Nero.alive do
        if C.ModeratorSafety and not moderatorResponding then for _,player in ipairs(Players:GetPlayers()) do respondToModerator(player) end end
        task.wait(1)
    end
end)
table.insert(Nero.conns,LP.Idled:Connect(function() if C.AntiAFK then VU:Button2Down(Vector2.zero,workspace.CurrentCamera.CFrame); task.wait(.1); VU:Button2Up(Vector2.zero,workspace.CurrentCamera.CFrame) end end))
local originalMovement={WalkSpeed=16,JumpHeight=7.2,UseJumpPower=false,JumpPower=50}
local function applyMovement(char)
    local h=char and char:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed=math.clamp(tonumber(C.WalkSpeed) or 16,0,250); h.UseJumpPower=false; h.JumpHeight=math.clamp(tonumber(C.JumpHeight) or 7.2,0,100) end
end
local initialHum=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid"); if initialHum then originalMovement={WalkSpeed=initialHum.WalkSpeed,JumpHeight=initialHum.JumpHeight,UseJumpPower=initialHum.UseJumpPower,JumpPower=initialHum.JumpPower} end
local noclipOriginals=setmetatable({},{__mode="k"})
local function restoreNoclip()
    for part,canCollide in pairs(noclipOriginals) do
        if part and part.Parent then pcall(function() part.CanCollide=canCollide end) end
        noclipOriginals[part]=nil
    end
end
Nero.RestoreNoclip=restoreNoclip
table.insert(Nero.conns,RunService.Stepped:Connect(function()
    if not Nero.alive then return end
    local char=LP.Character
    if C.Noclip and char then
        for _,part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if noclipOriginals[part]==nil then noclipOriginals[part]=part.CanCollide end
                part.CanCollide=false
            end
        end
    elseif next(noclipOriginals)~=nil then
        restoreNoclip()
    end
end))

local flight={root=nil,humanoid=nil,velocity=nil,gyro=nil,autoRotate=nil}
local function stopFlight()
    touchFlyUp=false; touchFlyDown=false
    if flightControls and flightControls.Parent then flightControls.Visible=false end
    if flight.velocity then pcall(function() flight.velocity:Destroy() end) end
    if flight.gyro then pcall(function() flight.gyro:Destroy() end) end
    if flight.humanoid and flight.humanoid.Parent then
        pcall(function()
            flight.humanoid.AutoRotate=flight.autoRotate~=false
            flight.humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
        end)
    end
    if flight.root and flight.root.Parent then pcall(function() flight.root.AssemblyLinearVelocity=Vector3.zero end) end
    flight.root=nil; flight.humanoid=nil; flight.velocity=nil; flight.gyro=nil; flight.autoRotate=nil
end
local function startFlight(root,humanoid)
    stopFlight()
    flight.root=root; flight.humanoid=humanoid; flight.autoRotate=humanoid.AutoRotate
    local velocity=inst("BodyVelocity",{Name="NeroFlightVelocity",MaxForce=Vector3.new(1e8,1e8,1e8),P=15000,Velocity=Vector3.zero},root)
    local gyro=inst("BodyGyro",{Name="NeroFlightGyro",MaxTorque=Vector3.new(0,1e8,0),P=12000,D=650,CFrame=root.CFrame},root)
    flight.velocity=velocity; flight.gyro=gyro
    humanoid.AutoRotate=false
    humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
end
Nero.StopFlight=stopFlight
spawnProcess(function()
    while Nero.alive do
        if C.Fly then
            local char=LP.Character
            local root=char and char:FindFirstChild("HumanoidRootPart")
            local humanoid=char and char:FindFirstChildOfClass("Humanoid")
            if root and humanoid and humanoid.Health>0 then
                if flight.root~=root or flight.humanoid~=humanoid or not (flight.velocity and flight.velocity.Parent and flight.gyro and flight.gyro.Parent) then startFlight(root,humanoid) end
                flightControls.Visible=UIS.TouchEnabled
                local speed=math.clamp(tonumber(C.FlySpeed) or 50,5,300)
                local vertical=0
                local typing=UIS:GetFocusedTextBox()~=nil
                if touchFlyUp or humanoid.Jump or (not typing and (UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.E))) then vertical+=1 end
                if touchFlyDown or (not typing and (UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.Q))) then vertical-=1 end
                local move=humanoid.MoveDirection
                local horizontal=Vector3.new(move.X,0,move.Z)
                if horizontal.Magnitude>1 then horizontal=horizontal.Unit end
                flight.velocity.Velocity=horizontal*speed+Vector3.new(0,vertical*speed,0)
                local activeCamera=workspace.CurrentCamera
                local look=activeCamera and activeCamera.CFrame.LookVector or root.CFrame.LookVector
                local flatLook=Vector3.new(look.X,0,look.Z)
                if flatLook.Magnitude>.01 then flight.gyro.CFrame=CFrame.lookAt(root.Position,root.Position+flatLook.Unit) end
                humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
            else
                stopFlight()
            end
        elseif flight.root then
            stopFlight()
        elseif flightControls.Visible then
            flightControls.Visible=false
        end
        RunService.RenderStepped:Wait()
    end
end)
local function plotReturnPosition()
    local plots=workspace:FindFirstChild("Plots"); if not plots then return end
    for _,plot in ipairs(plots:GetChildren()) do if plot:IsA("Model") and plot:GetAttribute("Owner")==LP.UserId then local area=plot:FindFirstChild("PlantableArea"); local part=area and area:FindFirstChildWhichIsA("BasePart"); if part then return part.CFrame*CFrame.new(0,5,0) end end end
end
table.insert(Nero.conns,LP.CharacterAdded:Connect(function(char) local h=char:WaitForChild("Humanoid",10); applyMovement(char); if C.RespawnReturn then task.wait(1); local root=char:FindFirstChild("HumanoidRootPart"); local cf=plotReturnPosition(); if root and cf then root.CFrame=cf end end end))
spawnProcess(function() while Nero.alive do applyMovement(LP.Character); task.wait(.25) end end)
spawnProcess(function() while Nero.alive do if C.AutoSave then saveConfig(C.ActiveConfig) end; task.wait(5) end end)
spawnProcess(function() while Nero.alive do if C.LoginClaim then Remotes.ClaimLoginStreak:FireServer() end; task.wait(30) end end)
spawnProcess(function()
    while Nero.alive do
        if C.Spin then
            local packs={}; for _,tool in ipairs(LP.Backpack:GetChildren()) do if tool:IsA("Tool") and (tool:GetAttribute("Type")=="SeedPack" or tool.Name:lower():find("seed pack",1,true)) then table.insert(packs,tool) end end
            table.sort(packs,function(a,b) local order={Royal=3,Gardener=2,Basic=1}; local function rank(x) for n,v in pairs(order) do if x.Name:find(n,1,true) then return v end end return 0 end; return C.PackPriority=="Worst First" and rank(a)<rank(b) or rank(a)>rank(b) end)
            local tool=packs[1]; local hum=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid"); if tool and hum then hum:EquipTool(tool); task.wait(.15); pcall(function() Remotes.RequestSpin:InvokeServer() end); task.wait(1.1) end
        end
        task.wait(1)
    end
end)
local function readableTime(sec)
    if type(sec)=="string" then return sec end
    sec=math.max(0,math.floor(tonumber(sec) or 0)); local d=sec//86400; local h=(sec%86400)//3600; local m=(sec%3600)//60
    return d>0 and string.format("%dd %dh %dm",d,h,m) or string.format("%dh %dm",h,m)
end
local function currency(name)
    local data=Nero.replica and Nero.replica.Data
    if data then return name=="Pearls" and (data.Pearls or 0) or (data.Money or 0) end
    local econ=RS:FindFirstChild("Economy"); local ctrl=econ and econ:FindFirstChild("CurrencyController"); local v=ctrl and (ctrl:FindFirstChild(name.."Amount") or ctrl:FindFirstChild("Amount"))
    if v and v:IsA("ValueBase") then return v.Value end
    local ls=LP:FindFirstChild("leaderstats"); v=ls and ls:FindFirstChild(name); return v and v.Value or "?"
end
local function playtime()
    local data=Nero.replica and Nero.replica.Data
    local stats=data and data.FloraBook and data.FloraBook.Stats
    if stats and stats.Playtime then return stats.Playtime end
    local pg=LP:FindFirstChild("PlayerGui")
    if pg then for _,x in ipairs(pg:GetDescendants()) do if x.Name=="Playtime" and x:IsA("Frame") then local label=x:FindFirstChild("StatNumber"); if label and label:IsA("TextLabel") and label.Text~="" then return label.Text end end end end
    local a=LP:GetAttribute("Playtime") or LP:GetAttribute("PlayTime"); if a then return a end
    for _,root in ipairs({LP,LP:FindFirstChild("PlayerGui")}) do if root then for _,x in ipairs(root:GetDescendants()) do if x:IsA("ValueBase") and x.Name:lower()=="playtime" then return x.Value end end end end
    return os.clock()-Nero.started
end
local function currentStock(id)
    local data=Nero.stockCache[id]; local rows={}
    if data and data.Items then for _,name in ipairs(orderedShopNames(id,data.Items)) do local v=data.Items[name]; local amount=type(v)=="table" and (v.Amount or 0) or 0; table.insert(rows,name.."  •  "..(amount>0 and tostring(amount).."x" or "OUT")) end end
    if #rows==0 then return "Waiting for live stock data..." end
    if #rows>9 then rows[10]="+"..tostring(#rows-9).." more items"; for i=#rows,11,-1 do table.remove(rows,i) end end
    return table.concat(rows,"\n")
end
spawnProcess(function()
    while Nero.alive do
        infoIdentityText.Text=string.format("@%s  •  %s  •  User ID %d  •  Account %d days",LP.Name,LP.DisplayName,LP.UserId,LP.AccountAge)
        infoStatsText.Text=string.format("Shillings: %s  •  Pearls: %s  •  Playtime: %s  •  Server age: %s",tostring(currency("Shillings")),tostring(currency("Pearls")),readableTime(playtime()),readableTime(workspace.DistributedGameTime))
        seedStockInfo.Text=currentStock("SeedShop"); gearStockInfo.Text=currentStock("GearShop")
        task.wait(.5)
    end
end)
spawnProcess(function()
    while Nero.alive do
        if C.ClaimDaily or C.ClaimWeekly then Remotes.RequestQuests:FireServer(); task.wait(.25) end
        if C.ClaimDaily then for i=1,5 do Remotes.ClaimQuest:FireServer("Daily",tostring(i)); task.wait(.05) end end
        if C.ClaimWeekly then for i=1,5 do Remotes.ClaimQuest:FireServer("Weekly",tostring(i)); task.wait(.05) end end
        task.wait(math.max(2,tonumber(C.QuestPoll) or 10))
    end
end)
spawnProcess(function()
    while Nero.alive do
        local elapsed=os.clock()-Nero.started
        if C.Status then
            if C.Plant and Nero.stats.lastPlantError then
                status.Text="  AUTO-PLANT WAITING • "..Nero.stats.lastPlantError
            else
                status.Text=string.format("  ACTIVE • Harvested %d  • Planted %d  • Sold %d  • Runtime %02d:%02d",Nero.stats.harvested,Nero.stats.planted,Nero.stats.sold,elapsed//60,elapsed%60)
            end
        end
        task.wait(1)
    end
end)
spawnProcess(function()
    while Nero.alive do
        themeTween(glow,TweenInfo.new(1.8,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=.6,BackgroundColor3=Color3.fromRGB(233,91,255)}); task.wait(1.8)
        themeTween(glow,TweenInfo.new(1.8,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=.38,BackgroundColor3=Color3.fromRGB(104,85,255)}); task.wait(1.8)
    end
end)
function Nero:Destroy()
    if not self.alive then return end
    self.alive=false
    for _,c in ipairs(self.conns) do pcall(function() c:Disconnect() end) end
    table.clear(self.conns)
    for _,thread in ipairs(self.threads) do pcall(task.cancel,thread) end
    table.clear(self.threads)
    if self.StopFlight then pcall(self.StopFlight) end
    if self.RestoreNoclip then pcall(self.RestoreNoclip) end
    pcall(function() VU:Button2Up(Vector2.zero,workspace.CurrentCamera.CFrame) end)
    local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed=originalMovement.WalkSpeed; h.UseJumpPower=originalMovement.UseJumpPower; h.JumpHeight=originalMovement.JumpHeight; h.JumpPower=originalMovement.JumpPower end
    if self.LoadingGui then self.LoadingGui:Destroy() end
    if self.PlayerControlsGui then self.PlayerControlsGui:Destroy() end
    if self.Gui then self.Gui:Destroy() end
    if getgenv().Nero==self then getgenv().Nero=nil end
end
if NERO_ENV.NeroLaunchSerial~=NERO_LAUNCH_ID then Nero:Destroy(); return end
print("[Nero] Loaded successfully. Tap N to show or hide Nero; X cancels every Nero process and closes it.")
