# Validation record

Status: NOT RUN.

Replace pending entries only after actually performing the check. Record
Studio version, date, server/client counts, outcome, and relevant output.
Do not treat this checklist as passed test results.

| Check | Expected behavior | Result |
|---|---|---|
| Studio Script Analysis | Review and resolve type/script diagnostics | Pending |
| Core.spec server runner | Prints Core assertions passed | Pending |
| Rojo build, if used | Builds a place with correct hierarchy | Pending |
| Two-player Slash | At most one damage event per cast | Pending |
| Heavy | Longer windup, recovery, and cooldown than Slash | Pending |
| Behind caster | No damage | Pending |
| Outside range | No damage | Pending |
| Wall between roots | No damage | Pending |
| Same non-neutral team | No damage | Pending |
| Neutral opponents | Damage permitted | Pending |
| ForceField | No damage | Pending |
| Dead caster or target | No attack/damage | Pending |
| Stun during windup | Cast cancelled; cooldown retained | Pending |
| Repeated stun | Later deadline wins | Pending |
| Death during windup | No delayed hit | Pending |
| Respawn during cast | Old actor cannot hit | Pending |
| Respawn during cooldown | Session cooldown retained | Pending |
| Disconnect | Actor and session resources removed | Pending |
| Destroy service twice | Safe; handlers disconnected | Pending |
| Malformed remote payload | Ignored without server error | Pending |
| Remote spam | Bounded handling; excess silently dropped | Pending |
| Dense scene | Measure omissions from 64-part cap | Pending |
| Simulated server stall | Expired active window does not land stale hit | Pending |

## Adversarial calls

From a client Command Bar in an isolated test place:

```lua
local remote = game.ReplicatedStorage.Combat.AbilityRequest
remote:FireServer({})
remote:FireServer(0 / 0)
remote:FireServer(string.rep("x", 1000))
remote:FireServer("Slash", workspace)
remote:FireServer("Unknown")
for _ = 1, 100 do
    remote:FireServer("Heavy")
end
```

Observe the server Output and target health. Do not run this spam check against
someone else's live game. No client-provided target or damage is consumed.

For lifecycle testing, retain the object returned by CombatService.Start in a
temporary server harness and call Destroy twice. Stop the original Bootstrap
first to avoid installing duplicate services.
