--!strict
local Types = require(game:GetService("ReplicatedStorage").Combat.Types)
type Ability = Types.Ability

-- Server-only definitions: clients do not choose damage or phase durations.
local definitions: {[string]: Ability} = {
    Slash = {
        Id = "Slash",
        Cooldown = 0.65,
        Windup = 0.12,
        Active = 0.10,
        Recovery = 0.25,
        Damage = 12,
        Stun = 0.18,
        Reach = 6,
        Width = 5,
        MaxTargets = 4,
    },
    Heavy = {
        Id = "Heavy",
        Cooldown = 2.5,
        Windup = 0.45,
        Active = 0.15,
        Recovery = 0.60,
        Damage = 28,
        Stun = 0.65,
        Reach = 7,
        Width = 6,
        MaxTargets = 4,
    },
}

for _, definition in pairs(definitions) do
    assert(definition.Cooldown >= 0)
    assert(definition.Windup > 0 and definition.Active > 0)
    assert(definition.Recovery > 0 and definition.Damage >= 0)
    assert(definition.Stun >= 0 and definition.Reach > 0)
    assert(definition.Width > 0 and definition.MaxTargets >= 1)
    table.freeze(definition)
end

return table.freeze(definitions)
