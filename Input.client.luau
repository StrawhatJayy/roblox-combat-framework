--!strict
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:WaitForChild("Combat")
local request = folder:WaitForChild("AbilityRequest")
local feedback = folder:WaitForChild("AbilityFeedback")
assert(request:IsA("RemoteEvent"))
assert(feedback:IsA("RemoteEvent"))

local function slash(
    _name: string, state: Enum.UserInputState, _input: InputObject
): Enum.ContextActionResult
    if state == Enum.UserInputState.Begin then
        request:FireServer("Slash")
    end
    return Enum.ContextActionResult.Sink
end

local function heavy(
    _name: string, state: Enum.UserInputState, _input: InputObject
): Enum.ContextActionResult
    if state == Enum.UserInputState.Begin then
        request:FireServer("Heavy")
    end
    return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction(
    "CombatSlash", slash, true, Enum.UserInputType.MouseButton1
)
ContextActionService:BindAction(
    "CombatHeavy", heavy, true, Enum.KeyCode.Q
)
ContextActionService:SetTitle("CombatSlash", "Slash")
ContextActionService:SetTitle("CombatHeavy", "Heavy")

local connection = feedback.OnClientEvent:Connect(function(
    id: unknown, result: unknown
)
    if typeof(id) == "string" and typeof(result) == "string" then
        print("[Combat]", id, result)
    end
end)

script.Destroying:Connect(function()
    ContextActionService:UnbindAction("CombatSlash")
    ContextActionService:UnbindAction("CombatHeavy")
    connection:Disconnect()
end)
