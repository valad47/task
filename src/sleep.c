#include "lua.h"
#include "lualib.h"
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <sys/time.h>
#include <stdlib.h>
#include <signal.h>

int vlm___sleep(lua_State *L) {
    double time = luaL_checknumber(L, 1);
    usleep((useconds_t)(time*1000000));

    return 0;
}

int vlm___time(lua_State *L) {
    struct timeval tv;

    gettimeofday(&tv,NULL);
    lua_pushnumber(L, ((double)tv.tv_sec)+((double)tv.tv_usec/1000000));
    return 1;
}

int setsig = 0;
int vlm_truethread(lua_State *L) {
    if(!setsig) {
        setsig = 1;
        signal(SIGCHLD, SIG_IGN);
    }
    lua_State *NL = lua_newthread(L);
    lua_pop(L, 1);
    lua_xmove(L, NL, 1);

    pid_t pid = fork();
    if(pid != 0)
        return 0;

    if(lua_resume(NL, 0, 0) != 0) {
        printf("[TRUETHREAD ERROR]: %s", lua_tostring(NL, -1));
    }
    exit(0);
}
