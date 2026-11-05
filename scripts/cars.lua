-- LocalScript placed in StarterPlayer -> StarterCharacterScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

-- Configuration Constants
local DASH_SPEED = 140
local DASH_DURATION = 0.65
local FOV_BOOST = 20
local LEAN_ANGLE_DEG = 25

--------------------------------------------------------------------------------
-- Helper: Particle Emitter Constructor
--------------------------------------------------------------------------------
local function createEmitter(parent, props)
	local emitter = Instance.new("ParticleEmitter")
	for key, value in pairs(props) do
		emitter[key] = value
	end
	emitter.Parent = parent
	return emitter
end

--------------------------------------------------------------------------------
-- Main Dash Execution
--------------------------------------------------------------------------------
local function executeDash()
	-- 1. Calculate random 2D direction on horizontal plane
	local randomRad = math.rad(math.random(0, 360))
	local dashDirection = Vector3.new(math.cos(randomRad), 0, math.sin(randomRad)).Unit

	-- Instantly align character rotation to target direction
	hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + dashDirection)

	-- 2. Configure Physics (LinearVelocity replaces deprecated BodyVelocity)
	local attachment = Instance.new("Attachment")
	attachment.Name = "DashAttachment"
	attachment.Parent = hrp

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Attachment0 = attachment
	linearVelocity.MaxForce = 300000
	linearVelocity.VectorVelocity = dashDirection * DASH_SPEED
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.Parent = hrp

	-- 3. Visual Effects Setup (Nitro Emitters)
	local nitroAttachment = Instance.new("Attachment")
	nitroAttachment.Name = "NitroThruster"
	nitroAttachment.Position = Vector3.new(0, -0.5, 0.5)
	nitroAttachment.Parent = hrp

	local fireEmitter = createEmitter(nitroAttachment, {
		Texture = "rbxassetid://243661074",
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0, 100, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 25))
		}),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.2),
			NumberSequenceKeypoint.new(1, 0.05)
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.8, 0.2),
			NumberSequenceKeypoint.new(1, 1)
		}),
		Lifetime = NumberRange.new(0.15, 0.3),
		Rate = 120,
		Speed = NumberRange.new(15, 25),
		EmissionDirection = Enum.NormalId.Back
	})

	local sparkEmitter = createEmitter(nitroAttachment, {
		Texture = "rbxassetid://258129763",
		Color = ColorSequence.new(Color3.fromRGB(180, 240, 255)),
		Size = NumberSequence.new(0.35, 0.05),
		Lifetime = NumberRange.new(0.2, 0.4),
		Rate = 50,
		Speed = NumberRange.new(20, 35),
		SpreadAngle = Vector2.new(12, 12),
		EmissionDirection = Enum.NormalId.Back
	})

	local nitroLight = Instance.new("PointLight")
	nitroLight.Color = Color3.fromRGB(0, 170, 255)
	nitroLight.Range = 16
	nitroLight.Brightness = 4
	nitroLight.Parent = hrp

	-- 4. Camera Dynamics
	local originalFOV = camera.FieldOfView
	local fovInTween = TweenService:Create(
		camera,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ FieldOfView = originalFOV + FOV_BOOST }
	)
	fovInTween:Play()

	-- 5. Humanoid Posture Adjustment (Forward Lean)
	local rootJoint = hrp:FindFirstChild("RootJoint")
	local originalC0 = rootJoint and rootJoint.C0 or CFrame.new()

	local renderConnection
	if rootJoint then
		renderConnection = RunService.RenderStepped:Connect(function()
			rootJoint.C0 = originalC0 * CFrame.Angles(math.rad(LEAN_ANGLE_DEG), 0, 0)
		end)
	end

	-- 6. Structured Cleanup Routine
	task.delay(DASH_DURATION, function()
		-- Stop active forces
		linearVelocity:Destroy()
		attachment:Destroy()

		-- Disable particles and let existing ones fade out naturally
		fireEmitter.Enabled = false
		sparkEmitter.Enabled = false
		nitroLight:Destroy()

		-- Restore procedural posture & camera FOV
		if renderConnection then
			renderConnection:Disconnect()
		end
		if rootJoint then
			rootJoint.C0 = originalC0
		end

		TweenService:Create(
			camera,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ FieldOfView = originalFOV }
		):Play()

		-- Clean up visual attachments after particle lifetimes clear
		Debris:AddItem(nitroAttachment, 0.5)
	end)
end

-- Execute single dash on load
executeDash()