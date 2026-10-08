--!strict
export type Limiter = {
    Allow: (number) -> boolean,
}

local RateLimiter = {}

function RateLimiter.new(capacity: number, refill: number): Limiter
    assert(capacity > 0 and refill > 0)
    local tokens = capacity
    local last: number? = nil

    return {
        Allow = function(now: number): boolean
            local previous = last
            if previous ~= nil then
                tokens = math.min(capacity,
                    tokens + math.max(0, now - previous) * refill)
            end
            last = now
            if tokens < 1 then
                return false
            end
            tokens -= 1
            return true
        end,
    }
end

return RateLimiter
