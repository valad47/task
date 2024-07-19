### About

This is simple task library, that let you use more than one thread.

### Usage

First of all, you should move/symlink `src/task.lua` to your luarocks package folder.

Next step, is require this library
```
local task = require("task")
```

Next step, you should wrap all your code into function, and then use `task.spawn(f)`, where `f` is function with your code.
At the end of your code, you must run `task.loop()` function, in order to all tasks work. Keep in mind, that this function creates infinity loop, that will only wnd when all tasks are done. If you want to this loop never end, simply change `task.CLOSE_WHEN_NO_JOBS` to true. If you want to integrate these loop into your own cycle, use function `task.step()` in your loop.

If you want to hold your function execution for `t` time, use `task.wait(t)`. 

If you want to create infinity loop, that will not suspend other tasks execution, simply write this:
```
while task.wait() do
    -- Your code --
end
```
It may a little slow down count of code repeating in second, but other your tasks will continue their work without troubles.

Keep in mind, that you have to call `task.wait()` in your wrapped functions, in order to other wrapped functions do their jobs in "multi-thread".