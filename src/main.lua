function printf(s, ...)
    print(string.format(s, ...))
end

task = require("task")

task.spawn(function()
    while true do
        printf("Actual wait time: %.5f", task.wait(1))
    end
end)

task.loop()