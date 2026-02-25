--!strict
-- ESP.lua (Fully Modular Toggle-Wired)
-- Master Toggle: vis_esp
-- Sub Toggles:
-- vis_glow
-- vis_boxes
-- vis_health
-- vis_name
-- vis_snap

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

local G = (typeof(getgenv) == "function") and getgenv() or _G
local Toggles = G.__HIGGI_TOGGLES_API

if not Toggles then
	warn("Toggle API missing")
	return
end

print("=== 2D BOX ESP LOADED (MODULAR) ===")

------------------------------------------------------------------
-- CONFIG
------------------------------------------------------------------

local BLUE = Color3.fromRGB(0,120,255)
local HEALTH_GREEN = Color3.fromRGB(0,255,0)

local SNAP_THICKNESS = 0.05
local SNAP_TRANSPARENCY = 0.15

local BOX_THICKNESS = 2
local HEALTH_WIDTH = 2

local MIN_BOX_HEIGHT = 6
local MIN_BOX_WIDTH = 3

------------------------------------------------------------------
-- STATE
------------------------------------------------------------------

local enabled = false
local renderConnection: RBXScriptConnection? = nil

local glowEnabled = true
local boxEnabled = true
local healthEnabled = true
local nameEnabled = true
local snapEnabled = true

type ESPData = {
	box: Frame,
	stroke: UIStroke,
	healthBg: Frame,
	healthFill: Frame,
	name: TextLabel,
}

type SnapData = {
	part: BasePart,
	ad: BoxHandleAdornment,
}

local espByModel: {[Model]: ESPData} = {}
local snapByModel: {[Model]: SnapData} = {}

local screenGui: ScreenGui? = nil

------------------------------------------------------------------
-- UTIL
------------------------------------------------------------------

local function isCharacterModel(model: Instance): boolean
	if not model:IsA("Model") then return false end
	return model:FindFirstChildOfClass("Humanoid") ~= nil
end

local function shouldSkip(model: Model, localChar: Model?): boolean
	if model == localChar then return true end
	if model.Name == "BotRig" then return true end
	return false
end

local function isGreen(c: Color3): boolean
	return c.G > 0.6 and c.R < 0.4 and c.B < 0.4
end

local function getHighlightColor(model: Model): Color3
	local highlight = model:FindFirstChildOfClass("Highlight")
	if not highlight then return BLUE end

	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

	if isGreen(highlight.FillColor) or isGreen(highlight.OutlineColor) then
		highlight.FillColor = BLUE
		highlight.OutlineColor = BLUE
	end

	return highlight.FillColor
end

------------------------------------------------------------------
-- GUI ROOT
------------------------------------------------------------------

local function createRoot()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "Higgi2DESP"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

------------------------------------------------------------------
-- CREATE ESP
------------------------------------------------------------------

local function createESP(model: Model): ESPData
	assert(screenGui)

	local box = Instance.new("Frame")
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Visible = false
	box.Parent = screenGui

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = BOX_THICKNESS
	stroke.Parent = box

	local healthBg = Instance.new("Frame")
	healthBg.BackgroundColor3 = Color3.fromRGB(35,35,35)
	healthBg.BorderSizePixel = 0
	healthBg.Parent = box

	local healthFill = Instance.new("Frame")
	healthFill.BorderSizePixel = 0
	healthFill.BackgroundColor3 = HEALTH_GREEN
	healthFill.Parent = healthBg

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.TextScaled = true
	name.Font = Enum.Font.GothamSemibold
	name.TextStrokeTransparency = 0.5
	name.Parent = box

	local data: ESPData = {
		box = box,
		stroke = stroke,
		healthBg = healthBg,
		healthFill = healthFill,
		name = name,
	}

	espByModel[model] = data
	return data
end

local function getESP(model: Model): ESPData
	return espByModel[model] or createESP(model)
end

------------------------------------------------------------------
-- SNAP
------------------------------------------------------------------

local function createSnap(model: Model): SnapData
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Transparency = 1
	p.Size = Vector3.new(0.2,0.2,0.2)
	p.Parent = workspace

	local ad = Instance.new("BoxHandleAdornment")
	ad.Adornee = p
	ad.AlwaysOnTop = true
	ad.ZIndex = 10
	ad.Transparency = SNAP_TRANSPARENCY
	ad.Parent = p

	local data: SnapData = {
		part = p,
		ad = ad,
	}

	snapByModel[model] = data
	return data
end

local function getSnap(model: Model): SnapData
	return snapByModel[model] or createSnap(model)
end

------------------------------------------------------------------
-- CLEANUP
------------------------------------------------------------------

local function destroyESP(model: Model)
	local esp = espByModel[model]
	if esp then
		esp.box:Destroy()
		espByModel[model] = nil
	end

	local snap = snapByModel[model]
	if snap then
		snap.part:Destroy()
		snapByModel[model] = nil
	end
end

local function fullCleanup()
	for model,_ in pairs(espByModel) do
		destroyESP(model)
	end

	if screenGui then
		screenGui:Destroy()
		screenGui = nil
	end
end

------------------------------------------------------------------
-- RENDER LOOP
------------------------------------------------------------------

local function startESP()

	if enabled then return end
	enabled = true

	createRoot()

	renderConnection = RunService.RenderStepped:Connect(function()

		if not enabled then return end

		local localChar = LocalPlayer.Character
		if not localChar then return end

		local localRoot = localChar:FindFirstChild("HumanoidRootPart") :: BasePart?
		local localHum = localChar:FindFirstChildOfClass("Humanoid")
		if not localRoot or not localHum then return end

		local origin = localRoot.Position - Vector3.new(0, localHum.HipHeight + (localRoot.Size.Y / 2), 0)

		for model,_ in pairs(espByModel) do
			if not model:IsDescendantOf(workspace) then
				destroyESP(model)
			end
		end

		for _, model in ipairs(workspace:GetDescendants()) do
			if not model:IsA("Model") then continue end
			if not isCharacterModel(model) then continue end
			if shouldSkip(model, localChar) then continue end

			local hum = model:FindFirstChildOfClass("Humanoid")
			local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
			local head = model:FindFirstChild("Head") :: BasePart?

			if not hum or not root or not head or hum.Health <= 0 then
				destroyESP(model)
				continue
			end

			local color = BLUE

			if glowEnabled then
				color = getHighlightColor(model)
			end

			local top3D = head.Position + Vector3.new(0,0.5,0)
			local bottom3D = root.Position - Vector3.new(0,hum.HipHeight + (root.Size.Y/2),0)

			local top2D, topOnScreen = Camera:WorldToViewportPoint(top3D)
			local bottom2D, bottomOnScreen = Camera:WorldToViewportPoint(bottom3D)

			if not topOnScreen or not bottomOnScreen then
				if espByModel[model] then
					espByModel[model].box.Visible = false
				end
				continue
			end

			local rawHeight = math.abs(bottom2D.Y - top2D.Y)
			local height = math.max(rawHeight, MIN_BOX_HEIGHT)
			local rawWidth = rawHeight * 0.5
			local width = math.max(rawWidth, MIN_BOX_WIDTH)

			local esp = getESP(model)
			local box = esp.box

			box.Visible = boxEnabled
			box.Size = UDim2.fromOffset(width, height)
			box.Position = UDim2.fromOffset(top2D.X - width/2, top2D.Y)

			esp.stroke.Enabled = boxEnabled
			esp.stroke.Color = color

			local plr = Players:GetPlayerFromCharacter(model)
			local displayName = plr and plr.DisplayName or model.Name

			esp.name.Visible = nameEnabled
			esp.name.Text = displayName
			esp.name.TextColor3 = color
			esp.name.Size = UDim2.new(1,0,0,14)
			esp.name.Position = UDim2.new(0,0,0,-16)

			local hpPercent = math.clamp(hum.Health / hum.MaxHealth,0,1)

			esp.healthBg.Visible = healthEnabled
			esp.healthFill.Visible = healthEnabled

			esp.healthBg.Size = UDim2.new(0, HEALTH_WIDTH, 1, 0)
			esp.healthBg.Position = UDim2.new(0, -HEALTH_WIDTH-2, 0, 0)

			esp.healthFill.Size = UDim2.new(1,0, hpPercent,0)
			esp.healthFill.Position = UDim2.new(0,0, 1-hpPercent,0)
			esp.healthFill.BackgroundColor3 = HEALTH_GREEN

			if snapEnabled then
				local dir = bottom3D - origin
				local len = dir.Magnitude

				if len > 0.1 then
					local mid = origin + dir*0.5
					local snap = getSnap(model)

					snap.part.CFrame = CFrame.lookAt(mid, bottom3D)
					snap.ad.Size = Vector3.new(SNAP_THICKNESS,SNAP_THICKNESS,len)
					snap.ad.Color3 = color
				end
			else
				if snapByModel[model] then
					snapByModel[model].part:Destroy()
					snapByModel[model] = nil
				end
			end
		end
	end)
end

local function stopESP()
	if not enabled then return end
	enabled = false

	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	fullCleanup()
end

------------------------------------------------------------------
-- TOGGLE BINDINGS
------------------------------------------------------------------

Toggles.Subscribe("vis_esp", function(state)
	if state then startESP() else stopESP() end
end)

Toggles.Subscribe("vis_glow", function(state)
	glowEnabled = state
end)

Toggles.Subscribe("vis_boxes", function(state)
	boxEnabled = state
end)

Toggles.Subscribe("vis_health", function(state)
	healthEnabled = state
end)

Toggles.Subscribe("vis_name", function(state)
	nameEnabled = state
end)

Toggles.Subscribe("vis_snap", function(state)
	snapEnabled = state
end)

if Toggles.GetState("vis_esp", false) then
	startESP()
end

print("=== 2D BOX ESP READY MAYBE TEST (MODULAR) ===")
