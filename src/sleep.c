#include "lua.h"
#include "lualib.h"
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

int vlm___sleep(lua_State *L) {
    usleep(luaL_checkinteger(L, 1));

    return 0;
}
