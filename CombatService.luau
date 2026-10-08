--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Combat.Types)
local StateMachine = require(script.Parent.StateMachine)
local Cooldowns = require(script.Parent.Cooldowns)
local RateLimiter = require(script.Parent.RateLimiter)
local Janitor = require(script.Parent.Janitor)
local Abilities = require(script.Parent.Abilities)
local Hitbox = require(script.Parent.Hitbox)

type Ability = Types.Ability
type Result = Types.Result

type Cast = {
    Ability: Ability,
    Started: number,
}

type Actor = {
    Character: Model,
    Humanoid: Humanoid,
    Root: BasePart,
    Machine: StateMachine.Machine,
    Scope: Janitor.Janitor,
    Cast: Cast?,
    StunUntil: number,
}

type Session = {
    Actor: Actor?,
    Cooldowns: Cooldowns.Cooldowns,
    Limiter: RateLimiter.Limiter,
}

export type Service = {
    Destroy: () -> (),
}

local CombatService = {}

function CombatService.Start(
    request: RemoteEvent,
    feedback: RemoteEvent
): Service
    local scope = Janitor.new()
    local sessions: {[Player]: Session} = {}
    local destroyed = false

    local function removeActor(session: Session)
        local actor = session.Actor
        session.Actor = nil
        if actor ~= nil then
            actor.Cast = nil
            actor.Scope.Destroy()
        end
    end

    local function addPlayer(player: Player)
        if sessions[player] ~= nil then
            return
        end
        sessions[player] = {
            Actor = nil,
            Cooldowns = Cooldowns.new(),
            Limiter = RateLimiter.new(8, 4),
        }
    end

    local function ready(player: Player, actor: Actor): boolean
        return player.Character == actor.Character
            and actor.Character:IsDescendantOf(workspace)
            and actor.Humanoid:IsDescendantOf(actor.Character)
            and actor.Root:IsDescendantOf(actor.Character)
            and actor.Humanoid.Health > 0
            and not actor.Root.Anchored
    end

    local function stun(humanoid: Humanoid, duration: number, now: number)
        if duration <= 0 then
            return
        end
        for _, session in pairs(sessions) do
            local target = session.Actor
            if target ~= nil and target.Humanoid == humanoid
                and target.Machine.Get() ~= "Dead" then
                -- Repeated stun extends the deadline without stacking tasks.
                target.Cast = nil
                target.StunUntil = math.max(target.StunUntil, now + duration)
                target.Machine.Transition("Stunned")
                return
            end
        end
    end

    local function advance(player: Player, actor: Actor, now: number)
        if actor.Humanoid.Health <= 0 then
            actor.Cast = nil
            actor.Machine.Transition("Dead")
            return
        end

        if actor.Machine.Get() == "Stunned" then
            if now >= actor.StunUntil then
                actor.Machine.Transition("Idle")
            end
            return
        end

        local cast = actor.Cast
        if cast == nil then
            return
        end

        local ability = cast.Ability
        local elapsed = now - cast.Started
        local activeEnd = ability.Windup + ability.Active
        local recoveryEnd = activeEnd + ability.Recovery

        -- A stalled server skips an expired active window instead of landing
        -- a stale hit. Each cast evaluates its hitbox at most once.
        if actor.Machine.Get() == "Windup" and elapsed >= ability.Windup then
            actor.Machine.Transition("Active")
            if elapsed < activeEnd and ready(player, actor) then
                for _, target in ipairs(Hitbox.Query(
                    player, actor.Character, actor.Root, ability
                )) do
                    if target.Health > 0 then
                        target:TakeDamage(ability.Damage)
                        if target.Health > 0 then
                            stun(target, ability.Stun, now)
                        end
                    end
                end
            end
        end

        if actor.Machine.Get() == "Active" and elapsed >= activeEnd then
            actor.Machine.Transition("Recovery")
        end
        if actor.Machine.Get() == "Recovery" and elapsed >= recoveryEnd then
            actor.Cast = nil
            actor.Machine.Transition("Idle")
        end
    end

    local function reconcile(player: Player, session: Session)
        local actor = session.Actor
        local character = player.Character

        if actor ~= nil then
            if character ~= actor.Character
                or not actor.Character:IsDescendantOf(workspace)
                or not actor.Root:IsDescendantOf(actor.Character)
                or not actor.Humanoid:IsDescendantOf(actor.Character) then
                removeActor(session)
            else
                return
            end
        end

        -- No yielding WaitForChild: incomplete characters are retried next frame.
        if character == nil or not character:IsDescendantOf(workspace) then
            return
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local root = character:FindFirstChild("HumanoidRootPart")
        if humanoid == nil or root == nil or not root:IsA("BasePart") then
            return
        end

        local actorScope = Janitor.new()
        local machine = StateMachine.new(function(state: Types.State)
            character:SetAttribute("CombatState", state)
        end)
        character:SetAttribute("CombatState", "Idle")
        local created: Actor = {
            Character = character,
            Humanoid = humanoid,
            Root = root,
            Machine = machine,
            Scope = actorScope,
            Cast = nil,
            StunUntil = 0,
        }
        session.Actor = created

        local deathConnection = humanoid.Died:Connect(function()
            created.Cast = nil
            machine.Transition("Dead")
        end)
        actorScope.Add(function()
            deathConnection:Disconnect()
        end)
        actorScope.Add(function()
            character:SetAttribute("CombatState", nil)
        end)

        if humanoid.Health <= 0 then
            machine.Transition("Dead")
        end
    end

    local function tryCast(
        player: Player,
        session: Session,
        id: string,
        now: number
    ): Result
        local ability = Abilities[id]
        if ability == nil then
            return "UnknownAbility"
        end
        local actor = session.Actor
        if actor == nil or not ready(player, actor) then
            return "NotReady"
        end
        if actor.Machine.Get() ~= "Idle" then
            return "Busy"
        end
        if session.Cooldowns.Remaining(id, now) > 0 then
            return "Cooldown"
        end
        if not actor.Machine.Transition("Windup") then
            return "Busy"
        end

        -- No yields between validation, state acquisition, and cooldown commit.
        session.Cooldowns.Start(id, ability.Cooldown, now)
        actor.Cast = {Ability = ability, Started = now}
        return "Accepted"
    end

    local requestConnection = request.OnServerEvent:Connect(function(
        player: Player, id: unknown, ...: unknown
    )
        local session = sessions[player]
        if session == nil then
            return
        end
        local now = os.clock()

        -- Charge malformed requests too. Throttled requests receive no reply.
        if not session.Limiter.Allow(now) then
            return
        end
        if select("#", ...) ~= 0
            or typeof(id) ~= "string"
            or #id > 24 then
            return
        end

        local result = tryCast(player, session, id, now)
        feedback:FireClient(player, id, result)
    end)
    scope.Add(function()
        requestConnection:Disconnect()
    end)

    local joined = Players.PlayerAdded:Connect(addPlayer)
    scope.Add(function()
        joined:Disconnect()
    end)

    local leaving = Players.PlayerRemoving:Connect(function(player)
        local session = sessions[player]
        if session ~= nil then
            removeActor(session)
            sessions[player] = nil
        end
    end)
    scope.Add(function()
        leaving:Disconnect()
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        addPlayer(player)
    end

    local heartbeat = RunService.Heartbeat:Connect(function()
        local now = os.clock()
        for player, session in pairs(sessions) do
            reconcile(player, session)
            local actor = session.Actor
            if actor ~= nil then
                advance(player, actor, now)
            end
        end
    end)
    scope.Add(function()
        heartbeat:Disconnect()
    end)

    return {
        Destroy = function()
            if destroyed then
                return
            end
            destroyed = true
            scope.Destroy()
            for player, session in pairs(sessions) do
                removeActor(session)
                sessions[player] = nil
            end
        end,
    }
end

return CombatService
