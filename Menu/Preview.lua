--!strict
-- Preview.lua
-- 2D ESP-Accurate Player Preview (Matches ESP.lua exactly)

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
	-- CONFIG (MATCHES ESP)
	------------------------------------------------------------

	local BOX_THICKNESS = 2
	local HEALTH_WIDTH = 2
	local HEALTH_GREEN = Color3.fromRGB(0,255,0)

	------------------------------------------------------------
	-- STATE
	------------------------------------------------------------

	local preview: Model? = nil

	local boxFrame: Frame? = nil
	local boxStroke: UIStroke? = nil
	local healthBg: Frame? = nil
	local healthFill: Frame? = nil
	local nameLabel: TextLabel? = nil

	------------------------------------------------------------
	-- BUILD 2D OVERLAY
	------------------------------------------------------------

	local function buildOverlay()

		-- BOX
		boxFrame = Instance.new("Frame")
		boxFrame.BackgroundTransparency = 1
		boxFrame.BorderSizePixel = 0
		boxFrame.Visible = false
		boxFrame.Parent = previewPanel

		boxStroke = Instance.new("UIStroke")
		boxStroke.Thickness = BOX_THICKNESS
		boxStroke.Parent = boxFrame

		-- HEALTH
		healthBg = Instance.new("Frame")
		healthBg.BackgroundColor3 = Color3.fromRGB(35,35,35)
		healthBg.BorderSizePixel = 0
		healthBg.Visible = false
		healthBg.Parent = boxFrame

		healthFill = Instance.new("Frame")
		healthFill.BorderSizePixel = 0
		healthFill.BackgroundColor3 = HEALTH_GREEN
		healthFill.Parent = healthBg

		-- NAME
		nameLabel = Instance.new("TextLabel")
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.GothamSemibold
		nameLabel.TextStrokeTransparency = 0.5
		nameLabel.TextWrapped = false
		nameLabel.TextXAlignment = Enum.TextXAlignment.Center
		nameLabel.TextYAlignment = Enum.TextYAlignment.Center
		nameLabel.AnchorPoint = Vector2.new(0.5,1)
		nameLabel.ClipsDescendants = false
		nameLabel.Visible = false
		nameLabel.Parent = previewPanel
	end

	------------------------------------------------------------
	-- APPLY CHAMS (SAME AS BEFORE)
	------------------------------------------------------------

	local originalPartState = {}

	local function applyPreviewChams()
		if not preview then return end

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
				inst.Color = Color3.fromRGB(0,120,255)
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
	end

	------------------------------------------------------------
	-- REFRESH VISIBILITY
	------------------------------------------------------------

	local function refreshVisibility()

		local boxes = Toggles.GetState("vis_boxes")
		local health = Toggles.GetState("vis_health")
		local name = Toggles.GetState("vis_name")
		local glow = Toggles.GetState("vis_glow")

		if boxFrame then
			boxFrame.Visible = boxes
		end

		if healthBg and healthFill then
			healthBg.Visible = health
			healthFill.Visible = health
		end

		if nameLabel then
			nameLabel.Visible = name
		end

		removePreviewChams()
		if glow then
			applyPreviewChams()
		end
	end

	------------------------------------------------------------
	-- BUILD AVATAR
	------------------------------------------------------------

	local function buildAvatar()

		world:ClearAllChildren()
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

		if nameLabel then
			nameLabel.Text = player.DisplayName
		end

		refreshVisibility()
	end

	------------------------------------------------------------
	-- RENDER LOOP (2D BOX CALC LIKE ESP)
	------------------------------------------------------------

	RunService.RenderStepped:Connect(function()

		if not preview or not preview.PrimaryPart then return end
		if not boxFrame or not boxStroke then return end

		local cf, size = preview:GetBoundingBox()
		local center = cf.Position

		local maxDim = math.max(size.X, size.Y, size.Z)
		local fov = math.rad(cam.FieldOfView)
		local distance = (maxDim / (2 * math.tan(fov / 2))) * 1.25

		cam.CFrame = CFrame.new(center + Vector3.new(0,0,distance), center)

		preview:SetPrimaryPartCFrame(
			CFrame.new(0,0,0) *
			CFrame.Angles(0, math.rad(180), 0)
		)

		-- project 3D top/bottom into viewport (LIKE ESP)
		local top3D = center + Vector3.new(0, size.Y/2, 0)
		local bottom3D = center - Vector3.new(0, size.Y/2, 0)

		local top2D = cam:WorldToViewportPoint(top3D)
		local bottom2D = cam:WorldToViewportPoint(bottom3D)

		local height = math.abs(bottom2D.Y - top2D.Y)
		local width = height * 0.5

		boxFrame.Size = UDim2.fromOffset(width, height)
		boxFrame.Position = UDim2.fromOffset(
			top2D.X - width/2,
			top2D.Y
		)

		boxStroke.Color = Color3.fromRGB(0,120,255)

		-- HEALTH MATCH
		local hpPercent = 1 -- preview always full

		if healthBg and healthFill then
			healthBg.Size = UDim2.new(0, HEALTH_WIDTH, 1, 0)
			healthBg.Position = UDim2.new(0, -HEALTH_WIDTH-2, 0, 0)

			healthFill.Size = UDim2.new(1,0, hpPercent,0)
			healthFill.Position = UDim2.new(0,0, 1-hpPercent,0)
			healthFill.BackgroundColor3 = HEALTH_GREEN
		end

		if nameLabel then
			nameLabel.Position = UDim2.fromOffset(
				top2D.X,
				top2D.Y - 4
			)
			nameLabel.Size = UDim2.fromOffset(200, 18)
			nameLabel.TextColor3 = Color3.fromRGB(0,120,255)
		end
	end)

	------------------------------------------------------------
	-- TOGGLE HOOKS
	------------------------------------------------------------

	Toggles.Subscribe("vis_boxes", refreshVisibility)
	Toggles.Subscribe("vis_health", refreshVisibility)
	Toggles.Subscribe("vis_name", refreshVisibility)
	Toggles.Subscribe("vis_glow", refreshVisibility)

	buildOverlay()
	buildAvatar()
end

return Preview
