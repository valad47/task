#include "lua.h"
#include "lualib.h"
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

int vlm___sleep(lua_State *L) {
    int time = luaL_checkinteger(L, 1);
    usleep((time < 1000000)?time:1000000);

    return 0;
}
