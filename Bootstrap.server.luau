--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatService = require(script.Parent.CombatService)

local folder = ReplicatedStorage:WaitForChild("Combat")
local request = folder:WaitForChild("AbilityRequest")
local feedback = folder:WaitForChild("AbilityFeedback")
assert(request:IsA("RemoteEvent"))
assert(feedback:IsA("RemoteEvent"))

local service = CombatService.Start(request, feedback)
script.Destroying:Connect(function()
    service.Destroy()
end)
