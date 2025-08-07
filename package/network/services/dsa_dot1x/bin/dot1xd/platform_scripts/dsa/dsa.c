#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <sys/prctl.h>
#include <sys/capability.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <errno.h>
#include <fcntl.h>
#include <uci.h>
#define STATUS_DIR "/tmp/run/dot1x_server/state"

const char* usage = "Usage:\n"
"	toggle_controlled_port [port] [true/false]  set port 802.1x authorized state\n"
"	assign_vlan [port] [vid]                    move port to vlan\n"
"	get_port_state [port]                       get port 802.1x authorized state\n"
"	teardown_port [port]                        disable 802.1x on this port and clean up\n";

void err_usage() {
	printf("%s\n", usage);
	exit(1);
}

struct action {
	const char* name;
	int arg_count;
	int allow_more_args;
	int (*handler)(const char* args[]);
};

int check_port(const char* port) {
	char port_path[256] = {0};
	snprintf(port_path, sizeof(port_path), "/sys/class/net/%s", port);
	if (access(port_path, F_OK)) {
		printf("Device \"%s\" does not exist\n", port);
		exit(1);
	}
	return 0;
}

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

int exec_wrapper(const char* path, const char* args[]) {
	int pid = fork();
	if (pid == 0) {
		int null_out = open("/dev/null", O_WRONLY);
		dup2(null_out, STDOUT_FILENO);
		dup2(null_out, STDERR_FILENO);
		execv(path, (char* const*)args);
		perror("execv");
		exit(1);
	}
	int stat;
	waitpid(pid, &stat, 0);
	return stat;
}

int check_port_block_status(const char* port) {
	char port_status_path[256] = {0};
	snprintf(port_status_path, sizeof(port_status_path), STATUS_DIR"/%s", port);
	return !access(port_status_path, F_OK);
}

void update_port_block_status(const char* port, int blocked) {
	char port_status_path[256] = {0};
	snprintf(port_status_path, sizeof(port_status_path), STATUS_DIR"/%s", port);
	if (mkdir(STATUS_DIR, 0755) && errno != EEXIST) {
		perror("mkdir status dir");
		exit(1);
	}
	if (blocked) {
		int fd = open(port_status_path, O_WRONLY | O_CREAT, 0644);
		close(fd);
	}
	else {
		unlink(port_status_path);
	}
}

int toggle_controlled_port(const char* args[]) {
	int isolate = 0;
	char dsa_isolate_path[256] = {0};
	FILE *isolate_file = NULL;
	check_port(args[0]);
	set_ambient_cap(CAP_NET_ADMIN);

	if (strcmp(args[1], "true") == 0) {
		if (check_port_block_status(args[0])) {
			printf("Port %s is already locked\n", args[0]);
			return 0;
		}
		exec_wrapper("/sbin/tc", (const char*[]) {"tc", "qdisc",  "add", "dev", args[0], "clsact", NULL});
		exec_wrapper("/sbin/tc", (const char*[]) {"tc", "filter", "add", "dev", args[0], "egress",  "prio", "2", "handle", "2", "matchall", "action", "drop", NULL});
		exec_wrapper("/sbin/tc", (const char*[]) {"tc", "filter", "add", "dev", args[0], "egress",  "prio", "1", "handle", "1", "protocol", "0x888e", "matchall", "action", "pass", NULL});
		exec_wrapper("/sbin/tc", (const char*[]) {"tc", "filter", "add", "dev", args[0], "ingress", "prio", "3", "handle", "3", "matchall", "action", "drop", NULL});
		exec_wrapper("/sbin/tc", (const char*[]) {"tc", "filter", "add", "dev", args[0], "ingress", "prio", "2", "handle", "2", "protocol", "0x888e", "matchall", "action", "pass", NULL});
		exec_wrapper("/sbin/tc", (const char*[]) {"tc", "filter", "add", "dev", args[0], "ingress", "prio", "1", "handle", "1", "protocol", "802.1Q", "flower", "vlan_ethtype", "0x888e", "action", "pass", NULL});
		isolate = 1;
	} else if (strcmp(args[1], "false") == 0) {
		if (!check_port_block_status(args[0])) {
			printf("Port %s is already unlocked\n", args[0]);
			return 0;
		}
		exec_wrapper("/sbin/tc", (const char*[]) {"tc", "filter", "del", "dev", args[0], "egress",  "prio", "1", "handle", "1", "matchall", NULL});
		exec_wrapper("/sbin/tc", (const char*[]) {"tc", "filter", "del", "dev", args[0], "egress",  "prio", "2", "handle", "2", "matchall", NULL});
		exec_wrapper("/sbin/tc", (const char*[]) {"tc", "filter", "del", "dev", args[0], "ingress", "prio", "1", "handle", "1", "matchall", NULL});
		exec_wrapper("/sbin/tc", (const char*[]) {"tc", "filter", "del", "dev", args[0], "ingress", "prio", "2", "handle", "2", "matchall", NULL});
		exec_wrapper("/sbin/tc", (const char*[]) {"tc", "filter", "del", "dev", args[0], "ingress", "prio", "3", "handle", "3", "matchall", NULL});
		exec_wrapper("/sbin/tc", (const char*[]) {"tc", "qdisc",  "del", "dev", args[0], "clsact", NULL});
		isolate = 0;
	} else {
		err_usage();
	}

	update_port_block_status(args[0], isolate);
	snprintf(dsa_isolate_path, sizeof(dsa_isolate_path), "/sys/class/net/%s/dsa_port/isolation", args[0]);
	isolate_file = fopen(dsa_isolate_path, "w");
	if (!isolate_file) return 0;
	fprintf(isolate_file, "%i\n", isolate);
	fclose(isolate_file);
	return 0;
}

int get_port_state(const char* args[]) {
	check_port(args[0]);
	if (check_port_block_status(args[0]))
		printf("UN");
	printf("AUTHORIZED\n");
	return 0;
}

int assign_uci_vlan(const char* port_name, const char* vlan_id)
{
	struct uci_context* uci = uci_alloc_context();
	struct uci_package *package;
	if (uci == NULL) {
		fprintf(stderr, "Failed to allocate UCI context\n");
		return 0;
	}

	if (uci_load(uci, "network", &package) != UCI_OK) {
		fprintf(stderr, "Failed to load network UCI package\n");
		return 0;
	}
	
	struct uci_element *e, *e2;
	char uci_lookup[256] = {0};
	struct uci_ptr ptr = {0};

	int vlan_found = 0;
	uci_foreach_element(&package->sections, e) {
		struct uci_section *s = uci_to_section(e);
		if (strcmp(s->type, "bridge-vlan") != 0)
			continue;
		// remove $port and $port:u from all vlans
		snprintf(uci_lookup, sizeof(uci_lookup), "network.%s.ports=%s", s->e.name, port_name);
		if (uci_lookup_ptr(uci, &ptr, uci_lookup, true) == UCI_OK)
			uci_del_list(uci, &ptr);
		snprintf(uci_lookup, sizeof(uci_lookup), "network.%s.ports=%s:u", s->e.name, port_name);
		if (uci_lookup_ptr(uci, &ptr, uci_lookup, true) == UCI_OK)
			uci_del_list(uci, &ptr);

		uci_foreach_element(&s->options, e2) {
			struct uci_option *o = uci_to_option(e2);
			if (o->type != UCI_TYPE_STRING || strcmp(o->e.name, "vlan") != 0) 
				continue;
			if (strcmp(o->v.string, vlan_id) != 0) 
				continue;
			vlan_found = 1;
			// add $port:u to desired vlan
			uci_add_list(uci, &ptr);
		}
	}
	uci_commit(uci, &package, false);
	uci_unload(uci, package);
	uci_free_context(uci);
	return vlan_found;
}

int assign_vlan(const char* args[]) {
	long target_vid = strtol(args[1], NULL, 10);
	int vlan_found = 0;
	check_port(args[0]);
	int vlan_exists = assign_uci_vlan(args[0], args[1]);
	setvbuf(stdout, NULL, _IONBF, 0);
	set_ambient_cap(CAP_NET_ADMIN);
	exec_wrapper("/usr/sbin/bridge", (const char*[]) {"bridge", "vlan", "del", "dev", args[0], "vid", "1-4094", NULL});
	if (!vlan_exists) {
		fprintf(stderr, "vlan %s does not exist! removed port from all vlans\n", args[1]);
		return 0;
	}
	exec_wrapper("/usr/sbin/bridge", (const char*[]) {"bridge", "vlan", "add", "dev", args[0], "vid", args[1], "pvid", "egress", "untagged", NULL});
	return 0;
}

int teardown_port(const char* args[]) {
	printf("teardown_port %s\n", args[0]);
	const char* argv[] = {args[0], "false"};
	toggle_controlled_port(argv);
	return 0;
}

int sync_port(const char* args[]) {
	return 0;
}

#define ACTION_COUNT 5
const struct action actions[ACTION_COUNT] = {
	{ "toggle_controlled_port", 2, 1, toggle_controlled_port },
	{ "get_port_state", 1, 0, get_port_state },
	{ "assign_vlan", 2, 0, assign_vlan },
	{ "teardown_port", 1, 0, teardown_port },
	{ "sync", 0, 0, sync_port },
};

int main(int argc, const char* argv[]) {
	if (argc < 2) err_usage();
	for (int i = 0; i < ACTION_COUNT; i++) {
		const struct action *act = actions+i;
		if (strcmp(argv[1], act->name) == 0) {
			if (argc < act->arg_count + 2) err_usage();
			if (argc > act->arg_count + 2 && !act->allow_more_args) err_usage();
			return act->handler(argv + 2);
		}
	}
	err_usage();
}

