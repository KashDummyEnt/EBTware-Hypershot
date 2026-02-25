--!strict
-- CleanMenu.lua
-- Full build with 2-column toggle layout per tab

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
-- LOAD TOGGLE MODULE
----------------------------------------------------------------
local TOGGLES_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/Menu/ToggleSwitches.lua"
local DRAG_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/Menu/DragController.lua"
local ESP_URL = "https://raw.githubusercontent.com/KashDummyEnt/EBTware-Hypershot/refs/heads/main/Features/ESP.lua"


local function loadModule(url: string)
	local ok, code = pcall(function()
		return game:HttpGet(url)
	end)
	if not ok then error(code) end

	local fn = loadstring(code)
	if not fn then error("compile fail") end

	local result = fn()
	if type(result) ~= "table" then
		error("Toggle module invalid")
	end

	return result
end

local Toggles = loadModule(TOGGLES_URL)
local DragController = loadModule(DRAG_URL)
local ESP = loadModule(ESP_URL)

local G = (typeof(getgenv) == "function") and getgenv() or _G
G.__HIGGI_TOGGLES_API = Toggles

----------------------------------------------------------------
-- ADAPTER FOR TOGGLE CONFIG
----------------------------------------------------------------
local ToggleConfig = {
	Bg2 = CONFIG.BgCard,
	Bg3 = CONFIG.BgSidebar,
	Text = CONFIG.Text,
	SubText = CONFIG.SubText,
	Stroke = CONFIG.Stroke,
	Accent = CONFIG.Accent,
}

local ToggleServices = {
	TweenService = TweenService,
	UserInputService = UserInputService,
}

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
	Text = "HyperShot",
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
-- SIDEBAR (NARROWER)
----------------------------------------------------------------
local SIDEBAR_WIDTH = 120 -- was 150

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
-- 2 COLUMN TOGGLE BUILDER
----------------------------------------------------------------
local function buildToggleLayout(page: Frame)
	local container = make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,1,0),
		Parent = page,
	})

	make("UIPadding", {
		PaddingTop = UDim.new(0,10),
		PaddingLeft = UDim.new(0,10),
		PaddingRight = UDim.new(0,10),
		Parent = container,
	})

	local horizontal = make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0,12),
		Parent = container,
	})

	local left = make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0.5,-6,1,0),
		Parent = container,
	})

	local right = make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0.5,-6,1,0),
		Parent = container,
	})

	make("UIListLayout", { Padding = UDim.new(0,12), Parent = left })
	make("UIListLayout", { Padding = UDim.new(0,12), Parent = right })

	return left, right
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
-- BUILD TOGGLE LAYOUTS
----------------------------------------------------------------
local mainL, mainR = buildToggleLayout(pageMain)
local visL, visR = buildToggleLayout(pageVisuals)
local worldL, worldR = buildToggleLayout(pageWorld)
local miscL, miscR = buildToggleLayout(pageMisc)
local setL, setR = buildToggleLayout(pageSettings)

----------------------------------------------------------------
-- ADD 2 ROWS PER TAB
----------------------------------------------------------------
Toggles.AddToggleCard(
	visL,
	"vis_esp",
	"2D Box ESP",
	"Draws boxes, health, and names.",
	1,
	false,
	ToggleConfig,
	ToggleServices
)

Toggles.AddToggleCard(
	visL,
	"vis_snaplines",
	"Snaplines",
	"Draws bottom snaplines.",
	2,
	false,
	ToggleConfig,
	ToggleServices
)

add4(mainL, mainR, "main_")
add4(visL, visR, "vis_")
add4(worldL, worldR, "world_")
add4(miscL, miscR, "misc_")
add4(setL, setR, "set_")

switchTab("Main")

DragController.Attach(header, window, UserInputService)
