#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/prctl.h>
#include <sys/capability.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <lauxlib.h>
#include <lualib.h>

extern const char _binary_mt76x8_lua_start[];

static void set_ambient_cap(int cap)
{
	int rc;
	cap_t caps = cap_get_proc();
	if (caps == NULL) {
		perror("cap_get_proc failed");
		exit(2);
	}

	if (cap_set_flag(caps, CAP_INHERITABLE, 1, &cap, CAP_SET) == -1) {
		perror("cap_set_flag failed");
		cap_free(caps);
		exit(2);
	}

	if (cap_set_proc(caps) == -1) {
		perror("cap_set_proc failed");
		cap_free(caps);
		exit(2);
	}

	cap_free(caps);

	if (prctl(PR_CAP_AMBIENT, PR_CAP_AMBIENT_RAISE, cap, 0, 0)) {
		perror("Cannot set cap");
		exit(1);
	}
}

int main(int argc, const char* argv[]) {
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
