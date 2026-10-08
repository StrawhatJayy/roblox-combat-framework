--!strict
export type Cooldowns = {
    Remaining: (string, number) -> number,
    Start: (string, number, number) -> (),
}

local Cooldowns = {}

function Cooldowns.new(): Cooldowns
    local deadlines: {[string]: number} = {}

    return {
        Remaining = function(id: string, now: number): number
            return math.max(0, (deadlines[id] or 0) - now)
        end,

        Start = function(id: string, duration: number, now: number)
            deadlines[id] = now + duration
        end,
    }
end

return Cooldowns
