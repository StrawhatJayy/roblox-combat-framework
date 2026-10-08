--!strict
-- Manual Studio runner. No third-party test library.
local Tests = {}

function Tests.Run(server: Instance)
    local StateMachine = require(server.StateMachine)
    local Cooldowns = require(server.Cooldowns)
    local RateLimiter = require(server.RateLimiter)
    local Janitor = require(server.Janitor)

    local transitions = 0
    local machine = StateMachine.new(function(_state)
        transitions += 1
    end)
    assert(not machine.Transition("Recovery"), "Illegal edge accepted")
    assert(machine.Transition("Windup"))
    assert(machine.Transition("Active"))
    assert(machine.Transition("Stunned"), "Interrupt failed")
    assert(not machine.Transition("Active"), "Stun bypassed")
    assert(machine.Transition("Idle"))
    assert(machine.Transition("Dead"))
    assert(not machine.Transition("Idle"), "Death must be terminal")
    assert(transitions == 5)

    local cooldowns = Cooldowns.new()
    cooldowns.Start("Slash", 2, 10)
    assert(cooldowns.Remaining("Slash", 11) == 1)
    assert(cooldowns.Remaining("Slash", 12) == 0)
    assert(cooldowns.Remaining("Heavy", 11) == 0)

    local limiter = RateLimiter.new(2, 1)
    assert(limiter.Allow(0))
    assert(limiter.Allow(0))
    assert(not limiter.Allow(0))
    assert(limiter.Allow(1))
    assert(not limiter.Allow(1))

    local janitor = Janitor.new()
    local order = ""
    janitor.Add(function() order ..= "A" end)
    janitor.Add(function() order ..= "B" end)
    janitor.Destroy()
    janitor.Destroy()
    assert(order == "BA", "Cleanup order/idempotence failed")
    janitor.Add(function() order ..= "C" end)
    assert(order == "BAC", "Late resource was not cleaned")

    print("Core assertions passed")
end

return Tests
