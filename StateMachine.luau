--!strict
local Types = require(game:GetService("ReplicatedStorage").Combat.Types)
type State = Types.State

export type Machine = {
    Get: () -> State,
    Transition: (State) -> boolean,
}

local edges: {[State]: {[State]: boolean}} = {
    Idle = {Windup = true, Stunned = true, Dead = true},
    Windup = {Active = true, Stunned = true, Dead = true},
    Active = {Recovery = true, Stunned = true, Dead = true},
    Recovery = {Idle = true, Stunned = true, Dead = true},
    Stunned = {Idle = true, Dead = true},
    Dead = {},
}

local StateMachine = {}

function StateMachine.new(onChanged: (State) -> ()): Machine
    local current: State = "Idle"

    return {
        Get = function(): State
            return current
        end,

        Transition = function(nextState: State): boolean
            if current == nextState then
                return false
            end
            if edges[current][nextState] ~= true then
                return false
            end
            current = nextState
            onChanged(current) -- Callbacks must not yield.
            return true
        end,
    }
end

return StateMachine
