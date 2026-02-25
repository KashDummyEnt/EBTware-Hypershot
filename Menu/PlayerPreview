--!strict
-- Preview.lua
-- 1:1 migration of original preview system

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
	-- BUILD AVATAR + PREVIEW ESP
	------------------------------------------------------------

	local PREVIEW_CHAMS_COLOR = Color3.fromRGB(255, 0, 0)

	local preview: Model? = nil
	local previewBox: Part? = nil

	------------------------------------------------------------
	-- NAME
	------------------------------------------------------------

	local previewNameLabel = Instance.new("TextLabel")
	previewNameLabel.Name = "PreviewName"
	previewNameLabel.Size = UDim2.new(1, -32, 0, 20)
	previewNameLabel.Position = UDim2.new(0, 16, 0, 8)
	previewNameLabel.BackgroundTransparency = 1
	previewNameLabel.Font = Enum.Font.GothamSemibold
	previewNameLabel.TextScaled = true
	previewNameLabel.TextColor3 = Color3.fromRGB(255,70,70)
	previewNameLabel.TextStrokeTransparency = 0.5
	previewNameLabel.Visible = false
	previewNameLabel.Parent = previewPanel

	------------------------------------------------------------
	-- HEALTH BAR
	------------------------------------------------------------

	local previewHealthContainer = Instance.new("Frame")
	previewHealthContainer.Size = UDim2.new(1, -32, 0, 8)
	previewHealthContainer.Position = UDim2.new(0, 16, 1, -24)
	previewHealthContainer.BackgroundTransparency = 1
	previewHealthContainer.Visible = false
	previewHealthContainer.Parent = previewPanel

	local back = Instance.new("Frame")
	back.Size = UDim2.new(1, 0, 1, 0)
	back.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	back.BorderSizePixel = 0
	back.Parent = previewHealthContainer

	local backCorner = Instance.new("UICorner")
	backCorner.CornerRadius = UDim.new(1, 0)
	backCorner.Parent = back

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BorderSizePixel = 0
	fill.Parent = back

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	------------------------------------------------------------
	-- PREVIEW HEALTH LOOP
	------------------------------------------------------------

	local previewHealthRunning = false
	local previewHealthConn: RBXScriptConnection? = nil
	local previewDirection = -1
	local previewSpeed = 0.4

	local function startPreviewHealthAnimation()

		if previewHealthRunning then return end

		previewHealthRunning = true
		previewDirection = -1

		fill.Size = UDim2.new(1, 0, 1, 0)
		fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)

		if previewHealthConn then
			previewHealthConn:Disconnect()
			previewHealthConn = nil
		end

		previewHealthConn = RunService.RenderStepped:Connect(function(dt)

			if not previewHealthRunning then return end

			local currentPct = fill.Size.X.Scale or 1
			local newPct = currentPct + (previewDirection * previewSpeed * dt)

			if newPct <= 0 then
				newPct = 0
				previewDirection = 1
			elseif newPct >= 1 then
				newPct = 1
				previewDirection = -1
			end

			fill.Size = UDim2.new(newPct, 0, 1, 0)

			fill.BackgroundColor3 = Color3.fromRGB(
				math.floor(255 * (1 - newPct)),
				math.floor(255 * newPct),
				0
			)
		end)
	end

	local function stopPreviewHealthAnimation()

		previewHealthRunning = false

		if previewHealthConn then
			previewHealthConn:Disconnect()
			previewHealthConn = nil
		end
	end

	------------------------------------------------------------
	-- CHAMS (FULL RESTORE SYSTEM)
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
				inst.Color = PREVIEW_CHAMS_COLOR
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
	-- BOX
	------------------------------------------------------------

	local function clearPreviewESP()
		if previewBox then
			previewBox:Destroy()
			previewBox = nil
		end
	end

	local function addPreviewBox()
		if not preview then return end

		local box = Instance.new("Part")
		box.Anchored = true
		box.CanCollide = false
		box.Material = Enum.Material.Plastic
		box.Transparency = 0.65
		box.Color = PREVIEW_CHAMS_COLOR
		box.Parent = world

		previewBox = box
	end

	------------------------------------------------------------
	-- REFRESH PREVIEW ESP
	------------------------------------------------------------

	local function refreshPreviewESP()

		clearPreviewESP()
		removePreviewChams()

		if Toggles.GetState("visuals_box3d") then
			addPreviewBox()
		end

		if Toggles.GetState("visuals_player") then
			applyPreviewChams()
		end

		local healthEnabled = Toggles.GetState("visuals_health") == true
		previewHealthContainer.Visible = healthEnabled

		if healthEnabled then
			startPreviewHealthAnimation()
		else
			stopPreviewHealthAnimation()
			fill.Size = UDim2.new(1, 0, 1, 0)
			fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		end

		local nameEnabled = Toggles.GetState("visuals_name") == true
		previewNameLabel.Visible = nameEnabled
	end

	------------------------------------------------------------
	-- BUILD AVATAR
	------------------------------------------------------------

	local function buildAvatar()
		world:ClearAllChildren()
		preview = nil
		clearPreviewESP()
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

	Toggles.Subscribe("visuals_box3d", refreshPreviewESP)
	Toggles.Subscribe("visuals_health", refreshPreviewESP)
	Toggles.Subscribe("visuals_name", refreshPreviewESP)
	Toggles.Subscribe("visuals_player", refreshPreviewESP)

	buildAvatar()

	------------------------------------------------------------
	-- PREVIEW MOTION SYSTEM (FULL ORIGINAL)
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

		if previewBox then
			local paddedSize = Vector3.new(
				size.X + 0.05,
				size.Y,
				size.Z
			)

			previewBox.Size = paddedSize
			previewBox.CFrame = cf
		end
	end)
end

return Preview
