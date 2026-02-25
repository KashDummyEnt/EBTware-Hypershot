--!strict
-- ESP.lua
-- Clean standalone-style 2D Box ESP (Single Toggle, Player-Tracked)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

------------------------------------------------------------------
-- WAIT FOR TOGGLE API (AdminESP-style safe wait, no logic copied)
------------------------------------------------------------------

local function getGlobal(): any
	local gg = (typeof(getgenv) == "function") and getgenv() or nil
	if gg then return gg end
	return _G
end

local G = getGlobal()

local function waitForTogglesApi(timeout: number)
	local start = os.clock()
	while os.clock() - start < timeout do
		local api = G.__HIGGI_TOGGLES_API
		if type(api) == "table" and type(api.Subscribe) == "function" then
			return api
		end
		task.wait(0.05)
	end
	return nil
end

local Toggles = waitForTogglesApi(6)
if not Toggles then
	warn("[ESP] Toggle API missing")
	return {}
end

print("=== 2D BOX ESP LOADED ===")

------------------------------------------------------------------
-- CONFIG
------------------------------------------------------------------

local BLUE = Color3.fromRGB(0,120,255)
local HEALTH_GREEN = Color3.fromRGB(0,255,0)

local BOX_THICKNESS = 2
local HEALTH_WIDTH = 2

local MIN_BOX_HEIGHT = 6
local MIN_BOX_WIDTH = 3

------------------------------------------------------------------
-- STATE
------------------------------------------------------------------

local ESP_ENABLED = false
local renderConn: RBXScriptConnection? = nil

------------------------------------------------------------------
-- STORAGE
------------------------------------------------------------------

type ESPData = {
	box: Frame,
	stroke: UIStroke,
	healthBg: Frame,
	healthFill: Frame,
	name: TextLabel,
}

local espByPlayer: {[Player]: ESPData} = {}

------------------------------------------------------------------
-- GUI ROOT (created once)
------------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Higgi2DESP"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

------------------------------------------------------------------
-- UTIL
------------------------------------------------------------------

local function isValidCharacter(plr: Player)
	local char = plr.Character
	if not char then return false end

	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	local head = char:FindFirstChild("Head")

	if not hum or not root or not head then
		return false
	end

	if hum.Health <= 0 then
		return false
	end

	return true
end

------------------------------------------------------------------
-- CREATE / DESTROY
------------------------------------------------------------------

local function createESP(plr: Player): ESPData
	local box = Instance.new("Frame")
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Visible = false
	box.Parent = screenGui

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = BOX_THICKNESS
	stroke.Color = BLUE
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
	name.TextColor3 = BLUE
	name.Parent = box

	local data: ESPData = {
		box = box,
		stroke = stroke,
		healthBg = healthBg,
		healthFill = healthFill,
		name = name,
	}

	espByPlayer[plr] = data
	return data
end

local function destroyESP(plr: Player)
	local data = espByPlayer[plr]
	if data then
		data.box:Destroy()
		espByPlayer[plr] = nil
	end
end

local function clearAll()
	for plr, _ in pairs(espByPlayer) do
		destroyESP(plr)
	end
end

------------------------------------------------------------------
-- RENDER LOOP (PLAYER TRACKED ONLY)
------------------------------------------------------------------

local function startRender()
	if renderConn then return end

	renderConn = RunService.RenderStepped:Connect(function()

		if not ESP_ENABLED then
			return
		end

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr == LocalPlayer then
				continue
			end

			if not isValidCharacter(plr) then
				destroyESP(plr)
				continue
			end

			local char = plr.Character :: Model
			local hum = char:FindFirstChildOfClass("Humanoid") :: Humanoid
			local root = char:FindFirstChild("HumanoidRootPart") :: BasePart
			local head = char:FindFirstChild("Head") :: BasePart

			local top3D = head.Position + Vector3.new(0,0.5,0)
			local bottom3D = root.Position - Vector3.new(0,hum.HipHeight + (root.Size.Y/2),0)

			local top2D, topOnScreen = Camera:WorldToViewportPoint(top3D)
			local bottom2D, bottomOnScreen = Camera:WorldToViewportPoint(bottom3D)

			if not topOnScreen or not bottomOnScreen then
				if espByPlayer[plr] then
					espByPlayer[plr].box.Visible = false
				end
				continue
			end

			local rawHeight = math.abs(bottom2D.Y - top2D.Y)
			local height = math.max(rawHeight, MIN_BOX_HEIGHT)
			local width = math.max(rawHeight * 0.5, MIN_BOX_WIDTH)

			local esp = espByPlayer[plr] or createESP(plr)
			local box = esp.box

			box.Visible = true
			box.Size = UDim2.fromOffset(width, height)
			box.Position = UDim2.fromOffset(top2D.X - width/2, top2D.Y)

			local displayName = plr.DisplayName
			esp.name.Text = displayName
			esp.name.Size = UDim2.new(1,0,0,14)
			esp.name.Position = UDim2.new(0,0,0,-16)

			local hpPercent = math.clamp(hum.Health / hum.MaxHealth,0,1)

			esp.healthBg.Size = UDim2.new(0, HEALTH_WIDTH, 1, 0)
			esp.healthBg.Position = UDim2.new(0, -HEALTH_WIDTH-2, 0, 0)

			esp.healthFill.Size = UDim2.new(1,0, hpPercent,0)
			esp.healthFill.Position = UDim2.new(0,0, 1-hpPercent,0)
		end
	end)
end

local function stopRender()
	if renderConn then
		renderConn:Disconnect()
		renderConn = nil
	end
end

------------------------------------------------------------
-- SINGLE TOGGLE (LAZY LOAD SAFE)
------------------------------------------------------------

local function applyState(state: boolean)
	ESP_ENABLED = state
	screenGui.Enabled = state

	if state then
		startRender()
	else
		stopRender()
		clearAll()
	end
end

Toggles.Subscribe("vis_esp", applyState)

-- IMPORTANT: defer initial state check
task.defer(function()
	local initial = Toggles.GetState("vis_esp", false)
	if initial then
		applyState(true)
	end
end)
