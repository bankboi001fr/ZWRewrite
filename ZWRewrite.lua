--[[
Discalmer :
You can use this AS you own hub but maybe add a credit this script isn't that good because i'm lazy

]] 

--Customizer

local printText = "ZW ON TOP ! :3"
local name = "Zyphranis Ware"
local dis = "Recoded Edition by DSB"
local v = "1"

--Service
local Client = game.Players.LocalPlayer
local Humanoid = Client.Character:WaitForChild("Humanoid")
local HumanoidRootPart = Client.Character.HumanoidRootPart
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--Folder
local BallsFolder = workspace:WaitForChild("Balls")
local AliveFolder = workspace:WaitForChild("Alive")
local DeadFolder = workspace:WaitForChild("Dead")

--Loadstring
local interface = loadstring(game:HttpGet('https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua'))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

--Config
local Config = {
	AutoParry = false,
	AutoSpam = false,
	Curve_Threshold = 0.5,
	Visualize = false,
}

--Store
local PlayerData = {
    Ping = 0,
    Dot = 0,
}

local Global = {
	cooldown = false,
	last_hit = 0,
	current_target = nil,
	parry_count = 0,
	is_spam = false,
	closestPlayer = nil,
	closestPlayerDistance = 0,
}

local Ball = {
	current_ball = nil,
	speed = 0,
    last_speed = 0,
	distance = 0,
	curved = false,
	max_speed = 0,
	last_velocity = Vector3.zero,
	aero_dynamic_time = 0,
	hell_hook_completed = true,
	lerp_radians = 0,
	radians = 0,
	last_curve_position = Vector3.zero,
	last_warping = 0,
    predicted_position = 0,
    predicted_distance = 0,
}

local AutoParry = {
	AutoParryDistance = 0,
	AutoParryDistanceMaxSpeedBased = 0,
}

local AutoSpam = {
	AutoSpamSpeedBased = 0,
	AutoSpamMovementBased = 0,
}


--Find Parry Function
local ParryFunction
local SwordsController = nil

for _, child in ipairs(game.ReplicatedStorage.Controllers:GetChildren()) do
	if child.Name:match("^SwordsController%s*$") then
		SwordsController = child
	end
end

for i,v in next, getconnections(Client.PlayerGui.Hotbar.Block.Activated) do
	if getfenv(v.Function).script == SwordsController then
		ParryFunction = v.Function
		print(v.Function)
	end
end

--Function

local function Parry()
	if not Global.cooldown then
		Global.cooldown = true
		Global.last_hit = os.clock()
		Global.parry_count += 1
		ParryFunction()

		local PingThreshold = math.clamp(PlayerData.Ping / 10, 10, math.huge)

		task.spawn(function()
			repeat
				RunService.Stepped:Wait()
			until (os.clock() - Global.last_hit) > 1 - (PingThreshold / 100)
			Global.cooldown = false
		end)

		task.delay(1,function()
			Global.parry_count -= 1
		end)
	end
end

local function GetClosestPlayer()
	local closestPlayer = nil
	local minDistance = math.huge

	for _, player in pairs(workspace.Alive:GetChildren()) do
		local humanoid = player:FindFirstChild("Humanoid")
		local rootPart = player:FindFirstChild("HumanoidRootPart")
		if humanoid and rootPart and player.Name ~= Client.Name then
			local distance = (HumanoidRootPart.Position - rootPart.Position).Magnitude
			if distance < minDistance then
				minDistance = distance
				closestPlayer = player
			end
		end
	end
	return closestPlayer
end


local function Reset()
	--Global Reset
	Global.last_hit = 0
	Global.cooldown = false
	Global.current_target = nil
	Global.is_spam = false
	Global.parry_count = 0
    Global.closestPlayer = nil
    Global.closestPlayerDistance = 0
	--Ball Reset
	Ball.current_ball = nil
	Ball.speed = 0
	Ball.distance = 0
	Ball.curved = false
	Ball.max_speed = 0
	Ball.aero_dynamic_time = 0
	Ball.hell_hook_completed = true
	Ball.lerp_radians = 0
	Ball.radians = 0
	Ball.last_warping = 0
    Ball.last_speed = 0
    Ball.last_curve_position = Vector3.zero
	--AutoParry / AutoSpam Reset
	AutoParry.AutoParryDistance = 0
	AutoParry.AutoParryDistanceMaxSpeedBased = 0
	AutoSpam.AutoSpamSpeedBased = 0
	AutoSpam.AutoSpamMovementBased = 0
    --PlayerData
    PlayerData.Dot = 0
    PlayerData.Ping = 0
end

local function linear_predict(a, b, time_volume)
	return a + (b - a) * time_volume
end

local function IsCurved()
	local target = Global.current_target

	if not target then
		return false
	end

	local current_target = Global.current_target.Name

	if target.PrimaryPart:FindFirstChild('MaxShield') and current_target ~= Client.Name and Ball.distance < 50 then
		return false
	end

	if Ball.current_ball:FindFirstChild('TimeHole1') and current_target ~= Client.Name and Ball.distance < 100 then
		Global.is_spam = false

		return false
	end

	if Ball.current_ball:FindFirstChild('WEMAZOOKIEGO') and current_target ~= Client.Name and Ball.distance < 100 then
		return false
	end

	if Ball.current_ball:FindFirstChild('At2') and Ball.speed <= 0 then
		return true
	end

	if Ball.current_ball:FindFirstChild('AeroDynamicSlashVFX') then

		Global.is_spam = false
		Ball.aero_dynamic_time = os.clock()
	end

	if workspace:FindFirstChild('Tornado') then
		if Ball.distance > 5 and (os.clock() - Ball.aero_dynamic_time) < (workspace.Tornado:GetAttribute("TornadoTime") or 1) + 0.314159 then
			return true
		end
	end

	if not Ball.hell_hook_completed and target.Name == Client.Name and Ball.distance > 5 - math.random() then
		return true
	end

	local ball_velocity = Ball.current_ball.AssemblyLinearVelocity

	local ball_direction = (HumanoidRootPart.Position - Ball.current_ball.Position).Unit

	local ballPosition = Ball.current_ball.Position

	local dotProduct = ball_direction:Dot(Ball.current_ball.AssemblyLinearVelocity.Unit)

	local speed_threshold = math.min(Ball.speed / 100, 40)
	local angle_threshold = 40 * math.max(dotProduct, 0)

	local player_ping = PlayerData.Ping

	local accurate_direction = ball_velocity.Unit
	accurate_direction *= ball_direction

	local direction_difference = (accurate_direction - ball_velocity).Unit
	local accurate_dot = ball_velocity.Unit:Dot(direction_difference)
	local dot_difference = dotProduct - accurate_dot
	local dot_threshold = Config.Curve_Threshold - player_ping / 1000 - Ball.speed / 1000

	local reach_time = Ball.distance / Ball.max_speed - (player_ping / 1000)
	local enough_speed = Ball.max_speed > 100

	local ball_distance_threshold = 15 - math.min(Ball.distance / 1000, 15) + angle_threshold + speed_threshold

	if enough_speed and reach_time > player_ping / 10 then
		ball_distance_threshold = math.max(ball_distance_threshold - 15, 15)
	end

	if Ball.distance < ball_distance_threshold then
		return false
	end

	if Ball.lerp_radians < 0.018 then
		Ball.last_curve_position = Ball.current_ball.position
		Ball.last_warping = os.clock() 
	end

	if (os.clock() - Ball.last_warping) < (reach_time / 1.5) then
		return true
	end

	if dot_difference < dot_threshold then
		return true
	end

	return dotProduct < dot_threshold
end

--Added / Removed

task.defer(function()

	BallsFolder.ChildAdded:Connect(function(v)
		if v:IsA("BasePart") and v:GetAttribute("realBall") then
			Ball.current_ball = v
			Global.current_target = workspace.Alive:FindFirstChild(Ball.current_ball:GetAttribute("target"))
		end
	end)

	BallsFolder.ChildRemoved:Connect(function()
		Reset()
	end)

	Humanoid.Died:Connect(function()
		Reset()
	end)
end)

--Remote thing

task.defer(function()
	game.ReplicatedStorage.Remotes.PlrHellHooked.OnClientEvent:Connect(function(hooker)
		if hooker.Name == Client.Name then
			Ball.hell_hook_completed = true

			return
		end

		AutoParry.ball.properties.hell_hook_completed = false
	end)

	game.ReplicatedStorage.Remotes.PlrHellHookCompleted.OnClientEvent:Connect(function()
		AutoParry.ball.properties.hell_hook_completed = true
	end)

	game.ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(slash, root)

		
		task.spawn(function()
			if root.Parent and root.Parent ~= Client.Character then
				if root.Parent.Parent == DeadFolder then
					return
				end

				Global.cooldown = false
			end
		end)

		if Global.is_spam then
			for i = 1,10 do
				ParryFunction()
			end
		end
	end)

	game.ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
		Global.last_hit = os.clock()
	
		if Client.Character.Parent ~= AliveFolder then
			return
		end

		if Global.is_spam then
			for i = 1, 10 do
				ParryFunction()
			end
		end

	end)
end)


--Main Function / Handler
task.spawn(function()
	local MainConnection

	if not MainConnection then
		MainConnection = RunService.PostSimulation:Connect(function()

			if interface.Unloaded then
				MainConnection:Disconnect()
				MainConnection = nil
			end

			if not Client or not Ball or Client.Character.Parent == DeadFolder or not Ball.current_ball or not Global.current_target then
				return
			end
        

			local PingThreshold = math.clamp(PlayerData.Ping / 10, 10, math.huge)
            local Buffer = Ball.speed > 500 and 1.2 or 1

			AutoParry.AutoParryDistance = PingThreshold + math.max(Ball.speed / 2.3, 15) * Buffer
			AutoParry.AutoParryDistanceMaxSpeedBased = PingThreshold + Ball.max_speed / 2.3 * Buffer

			local baseMoveAmount = 0.5
			local moveAmount = baseMoveAmount * (1 / (Global.closestPlayerDistance + 0.01)) * 1000

			AutoSpam.AutoSpamSpeedBased = PingThreshold + Ball.speed / 9.5
			AutoSpam.AutoSpamMovementBased = PingThreshold + moveAmount + (Ball.speed / 5.5)

            if Config.AutoParry and Global.current_target.Name == Client.Name then
                if (Ball.distance <= AutoParry.AutoParryDistance or Ball.distance <= AutoParry.AutoParryDistanceMaxSpeedBased) or 
                   (Ball.predicted_distance <= AutoParry.AutoParryDistance or Ball.predicted_distance <= AutoParry.AutoParryDistanceMaxSpeedBased) then
                    if not Ball.curved then
                        Parry()
                    end
                end
            end

			if Config.AutoSpam and Ball.speed >= 10 then
                Global.is_spam = Global.closestPlayerDistance <= AutoSpam.AutoSpamMovementBased and (Ball.distance <= AutoSpam.AutoSpamSpeedBased or Ball.predicted_distance <= AutoSpam.AutoSpamSpeedBased) and Ball.lerp_radians > 0.026 and Global.parry_count > 0
			end
		end)
	end
end)

local NotMainConnection

task.defer(function()
	NotMainConnection = RunService.PreSimulation:Connect(function()
		if interface.Unloaded then
			NotMainConnection:Disconnect()
			NotMainConnection = nil
			return
		end

        Humanoid = Client.Character.Humanoid
        HumanoidRootPart = Client.Character.HumanoidRootPart

		for _, ball in pairs(BallsFolder:GetChildren()) do
			if ball:GetAttribute("realBall") then
				Ball.current_ball = ball
			end
		end

		if Client.Character.Parent == DeadFolder or not Ball.current_ball then
			return
		end

		if Global.is_spam then
			task.spawn(function()
				repeat
					for i = 1, 10 do
						ParryFunction()
					end
					task.wait()
				until not Global.is_spam
			end)
		end

		Global.closestPlayer = GetClosestPlayer()

		Global.closestPlayerDistance = (HumanoidRootPart.Position - Global.closestPlayer.HumanoidRootPart.Position).Magnitude

		Global.current_target = workspace.Alive:FindFirstChild(Ball.current_ball:GetAttribute("target"))

		Ball.distance = (Ball.current_ball.Position - HumanoidRootPart.Position).Magnitude
        
        Ball.speed = Ball.current_ball.AssemblyLinearVelocity.Magnitude

		Ball.direction = (HumanoidRootPart.Position - Ball.current_ball.Position).Unit

		Ball.velocity = Ball.current_ball.AssemblyLinearVelocity

        local predicted_volume = Client:GetNetworkPing() + (Ball.speed / 1000)

        Ball.predicted_position = Ball.current_ball.Position + (Ball.velocity * predicted_volume)

        Ball.predicted_distance = (HumanoidRootPart.Position - Ball.predicted_position).Magnitude

		Ball.max_speed = math.max(Ball.max_speed, Ball.speed)

        local dot_product = Ball.direction:Dot(Ball.velocity)

        dot_product = math.clamp(dot_product, -1, 1)

        Ball.radians = math.rad(math.asin(dot_product))

		Ball.lerp_radians = linear_predict(Ball.lerp_radians, Ball.radians, predicted_volume)

		if Ball.lerp_radians < 0 then
			Ball.lerp_radians = 0.027
		end

		Ball.curved = IsCurved()
        
        PlayerData.Ping = Client:GetNetworkPing() * 2000

        local directionToPlayer = (HumanoidRootPart.Position - Ball.current_ball.Position).unit

        local velocity = HumanoidRootPart.AssemblyLinearVelocity
    
        PlayerData.Dot = velocity:Dot(directionToPlayer)

	end)
end)

local visualizeRunserver

task.defer(function()
	local visualizePart = Instance.new("Part",workspace)
	visualizePart.Name = "VisualizePart"
	visualizePart.Material = Enum.Material.ForceField
	visualizePart.CanCollide = false
	visualizePart.Shape = Enum.PartType.Ball
	visualizePart.Transparency = 1

	visualizeRunserver = RunService.RenderStepped:Connect(function()

		if interface.Unloaded then
			visualizePart:Destroy()
			visualizeRunserver:Disconnect()
			visualizeRunserver = nil
		end

		if Config.Visualize then

			local size = AutoParry.AutoParryDistanceMaxSpeedBased
			visualizePart.Transparency = 0
			visualizePart.Position = Client.Character.HumanoidRootPart.Position
			visualizePart.Size = Vector3.new(size,size,size)
		else
			visualizePart.Transparency = 1
		end
	end)
end)

-- Gui

local Window = interface:CreateWindow({
	Title = name.."/"..v,
	SubTitle = dis,
	TabWidth = 180,
	Size = UDim2.fromOffset(500, 350),
	Acrylic = false,
	Theme = "Darker",
	MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
	Main = Window:AddTab({ Title = "Auto Parry", Icon = "sword" }),
	Visual = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
	--Setting = Window:AddTab({ Title = "Settings", Icon = "cog" }),
}

local Options = interface.Options


--Main Tab

do

	local auto_parry = Tabs.Main:AddToggle("ap",{

		Title = "Auto Parry", 

		Description = "Automantic Parry",

		Default = false,

	})

	auto_parry:OnChanged(function(v)

		Config.AutoParry = v

	end)

	local auto_spam = Tabs.Main:AddToggle("as",{

		Title = "Auto Spam", 

		Description = "Automantic Spam",

		Default = false,

	})

	auto_spam:OnChanged(function(v)

		Config.AutoSpam = v

	end)

	local Curve_Threshold = Tabs.Main:AddSlider("CT", 
		{
			Title = "Curve Threshold",
			Description = "Curve Threshold (more = less detection less = more detection)",
			Default = 0.5,
			Min = 0.1,
			Max = 0.9,
			Rounding = 1,
			Callback = function(Value)

				Config.Curve_Threshold = math.round(Value)

			end
		})
end

do
	local Visualize = Tabs.Visual:AddToggle("V",{

		Title = "Visualize", 

		Description = "Enabled Visualize (for auto parry only)",

		Default = false,
	})

	Visualize:OnChanged(function(v)
		Config.Visualize = v
	end)


end

print(printText)
