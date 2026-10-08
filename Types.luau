--!strict
export type State =
    "Idle" | "Windup" | "Active" | "Recovery" | "Stunned" | "Dead"

export type Ability = {
    Id: string,
    Cooldown: number,
    Windup: number,
    Active: number,
    Recovery: number,
    Damage: number,
    Stun: number,
    Reach: number,
    Width: number,
    MaxTargets: number,
}

export type Result =
    "Accepted" | "UnknownAbility" | "NotReady" | "Busy" | "Cooldown"

return {}
