--!strict
-- DragController.lua
-- Handles dragging logic for any frame

local DragController = {}

function DragController.Attach(
	header: GuiObject,
	target: GuiObject,
	UserInputService: UserInputService
)
	local dragging = false
	local dragStart = Vector2.zero
	local startPos = UDim2.new()

	local function beginDrag(input: InputObject)
		dragging = true
		dragStart = input.Position
		startPos = target.Position
	end

	local function updateDrag(input: InputObject)
		if not dragging then return end
		local delta = input.Position - dragStart

		target.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end

	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag(input)
		end
	end)

	header.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
			updateDrag(input)
		end
	end)
end

return DragController
