local wait_poll = {}
local jobs = {}
local new_jobs = {}
local jobs_count = 0

local task = {}
    task.DEBUG = false
    task.CLOSE_WHEN_NO_JOBS = true

local function debug(...)
    if not task.DEBUG then return end
    print(("[ %.3f ]"):format(os.clock()), ...)
end

function task.step()
    for i, v in pairs(jobs) do
        if coroutine.status(v) == "dead" then
            debug("Deleting ", v)
            jobs[i] = nil
            jobs_count = jobs_count - 1
        end
    end

    for i, v in pairs(new_jobs) do
        table.insert(jobs, v[1])
        new_jobs[i] = nil
        debug("Starting ", v[1])
        coroutine.resume(table.unpack(v))
    end

    for i, v in pairs(wait_poll) do
        if v <= os.time() then
            if coroutine.status(i) == "dead" then
                print("Failed to resume ", i, " because it's dead. Please check your code, it's have an error")
                wait_poll[i] = nil
                goto continue
            end
            debug("Resuming", i)
            wait_poll[i] = nil
            coroutine.resume(i)
        end
        ::continue::
    end

    return true
end

function task.spawn(f, ...)
    if type(f) ~= "function" then
        error("[ERROR] task.spawn claims only function as argument", 2)
    end

    local thread = coroutine.create(f)
    debug("Creating ", thread)

    table.insert(new_jobs, {thread, ...})
end

function task.wait(time)
    local current = os.time()
    local thread, main = coroutine.running()

    if main then
        error("[ERROR] You cannot use \"wait\" function outside of task.spawn() thread.", 2)
    end

    local function stupid_lua_is_not_like_luau()
        if time then
            return time + current
        else
            return current
        end
    end

    wait_poll[thread] = stupid_lua_is_not_like_luau()
    
    debug("Waiting ", thread)
    
    coroutine.yield()
    return (os.time() - current)
end


function task.loop()
    while true do
        task.step()

        if task.CLOSE_WHEN_NO_JOBS and jobs_count <= 0 then
            return
        end
    end
end

return task
