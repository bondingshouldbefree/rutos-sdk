#include <unistd.h>
#include <sys/capability.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <lauxlib.h>
#include <lualib.h>
#include "../rootless.h"

extern const char _binary_mt76x8_lua_start[];

int main(int argc, const char* argv[]) {
	cap_value_t keep_caps[] = { CAP_NET_ADMIN };
	drop_root(keep_caps);
	set_ambient_cap(CAP_NET_ADMIN);
	lua_State *L = luaL_newstate();

	lua_newtable(L);
	for (int i = 0; i < argc; i++) {
		lua_pushstring(L, argv[i]);
		lua_rawseti(L, -2, i == 0 ? -1 : i);
	}
	lua_setglobal(L, "arg");

	luaL_openlibs(L);
	luaL_dostring(L, _binary_mt76x8_lua_start);
	lua_close(L);
}
