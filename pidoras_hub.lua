local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

_G.PidorasSettings = {
    ChamsEnabled = false, NameESPEnabled = false, HealthBarEnabled = false, CorpseESPEnabled = false,
    ItemWeapons = false, ItemAmmo = false, ItemMeds = false, ItemFood = false, ItemEquip = false,
    ItemContainers = false, ExtractionESPEnabled = false, BotESPEnabled = false,
    FullbrightEnabled = false, OptimizerEnabled = false,
    TargetFOV = 70,
    AimbotEnabled = false, AimbotFOV = 150, AimbotSmooth = 0, AimbotWallcheck = true, AimbotHitbox = "Head", AimbotMaxDist = 500, IgnoreTeammates = true,
    TriggerbotEnabled = false, TriggerIgnoreNPCs = true, TriggerbotDelay = 0.4,
    PredictionEnabled = false,
    NoRecoilEnabled = false
}

local activeHighlights, activeNameESPs, activeHealthBars, activeItemESPs, activeExtractionESPs, activeBotESPs, activeCorpseESPs = {}, {}, {}, {}, {}, {}, {}
local originalLightingSettings = {}
local itemESPConnection = nil

local OldRecoilValues = {}

local ReadableNames = {
    ["AKMN"] = "AKMN", ["M4A1"] = "M4A1", ["FAL"] = "FAL", ["Saiga-12"] = "Saiga-12",
    ["Makarov"] = "Makarov", ["TT-33"] = "TT-33", ["R700"] = "R700", ["PPSH-41"] = "PPSH-41",
    ["AI-2"] = "Аптечка AI-2", ["AI-4"] = "Аптечка AI-4", ["Bandage"] = "Бинт", 
    ["Promedol"] = "Промедол", ["Wound Dressing"] = "Перевязка",
    ["Water"] = "Вода", ["Benny's Beans"] = "Бобы", ["Bloxy Cola"] = "Кола", ["Chocolate"] = "Шоколад",
    ["Altyn"] = "Шлем Алтын", ["TOR-S"] = "Шлем ТОР-С", ["6B5"] = "Бронежилет 6B5",
    ["MagBulletPart"] = "Патроны / Магазин", ["BulletPart"] = "Патроны",
    ["MilitaryBox"] = "Военный ящик", ["ABPOPA"] = "Ящик ABPOPA", ["LootBag"] = "Сумка с лутом", ["Corpse"] = "Труп"
}

local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "PidorasHub_UI"; ScreenGui.ResetOnSpawn = false; ScreenGui.Parent = PlayerGui

local FovCircle = Instance.new("Frame"); FovCircle.AnchorPoint = Vector2.new(0.5, 0.5); FovCircle.Position = UDim2.new(0.5, 0, 0.5, 0); FovCircle.Size = UDim2.new(0, _G.PidorasSettings.AimbotFOV * 2, 0, _G.PidorasSettings.AimbotFOV * 2); FovCircle.BackgroundTransparency = 1; FovCircle.Visible = false; FovCircle.Parent = ScreenGui
local FovCircleCorner = Instance.new("UICorner"); FovCircleCorner.CornerRadius = UDim.new(1, 0); FovCircleCorner.Parent = FovCircle
local FovCircleStroke = Instance.new("UIStroke"); FovCircleStroke.Color = Color3.fromRGB(255, 50, 50); FovCircleStroke.Thickness = 1.5; FovCircleStroke.Transparency = 0.5; FovCircleStroke.Parent = FovCircle

local TargetDot = Instance.new("BillboardGui"); TargetDot.Name = "TargetDot"; TargetDot.Size = UDim2.new(0, 15, 0, 15); TargetDot.AlwaysOnTop = true; TargetDot.Enabled = false; TargetDot.Parent = ScreenGui
local DotFrame = Instance.new("Frame"); DotFrame.Size = UDim2.new(1, 0, 1, 0); DotFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0); DotFrame.Parent = TargetDot
local DotCorner = Instance.new("UICorner"); DotCorner.CornerRadius = UDim.new(1, 0); DotCorner.Parent = DotFrame

local MainFrame = Instance.new("Frame"); MainFrame.Size = UDim2.new(0, 420, 0, 320); MainFrame.Position = UDim2.new(0.5, -210, 0.5, -160); MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20); MainFrame.BorderSizePixel = 0; MainFrame.Parent = ScreenGui
local MainCorner = Instance.new("UICorner"); MainCorner.CornerRadius = UDim.new(0, 6); MainCorner.Parent = MainFrame
local MainStroke = Instance.new("UIStroke"); MainStroke.Color = Color3.fromRGB(80, 80, 80); MainStroke.Thickness = 1.5; MainStroke.Parent = MainFrame

local TopBar = Instance.new("Frame"); TopBar.Size = UDim2.new(1, 0, 0, 35); TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30); TopBar.Parent = MainFrame
local TopBarCorner = Instance.new("UICorner"); TopBarCorner.CornerRadius = UDim.new(0, 6); TopBarCorner.Parent = TopBar
local Title = Instance.new("TextLabel"); Title.Size = UDim2.new(1, -80, 1, 0); Title.Position = UDim2.new(0, 15, 0, 0); Title.BackgroundTransparency = 1; Title.Text = "Pidoras hub"; Title.TextColor3 = Color3.fromRGB(200, 200, 200); Title.Font = Enum.Font.GothamBold; Title.TextSize = 13; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Parent = TopBar

local MinimizeBtn = Instance.new("TextButton"); MinimizeBtn.Size = UDim2.new(0, 25, 0, 25); MinimizeBtn.Position = UDim2.new(1, -60, 0, 5); MinimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50); MinimizeBtn.Text = "—"; MinimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200); MinimizeBtn.Font = Enum.Font.GothamBold; MinimizeBtn.Parent = TopBar
local CloseBtn = Instance.new("TextButton"); CloseBtn.Size = UDim2.new(0, 25, 0, 25); CloseBtn.Position = UDim2.new(1, -30, 0, 5); CloseBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80); CloseBtn.Text = "X"; CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255); CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.Parent = TopBar

local Sidebar = Instance.new("Frame"); Sidebar.Size = UDim2.new(0, 110, 1, -35); Sidebar.Position = UDim2.new(0, 0, 0, 35); Sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 25); Sidebar.Parent = MainFrame
local Indicator = Instance.new("Frame"); Indicator.Size = UDim2.new(0, 3, 0.6, 0); Indicator.Position = UDim2.new(0, 0, 0.2, 0); Indicator.BackgroundColor3 = Color3.fromRGB(150, 150, 150); Indicator.Parent = Sidebar

local TabVisuals = Instance.new("TextButton"); TabVisuals.Size = UDim2.new(1, 0, 0, 35); TabVisuals.Position = UDim2.new(0, 0, 0, 10); TabVisuals.BackgroundTransparency = 1; TabVisuals.Text = "Visuals"; TabVisuals.TextColor3 = Color3.fromRGB(255, 255, 255); TabVisuals.Font = Enum.Font.GothamMedium; TabVisuals.TextSize = 13; TabVisuals.Parent = Sidebar
local TabCombat = Instance.new("TextButton"); TabCombat.Size = UDim2.new(1, 0, 0, 35); TabCombat.Position = UDim2.new(0, 0, 0, 50); TabCombat.BackgroundTransparency = 1; TabCombat.Text = "Combat"; TabCombat.TextColor3 = Color3.fromRGB(150, 150, 150); TabCombat.Font = Enum.Font.GothamMedium; TabCombat.TextSize = 13; TabCombat.Parent = Sidebar
local TabMisc = Instance.new("TextButton"); TabMisc.Size = UDim2.new(1, 0, 0, 35); TabMisc.Position = UDim2.new(0, 0, 0, 90); TabMisc.BackgroundTransparency = 1; TabMisc.Text = "Misc"; TabMisc.TextColor3 = Color3.fromRGB(150, 150, 150); TabMisc.Font = Enum.Font.GothamMedium; TabMisc.TextSize = 13; TabMisc.Parent = Sidebar
local TabInfo = Instance.new("TextButton"); TabInfo.Size = UDim2.new(1, 0, 0, 35); TabInfo.Position = UDim2.new(0, 0, 0, 130); TabInfo.BackgroundTransparency = 1; TabInfo.Text = "Info"; TabInfo.TextColor3 = Color3.fromRGB(150, 150, 150); TabInfo.Font = Enum.Font.GothamMedium; TabInfo.TextSize = 13; TabInfo.Parent = Sidebar

local ContentFrame = Instance.new("Frame"); ContentFrame.Size = UDim2.new(1, -120, 1, -45); ContentFrame.Position = UDim2.new(0, 115, 0, 40); ContentFrame.BackgroundTransparency = 1; ContentFrame.Parent = MainFrame

local function CreateSection(parent, text, yPos) local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, 0, 0, 20); lbl.Position = UDim2.new(0, 0, 0, yPos); lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(120, 120, 120); lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = parent end

local function CreateToggleRow(parent, text, yPos, defaultState, callback)
    local Row = Instance.new("TextButton"); Row.Size = UDim2.new(1, 0, 0, 28); Row.Position = UDim2.new(0, 0, 0, yPos); Row.BackgroundColor3 = Color3.fromRGB(25, 25, 25); Row.BackgroundTransparency = 0.01; Row.Text = ""; Row.Parent = parent
    local RowCorner = Instance.new("UICorner"); RowCorner.CornerRadius = UDim.new(0, 4); RowCorner.Parent = Row
    local Txt = Instance.new("TextLabel"); Txt.Size = UDim2.new(1, -30, 1, 0); Txt.Position = UDim2.new(0, 10, 0, 0); Txt.BackgroundTransparency = 1; Txt.Text = text; Txt.TextColor3 = defaultState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200); Txt.Font = Enum.Font.GothamMedium; Txt.TextSize = 12; Txt.TextXAlignment = Enum.TextXAlignment.Left; Txt.Parent = Row
    local Cb = Instance.new("Frame"); Cb.Size = UDim2.new(0, 14, 0, 14); Cb.Position = UDim2.new(1, -22, 0.5, -7); Cb.BackgroundColor3 = Color3.fromRGB(20, 20, 20); Cb.Parent = Row
    local CbStroke = Instance.new("UIStroke"); CbStroke.Color = Color3.fromRGB(100, 100, 100); CbStroke.Thickness = 1.5; CbStroke.Parent = Cb
    local CbFill = Instance.new("Frame"); CbFill.Size = UDim2.new(0, 6, 0, 6); CbFill.Position = UDim2.new(0.5, -3, 0.5, -3); CbFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255); CbFill.Visible = defaultState; CbFill.Parent = Cb
    
    Row.MouseButton1Click:Connect(function() 
        CbFill.Visible = not CbFill.Visible
        Txt.TextColor3 = CbFill.Visible and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        callback(CbFill.Visible) 
    end)
end

local function CreateSlider(parent, text, yPos, minVal, maxVal, defaultVal, callback)
    local Frame = Instance.new("Frame"); Frame.Size = UDim2.new(1, 0, 0, 40); Frame.Position = UDim2.new(0, 0, 0, yPos); Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25); Frame.Parent = parent
    local FCorner = Instance.new("UICorner"); FCorner.CornerRadius = UDim.new(0, 4); FCorner.Parent = Frame
    local Label = Instance.new("TextLabel"); Label.Size = UDim2.new(1, 0, 0, 18); Label.Position = UDim2.new(0, 10, 0, 2); Label.BackgroundTransparency = 1; Label.Text = text .. ": " .. defaultVal; Label.TextColor3 = Color3.fromRGB(200, 200, 200); Label.Font = Enum.Font.GothamMedium; Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.Parent = Frame
    local Bg = Instance.new("Frame"); Bg.Size = UDim2.new(1, -20, 0, 6); Bg.Position = UDim2.new(0, 10, 0, 22); Bg.BackgroundColor3 = Color3.fromRGB(50, 50, 50); Bg.Parent = Frame
    local Fill = Instance.new("Frame"); Fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0); Fill.BackgroundColor3 = Color3.fromRGB(200, 200, 200); Fill.Parent = Bg
    local Knob = Instance.new("Frame"); Knob.Size = UDim2.new(0, 12, 0, 12); Knob.Position = UDim2.new((defaultVal - minVal) / (maxVal - minVal), -6, 0.5, -6); Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Knob.Parent = Bg
    local KCorner = Instance.new("UICorner"); KCorner.CornerRadius = UDim.new(1, 0); KCorner.Parent = Knob
    local dragging = false
    Bg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
    UserInputService.InputChanged:Connect(function(input) 
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then 
            local relX = math.clamp((UserInputService:GetMouseLocation().X - Bg.AbsolutePosition.X) / Bg.AbsoluteSize.X, 0, 1)
            Fill.Size = UDim2.new(relX, 0, 1, 0); Knob.Position = UDim2.new(relX, -6, 0.5, -6)
            local val = math.floor((minVal + (relX * (maxVal - minVal))) * 10) / 10
            Label.Text = text .. ": " .. val
            callback(val) 
        end 
    end)
end

local ScrollingFrame = Instance.new("ScrollingFrame"); ScrollingFrame.Size = UDim2.new(1, 0, 1, 0); ScrollingFrame.BackgroundTransparency = 1; ScrollingFrame.BorderSizePixel = 0; ScrollingFrame.ScrollBarThickness = 0; ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 700); ScrollingFrame.Parent = ContentFrame

CreateSection(ScrollingFrame, "ESP (PLAYERS)", 5)
CreateToggleRow(ScrollingFrame, "Highlight (Chams)", 25, false, function(state) _G.PidorasSettings.ChamsEnabled = state; if not state then ClearHighlights() else StartChams() end end)
CreateToggleRow(ScrollingFrame, "Name ESP", 58, false, function(state) _G.PidorasSettings.NameESPEnabled = state; if not state then ClearNameESPs() else StartNameESP() end end)
CreateToggleRow(ScrollingFrame, "Health Bar", 91, false, function(state) _G.PidorasSettings.HealthBarEnabled = state; if not state then ClearHealthBars() else StartHealthBars() end end)
CreateToggleRow(ScrollingFrame, "Corpse ESP (Трупы)", 124, false, function(state) _G.PidorasSettings.CorpseESPEnabled = state; if not state then ClearCorpseESPs() else StartCorpseESP() end end)

CreateSection(ScrollingFrame, "ESP (ITEMS)", 160)
CreateToggleRow(ScrollingFrame, "Weapons (Оружие)", 180, false, function(state) _G.PidorasSettings.ItemWeapons = state; ClearItemESPs(); UpdateItemESP() end)
CreateToggleRow(ScrollingFrame, "Ammo (Патроны)", 213, false, function(state) _G.PidorasSettings.ItemAmmo = state; ClearItemESPs(); UpdateItemESP() end)
CreateToggleRow(ScrollingFrame, "Medicals (Аптечки)", 246, false, function(state) _G.PidorasSettings.ItemMeds = state; ClearItemESPs(); UpdateItemESP() end)
CreateToggleRow(ScrollingFrame, "Food & Water (Еда)", 279, false, function(state) _G.PidorasSettings.ItemFood = state; ClearItemESPs(); UpdateItemESP() end)
CreateToggleRow(ScrollingFrame, "Equipment (Броня)", 312, false, function(state) _G.PidorasSettings.ItemEquip = state; ClearItemESPs(); UpdateItemESP() end)
CreateToggleRow(ScrollingFrame, "Crates / Boxes (Ящики)", 345, false, function(state) _G.PidorasSettings.ItemContainers = state; ClearItemESPs(); UpdateItemESP() end)

CreateSection(ScrollingFrame, "ESP (WORLD)", 380)
CreateToggleRow(ScrollingFrame, "Bot ESP (NPCs)", 400, false, function(state) _G.PidorasSettings.BotESPEnabled = state; if not state then ClearBotESPs() else StartBotESP() end end)
CreateToggleRow(ScrollingFrame, "Extraction ESP (Выходы)", 433, false, function(state) _G.PidorasSettings.ExtractionESPEnabled = state; ClearItemESPs(); UpdateItemESP() end)
CreateToggleRow(ScrollingFrame, "Fullbright (Свет)", 466, false, function(state) _G.PidorasSettings.FullbrightEnabled = state; ToggleFullbright(state) end)
CreateSlider(ScrollingFrame, "Camera FOV", 499, 70, 120, 70, function(val) _G.PidorasSettings.TargetFOV = val end)

local CombatContent = Instance.new("ScrollingFrame"); CombatContent.Size = UDim2.new(1, 0, 1, 0); CombatContent.BackgroundTransparency = 1; CombatContent.BorderSizePixel = 0; CombatContent.ScrollBarThickness = 0; CombatContent.CanvasSize = UDim2.new(0, 0, 0, 600); CombatContent.Visible = false; CombatContent.Parent = ContentFrame
CreateSection(CombatContent, "AIMBOT", 5)
CreateToggleRow(CombatContent, "Aimbot", 25, false, function(state) _G.PidorasSettings.AimbotEnabled = state; FovCircle.Visible = state end)
CreateToggleRow(CombatContent, "Triggerbot (Автострельба)", 58, false, function(state) _G.PidorasSettings.TriggerbotEnabled = state end)
CreateToggleRow(CombatContent, "Ignore NPCs (Только игроки)", 91, true, function(state) _G.PidorasSettings.TriggerIgnoreNPCs = state end)
CreateToggleRow(CombatContent, "Wallcheck", 124, false, function(state) _G.PidorasSettings.AimbotWallcheck = state end)
CreateToggleRow(CombatContent, "Ignore Teammates (Не бить своих)", 157, true, function(state) _G.PidorasSettings.IgnoreTeammates = state end)

CreateSlider(CombatContent, "Triggerbot Delay", 190, 0.1, 2.0, 0.4, function(val) _G.PidorasSettings.TriggerbotDelay = val end)
CreateSlider(CombatContent, "Aimbot FOV", 236, 50, 500, 150, function(val) _G.PidorasSettings.AimbotFOV = val; FovCircle.Size = UDim2.new(0, val * 2, 0, val * 2) end)
CreateSlider(CombatContent, "Smoothness (0 = Instant)", 282, 0, 10, 0, function(val) _G.PidorasSettings.AimbotSmooth = val end)
CreateSlider(CombatContent, "Max Distance", 328, 50, 1000, 500, function(val) _G.PidorasSettings.AimbotMaxDist = val end)

CreateSection(CombatContent, "ADVANCED COMBAT", 380)
CreateToggleRow(CombatContent, "Prediction (Упреждение)", 400, false, function(state) _G.PidorasSettings.PredictionEnabled = state end)
CreateToggleRow(CombatContent, "No Recoil (Без отдачи)", 433, false, function(state) 
    _G.PidorasSettings.NoRecoilEnabled = state
    ToggleNoRecoil(state)
end)

local MiscContent = Instance.new("ScrollingFrame"); MiscContent.Size = UDim2.new(1, 0, 1, 0); MiscContent.BackgroundTransparency = 1; MiscContent.BorderSizePixel = 0; MiscContent.ScrollBarThickness = 0; MiscContent.CanvasSize = UDim2.new(0, 0, 0, 100); MiscContent.Visible = false; MiscContent.Parent = ContentFrame
CreateToggleRow(MiscContent, "Optimizer (FPS Boost)", 5, false, function(state) _G.PidorasSettings.OptimizerEnabled = state; ToggleOptimizer(state) end)

local InfoContent = Instance.new("Frame"); InfoContent.Size = UDim2.new(1, 0, 1, 0); InfoContent.BackgroundTransparency = 1; InfoContent.Visible = false; InfoContent.Parent = ContentFrame

local InfoTitle = Instance.new("TextLabel"); InfoTitle.Size = UDim2.new(1, 0, 0, 30); InfoTitle.Position = UDim2.new(0, 0, 0, 10); InfoTitle.BackgroundTransparency = 1; InfoTitle.Text = "Telegram Channel"; InfoTitle.TextColor3 = Color3.fromRGB(255, 255, 255); InfoTitle.Font = Enum.Font.GothamBold; InfoTitle.TextSize = 18; InfoTitle.Parent = InfoContent

local TgLink = "https://t.me/+Kqqs0F6TAcdiMzI6"
local LinkLabel = Instance.new("TextLabel"); LinkLabel.Size = UDim2.new(1, -20, 0, 40); LinkLabel.Position = UDim2.new(0, 10, 0, 50); LinkLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30); LinkLabel.Text = TgLink; LinkLabel.TextColor3 = Color3.fromRGB(0, 200, 255); LinkLabel.Font = Enum.Font.GothamMedium; LinkLabel.TextSize = 12; LinkLabel.Parent = InfoContent
local LinkCorner = Instance.new("UICorner"); LinkCorner.CornerRadius = UDim.new(0, 4); LinkCorner.Parent = LinkLabel

local CopyBtn = Instance.new("TextButton"); CopyBtn.Size = UDim2.new(1, -20, 0, 35); CopyBtn.Position = UDim2.new(0, 10, 0, 100); CopyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); CopyBtn.Text = "Скопировать ссылку"; CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255); CopyBtn.Font = Enum.Font.GothamBold; CopyBtn.TextSize = 14; CopyBtn.Parent = InfoContent
local CopyCorner = Instance.new("UICorner"); CopyCorner.CornerRadius = UDim.new(0, 4); CopyCorner.Parent = CopyBtn

CopyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(TgLink)
        CopyBtn.Text = "Скопировано!"
        CopyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        task.wait(2)
        CopyBtn.Text = "Скопировать ссылку"
        CopyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    else
        CopyBtn.Text = "Ошибка копирования"
    end
end)

local Watermark = Instance.new("TextLabel"); Watermark.Size = UDim2.new(0, 200, 0, 30); Watermark.Position = UDim2.new(0, 10, 0, 10); Watermark.BackgroundColor3 = Color3.fromRGB(20, 20, 20); Watermark.BackgroundTransparency = 0.4; Watermark.Text = "Pidoras hub | FPS: 0"; Watermark.TextColor3 = Color3.fromRGB(255, 255, 255); Watermark.Font = Enum.Font.GothamBold; Watermark.TextSize = 14; Watermark.TextYAlignment = Enum.TextYAlignment.Center; Watermark.TextStrokeTransparency = 0; Watermark.Visible = false; Watermark.Parent = ScreenGui
local WmCorner = Instance.new("UICorner"); WmCorner.CornerRadius = UDim.new(0, 4); WmCorner.Parent = Watermark
local WmStroke = Instance.new("UIStroke"); WmStroke.Color = Color3.fromRGB(80, 80, 80); WmStroke.Thickness = 1.5; WmStroke.Parent = Watermark
task.spawn(function() while ScreenGui.Parent do Watermark.Text = string.format("Pidoras hub | FPS: %d", math.floor(1 / RunService.RenderStepped:Wait())) end end)

local dragging, dragStart, startPos = false, nil, nil
TopBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = input.Position; startPos = MainFrame.Position; input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) end end)
UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local delta = input.Position - dragStart; MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)

local function SwitchTab(activeTab, showFrame) 
    TabVisuals.TextColor3 = Color3.fromRGB(150, 150, 150); TabCombat.TextColor3 = Color3.fromRGB(150, 150, 150); TabMisc.TextColor3 = Color3.fromRGB(150, 150, 150); TabInfo.TextColor3 = Color3.fromRGB(150, 150, 150)
    activeTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    Indicator.Parent = activeTab
    ScrollingFrame.Visible = false; CombatContent.Visible = false; MiscContent.Visible = false; InfoContent.Visible = false
    showFrame.Visible = true 
end

TabVisuals.MouseButton1Click:Connect(function() SwitchTab(TabVisuals, ScrollingFrame) end)
TabCombat.MouseButton1Click:Connect(function() SwitchTab(TabCombat, CombatContent) end)
TabMisc.MouseButton1Click:Connect(function() SwitchTab(TabMisc, MiscContent) end)
TabInfo.MouseButton1Click:Connect(function() SwitchTab(TabInfo, InfoContent) end)

function ClearHighlights() for p, h in pairs(activeHighlights) do if h then h:Destroy() end activeHighlights[p] = nil end end
function ClearNameESPs() for p, g in pairs(activeNameESPs) do if g then g:Destroy() end activeNameESPs[p] = nil end end
function ClearHealthBars() for p, g in pairs(activeHealthBars) do if g then g:Destroy() end activeHealthBars[p] = nil end end
function ClearItemESPs() for obj, gui in pairs(activeItemESPs) do if gui then gui:Destroy() end activeItemESPs[obj] = nil end; for obj, gui in pairs(activeExtractionESPs) do if gui then gui:Destroy() end activeExtractionESPs[obj] = nil end end
function ClearBotESPs() for obj, gui in pairs(activeBotESPs) do if gui then gui:Destroy() end activeBotESPs[obj] = nil end end
function ClearCorpseESPs() for obj, bb in pairs(activeCorpseESPs) do if bb then bb:Destroy() end if obj and obj:FindFirstChild("CorpseESP_HL") then obj.CorpseESP_HL:Destroy() end activeCorpseESPs[obj] = nil end end

function StartChams() task.spawn(function() while _G.PidorasSettings.ChamsEnabled do for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LocalPlayer and plr.Character then if not activeHighlights[plr] or activeHighlights[plr].Parent ~= plr.Character then if activeHighlights[plr] then activeHighlights[plr]:Destroy() end local hl = Instance.new("Highlight"); hl.FillColor = Color3.fromRGB(255, 0, 0); hl.OutlineColor = Color3.fromRGB(255, 255, 255); hl.FillTransparency = 1; hl.Parent = plr.Character; activeHighlights[plr] = hl end end end task.wait(2) end end) end
function StartNameESP() task.spawn(function() while _G.PidorasSettings.NameESPEnabled do local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LocalPlayer and plr.Character and myRoot then local head = plr.Character:FindFirstChild("Head"); local targetRoot = plr.Character:FindFirstChild("HumanoidRootPart"); if head and targetRoot then local dist = math.floor((myRoot.Position - targetRoot.Position).Magnitude); if not activeNameESPs[plr] or activeNameESPs[plr].Parent ~= head then if activeNameESPs[plr] then activeNameESPs[plr]:Destroy() end local bb = Instance.new("BillboardGui"); bb.Size = UDim2.new(0, 120, 0, 25); bb.StudsOffset = Vector3.new(0, 2.5, 0); bb.AlwaysOnTop = true; bb.Parent = head; local txt = Instance.new("TextLabel"); txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1; txt.TextColor3 = Color3.fromRGB(255, 255, 255); txt.TextStrokeTransparency = 0; txt.Font = Enum.Font.GothamBold; txt.TextSize = 14; txt.Parent = bb; activeNameESPs[plr] = bb end; local txt = activeNameESPs[plr]:FindFirstChild("TextLabel"); if txt then txt.Text = plr.Name .. " [" .. dist .. "m]" end end end end task.wait(0.5) end end) end
function StartHealthBars() task.spawn(function() while _G.PidorasSettings.HealthBarEnabled do local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LocalPlayer and plr.Character and myRoot then local hrp = plr.Character:FindFirstChild("HumanoidRootPart"); local hum = plr.Character:FindFirstChildOfClass("Humanoid"); if hrp and hum then local dist = (myRoot.Position - hrp.Position).Magnitude; local isVisible = dist <= 400; if not activeHealthBars[plr] or activeHealthBars[plr].Parent ~= hrp then if activeHealthBars[plr] then activeHealthBars[plr]:Destroy() end local bb = Instance.new("BillboardGui"); bb.Size = UDim2.new(0, 6, 0, 40); bb.StudsOffset = Vector3.new(2.5, 0, 0); bb.AlwaysOnTop = true; bb.Parent = hrp; local bg = Instance.new("Frame"); bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = Color3.fromRGB(30, 30, 30); bg.BackgroundTransparency = 0.3; bg.Parent = bb; local bgStroke = Instance.new("UIStroke"); bgStroke.Color = Color3.fromRGB(0, 0, 0); bgStroke.Thickness = 1; bgStroke.Parent = bg; local fill = Instance.new("Frame"); fill.Name = "Fill"; fill.Size = UDim2.new(1, 0, 1, 0); fill.AnchorPoint = Vector2.new(0, 1); fill.Position = UDim2.new(0, 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0); fill.Parent = bg; activeHealthBars[plr] = bb end; activeHealthBars[plr].Enabled = isVisible; if isVisible then local fill = activeHealthBars[plr]:FindFirstChild("Fill", true); if fill then local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1); fill.Size = UDim2.new(1, 0, ratio, 0); if ratio > 0.6 then fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0) elseif ratio > 0.3 then fill.BackgroundColor3 = Color3.fromRGB(255, 255, 0) else fill.BackgroundColor3 = Color3.fromRGB(255, 0, 0) end end end end end end task.wait(0.2) end end) end

function StartCorpseESP() 
    task.spawn(function() 
        while _G.PidorasSettings.CorpseESPEnabled do 
            local count = 0
            for _, obj in ipairs(Workspace:GetDescendants()) do 
                count = count + 1
                if count % 200 == 0 then task.wait() end
                
                -- Игнорируем собственного персонажа (защита от самоподсветки)
                if obj == LocalPlayer.Character or (LocalPlayer.Character and obj:IsDescendantOf(LocalPlayer.Character)) then continue end
                
                if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
                    local hum = obj:FindFirstChildOfClass("Humanoid")
                    
                    -- Если есть Humanoid и он ЖИВОЙ — пропускаем
                    if hum and hum.Health > 0 then continue end
                    
                    local isCorpse = false
                    local foundPlayerName = nil
                    
                    -- Проверяем имя модели на совпадение с игроками в лобби (исключая себя)
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= LocalPlayer and string.find(obj.Name, plr.Name) then
                            foundPlayerName = plr.Name
                            break
                        end
                    end
                    
                    -- Если в имени модели нет ника, проверяем Humanoid (если он остался)
                    if not foundPlayerName and hum then
                        for _, plr in ipairs(Players:GetPlayers()) do
                            if plr ~= LocalPlayer and (hum.DisplayName == plr.Name or hum.DisplayName == plr.DisplayName) then
                                foundPlayerName = plr.Name
                                break
                            end
                        end
                    end

                    if foundPlayerName then
                        isCorpse = true
                    end

                    if isCorpse then
                        local head = obj:FindFirstChild("Head") or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
                        if head and not obj:FindFirstChild("CorpseESP_HL") then
                            local hl = Instance.new("Highlight")
                            hl.Name = "CorpseESP_HL"
                            hl.FillColor = Color3.fromRGB(255, 50, 50)
                            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                            hl.FillTransparency = 0.5
                            hl.OutlineTransparency = 0
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            hl.Adornee = obj
                            hl.Parent = obj
                            
                            local bb = Instance.new("BillboardGui")
                            bb.Name = "CorpseESP_BB"
                            bb.Size = UDim2.new(0, 200, 0, 50)
                            bb.StudsOffset = Vector3.new(0, 3, 0)
                            bb.AlwaysOnTop = true
                            bb.Parent = head
                            
                            local txt = Instance.new("TextLabel")
                            txt.Size = UDim2.new(1, 0, 1, 0)
                            txt.BackgroundTransparency = 1
                            txt.Text = "💀 " .. foundPlayerName
                            txt.TextColor3 = Color3.fromRGB(255, 255, 0)
                            txt.TextStrokeTransparency = 0
                            txt.Font = Enum.Font.GothamBold
                            txt.TextSize = 16
                            txt.Parent = bb
                            
                            activeCorpseESPs[obj] = bb
                        end
                    end
                end
            end
            task.wait(1.5) 
        end
    end) 
end

function StartBotESP() task.spawn(function() while _G.PidorasSettings.BotESPEnabled do for _, obj in ipairs(Workspace:GetChildren()) do if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then local hum = obj:FindFirstChildOfClass("Humanoid"); local head = obj:FindFirstChild("Head"); if hum and hum.Health > 0 and head then if not activeBotESPs[obj] or activeBotESPs[obj].Parent ~= head then if activeBotESPs[obj] then activeBotESPs[obj]:Destroy() end local bb = Instance.new("BillboardGui"); bb.Size = UDim2.new(0, 100, 0, 25); bb.StudsOffset = Vector3.new(0, 2.5, 0); bb.AlwaysOnTop = true; bb.Parent = head; local txt = Instance.new("TextLabel"); txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1; txt.Text = "🤖 БОТ (" .. obj.Name .. ")"; txt.TextColor3 = Color3.fromRGB(255, 150, 50); txt.TextStrokeTransparency = 0; txt.Font = Enum.Font.GothamBold; txt.TextSize = 14; txt.Parent = bb; activeBotESPs[obj] = bb end end end end task.wait(1) end end) end

local function ProcessWorldESP()
    if not (_G.PidorasSettings.ItemWeapons or _G.PidorasSettings.ItemAmmo or _G.PidorasSettings.ItemMeds or _G.PidorasSettings.ItemFood or _G.PidorasSettings.ItemEquip or _G.PidorasSettings.ItemContainers or _G.PidorasSettings.ExtractionESPEnabled) then return end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not myRoot then return end
    local count = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        count = count + 1; if count % 100 == 0 then task.wait() end
        if obj:IsDescendantOf(LocalPlayer.Character) or obj:FindFirstAncestorOfClass("Tool") or obj:IsA("Tool") then continue end
        if obj:IsA("Player") or obj:IsA("Terrain") or obj:IsA("TextLabel") or obj:IsA("BillboardGui") or obj:IsA("ProximityPrompt") then continue end
        local ancestorModel = obj:FindFirstAncestorWhichIsA("Model")
        if ancestorModel then
            if ancestorModel:FindFirstChildOfClass("Humanoid") and ancestorModel:FindFirstChildOfClass("Humanoid").Health > 0 then continue end
            if Players:GetPlayerFromCharacter(ancestorModel) then continue end
            if activeItemESPs[ancestorModel] then continue end
        end
        local name = string.lower(obj.Name)
        local blacklist = {"tree", "bush", "grass", "rock", "boulder", "map", "mesh", "terrain", "wall", "trigger", "foam", "occupant", "tower", "effect", "spawn", "salfetka", "torsion", "wheel", "engine", "chassis", "door", "mount", "stock", "toilet", "upperarm", "lowerarm", "lefthand", "righthand", "leftfoot", "rightfoot", "leftleg", "rightleg", "skeleton", "bone", "corpse", "ragdoll", "figure", "dummy", "torso", "head", "neck", "pelvis", "prompt", "arm", "leg", "hand", "foot", "magazine", "mag", "clip", "hitbox", "face"}
        local isIgnored = false; for _, word in ipairs(blacklist) do if string.find(name, word) then isIgnored = true; break end end; if isIgnored then continue end
        local pos = nil; if obj:IsA("BasePart") then pos = obj.Position elseif obj:IsA("Model") and obj.PrimaryPart then pos = obj.PrimaryPart.Position elseif obj:IsA("Model") then local p = obj:FindFirstChildWhichIsA("BasePart"); if p then pos = p.Position end end
        if pos and (myRoot.Position - pos).Magnitude > 2000 then continue end
        local color = nil; local displayName = ReadableNames[obj.Name] or obj.Name; local isExtract = false
        if _G.PidorasSettings.ExtractionESPEnabled then
            local prompt = obj:FindFirstChildOfClass("ProximityPrompt"); local promptText = ""
            if prompt then promptText = string.lower(prompt.ActionText .. " " .. prompt.ObjectText) end
            if string.find(name, "exit") or string.find(name, "extract") or string.find(name, "evac") or string.find(name, "escape") or string.find(promptText, "extract") or string.find(promptText, "evac") then color = Color3.fromRGB(0, 255, 255); displayName = "🚪 ВЫХОД (" .. obj.Name .. ")"; isExtract = true end
        end
        if not isExtract and _G.PidorasSettings.ItemContainers then if string.find(name, "crate") or string.find(name, "box") or string.find(name, "container") or string.find(name, "satchel") or string.find(name, "safe") or string.find(name, "abpopa") or string.find(name, "lootbag") then color = Color3.fromRGB(180, 50, 255); displayName = "📦 Ящик / Сумка (" .. (ReadableNames[obj.Name] or obj.Name) .. ")" end end
        if not isExtract and not color then
            if _G.PidorasSettings.ItemWeapons and (obj:IsA("Tool") or string.find(name, "gun") or string.find(name, "rifle") or string.find(name, "pistol") or string.find(name, "akmn") or string.find(name, "m4a1") or string.find(name, "fal") or string.find(name, "saiga") or string.find(name, "weapon")) then color = Color3.fromRGB(255, 50, 50)
            elseif _G.PidorasSettings.ItemAmmo and (string.find(name, "ammo") or string.find(name, "round") or string.find(name, "bullet")) then color = Color3.fromRGB(255, 150, 50)
            elseif _G.PidorasSettings.ItemMeds and (string.find(name, "medbag") or string.find(name, "medkit") or string.find(name, "bandage") or string.find(name, "pill") or string.find(name, "promedol") or string.find(name, "ai-2") or string.find(name, "medical") or string.find(name, "kit")) then color = Color3.fromRGB(50, 255, 50)
            elseif _G.PidorasSettings.ItemFood and (string.find(name, "food") or string.find(name, "water") or string.find(name, "bean") or string.find(name, "cola") or string.find(name, "choc") or string.find(name, "bottle")) then color = Color3.fromRGB(255, 255, 50)
            elseif _G.PidorasSettings.ItemEquip and (string.find(name, "armor") or string.find(name, "vest") or string.find(name, "helmet") or string.find(name, "backpack") or string.find(name, "rig") or string.find(name, "altyn") or string.find(name, "platecarrier")) then color = Color3.fromRGB(50, 150, 255) end
        end
        if color then
            local targetTable = isExtract and activeExtractionESPs or activeItemESPs
            if not targetTable[obj] then
                local billboard = Instance.new("BillboardGui"); billboard.Size = UDim2.new(0, 150, 0, 25); billboard.StudsOffset = Vector3.new(0, 1.5, 0); billboard.AlwaysOnTop = true
                local text = Instance.new("TextLabel"); text.Size = UDim2.new(1, 0, 1, 0); text.BackgroundTransparency = 1; text.Text = displayName; text.TextColor3 = color; text.TextStrokeTransparency = 0; text.Font = Enum.Font.GothamBold; text.TextSize = 12; text.Parent = billboard
                if obj:IsA("Model") and obj.PrimaryPart then billboard.Parent = obj.PrimaryPart elseif obj:IsA("BasePart") then billboard.Parent = obj else local part = obj:FindFirstChildWhichIsA("BasePart"); if part then billboard.Parent = part else continue end end
                targetTable[obj] = billboard
            end
        end
    end
end

function UpdateItemESP() 
    local isAnyOn = _G.PidorasSettings.ItemWeapons or _G.PidorasSettings.ItemAmmo or _G.PidorasSettings.ItemMeds or _G.PidorasSettings.ItemFood or _G.PidorasSettings.ItemEquip or _G.PidorasSettings.ItemContainers or _G.PidorasSettings.ExtractionESPEnabled
    if not isAnyOn then ClearItemESPs(); return end
    if not itemESPConnection then 
        itemESPConnection = task.spawn(function() 
            while (_G.PidorasSettings.ItemWeapons or _G.PidorasSettings.ItemAmmo or _G.PidorasSettings.ItemMeds or _G.PidorasSettings.ItemFood or _G.PidorasSettings.ItemEquip or _G.PidorasSettings.ItemContainers or _G.PidorasSettings.ExtractionESPEnabled) do 
                ProcessWorldESP(); task.wait(1) 
            end 
            ClearItemESPs(); itemESPConnection = nil 
        end) 
    end 
end

local function GetClosestTarget()
    local closestTarget = nil; local shortestDist = math.huge; local fov = _G.PidorasSettings.AimbotFOV; local camPos = Camera.CFrame.Position
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            if _G.PidorasSettings.IgnoreTeammates and LocalPlayer.Team and plr.Team == LocalPlayer.Team then continue end
            
            local hum = plr.Character:FindFirstChildOfClass("Humanoid"); local targetPart = plr.Character:FindFirstChild(_G.PidorasSettings.AimbotHitbox)
            if hum and hum.Health > 0 and targetPart then
                local distToCenter = (camPos - targetPart.Position).Magnitude
                if distToCenter <= _G.PidorasSettings.AimbotMaxDist then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local distToScreenCenter = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                        if distToScreenCenter < fov then
                            local canSee = true
                            if _G.PidorasSettings.AimbotWallcheck then
                                local rayParams = RaycastParams.new(); rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}; rayParams.FilterType = Enum.RaycastFilterType.Exclude
                                local rayResult = Workspace:Raycast(camPos, targetPart.Position - camPos, rayParams)
                                if rayResult and not rayResult.Instance:IsDescendantOf(plr.Character) then canSee = false end
                            end
                            if canSee and distToScreenCenter < shortestDist then shortestDist = distToScreenCenter; closestTarget = targetPart end
                        end
                    end
                end
            end
        end
    end
    return closestTarget
end

local triggerbotCooldown = 0
local cachedFirePos = nil

local function GetFirePos()
    if cachedFirePos then return cachedFirePos end
    local bestPos = Vector2.new(Camera.ViewportSize.X - 100, Camera.ViewportSize.Y - 100)
    local bestDist = math.huge
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if (obj:IsA("ImageButton") or obj:IsA("TextButton")) and obj.Visible then
            local name = string.lower(obj.Name)
            if string.find(name, "attack") or string.find(name, "fire") or string.find(name, "shoot") or string.find(name, "mouse") then
                cachedFirePos = obj.AbsolutePosition + (obj.AbsoluteSize / 2)
                return cachedFirePos
            end
            if obj:IsA("ImageButton") then
                local pos = obj.AbsolutePosition + (obj.AbsoluteSize / 2)
                if pos.X > Camera.ViewportSize.X / 2 and pos.Y > Camera.ViewportSize.Y / 1.5 then
                    local dist = (Vector2.new(Camera.ViewportSize.X, Camera.ViewportSize.Y) - pos).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        bestPos = pos
                    end
                end
            end
        end
    end
    cachedFirePos = bestPos
    return cachedFirePos
end

local function FireWeapon()
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool then pcall(function() tool:Activate() end) end
    
    if UserInputService.TouchEnabled then
        local pos = GetFirePos()
        pcall(function()
            VirtualUser:Button1Down(pos)
            task.wait(0.05)
            VirtualUser:Button1Up(pos)
        end)
    else
        if mouse1click then
            pcall(function() mouse1click() end)
        end
    end
end

-- ==========================================
-- НОВАЯ ЛОГИКА NO RECOIL (через RecoilStrength)
-- ==========================================
local function ToggleNoRecoil(state)
    local ammoFolder = ReplicatedStorage:FindFirstChild("AmmoTypes") or ReplicatedStorage:FindFirstChild("Ammo")
    
    if not ammoFolder then 
        warn("Папка с патронами не найдена.")
        return 
    end

    for _, ammo in ipairs(ammoFolder:GetChildren()) do
        local currentAttr = ammo:GetAttribute("RecoilStrength")
        
        if currentAttr ~= nil then
            if state then
                if OldRecoilValues[ammo.Name] == nil then
                    OldRecoilValues[ammo.Name] = currentAttr
                end
                ammo:SetAttribute("RecoilStrength", 0)
            else
                if OldRecoilValues[ammo.Name] ~= nil then
                    ammo:SetAttribute("RecoilStrength", OldRecoilValues[ammo.Name])
                end
            end
        end
    end
end

-- Периодическая проверка на случай, если патроны подгружаются позже
task.spawn(function()
    while task.wait(2) do
        if _G.PidorasSettings.NoRecoilEnabled then
            ToggleNoRecoil(true)
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if Camera.FieldOfView ~= _G.PidorasSettings.TargetFOV then Camera.FieldOfView = _G.PidorasSettings.TargetFOV end

    if _G.PidorasSettings.AimbotEnabled then
        local target = GetClosestTarget()
        if target then
            TargetDot.Adornee = target
            TargetDot.Enabled = true
            local targetPos = target.Position
            if _G.PidorasSettings.PredictionEnabled then local velocity = target.AssemblyLinearVelocity; targetPos = targetPos + (velocity * 0.15) end
            if _G.PidorasSettings.AimbotSmooth == 0 then Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPos)
            else local alpha = 1 / (_G.PidorasSettings.AimbotSmooth * 5); Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetPos), alpha) end
        else
            TargetDot.Adornee = nil
            TargetDot.Enabled = false
        end
    else
        TargetDot.Adornee = nil
        TargetDot.Enabled = false
    end

    if _G.PidorasSettings.TriggerbotEnabled and tick() > triggerbotCooldown then
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local ray = Camera:ViewportPointToRay(screenCenter.X, screenCenter.Y)
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, rayParams)
        
        if result and result.Instance then
            local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
            if hitModel and hitModel:FindFirstChildOfClass("Humanoid") and hitModel ~= LocalPlayer.Character then
                local plr = Players:GetPlayerFromCharacter(hitModel)
                
                if _G.PidorasSettings.IgnoreTeammates and plr and LocalPlayer.Team and plr.Team == LocalPlayer.Team then return end

                local isRealPlayer = false
                if plr and plr.UserId > 0 then isRealPlayer = true end
                
                local distToTarget = (Camera.CFrame.Position - hitModel.HumanoidRootPart.Position).Magnitude
                
                if (_G.PidorasSettings.TriggerIgnoreNPCs and isRealPlayer and distToTarget < 300) or (not _G.PidorasSettings.TriggerIgnoreNPCs and distToTarget < 300) then
                    triggerbotCooldown = tick() + _G.PidorasSettings.TriggerbotDelay
                    FireWeapon()
                end
            end
        end
    end
end)

function ToggleFullbright(state) 
    if state then 
        originalLightingSettings.Ambient = Lighting.Ambient; originalLightingSettings.OutdoorAmbient = Lighting.OutdoorAmbient; originalLightingSettings.ClockTime = Lighting.ClockTime
        Lighting.Ambient = Color3.fromRGB(255, 255, 255); Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255); Lighting.ClockTime = 14 
    else 
        if originalLightingSettings.Ambient then Lighting.Ambient = originalLightingSettings.Ambient; Lighting.OutdoorAmbient = originalLightingSettings.OutdoorAmbient; Lighting.ClockTime = originalLightingSettings.ClockTime end 
    end 
end

function ToggleOptimizer(state)
    local success, err = pcall(function()
        if state then
            originalLightingSettings.GlobalShadows = Lighting.GlobalShadows
            originalLightingSettings.FogEnd = Lighting.FogEnd
            originalLightingSettings.EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale
            originalLightingSettings.EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
            
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 100000
            Lighting.EnvironmentDiffuseScale = 0
            Lighting.EnvironmentSpecularScale = 0
            
            for _, effect in pairs(Lighting:GetChildren()) do
                if effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") or effect:IsA("DepthOfFieldEffect") then
                    originalLightingSettings[effect.Name] = effect.Enabled; effect.Enabled = false
                elseif effect:IsA("Atmosphere") then
                    originalLightingSettings.AtomosphereDensity = effect.Density; effect.Density = 0
                end
            end
            
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") then
                    obj.Enabled = false
                end
                if obj:IsA("BasePart") then
                    obj.CastShadow = false
                end
            end
        else
            if originalLightingSettings.GlobalShadows ~= nil then 
                Lighting.GlobalShadows = originalLightingSettings.GlobalShadows
                Lighting.FogEnd = originalLightingSettings.FogEnd 
                Lighting.EnvironmentDiffuseScale = originalLightingSettings.EnvironmentDiffuseScale
                Lighting.EnvironmentSpecularScale = originalLightingSettings.EnvironmentSpecularScale
            end
            for _, effect in pairs(Lighting:GetChildren()) do
                if effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") or effect:IsA("DepthOfFieldEffect") then
                    if originalLightingSettings[effect.Name] ~= nil then effect.Enabled = originalLightingSettings[effect.Name] end
                elseif effect:IsA("Atmosphere") and originalLightingSettings.AtmosphereDensity then effect.Density = originalLightingSettings.AtmosphereDensity end
            end
        end
    end)
end

MinimizeBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false; Watermark.Visible = true; if not _G.PidorasSettings.AimbotEnabled then FovCircle.Visible = false end; TargetDot.Enabled = false end)
Watermark.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Watermark.Visible = false; MainFrame.Visible = true; if _G.PidorasSettings.AimbotEnabled then FovCircle.Visible = true end end end)
CloseBtn.MouseButton1Click:Connect(function() 
    for k, _ in pairs(_G.PidorasSettings) do _G.PidorasSettings[k] = false end
    ToggleNoRecoil(false)
    ClearHighlights(); ClearNameESPs(); ClearHealthBars(); ClearItemESPs(); ClearBotESPs(); ClearCorpseESPs(); ToggleFullbright(false); pcall(ToggleOptimizer, false); Camera.FieldOfView = 70
    TargetDot.Adornee = nil; TargetDot.Enabled = false
    ScreenGui:Destroy(); _G.PidorasSettings = nil 
end)
