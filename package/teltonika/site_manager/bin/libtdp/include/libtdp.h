

#ifndef _LIBTDP_H_
#define _LIBTDP_H_

#include <ifaddrs.h>
#include <stdbool.h>
#include <time.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include <libubox/uloop.h>
#include <libubox/utils.h>
#include <libubox/avl.h>

#define LTDP_VERSION	    0x01
#define LTDP_TDP_PORT	    21114
#define LTPD_TDP_MCAST_ADDR "224.0.0.154"

typedef enum {
	LIBTDP_SUCCESS,
	LIBTDP_ERROR,
} ltdp_stat_t;

enum {
	LTDP_IFACE_CLIENT = 1,
	LTDP_IFACE_SERVER = 1 << 1,
};

enum {
	LTDP_UNICAST   = 1,
	LTDP_MULTICAST = 1 << 1,
};

enum {
	LTDP_TYPE_REQUEST  = 0x01,
	LTDP_TYPE_RESPONSE = 0x02,
	LTDP_TYPE_ANNOUNCE = 0x03, // TODO: could be used for server announcements
};

enum {
	LTDP_FLAG_MULTICAST_RESPONSE = 1 << 0,
	LTDP_FLAG_UNICAST_RESPONSE   = 1 << 1,
};

enum {
	LTDP_ATTR_ID	   = 0x01,
	LTDP_ATTR_NAME	   = 0x02,
	LTDP_ATTR_TYPE	   = 0x03,
	LTDP_ATTR_VERSION  = 0x04,
	LTDP_ATTR_IP	   = 0x05,
	LTDP_ATTR_PORT	   = 0x06,
	LTDP_ATTR_MAC	   = 0x07,
	LTDP_ATTR_MODEL	   = 0x08,
	LTDP_ATTR_FIRMWARE = 0x09,
	_LTDP_ATTR_MAX	   = 0x0A,
};

struct ltdp_hdr {
	uint8_t type;
	uint8_t version;
	uint8_t flags;
} __attribute__((packed));

struct ltdp_attr {
	uint8_t type;
	uint16_t length;
	uint8_t data[0];
} __attribute__((packed));

struct ltdp_pkt {
	struct ltdp_hdr hdr;
	// uint8_t challange[16];
	uint16_t length;
	uint8_t data[0];
} __attribute__((packed));

/* Rate limiter defaults */
#define LTDP_RATELIMIT_DEFAULT_RATE  10  /* tokens (requests) per second */
#define LTDP_RATELIMIT_DEFAULT_BURST 20  /* max burst size */
#define LTDP_RATELIMIT_CLEANUP_INTERVAL 30 /* seconds between stale entry cleanup */
#define LTDP_RATELIMIT_ENTRY_TIMEOUT 60    /* seconds before a stale entry is removed */

struct ltdp_ratelimit_entry {
	struct avl_node node;
	struct in_addr addr;
	uint32_t tokens;
	struct timespec last_refill;
};

struct ltdp_ratelimit {
	struct avl_tree tree;
	uint32_t rate;   /* tokens added per second */
	uint32_t burst;  /* max tokens (bucket size) */
	struct uloop_timeout cleanup_timer;
	bool enabled;
};

struct ltdp_iface;
typedef ltdp_stat_t (*ltdp_cb_t)(struct ltdp_iface *iface, struct sockaddr_in *from, struct ltdp_pkt *pkt);

struct ltdp_iface {
	uint8_t iface_type;
	struct list_head list;
	char *name;
	struct in_addr v4_addr;
	struct in_addr v4_netmask;
	int ifindex;
	char v4_addrs[INET_ADDRSTRLEN];
	struct sockaddr_in mcast_addr;
	char mcast_addrs[INET_ADDRSTRLEN];
	struct uloop_fd sock;
	struct uloop_timeout pending_timer;
	struct uloop_timeout t;
	ltdp_cb_t cb;
	void *priv;
	struct ltdp_ratelimit ratelimit;
};

struct ltdp_ctx {
	struct list_head ifaces;
	void *priv;
};

struct ltdp_ctx *ltdp_init(void *priv);
struct ltdp_iface *ltdp_interface_add(struct ltdp_ctx *ctx, const char *name, const char *ipaddr,
				      ltdp_cb_t cb, uint8_t iface_type);
void ldtp_iface_remove(struct ltdp_iface *iface);
ltdp_stat_t ltdp_connect(struct ltdp_ctx *ctx);
void ltdp_destroy_ctx(struct ltdp_ctx *ctx);
ltdp_stat_t ltdp_send_discover(struct ltdp_ctx *ctx, uint8_t flags);
ltdp_stat_t ltdp_pkt_add_attr(struct ltdp_pkt *pkt, size_t size, uint8_t type, uint8_t len, const void *data);
size_t ltdp_pkt_append_attr(struct ltdp_pkt **pkt, uint8_t type, uint8_t len, const void *data);
size_t ltdp_init_response_pkt(struct ltdp_pkt **pkt, uint32_t attrs);

/**
 * @brief Enable rate limiting on a TDP interface (server-side).
 *
 * Uses a per-source-IP token bucket to limit how many requests are
 * processed per second, mitigating amplification/flooding attacks.
 *
 * @param iface  The TDP interface to protect
 * @param rate   Tokens (requests) replenished per second (0 = use default)
 * @param burst  Maximum token bucket size / burst allowance  (0 = use default)
 */
void ltdp_ratelimit_enable(struct ltdp_iface *iface, uint32_t rate, uint32_t burst);

/**
 * @brief Disable and free rate limiting resources on a TDP interface.
 */
void ltdp_ratelimit_disable(struct ltdp_iface *iface);

static inline void ltdp_iface_connect(struct ltdp_iface *iface)
{
	uloop_timeout_set(&iface->t, 1);
}

static inline void ltdp_iface_connect_auto(struct ltdp_iface *iface)
{
	if (!iface->sock.registered) {
		ltdp_iface_connect(iface);
	}
}

static inline ltdp_stat_t ltdp_send_packet(int fd, struct sockaddr_in *addr, struct ltdp_pkt *pkt, size_t len)
{
	if (sendto(fd, pkt, len, 0, (struct sockaddr *)addr, sizeof(*addr)) < 0) {
		return LIBTDP_ERROR;
	}

	return LIBTDP_SUCCESS;
}

static inline ltdp_stat_t ltdp_send_mcast_packet(struct ltdp_iface *iface, struct ltdp_pkt *pkt, size_t len)
{
	return ltdp_send_packet(iface->sock.fd, &iface->mcast_addr, pkt, len);
}

static inline void ltdp_pkt_finish(struct ltdp_pkt *pkt)
{
	pkt->length = cpu_to_be16(pkt->length);
}

static inline struct ltdp_iface *ltdp_interface_add_client(struct ltdp_ctx *ctx, const char *name,
							   const char *ipaddr, ltdp_cb_t cb)
{
	return ltdp_interface_add(ctx, name, ipaddr, cb, LTDP_IFACE_CLIENT);
}

static inline struct ltdp_iface *ltdp_interface_add_server(struct ltdp_ctx *ctx, const char *name,
							   const char *ipaddr, ltdp_cb_t cb)
{
	return ltdp_interface_add(ctx, name, ipaddr, cb, LTDP_IFACE_SERVER);
}

static inline bool ltdp_iface_is_client(struct ltdp_iface *iface)
{
	return iface->iface_type == LTDP_IFACE_CLIENT;
}

static inline bool ltdp_iface_is_server(struct ltdp_iface *iface)
{
	return iface->iface_type == LTDP_IFACE_SERVER;
}

#define _ltdp_unused(p) ((void)(p))
#define _ltdp_for_each_attr(attr, pkt)                                                                       \
	for (attr = (struct ltdp_attr *)pkt->data; (uint8_t *)attr < (pkt->data + pkt->length);              \
	     attr = (struct ltdp_attr *)((uint8_t *)attr + attr->length + sizeof(struct ltdp_attr)))

#endif //_LIBTDP_H_
