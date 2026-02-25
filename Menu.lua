--!strict
-- CleanMenu.lua
-- Full build with 2-column toggle layout per tab
-- Lazy ESP load + crash fix (no startup execution)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------
local CONFIG = {
	GuiName = "CleanMenuGui",

	Width = 560,
	Height = 380,

	Accent = Color3.fromRGB(170, 0, 255),
	BgMain = Color3.fromRGB(18,18,22),
	BgSidebar = Color3.fromRGB(22,22,28),
	BgCard = Color3.fromRGB(28,28,35),

	Text = Color3.fromRGB(240,240,245),
	SubText = Color3.fromRGB(170,170,180),
	Stroke = Color3.fromRGB(60,60,70),
}

----------------------------------------------------------------
-- MODULE URLS
----------------------------------------------------------------
local TOGGLES_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/Menu/ToggleSwitches.lua"
local DRAG_URL    = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/Menu/DragController.lua"
local ESP_URL     = "https://raw.githubusercontent.com/KashDummyEnt/EBTware-Hypershot/refs/heads/main/Features/ESP.lua"

----------------------------------------------------------------
-- SAFE MODULE LOADER
----------------------------------------------------------------
local function loadModule(url: string)
	local ok, code = pcall(function()
		return game:HttpGet(url)
	end)
	if not ok then error(code) end

	local fn = loadstring(code)
	if not fn then error("compile fail") end

	local result = fn()
	return result
end

----------------------------------------------------------------
-- LOAD CORE MODULES
----------------------------------------------------------------
local Toggles = loadModule(TOGGLES_URL)
local DragController = loadModule(DRAG_URL)

local G = (typeof(getgenv) == "function") and getgenv() or _G
G.__HIGGI_TOGGLES_API = Toggles

----------------------------------------------------------------
-- LAZY FEATURE LOADER
----------------------------------------------------------------
local featureLoaded: {[string]: boolean} = {}

local function ensureFeatureLoaded(key: string, url: string)
	if featureLoaded[key] then
		return
	end
	featureLoaded[key] = true
	loadModule(url)
end

----------------------------------------------------------------
-- UI HELPERS (UNCHANGED)
----------------------------------------------------------------
local function make(class, props)
	local inst = Instance.new(class)
	if props then
		for k,v in pairs(props) do
			inst[k] = v
		end
	end
	return inst
end

local function addCorner(parent, r)
	make("UICorner", {
		CornerRadius = UDim.new(0,r),
		Parent = parent,
	})
end

local function addStroke(parent)
	make("UIStroke", {
		Color = CONFIG.Stroke,
		Thickness = 1,
		Transparency = 0.3,
		Parent = parent,
	})
end

----------------------------------------------------------------
-- DESTROY OLD
----------------------------------------------------------------
local existing = playerGui:FindFirstChild(CONFIG.GuiName)
if existing then
	existing:Destroy()
end

----------------------------------------------------------------
-- SCREEN GUI
----------------------------------------------------------------
local screenGui = make("ScreenGui", {
	Name = CONFIG.GuiName,
	ResetOnSpawn = false,
	Parent = playerGui,
})

----------------------------------------------------------------
-- MAIN WINDOW
----------------------------------------------------------------
local window = make("Frame", {
	BackgroundColor3 = CONFIG.BgMain,
	Size = UDim2.fromOffset(CONFIG.Width, CONFIG.Height),
	Position = UDim2.fromScale(0.5,0.5),
	AnchorPoint = Vector2.new(0.5,0.5),
	Parent = screenGui,
})
addCorner(window,16)
addStroke(window)

----------------------------------------------------------------
-- HEADER
----------------------------------------------------------------
local header = make("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1,0,0,50),
	Active = true,
	Parent = window,
})

make("TextLabel", {
	BackgroundTransparency = 1,
	Text = "EBTware - HyperShot",
	TextColor3 = CONFIG.Accent,
	TextSize = 22,
	Font = Enum.Font.GothamBold,
	Position = UDim2.new(0,20,0,0),
	Size = UDim2.new(1,-20,1,0),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = header,
})

----------------------------------------------------------------
-- BODY
----------------------------------------------------------------
local body = make("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0,0,0,50),
	Size = UDim2.new(1,0,1,-50),
	Parent = window,
})

----------------------------------------------------------------
-- SIDEBAR
----------------------------------------------------------------
local SIDEBAR_WIDTH = 120

local sidebar = make("Frame", {
	BackgroundColor3 = CONFIG.BgSidebar,
	Position = UDim2.new(0,12,0,10),
	Size = UDim2.new(0,SIDEBAR_WIDTH,1,-20),
	Parent = body,
})
addCorner(sidebar,14)
addStroke(sidebar)

make("UIListLayout", {
	Padding = UDim.new(0,6),
	Parent = sidebar,
})

make("UIPadding", {
	PaddingTop = UDim.new(0,10),
	PaddingLeft = UDim.new(0,10),
	PaddingRight = UDim.new(0,10),
	PaddingBottom = UDim.new(0,10),
	Parent = sidebar,
})

----------------------------------------------------------------
-- PAGE CONTAINER
----------------------------------------------------------------
local pages = make("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, SIDEBAR_WIDTH + 24, 0, 10),
	Size = UDim2.new(1, -(SIDEBAR_WIDTH + 36), 1, -20),
	Parent = body,
})

----------------------------------------------------------------
-- TAB SYSTEM
----------------------------------------------------------------
local currentTab = nil
local tabButtons = {}

local function createPage(name: string)
	local page = make("Frame", {
		Name = name,
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,1,0),
		Visible = false,
		Parent = pages,
	})
	return page
end

local function switchTab(name: string)
	for _, page in pairs(pages:GetChildren()) do
		if page:IsA("Frame") then
			page.Visible = (page.Name == name)
		end
	end

	for nameBtn, btn in pairs(tabButtons) do
		btn.BackgroundColor3 = (nameBtn == name)
			and CONFIG.BgCard
			or CONFIG.BgSidebar
	end

	currentTab = name
end

local function createTab(name: string)
	local btn = make("TextButton", {
		Text = name,
		AutoButtonColor = false,
		TextColor3 = CONFIG.Text,
		BackgroundColor3 = CONFIG.BgSidebar,
		Size = UDim2.new(1,0,0,40),
		Font = Enum.Font.GothamSemibold,
		TextSize = 14,
		Parent = sidebar,
	})
	addCorner(btn,10)

	btn.MouseButton1Click:Connect(function()
		switchTab(name)
	end)

	tabButtons[name] = btn
	return createPage(name)
end

----------------------------------------------------------------
-- CREATE TABS
----------------------------------------------------------------
local pageMain = createTab("Main")
local pageVisuals = createTab("Visuals")
local pageWorld = createTab("World")
local pageMisc = createTab("Misc")
local pageSettings = createTab("Settings")

----------------------------------------------------------------
-- VISUALS GRID LAYOUT (2 COLUMN)
----------------------------------------------------------------

local visualsPadding = Instance.new("UIPadding")
visualsPadding.PaddingTop = UDim.new(0, 6)
visualsPadding.PaddingLeft = UDim.new(0, 6)
visualsPadding.PaddingRight = UDim.new(0, 6)
visualsPadding.PaddingBottom = UDim.new(0, 6)
visualsPadding.Parent = pageVisuals

local visualsGrid = Instance.new("UIGridLayout")
visualsGrid.CellSize = UDim2.new(0.5, -8, 0, 70)
visualsGrid.CellPadding = UDim2.new(0, 8, 0, 8)
visualsGrid.HorizontalAlignment = Enum.HorizontalAlignment.Left
visualsGrid.VerticalAlignment = Enum.VerticalAlignment.Top
visualsGrid.SortOrder = Enum.SortOrder.LayoutOrder
visualsGrid.Parent = pageVisuals

----------------------------------------------------------------
-- AUTO LOAD ESP WHEN ANY VISUAL TOGGLE ENABLES
----------------------------------------------------------------

local function ensureESP()
	ensureFeatureLoaded("vis_esp", ESP_URL)
end

Toggles.Subscribe("vis_glow", function(state)
	if state then ensureESP() end
end)

Toggles.Subscribe("vis_boxes", function(state)
	if state then ensureESP() end
end)

Toggles.Subscribe("vis_health", function(state)
	if state then ensureESP() end
end)

Toggles.Subscribe("vis_name", function(state)
	if state then ensureESP() end
end)

Toggles.Subscribe("vis_snap", function(state)
	if state then ensureESP() end
end)

----------------------------------------------------------------
-- VISUALS TAB
----------------------------------------------------------------

-- Glow / Highlight
Toggles.AddToggleCard(
	pageVisuals,
	"vis_glow",
	"Glow / Highlight",
	"Forces AlwaysOnTop highlight. Converts green glow to blue.",
	1,
	false,
	{
		Bg2 = CONFIG.BgCard,
		Bg3 = CONFIG.BgSidebar,
		Accent = CONFIG.Accent,
		Text = CONFIG.Text,
		SubText = CONFIG.SubText,
		Stroke = CONFIG.Stroke,
	},
	{
		TweenService = TweenService,
		UserInputService = UserInputService,
	}
)

-- Boxes
Toggles.AddToggleCard(
	pageVisuals,
	"vis_boxes",
	"Boxes",
	"Draws 2D box around players.",
	2,
	false,
	{
		Bg2 = CONFIG.BgCard,
		Bg3 = CONFIG.BgSidebar,
		Accent = CONFIG.Accent,
		Text = CONFIG.Text,
		SubText = CONFIG.SubText,
		Stroke = CONFIG.Stroke,
	},
	{
		TweenService = TweenService,
		UserInputService = UserInputService,
	}
)

-- Health Bar
Toggles.AddToggleCard(
	pageVisuals,
	"vis_health",
	"Health Bar",
	"Shows vertical health bar on left side.",
	3,
	false,
	{
		Bg2 = CONFIG.BgCard,
		Bg3 = CONFIG.BgSidebar,
		Accent = CONFIG.Accent,
		Text = CONFIG.Text,
		SubText = CONFIG.SubText,
		Stroke = CONFIG.Stroke,
	},
	{
		TweenService = TweenService,
		UserInputService = UserInputService,
	}
)

-- Name
Toggles.AddToggleCard(
	pageVisuals,
	"vis_name",
	"Name",
	"Displays player name above box.",
	4,
	false,
	{
		Bg2 = CONFIG.BgCard,
		Bg3 = CONFIG.BgSidebar,
		Accent = CONFIG.Accent,
		Text = CONFIG.Text,
		SubText = CONFIG.SubText,
		Stroke = CONFIG.Stroke,
	},
	{
		TweenService = TweenService,
		UserInputService = UserInputService,
	}
)

-- Snapline
Toggles.AddToggleCard(
	pageVisuals,
	"vis_snap",
	"Snapline",
	"Draws 3D snapline from you to player.",
	5,
	false,
	{
		Bg2 = CONFIG.BgCard,
		Bg3 = CONFIG.BgSidebar,
		Accent = CONFIG.Accent,
		Text = CONFIG.Text,
		SubText = CONFIG.SubText,
		Stroke = CONFIG.Stroke,
	},
	{
		TweenService = TweenService,
		UserInputService = UserInputService,
	}
)

----------------------------------------------------------------
-- DEFAULT TAB + DRAG
----------------------------------------------------------------

switchTab("Main")
DragController.Attach(header, window, UserInputService)
