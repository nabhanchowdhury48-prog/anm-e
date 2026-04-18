local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({Title = "FPS Flick", SubTitle = "Clean Version", Theme = "Dark"})

local Main = Window:AddTab({Title = "Main"})

local silent = false
local flick = true
local autofire = true

local target = nil
local prediction = 0.15

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    if silent and target and (method == "FireServer" or method == "InvokeServer") then
        local name = self.Name:lower()
        if name:find("shoot") or name:find("fire") or name:find("bullet") then
            if args[1] and typeof(args[1]) == "Vector3" then
                args[1] = target.Position + (target.Velocity * prediction)
            end
        end
    end
    return old(self, unpack(args))
end)
setreadonly(mt, true)

local function getTarget()
    local closest = nil
    local minDist = 9999
    for _, p in ipairs(Players:GetPlayers()) do
        if p \~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            if not (p.Team and LocalPlayer.Team and p.Team == LocalPlayer.Team) then
                local pos = Camera:WorldToViewportPoint(p.Character.Head.Position)
                local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = p.Character.Head
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function(delta)
    target = getTarget()
    
    if target then
        if flick then
            local pos = target.Position + target.Velocity * prediction
            local cf = CFrame.lookAt(Camera.CFrame.Position, pos)
            Camera.CFrame = Camera.CFrame:Lerp(cf, 0.75 * delta * 80)
        end
        if autofire then
            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                for _, v in tool:GetDescendants() do
                    if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                        local n = v.Name:lower()
                        if n:find("shoot") or n:find("fire") or n:find("bullet") then
                            pcall(function() v:FireServer(target.Position + target.Velocity * prediction) end)
                            break
                        end
                    end
                end
            end
        end
    end
end)

Main:AddToggle({Title = "Silent Aim", Default = false, Callback = function(v) silent = v end})
Main:AddToggle({Title = "Strong Flick", Default = true, Callback = function(v) flick = v end})
Main:AddToggle({Title = "Auto Fire", Default = true, Callback = function(v) autofire = v end})

Fluent:Notify({Title = "Loaded", Content = "FPS Flick script is ready", Duration = 6})
