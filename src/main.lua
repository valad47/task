function printf(s, ...)
    print(string.format(s, ...))
end

local task = require("task")
task.COLOR = true
task.DEBUG = true

task.spawn(function ()
    while task.wait() do
        task.spawn(function ()
            task.wait(20)
        end)
    end
end)

task.loop()