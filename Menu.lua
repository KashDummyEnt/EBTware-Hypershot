--!strict
-- CleanMenu.lua
-- Sidebar Layout (Fully Fixed + Toggle Module Compatible)

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

	-- REQUIRED NAMES FOR TOGGLE MODULE
	Bg  = Color3.fromRGB(18,18,22),   -- main window
	Bg2 = Color3.fromRGB(22,22,28),   -- sidebar / secondary
	Bg3 = Color3.fromRGB(28,28,35),   -- card background

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
	local code = game:HttpGet(url)
	return loadstring(code)()
end

----------------------------------------------------------------
-- LOAD CORE MODULES
----------------------------------------------------------------

local Toggles = loadModule(TOGGLES_URL)
local DragController = loadModule(DRAG_URL)

local G = (typeof(getgenv) == "function" and getgenv()) or _G
G.__HIGGI_TOGGLES_API = Toggles

----------------------------------------------------------------
-- SERVICES TABLE (REQUIRED)
----------------------------------------------------------------

local SERVICES = {
	TweenService = TweenService,
	UserInputService = UserInputService,
	Overlay = nil,
	SubscribeAccent = function() end,
}

----------------------------------------------------------------
-- LAZY FEATURE LOADER
----------------------------------------------------------------

local featureLoaded: {[string]: boolean} = {}

local function ensureFeatureLoaded(key: string, url: string)
	if featureLoaded[key] then return end
	featureLoaded[key] = true
	loadModule(url)
end

----------------------------------------------------------------
-- UI HELPERS
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
if existing then existing:Destroy() end

----------------------------------------------------------------
-- SCREEN GUI
----------------------------------------------------------------

local screenGui = make("ScreenGui", {
	Name = CONFIG.GuiName,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	Parent = playerGui,
})

SERVICES.Overlay = screenGui

----------------------------------------------------------------
-- FLOATING TOGGLE BUTTON
----------------------------------------------------------------

local toggleBtn = make("ImageButton", {
	Name = "MenuToggleButton",
	Size = UDim2.fromOffset(44, 44),
	Position = UDim2.fromOffset(16, 80),
	BackgroundColor3 = CONFIG.Bg2,
	ZIndex = 10,
	Parent = screenGui,
})
addCorner(toggleBtn, 22)
addStroke(toggleBtn)

----------------------------------------------------------------
-- INPUT BLOCKER
----------------------------------------------------------------

local inputBlocker = make("TextButton", {
	Size = UDim2.fromScale(1,1),
	BackgroundTransparency = 1,
	Text = "",
	AutoButtonColor = false,
	Visible = false,
	ZIndex = 1,
	Parent = screenGui,
})

----------------------------------------------------------------
-- MAIN WINDOW
----------------------------------------------------------------

local popupGroup = make("Frame", {
	Size = UDim2.fromOffset(CONFIG.Width, CONFIG.Height),
	Position = UDim2.fromScale(0.5,0.5),
	AnchorPoint = Vector2.new(0.5,0.5),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = screenGui,
})
popupGroup.ZIndex = 5

local window = make("Frame", {
	BackgroundColor3 = CONFIG.Bg,
	Size = UDim2.fromScale(1,1),
	Parent = popupGroup,
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

local close = make("TextButton", {
	Text = "X",
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	Size = UDim2.fromOffset(32,28),
	Position = UDim2.new(1,-42,0,8),
	BackgroundColor3 = CONFIG.Bg3,
	TextColor3 = CONFIG.Text,
	Parent = header,
})
addCorner(close,8)
addStroke(close)

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
	BackgroundColor3 = CONFIG.Bg2,
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

local page = make("ScrollingFrame", {
	Name = name,
	BackgroundTransparency = 1,
	Size = UDim2.new(1,0,1,0),
	CanvasSize = UDim2.new(0,0,0,0),
	ScrollBarThickness = 4,
	ClipsDescendants = false,
	Visible = false,
	Parent = pages,
})

	make("UIPadding", {
		PaddingTop = UDim.new(0,8),
		PaddingBottom = UDim.new(0,8),
		Parent = page,
	})

	local COLUMN_WIDTH = (page.AbsoluteSize.X / 2) - 12

	local leftColumn = make("Frame", {
		Name = "Left",
		BackgroundTransparency = 1,
		Size = UDim2.new(0.5,-6,1,0),
		Position = UDim2.new(0,0,0,0),
		Parent = page,
	})

	local rightColumn = make("Frame", {
		Name = "Right",
		BackgroundTransparency = 1,
		Size = UDim2.new(0.5,-6,1,0),
		Position = UDim2.new(0.5,6,0,0),
		Parent = page,
	})

	make("UIListLayout", {
		Padding = UDim.new(0,8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = leftColumn,
	})

	make("UIListLayout", {
		Padding = UDim.new(0,8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = rightColumn,
	})

	local function updateCanvas()
		local leftHeight = leftColumn.UIListLayout.AbsoluteContentSize.Y
		local rightHeight = rightColumn.UIListLayout.AbsoluteContentSize.Y
		local height = math.max(leftHeight, rightHeight)
		page.CanvasSize = UDim2.new(0,0,0,height + 16)
	end

	leftColumn.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
	rightColumn.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

	return {
		Page = page,
		Left = leftColumn,
		Right = rightColumn
	}
end

local function switchTab(name: string)
	for _,page in pairs(pages:GetChildren()) do
		if page:IsA("ScrollingFrame") then
			page.Visible = (page.Name == name)
		end
	end

	for tab,btn in pairs(tabButtons) do
		btn.BackgroundColor3 = (tab == name)
			and CONFIG.Bg3
			or CONFIG.Bg2
	end

	currentTab = name
end

local function createTab(name: string)
	local btn = make("TextButton", {
		Text = name,
		AutoButtonColor = false,
		TextColor3 = CONFIG.Text,
		BackgroundColor3 = CONFIG.Bg2,
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
	local pageData = createPage(name)
return pageData
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
-- ESP AUTO LOAD
----------------------------------------------------------------

local function ensureESP()
	ensureFeatureLoaded("vis_esp", ESP_URL)
end

Toggles.Subscribe("vis_glow", function(state) if state then ensureESP() end end)
Toggles.Subscribe("vis_boxes", function(state) if state then ensureESP() end end)
Toggles.Subscribe("vis_health", function(state) if state then ensureESP() end end)
Toggles.Subscribe("vis_name", function(state) if state then ensureESP() end end)
Toggles.Subscribe("vis_snap", function(state) if state then ensureESP() end end)

----------------------------------------------------------------
-- VISUALS TOGGLES
----------------------------------------------------------------

----------------------------------------------------------------
-- VISUALS TOGGLES (2 COLUMN LAYOUT)
----------------------------------------------------------------

-- LEFT COLUMN
Toggles.AddToggleCard(
	pageVisuals.Left,
	"vis_glow",
	"Glow / Highlight",
	"Forces AlwaysOnTop highlight.",
	1,
	false,
	CONFIG,
	SERVICES
)

-- RIGHT COLUMN
Toggles.AddToggleCard(
	pageVisuals.Right,
	"vis_boxes",
	"Boxes",
	"Draws 2D box around players.",
	2,
	false,
	CONFIG,
	SERVICES
)

-- LEFT COLUMN
Toggles.AddToggleCard(
	pageVisuals.Left,
	"vis_health",
	"Health Bar",
	"Shows vertical health bar.",
	3,
	false,
	CONFIG,
	SERVICES
)

-- RIGHT COLUMN
Toggles.AddToggleCard(
	pageVisuals.Right,
	"vis_name",
	"Name",
	"Displays player name.",
	4,
	false,
	CONFIG,
	SERVICES
)

-- LEFT COLUMN
Toggles.AddToggleCard(
	pageVisuals.Left,
	"vis_snap",
	"Snapline",
	"Draws snapline to players.",
	5,
	false,
	CONFIG,
	SERVICES
)

----------------------------------------------------------------
-- DEFAULT TAB + DRAG
----------------------------------------------------------------

switchTab("Main")
DragController.Attach(header, popupGroup, UserInputService)

----------------------------------------------------------------
-- OPEN / CLOSE
----------------------------------------------------------------

local function setMenuState(state: boolean)
	popupGroup.Visible = state
	inputBlocker.Visible = state

	if state then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	end
end

toggleBtn.MouseButton1Click:Connect(function()
	setMenuState(not popupGroup.Visible)
end)

close.MouseButton1Click:Connect(function()
	setMenuState(false)
end)
