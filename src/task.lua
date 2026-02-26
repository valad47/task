local wait_poll = {}
local jobs = {}
local new_jobs = {}
local defer_list = {}
local delay_args = {}
local jobs_count = 0
local total_jobs = 0
local steps = 0

local pprint = require_shared("pprint")

local task = {}
    task.DEBUG = false
    task.CLOSE_WHEN_NO_JOBS = true
    task.SHOW_CURSOR = true
    task.MAX_DEBUG_ROW = 9
    task.ESCAPE_ROW = 10
    task.LOAD_SO = true
    task.SO_PREFIX = "vlm_"
    function task.__sleep() end
    function task.__time() end

local color = require_shared("color")

local function debug(pos, ...)
    if not task.DEBUG then return end
    print(color(("\27[%dH".."\27[0K".."\r".."[ %.3f ]"):format(pos, os.clock()), 235), color("[ TASK ]", 111), ...)
end

local function get_address(t)
    local s = string.gsub(tostring(t), "thread: ", "")
    return tonumber(s)
end

function task.step()
    for i, v in jobs do
       if coroutine.status(v) == "dead" then
            if defer_list[v] then
                table.insert(new_jobs, defer_list[v])
                defer_list[v] = nil
            end
            debug(3, "Deleting ", color(v, get_address(v)))
            table.remove(jobs, i)
            jobs_count = jobs_count - 1
        end
    end

    for i, v in new_jobs do
        table.insert(jobs, v[1])
        table.remove(new_jobs, i)
        debug(4, color("Starting", 76), color(v[1], get_address(v[1])))
        jobs_count = jobs_count + 1
        total_jobs = total_jobs + 1
        local pass, err = coroutine.resume(table.unpack(v))
        if not pass then
            print(color("[ ERROR ]", 52), color(v[1], get_address(v[1])), err)
        end
    end

    local time = task.__time()
    for i, v in wait_poll do
        if v <= time then
            debug(6, color("Resuming", 35), color(i, get_address(i)))
            wait_poll[i] = nil

            local pass, err

            if delay_args[i] then
                pass, err = coroutine.resume(i, table.unpack(delay_args[i]))
                delay_args[i] = nil
            else
                pass, err = coroutine.resume(i)
            end

            if not pass then
                print(color("[ ERROR ]", 52), color(i, get_address(i)), err)
            end
            time = task.__time()
        end
    end
    steps += 1
    debug(1, `Steps: {steps}\tJobs: {jobs_count}\tTotal jobs: {total_jobs}`)
    return true
end

local function toThread(functionOrThread)
    return if type(functionOrThread) == "function" then coroutine.create(functionOrThread) else functionOrThread
end

function task.spawn(functionOrThread, ...)
    local thread = toThread(functionOrThread)

    debug(2, color("Creating ", 50), color(thread, get_address(thread)))

    table.insert(new_jobs, {thread, ...})
    return thread
end

function task.cancel(thread)
    coroutine.close(thread)
end

function task.delay(duration, functionOrThread, ...)
    local current = task.__time()
    local thread = toThread(functionOrThread)

    table.insert(jobs, thread)

    jobs_count = jobs_count + 1
    total_jobs = total_jobs + 1

    wait_poll[thread] = if duration then duration+current else current
    delay_args[thread] = {...}

    return thread
end

function task.defer(functionOrThread, ...)
    local thread = coroutine.running()
    local newThread = toThread(functionOrThread)

    if not table.find(jobs, thread) then
        error("[ERROR] You cannot use \"defer\" function outside of task.spawn() thread.", 2)
    end

    defer_list[thread] = {newThread, ...}

    return newThread
end

function task.wait(duration)
    local current = task.__time()
    local thread = coroutine.running()

    if not table.find(jobs, thread) then
        error("[ERROR] You cannot use \"wait\" function outside of task.spawn() thread.", 2)
    end

    wait_poll[thread] = if duration then duration+current else current

    debug(5, color("Waiting ", 31), color(thread, get_address(thread)))

    coroutine.yield()
    return (task.__time() - current)
end

function task.__closest_time()
    local min = 0;
    local time = task.__time()
    for i, v in wait_poll do
       min = if (v - time) < min  and (v - time) > 0 then v - time else min
    end

    return min
end

function task.loop()
    while true do
        task.step()

        local closest_time = task.__closest_time()
        if closest_time > 0 then task.__sleep(closest_time) end
        if task.CLOSE_WHEN_NO_JOBS and jobs_count <= 0 then
            if task.DEBUG then print(`\27[{task.ESCAPE_ROW};0H`) end
            return
        end
    end
end

function task.truethread() end

function task.setdebug()
	print(`\27[2J`)
	task.DEBUG = true
end

return task
