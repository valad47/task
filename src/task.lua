local wait_poll = {}
local jobs = {}
local new_jobs = {}
local jobs_count = 0
local total_jobs = 0

local task = {}
    task.DEBUG = false
    task.CLOSE_WHEN_NO_JOBS = true
    task.SHOW_CURSOR = true
    task.MAX_DEBUG_ROW = 9
    task.ESCAPE_ROW = 10
    task.LOAD_SO = true
    task.SO_PREFIX = "vlm_"
    function task.__sleep() end

local color = function (s, n)
        return "\27[38;5;".. n%256 .."m"..tostring(s).."\27[0m"
end

local function debug(pos, ...)
    if not task.DEBUG then return end
    print(color(("\27[%dH".."\27[0K".."\r".."[ %.3f ]"):format(pos, os.clock()), 235), color("[ TASK ]", 111), ...)
end

local function get_address(t)
    local s = string.gsub(tostring(t), "thread: ", "")
    return tonumber(s)
end

function task.step()
    for i, v in pairs(jobs) do
        if coroutine.status(v) == "dead" then
            debug(3, "Deleting ", color(v, get_address(v)))
            jobs[i] = nil
            jobs_count = jobs_count - 1
        end
    end


    for i, v in pairs(new_jobs) do
        table.insert(jobs, v[1])
        new_jobs[i] = nil
        debug(4, color("Starting", 76), color(v[1], get_address(v[1])))
        jobs_count = jobs_count + 1
        total_jobs = total_jobs + 1
        local pass, err = coroutine.resume(table.unpack(v))
        if not pass then
            print(color("[ ERROR ]", 52), color(v[1], get_address(v[1])), err)
        end
    end

    for i, v in pairs(wait_poll) do
        if v <= os.time() then
            debug(6, color("Resuming", 35), color(i, get_address(i)))
            wait_poll[i] = nil
            local pass, err = coroutine.resume(i)
            if not pass then
                print(color("[ ERROR ]", 52), color(i, get_address(i)), err)
            end
        end
    end

    return true
end

function task.spawn(f, ...)
    if type(f) ~= "function" then
        error(color("[ERROR]", 52).." task.spawn claims only function as argument", 2)
    end

    local thread = coroutine.create(f)
    debug(2, color("Creating ", 50), color(thread, get_address(thread)))

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

    debug(5, color("Waiting ", 31), color(thread, get_address(thread)))

    coroutine.yield()
    return (os.time() - current)
end

local function min(t: {})
    local min = 1;
    for i, v in t do
       local time = os.time()
       min = if (v - time) < min  and (v - time) > 0 then v - time else min
    end

    return min
end


function task.loop()
    while true do
        task.step()

        task.__sleep(min(wait_poll) * 1000000)
        if task.CLOSE_WHEN_NO_JOBS and jobs_count <= 0 then
		    if task.DEBUG then print(`\27[{task.ESCAPE_ROW};0H`) end
            return
        end
    end
end

function task.setdebug()
	print(`\27[2J`)
	task.DEBUG = true
end

return task
