
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libapi.h>

int main(int argc, char **argv)
{
	char *endpoint		= NULL;
	enum lapi_method method = LAPI_METHOD_GET;

	if (argc < 2) {
		fprintf(stderr, "Usage: %s <endpoint> [method]\n", argv[0]);
		return 1;
	}

	endpoint = argv[1];
	if (argc > 2) {
		if (strcmp(argv[2], "GET") == 0) {
			method = LAPI_METHOD_GET;
		} else if (strcmp(argv[2], "POST") == 0) {
			method = LAPI_METHOD_POST;
		} else if (strcmp(argv[2], "PUT") == 0) {
			method = LAPI_METHOD_PUT;
		} else if (strcmp(argv[2], "DELETE") == 0) {
			method = LAPI_METHOD_DELETE;
		} else {
			fprintf(stderr, "Invalid method: %s\n", argv[2]);
			return 1;
		}
	}

	if (lapi_init() != LAPI_SUCCESS) {
		fprintf(stderr, "Failed to initialize libapi\n");

		return 1;
	}

	if (lapi_grant_access(endpoint, method) == LAPI_SUCCESS) {
		printf("Access granted\n");
	} else {
		printf("Access denied\n");
	}

	lapi_destroy();

	return 0;
}
