--!strict
-- Preview.lua
-- 2D Preview ESP (Matches ESP.lua)

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
	-- CONSTANTS (MATCH ESP)
	------------------------------------------------------------

	local BOX_THICKNESS = 2
	local HEALTH_WIDTH = 2
	local MIN_BOX_HEIGHT = 6
	local MIN_BOX_WIDTH = 3
	local HEALTH_GREEN = Color3.fromRGB(0,255,0)
	local PREVIEW_COLOR = Color3.fromRGB(255,70,70)

	------------------------------------------------------------
	-- STATE
	------------------------------------------------------------

	local preview: Model? = nil

	------------------------------------------------------------
	-- NAME (same method you're already using)
	------------------------------------------------------------

	local previewNameLabel = Instance.new("TextLabel")
	previewNameLabel.Name = "PreviewName"
	previewNameLabel.BackgroundTransparency = 1
	previewNameLabel.Font = Enum.Font.GothamSemibold
	previewNameLabel.TextColor3 = PREVIEW_COLOR
	previewNameLabel.TextStrokeTransparency = 0.5
	previewNameLabel.TextScaled = false
	previewNameLabel.TextSize = 16
	previewNameLabel.Visible = false
	previewNameLabel.Parent = previewPanel

	------------------------------------------------------------
	-- 2D BOX (MATCHES REAL ESP)
	------------------------------------------------------------

	local previewBoxFrame = Instance.new("Frame")
	previewBoxFrame.BackgroundTransparency = 1
	previewBoxFrame.BorderSizePixel = 0
	previewBoxFrame.Visible = false
	previewBoxFrame.Parent = previewPanel

	local previewStroke = Instance.new("UIStroke")
	previewStroke.Thickness = BOX_THICKNESS
	previewStroke.Color = PREVIEW_COLOR
	previewStroke.Parent = previewBoxFrame

	local previewHealthBg = Instance.new("Frame")
	previewHealthBg.BackgroundColor3 = Color3.fromRGB(35,35,35)
	previewHealthBg.BorderSizePixel = 0
	previewHealthBg.Visible = false
	previewHealthBg.Parent = previewBoxFrame

	local previewHealthFill = Instance.new("Frame")
	previewHealthFill.BorderSizePixel = 0
	previewHealthFill.BackgroundColor3 = HEALTH_GREEN
	previewHealthFill.Parent = previewHealthBg

	------------------------------------------------------------
	-- CHAMS (UNCHANGED FROM YOUR ORIGINAL)
	------------------------------------------------------------

	local originalPartState: {[BasePart]: {
		Material: Enum.Material,
		Color: Color3,
		Transparency: number
	}} = {}

	local originalTextureState: {[Instance]: any} = {}
	local originalParentState: {[Instance]: Instance} = {}

	local function applyPreviewChams()
		if not preview then return end

		for _, inst in ipairs(preview:GetDescendants()) do
			if inst:IsA("Decal") or inst:IsA("Texture") then
				originalTextureState[inst] = inst.Transparency
				inst.Transparency = 1
			elseif inst:IsA("SpecialMesh") then
				originalTextureState[inst] = inst.TextureId
				inst.TextureId = ""
			elseif inst:IsA("MeshPart") then
				originalTextureState[inst] = inst.TextureID
				inst.TextureID = ""
			elseif inst:IsA("SurfaceAppearance")
				or inst:IsA("Shirt")
				or inst:IsA("Pants")
				or inst:IsA("ShirtGraphic") then
				originalParentState[inst] = inst.Parent
				inst.Parent = nil
			end
		end

		for _, inst in ipairs(preview:GetDescendants()) do
			if inst:IsA("BasePart") then
				if not originalPartState[inst] then
					originalPartState[inst] = {
						Material = inst.Material,
						Color = inst.Color,
						Transparency = inst.Transparency
					}
				end
				inst.Material = Enum.Material.Neon
				inst.Color = PREVIEW_COLOR
				inst.Transparency = 0
			end
		end
	end

	local function removePreviewChams()
		for part, data in pairs(originalPartState) do
			if part and part.Parent then
				part.Material = data.Material
				part.Color = data.Color
				part.Transparency = data.Transparency
			end
		end
		table.clear(originalPartState)

		for inst, saved in pairs(originalTextureState) do
			if inst and inst.Parent then
				if inst:IsA("Decal") or inst:IsA("Texture") then
					inst.Transparency = saved
				elseif inst:IsA("SpecialMesh") then
					inst.TextureId = saved
				elseif inst:IsA("MeshPart") then
					inst.TextureID = saved
				end
			end
		end
		table.clear(originalTextureState)

		for inst, parent in pairs(originalParentState) do
			if inst and parent then
				inst.Parent = parent
			end
		end
		table.clear(originalParentState)
	end

	------------------------------------------------------------
	-- REFRESH
	------------------------------------------------------------

	local function refreshPreviewESP()

		removePreviewChams()

		if Toggles.GetState("vis_glow") then
			applyPreviewChams()
		end

		previewNameLabel.Visible = Toggles.GetState("vis_name")
	end

	------------------------------------------------------------
	-- BUILD AVATAR
	------------------------------------------------------------

	local function buildAvatar()

		world:ClearAllChildren()
		preview = nil
		removePreviewChams()

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

		previewNameLabel.Text = player.DisplayName

		refreshPreviewESP()
	end

	------------------------------------------------------------
	-- TOGGLES
	------------------------------------------------------------

	Toggles.Subscribe("vis_boxes", refreshPreviewESP)
	Toggles.Subscribe("vis_health", refreshPreviewESP)
	Toggles.Subscribe("vis_name", refreshPreviewESP)
	Toggles.Subscribe("vis_glow", refreshPreviewESP)

	buildAvatar()

	------------------------------------------------------------
	-- RENDER LOOP (2D BOX PROJECTION)
	------------------------------------------------------------

	RunService.RenderStepped:Connect(function()

		if not preview or not preview.PrimaryPart then
			previewBoxFrame.Visible = false
			return
		end

		local hum = preview:FindFirstChildOfClass("Humanoid")
		local root = preview:FindFirstChild("HumanoidRootPart")
		local head = preview:FindFirstChild("Head")

		if not hum or not root or not head then return end

		local top3D = head.Position + Vector3.new(0,0.5,0)
		local bottom3D = root.Position - Vector3.new(0, hum.HipHeight + (root.Size.Y/2), 0)

		local top2D, topOnScreen = cam:WorldToViewportPoint(top3D)
		local bottom2D, bottomOnScreen = cam:WorldToViewportPoint(bottom3D)

		if not topOnScreen or not bottomOnScreen then
			previewBoxFrame.Visible = false
			previewHealthBg.Visible = false
			return
		end

		local rawHeight = math.abs(bottom2D.Y - top2D.Y)
		local height = math.max(rawHeight, MIN_BOX_HEIGHT)
		local width = math.max(rawHeight * 0.5, MIN_BOX_WIDTH)

		local boxEnabled = Toggles.GetState("vis_boxes")
		previewBoxFrame.Visible = boxEnabled
		previewStroke.Enabled = boxEnabled

		previewBoxFrame.Size = UDim2.fromOffset(width, height)
		previewBoxFrame.Position = UDim2.fromOffset(
			top2D.X - width/2,
			top2D.Y
		)

		-- NAME
		if Toggles.GetState("vis_name") then
			previewNameLabel.TextSize = math.clamp(height * 0.2, 14, 22)
			previewNameLabel.Size = UDim2.fromOffset(200, previewNameLabel.TextSize + 4)
			previewNameLabel.Position = UDim2.fromOffset(
				top2D.X - 100,
				top2D.Y - previewNameLabel.TextSize - 4
			)
		end

		-- HEALTH (static 75% preview value)
		local hpPercent = 0.75
		local healthEnabled = Toggles.GetState("vis_health")

		previewHealthBg.Visible = healthEnabled
		previewHealthFill.Visible = healthEnabled

		previewHealthBg.Size = UDim2.new(0, HEALTH_WIDTH, 1, 0)
		previewHealthBg.Position = UDim2.new(0, -HEALTH_WIDTH-2, 0, 0)

		previewHealthFill.Size = UDim2.new(1,0, hpPercent,0)
		previewHealthFill.Position = UDim2.new(0,0,1-hpPercent,0)
		previewHealthFill.BackgroundColor3 = HEALTH_GREEN
	end)

	------------------------------------------------------------
	-- ORIGINAL DRAG / ROTATION SYSTEM (UNCHANGED)
	------------------------------------------------------------

	local draggingPreview = false
	local lastX = 0
	local rotationY = 0
	local velocity = 0

	local dragSensitivity = 0.4
	local inertiaDamping = 0.92

	local idleTimer = 0
	local idleDelay = 1.2

	local springTargetAngle = 35
	local springFrequency = 0.6
	local springStiffness = 8
	local springDamping = 6
	local springVelocity = 0

	viewport.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			draggingPreview = true
			lastX = input.Position.X
			idleTimer = 0
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
			idleTimer = 0
		end
	end)

	RunService.RenderStepped:Connect(function(dt)

		if not preview or not preview.PrimaryPart then return end

		if not draggingPreview then
			idleTimer += dt
		end

		if not draggingPreview and idleTimer <= idleDelay then
			rotationY += velocity
			velocity *= inertiaDamping
			if math.abs(velocity) < 0.01 then
				velocity = 0
			end
		end

		if not draggingPreview and idleTimer > idleDelay then
			local target = math.sin(tick() * springFrequency) * springTargetAngle
			local displacement = target - rotationY
			local force = displacement * springStiffness
			springVelocity += force * dt
			springVelocity -= springVelocity * springDamping * dt
			rotationY += springVelocity * dt
		end

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
	end)
end

return Preview
