--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Types = require(game:GetService("ReplicatedStorage").Combat.Types)
type Ability = Types.Ability

local Hitbox = {}

function Hitbox.Query(
    attacker: Player,
    character: Model,
    root: BasePart,
    ability: Ability
): {Humanoid}
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    overlap.FilterDescendantsInstances = {character}
    overlap.MaxParts = 64

    local ray = RaycastParams.new()
    ray.FilterType = Enum.RaycastFilterType.Exclude
    ray.FilterDescendantsInstances = {character}

    local frame = root.CFrame * CFrame.new(0, 0, -ability.Reach / 2)
    local size = Vector3.new(ability.Width, 5, ability.Reach)
    local parts = Workspace:GetPartBoundsInBox(frame, size, overlap)

    local found: {Humanoid} = {}
    local seen: {[Humanoid]: boolean} = {}

    for _, part in ipairs(parts) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model == nil or model == character then
            continue
        end
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        local targetRoot = model:FindFirstChild("HumanoidRootPart")
        if humanoid == nil or seen[humanoid] then
            continue
        end
        seen[humanoid] = true

        if humanoid.Health <= 0
            or targetRoot == nil
            or not targetRoot:IsA("BasePart")
            or model:FindFirstChildOfClass("ForceField") ~= nil then
            continue
        end

        local targetPlayer = Players:GetPlayerFromCharacter(model)
        if targetPlayer ~= nil
            and not attacker.Neutral
            and not targetPlayer.Neutral
            and attacker.Team == targetPlayer.Team then
            continue
        end

        local offset = targetRoot.Position - root.Position
        local distance = offset.Magnitude
        if distance > ability.Reach or distance < 0.001 then
            continue
        end
        if root.CFrame.LookVector:Dot(offset.Unit) < 0 then
            continue
        end

        local obstruction = Workspace:Raycast(root.Position, offset, ray)
        if obstruction ~= nil
            and not obstruction.Instance:IsDescendantOf(model) then
            continue
        end

        table.insert(found, humanoid)
        if #found >= ability.MaxTargets then
            break
        end
    end

    return found
end

return Hitbox
