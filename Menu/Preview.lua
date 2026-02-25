--!strict
-- Preview.lua
-- 2D Overlay Preview (Matches ESP.lua EXACTLY)

local Preview = {}

function Preview.Init(deps)

	local Players = deps.Players
	local RunService = deps.RunService
	local UserInputService = deps.UserInputService
	local Toggles = deps.Toggles
	local viewport = deps.Viewport
	local world = deps.WorldModel
	local cam = deps.Camera
	local previewPanel = deps.PreviewPanel

	local player = Players.LocalPlayer

	------------------------------------------------------------
	-- CONFIG (MATCHES ESP.lua)
	------------------------------------------------------------

	local BOX_THICKNESS = 2
	local HEALTH_WIDTH = 2

	local MIN_BOX_HEIGHT = 6
	local MIN_BOX_WIDTH = 3

	local HEALTH_GREEN = Color3.fromRGB(0,255,0)

	------------------------------------------------------------
	-- STATE
	------------------------------------------------------------

	local preview: Model? = nil

	------------------------------------------------------------
	-- OVERLAY ROOT (2D)
	------------------------------------------------------------

	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1,1)
	overlay.BackgroundTransparency = 1
	overlay.ClipsDescendants = true
	overlay.Parent = previewPanel

	------------------------------------------------------------
	-- 2D BOX
	------------------------------------------------------------

	local box = Instance.new("Frame")
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Visible = false
	box.Parent = overlay

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = BOX_THICKNESS
	stroke.Parent = box

	------------------------------------------------------------
	-- NAME
	------------------------------------------------------------

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamSemibold
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.TextWrapped = false
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.TextYAlignment = Enum.TextYAlignment.Center
	nameLabel.AnchorPoint = Vector2.new(0.5,1)
	nameLabel.Visible = false
	nameLabel.Parent = overlay

	------------------------------------------------------------
	-- HEALTH (VERTICAL LEFT LIKE ESP)
	------------------------------------------------------------

	local healthBg = Instance.new("Frame")
	healthBg.BackgroundColor3 = Color3.fromRGB(35,35,35)
	healthBg.BorderSizePixel = 0
	healthBg.Visible = false
	healthBg.Parent = box

	local healthFill = Instance.new("Frame")
	healthFill.BorderSizePixel = 0
	healthFill.BackgroundColor3 = HEALTH_GREEN
	healthFill.Parent = healthBg

	------------------------------------------------------------
	-- BUILD AVATAR
	------------------------------------------------------------

	local function buildAvatar()

		world:ClearAllChildren()
		preview = nil

		local desc = Players:GetHumanoidDescriptionFromUserId(player.UserId)
		local rig = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)

		rig.Parent = world
		RunService.Heartbeat:Wait()

		for _, v in ipairs(rig:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = false
				v.Massless = true
			elseif v:IsA("Script") or v:IsA("LocalScript") then
				v:Destroy()
			end
		end

		rig.PrimaryPart = rig:FindFirstChild("HumanoidRootPart")
		preview = rig

		nameLabel.Text = player.DisplayName
	end

	------------------------------------------------------------
	-- REFRESH VISIBILITY
	------------------------------------------------------------

	local function refreshPreviewESP()
		box.Visible = Toggles.GetState("vis_boxes") == true
		stroke.Enabled = box.Visible

		local healthEnabled = Toggles.GetState("vis_health") == true
		healthBg.Visible = healthEnabled
		healthFill.Visible = healthEnabled

		nameLabel.Visible = Toggles.GetState("vis_name") == true
	end

	Toggles.Subscribe("vis_boxes", refreshPreviewESP)
	Toggles.Subscribe("vis_health", refreshPreviewESP)
	Toggles.Subscribe("vis_name", refreshPreviewESP)

	buildAvatar()
	refreshPreviewESP()

	------------------------------------------------------------
	-- DRAG ROTATION (UNCHANGED)
	------------------------------------------------------------

	local draggingPreview = false
	local lastX = 0
	local rotationY = 0
	local velocity = 0

	local dragSensitivity = 0.4
	local inertiaDamping = 0.92

	viewport.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			draggingPreview = true
			lastX = input.Position.X
		end
	end)

	viewport.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			draggingPreview = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not draggingPreview then return end

		if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then

			local delta = input.Position.X - lastX
			lastX = input.Position.X

			local applied = delta * dragSensitivity

			rotationY += applied
			velocity = applied
		end
	end)

	------------------------------------------------------------
	-- RENDER LOOP (2D BOX CALC LIKE ESP.lua)
	------------------------------------------------------------

	RunService.RenderStepped:Connect(function(dt)

		if not preview or not preview.PrimaryPart then return end

		preview:SetPrimaryPartCFrame(
			CFrame.new(0,0,0) *
			CFrame.Angles(0, math.rad(180 + rotationY), 0)
		)

		local cf, size = preview:GetBoundingBox()
		local center = cf.Position

		local maxDim = math.max(size.X, size.Y, size.Z)
		local fov = math.rad(cam.FieldOfView)
		local distance = (maxDim / (2 * math.tan(fov / 2))) * 1.25

		cam.CFrame = CFrame.new(center + Vector3.new(0,0,distance), center)

		-- PROJECT TOP/BOTTOM LIKE REAL ESP

		local top3D = center + Vector3.new(0, size.Y/2, 0)
		local bottom3D = center - Vector3.new(0, size.Y/2, 0)

		local top2D, topVisible = cam:WorldToViewportPoint(top3D)
		local bottom2D, bottomVisible = cam:WorldToViewportPoint(bottom3D)

		if not topVisible or not bottomVisible then
			box.Visible = false
			nameLabel.Visible = false
			healthBg.Visible = false
			return
		end

		local rawHeight = math.abs(bottom2D.Y - top2D.Y)
		local height = math.max(rawHeight, MIN_BOX_HEIGHT)
		local width = math.max(rawHeight * 0.5, MIN_BOX_WIDTH)

		local x = top2D.X - width/2
		local y = top2D.Y

		box.Size = UDim2.fromOffset(width, height)
		box.Position = UDim2.fromOffset(x, y)

		stroke.Color = Color3.fromRGB(0,120,255)

		nameLabel.TextSize = math.clamp(height * 0.2, 14, 22)
		nameLabel.Size = UDim2.fromOffset(200, nameLabel.TextSize + 4)
		nameLabel.Position = UDim2.fromOffset(top2D.X, top2D.Y - 4)

		-- FAKE HEALTH PERCENT (Preview Animation Feel)
		local pct = (math.sin(tick()*2)+1)/2

		healthBg.Size = UDim2.new(0, HEALTH_WIDTH, 1, 0)
		healthBg.Position = UDim2.new(0, -HEALTH_WIDTH-2, 0, 0)

		healthFill.Size = UDim2.new(1,0, pct,0)
		healthFill.Position = UDim2.new(0,0, 1-pct,0)
		healthFill.BackgroundColor3 = HEALTH_GREEN
	end)
end

return Preview
