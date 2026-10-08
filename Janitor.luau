--!strict
export type Janitor = {
    Add: (() -> ()) -> (),
    Destroy: () -> (),
}

local Janitor = {}

function Janitor.new(): Janitor
    local tasks: {() -> ()} = {}
    local destroyed = false

    local function clean(callback: () -> ())
        local ok, problem = pcall(callback)
        if not ok then
            warn("[Combat cleanup]", problem)
        end
    end

    return {
        Add = function(callback: () -> ())
            if destroyed then
                clean(callback)
            else
                table.insert(tasks, callback)
            end
        end,

        Destroy = function()
            if destroyed then
                return
            end
            destroyed = true
            -- Reverse order allows dependent resources to be removed first.
            for index = #tasks, 1, -1 do
                clean(tasks[index])
            end
            table.clear(tasks)
        end,
    }
end

return Janitor
