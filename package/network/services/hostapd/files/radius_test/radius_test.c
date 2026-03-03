/*
 * Example application using RADIUS client as a library
 * Copyright (c) 2007, Jouni Malinen <j@w1.fi>
 *
 * This software may be distributed under the terms of the BSD license.
 * See README for more details.
 */

#include "includes.h"

#include <errno.h>
#include <getopt.h>
#include "common.h"
#include "eloop.h"
#include "radius/radius.h"
#include "radius/radius_client.h"
#include <string.h>

struct radius_ctx {
	struct radius_client_data *radius;
	struct hostapd_radius_servers conf;
	struct in_addr own_ip_addr;
	const char *username;
	const char *password;
};

static RadiusRxResult receive_auth(struct radius_msg *msg, struct radius_msg *req, const u8 *shared_secret,
				   size_t shared_secret_len, void *data)
{
	exit(0);
}

static void request_timeout(void *eloop_ctx, void *timeout_ctx)
{
	printf("Timed out\n");
	exit(1);
}

static void send_message(void *eloop_ctx, void *timeout_ctx)
{
	struct radius_ctx *ctx = eloop_ctx;
	struct radius_msg *msg;

	msg = radius_msg_new(RADIUS_CODE_ACCESS_REQUEST, 0);
	if (msg == NULL) {
		printf("Could not create RADIUS packet\n");
		exit(-1);
	}

	radius_msg_make_authenticator(msg);

	if (!radius_msg_add_attr(msg, RADIUS_ATTR_USER_NAME, (u8 *)ctx->username, strlen(ctx->username))) {
		printf("Could not add User-Name attribute\n");
		exit(-1);
	}

	if (!radius_msg_add_attr(msg, RADIUS_ATTR_NAS_IP_ADDRESS, (u8 *)&ctx->own_ip_addr, 4)) {
		printf("Could not add NAS-IP-Address attribute\n");
		exit(-1);
	}

	if (!radius_msg_add_attr_user_password(msg, (u8 *)ctx->password, strlen(ctx->password),
					       ctx->conf.auth_server->shared_secret,
					       ctx->conf.auth_server->shared_secret_len)) {
		printf("Could not add User-Password attribute\n");
		exit(-1);
	}

	if (radius_client_send(ctx->radius, msg, RADIUS_AUTH, NULL) < 0)
		radius_msg_free(msg);
}

void print_help(char *program_name)
{
	printf("Usage: %s [OPTIONS]\n", program_name);
	printf("Options:\n");
	printf("    -a, --address   ADDRESS specify the server IPv4 or IPv6 address (required) \n");
	printf("    -s, --secret    SECRET specify the server shared secret (required) \n");
	printf("    -u, --username  USERNAME specify the user name (required) \n");
	printf("    -p, --password  PASSWORD specify the user password (required) \n");
	printf("    -t, --timeout   TIMEOUT specify the request timeout in seconds (required) \n");
	printf("    -o, --port PORT specify the server port (required) \n");
	printf("    -h, --help      Display this help message\n");
	exit(EXIT_SUCCESS);
}

int main(int argc, char *argv[])
{
	long port = -1;

	char *hostname	    = NULL;
	char *shared_secret = NULL;
	char *username	    = NULL;
	char *password	    = NULL;
	long timeout	    = -1;
	int options_mask    = 0b000000;

	struct option long_options[] = { { "address", 1, 0, 'a' },  { "secret", 1, 0, 's' },
					 { "username", 1, 0, 'u' }, { "password", 1, 0, 'p' },
					 { "timeout", 1, 0, 't' },  { "port", 1, 0, 'o' },
					 { "help", 0, 0, 'h' },	    { 0, 0, 0, 0 } };
	int opt;
	int option_index = 0;
	char *endptr;
	while ((opt = getopt_long_only(argc, argv, "a:s:u:p:t:o:", long_options, &option_index)) != -1) {
		switch (opt) {
		case 'a':
			hostname = optarg;
			options_mask |= 1 << 0;
			if (strlen(optarg) > 39) {
				printf("Maximum accepted address length is 39 bytes\n");
				exit(1);
			}
			break;
		case 's':
			shared_secret = optarg;
			options_mask |= 1 << 1;
			if (strlen(optarg) > 256) {
				printf("Maximum accepted secret length is 256 bytes\n");
				return 1;
			}
			break;
		case 'u':
			username = optarg;
			options_mask |= 1 << 2;
			if (strlen(optarg) > 253) {
				printf("Maximum accepted username length is 253 bytes\n");
				exit(1);
			}
			break;
		case 'p':
			password = optarg;
			options_mask |= 1 << 3;
			if (strlen(optarg) > 112) {
				printf("Maximum accepted password length is 112 bytes\n");
				exit(1);
			}
			break;
		case 't':
			errno	= 0;
			timeout = strtol(optarg, &endptr, 10);
			options_mask |= 1 << 4;
			if (errno || *endptr != '\0') {
				printf("Invalid timeout: %s\n", optarg);
				exit(1);
			}
			if (timeout < 1 || timeout > 120) {
				printf("Invalid timeout: %li. Timeout range is 1 to 120 seconds\n", timeout);
				exit(1);
			}
			break;
		case 'o':
			errno = 0;
			port  = strtol(optarg, &endptr, 10);
			options_mask |= 1 << 5;
			if (errno || *endptr != '\0') {
				printf("Invalid port number: %s\n", optarg);
				exit(1);
			}
			if (port < 1 || port > 65535) {
				printf("Invalid port: %li. Port range is 1 to 65535\n", port);
				exit(1);
			}
			break;
		case 'h':
		default:
			print_help(argv[0]);
			exit(1);
		}
	}

	if (options_mask != 0b111111) {
		print_help(argv[0]);
		exit(0);
	}

	struct radius_ctx ctx;
	struct hostapd_radius_server *srv;

	if (os_program_init())
		return -1;

	os_memset(&ctx, 0, sizeof(ctx));
	inet_aton("127.0.0.1", &ctx.own_ip_addr);

	if (eloop_init()) {
		printf("Failed to initialize event loop\n");
		return -1;
	}

	srv = os_zalloc(sizeof(*srv));
	if (srv == NULL)
		return -1;

	srv->addr.af = AF_INET;
	srv->port    = port;

	if (hostapd_parse_ip_addr(hostname, &srv->addr) < 0) {
		printf("Failed to parse IP address\n");
		exit(-1);
	}

	srv->shared_secret     = (u8 *)os_strdup(shared_secret);
	srv->shared_secret_len = strlen(shared_secret);

	ctx.conf.auth_server = ctx.conf.auth_servers = srv;
	ctx.conf.num_auth_servers		     = 1;
	ctx.conf.msg_dumps			     = 1;
	ctx.password				     = password;
	ctx.username				     = username;

	ctx.radius = radius_client_init(&ctx, &ctx.conf);
	if (ctx.radius == NULL) {
		printf("Failed to initialize RADIUS client\n");
		exit(-1);
	}

	if (radius_client_register(ctx.radius, RADIUS_AUTH, receive_auth, &ctx) < 0) {
		printf("Failed to register RADIUS authentication handler\n");
		exit(-1);
	}

	eloop_register_timeout(0, 0, send_message, &ctx, NULL);
	eloop_register_timeout(timeout, 0, request_timeout, &ctx, NULL);
	eloop_run();

	return 0;
}
