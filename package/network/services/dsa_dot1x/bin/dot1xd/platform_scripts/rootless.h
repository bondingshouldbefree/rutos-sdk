#ifndef _H_DOT1X_ROOTLESS
#define _H_DOT1X_ROOTLESS
#include <sys/capability.h>
#include <sys/prctl.h>
#include <pwd.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <grp.h>

#define DOT1X_SERVER_USER "dot1x_server"

static inline void set_ambient_cap(int cap)
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
		perror("Cannot raise capability");
		exit(1);
	}
}

static inline void drop_root(cap_value_t *keep_caps)
{
	if (getuid() != 0)
		return;
	int caps_ok = 0;
	prctl(PR_SET_KEEPCAPS, 1);
	struct passwd *pwd = getpwnam(DOT1X_SERVER_USER);
	if (!pwd) {
		fprintf(stderr, "Failed to find user '%s'\n", DOT1X_SERVER_USER);
		exit(EXIT_FAILURE);
	}
	if(initgroups(DOT1X_SERVER_USER, pwd->pw_gid) != 0) {
		fprintf(stderr, "Failed to init user groups for user %s gid %i\n", DOT1X_SERVER_USER, pwd->pw_gid);
		exit(EXIT_FAILURE);
	}
	if (setgid(pwd->pw_gid) != 0 || setuid(pwd->pw_uid) != 0) {
		fprintf(stderr, "Failed to setgid(%i)+setuid(%i) to user '%s'\n",
			pwd->pw_gid, pwd->pw_uid, DOT1X_SERVER_USER);
		exit(EXIT_FAILURE);
	}
	cap_t caps = cap_init();
	if (!caps) {
		caps_ok = 1;
		goto end;
	}
	if (cap_clear(caps) == -1) {
		caps_ok = 2;
		goto end;
	}
	if (cap_set_flag(caps, CAP_PERMITTED, 1, keep_caps, CAP_SET) == -1 ||
	    cap_set_flag(caps, CAP_INHERITABLE, 1, keep_caps, CAP_SET) == -1) {
		caps_ok = 3;
		goto end;
	}
	if (cap_set_proc(caps) < 0) {
		caps_ok = 4;
		goto end;
	}
end:
	if (caps)
		cap_free(caps);
	if (!caps_ok)
		return;
	fprintf(stderr,
		"There was a fatal error in capability setup step %i: %i\n",
		caps_ok, errno);
	exit(EXIT_FAILURE);
}
#endif
