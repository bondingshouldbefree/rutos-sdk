/*
 * iwinfo - Wireless Information Library - QCAWifi Headers
 *
 *   Copyright (c) 2013 The Linux Foundation. All rights reserved.
 *   Copyright (C) 2009 Jo-Philipp Wich <xm@subsignal.org>
 *
 * The iwinfo library is free software: you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 2
 * as published by the Free Software Foundation.
 *
 * The iwinfo library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with the iwinfo library. If not, see http://www.gnu.org/licenses/.
 *
 * This file is based on: src/include/iwinfo/madwifi.h
 */

#ifndef __IWINFO_QCAWIFI_H_
#define __IWINFO_QCAWIFI_H_

#include <fcntl.h>

/* The driver is using only one "_" character in front of endianness macros
 * whereas the uClibc is using "__" */
#include <endian.h>
#if __BYTE_ORDER == __BIG_ENDIAN
#define _BYTE_ORDER _BIG_ENDIAN
#elif __BYTE_ORDER == __LITTLE_ENDIAN
#define _BYTE_ORDER _LITTLE_ENDIAN
#else
#error "__BYTE_ORDER undefined"
#endif

#include "iwinfo.h"
#include "iwinfo/utils.h"
#include <time.h>

typedef struct timespec timespec_t;

#define IEEE80211_ADDR_LEN              6       /* size of 802.11 address */
#define IEEE80211_RATE_MAXSIZE          44      /* max rates we'll handle */
#define IEEE80211_MAX_IFNAME            16
#define RRM_CAPS_LEN                    5
#define MAX_NUM_OPCLASS_SUPPORTED       64
#define HEHANDLE_CAP_PHYINFO_SIZE       3
#define IEEE80211_SEQ_SEQ_MASK          0xfff0
#define IEEE80211_SEQ_SEQ_SHIFT         4
#define IEEE80211_RATE_VAL              0x7f
#define HEHANDLE_CAP_TXRX_MCS_NSS_SIZE  3

#define LINUX_PVT_SET_VENDORPARAM       (SIOCDEVPRIVATE+0)
#define LINUX_PVT_GET_VENDORPARAM       (SIOCDEVPRIVATE+1)
#define	SIOCG80211STATS		(SIOCDEVPRIVATE+2)
/* NB: require in+out parameters so cannot use wireless extensions, yech */
#define	IEEE80211_IOCTL_GETKEY		(SIOCDEVPRIVATE+3)
#define	IEEE80211_IOCTL_GETWPAIE	(SIOCDEVPRIVATE+4)
#define	IEEE80211_IOCTL_STA_STATS	(SIOCDEVPRIVATE+5)
#define	IEEE80211_IOCTL_STA_INFO	(SIOCDEVPRIVATE+6)
#define	SIOC80211IFCREATE		(SIOCDEVPRIVATE+7)
#define	SIOC80211IFDESTROY	 	(SIOCDEVPRIVATE+8)

#define	IEEE80211_CLONE_BSSID	0x0001	/* allocate unique mac/bssid */
#define	IEEE80211_NO_STABEACONS	0x0002	/* Do not setup the station beacon timers */

struct ieee80211_clone_params {
	char icp_name[IEEE80211_MAX_IFNAME]; /* device name */
	u_int16_t icp_opmode; /* operating mode */
	u_int32_t icp_flags; /* see IEEE80211_CLONE_BSSID for e.g */
	u_int8_t icp_bssid[IEEE80211_ADDR_LEN];    /* optional mac/bssid address */
	int32_t icp_vapid; /* vap id for MAC addr req */
	u_int8_t icp_mataddr[IEEE80211_ADDR_LEN]; /* optional MAT address */
};

enum ieee80211_opmode {
	IEEE80211_M_STA         = 1,                 /* infrastructure station */
	IEEE80211_M_IBSS        = 0,                 /* IBSS (adhoc) station */
	IEEE80211_M_AHDEMO      = 3,                 /* Old lucent compatible adhoc demo */
	IEEE80211_M_HOSTAP      = 6,                 /* Software Access Point */
	IEEE80211_M_MONITOR     = 8,                 /* Monitor mode */
	IEEE80211_M_WDS         = 2,                 /* WDS link */
	IEEE80211_M_BTAMP       = 9,                 /* VAP for BT AMP */

	IEEE80211_M_P2P_GO      = 33,                /* P2P GO */
	IEEE80211_M_P2P_CLIENT  = 34,                /* P2P Client */
	IEEE80211_M_P2P_DEVICE  = 35,                /* P2P Device */


	IEEE80211_OPMODE_MAX    = IEEE80211_M_BTAMP, /* Highest numbered opmode in the list */

	IEEE80211_M_ANY         = 0xFF               /* Any of the above; used by NDIS 6.x */
};

/**
 * enum wlan_band_id - Operational wlan band id
 * @WLAN_BAND_UNSPECIFIED: Band id not specified. Default to 2GHz/5GHz band
 * @WLAN_BAND_2GHZ: Band 2.4 GHz
 * @WLAN_BAND_5GHZ: Band 5 GHz
 * @WLAN_BAND_6GHZ: Band 6 GHz
 * @WLAN_BAND_MAX:  Max supported band
 */
 enum wlan_band_id {
	WLAN_BAND_UNSPECIFIED = 0,
	WLAN_BAND_2GHZ = 1,
	WLAN_BAND_5GHZ = 2,
	WLAN_BAND_6GHZ = 3,
	/* Add new band definitions here */
	WLAN_BAND_MAX,
};

 /*
  * Station information block; the mac address is used
  * to retrieve other data like stats, unicast key, etc.
  */
 struct ieee80211req_sta_info {
   u_int16_t isi_len;     /* length (mult of 4) */
   u_int16_t isi_freq;    /* MHz */
   int32_t isi_nf;        /* noise floor */
   u_int16_t isi_ieee;    /* IEEE channel number */
   u_int32_t awake_time;  /* time is active mode */
   u_int32_t ps_time;     /* time in power save mode */
   u_int64_t isi_flags;   /* channel flags */
   u_int16_t isi_state;   /* state flags */
   u_int8_t isi_authmode; /* authentication algorithm */
   int8_t isi_rssi;
   int8_t isi_min_rssi;
   int8_t isi_max_rssi;
   u_int16_t isi_capinfo;    /* capabilities */
   u_int16_t isi_pwrcapinfo; /* power capabilities */
   u_int8_t isi_athflags;    /* Atheros capabilities */
   u_int8_t isi_erp;         /* ERP element */
   u_int8_t isi_ps;          /* psmode */
   u_int8_t isi_macaddr[IEEE80211_ADDR_LEN];
   u_int8_t isi_nrates;
   /* negotiated rates */
   u_int8_t isi_rates[IEEE80211_RATE_MAXSIZE];
   u_int8_t isi_txrate;      /* index to isi_rates[] */
   u_int32_t isi_txratekbps; /* tx rate in Kbps, for 11n */
   u_int16_t isi_ie_len;     /* IE length */
   u_int16_t isi_associd;    /* assoc response */
   u_int16_t isi_txpower;    /* current tx power */
   u_int16_t isi_vlan;       /* vlan tag */
   u_int16_t isi_txseqs[17]; /* seq to be transmitted */
   u_int16_t isi_rxseqs[17]; /* seq previous for qos frames*/
   u_int16_t isi_inact;      /* inactivity timer */
   u_int8_t isi_uapsd;       /* UAPSD queues */
   u_int8_t isi_opmode;      /* sta operating mode */
   u_int8_t isi_cipher;
   u_int32_t isi_assoc_time; /* sta association time */
   timespec_t isi_tr069_assoc_time; /* sta association time in timespec format */

   u_int16_t isi_htcap;      /* HT capabilities */
   u_int32_t isi_rxratekbps; /* rx rate in Kbps */

   u_int32_t isi_maxrate_per_client; /* Max rate per client */
   u_int16_t isi_stamode;            /* Wireless mode for connected sta */
   u_int32_t isi_ext_cap;            /* Extended capabilities */
   u_int32_t isi_ext_cap2;           /* Extended capabilities 2 */
   u_int32_t isi_ext_cap3;           /* Extended capabilities 3 */
   u_int32_t isi_ext_cap4;           /* Extended capabilities 4 */
   u_int8_t isi_nss;                 /* number of tx and rx chains */
   u_int8_t isi_supp_nss;            /* number of tx and rx chains supported */
   u_int8_t isi_is_256qam;           /* 256 QAM support */
   u_int8_t isi_operating_bands : 2; /* Operating bands */
#if ATH_SUPPORT_EXT_STAT
   u_int8_t isi_chwidth; /* communication band width */
   u_int32_t isi_vhtcap; /* VHT capabilities */
#endif
#if ATH_EXTRA_RATE_INFO_STA
   u_int8_t isi_tx_rate_mcs;
   u_int8_t isi_tx_rate_flags;
   u_int8_t isi_rx_rate_mcs;
   u_int8_t isi_rx_rate_flags;
#endif
   u_int8_t isi_rrm_caps[RRM_CAPS_LEN]; /* RRM capabilities */
   u_int8_t isi_curr_op_class;
   u_int8_t isi_num_of_supp_class;
   u_int8_t isi_supp_class[MAX_NUM_OPCLASS_SUPPORTED];
   u_int8_t isi_nr_channels;
   u_int8_t isi_first_channel;
   u_int16_t isi_curr_mode;
   u_int8_t isi_beacon_measurement_support;
   enum wlan_band_id isi_band; /* band info: 2G,5G,6G */
   u_int8_t isi_is_he;
   u_int16_t isi_hecap_rxmcsnssmap[HEHANDLE_CAP_TXRX_MCS_NSS_SIZE];
   u_int16_t isi_hecap_txmcsnssmap[HEHANDLE_CAP_TXRX_MCS_NSS_SIZE];
   u_int32_t isi_hecap_phyinfo[HEHANDLE_CAP_PHYINFO_SIZE];
   u_int8_t isi_he_mu_capable;
#if WLAN_FEATURE_11BE
   u_int8_t isi_is_eht;
   uint32_t isi_ehtcap_rxmcsnssmap[EHTHANDLE_CAP_TXRX_MCS_NSS_SIZE];
   uint32_t isi_ehtcap_txmcsnssmap[EHTHANDLE_CAP_TXRX_MCS_NSS_SIZE];
   u_int32_t isi_ehtcap_phyinfo[EHTHANDLE_CAP_PHYINFO_SIZE];
#endif /* WLAN_FEATURE_11BE */
#if WLAN_FEATURE_11BE_MLO
   u_int8_t isi_is_mlo;
   u_int8_t isi_mldaddr[IEEE80211_ADDR_LEN];
   u_int8_t isi_num_links;
   u_int8_t isi_is_emlsr;
   u_int8_t isi_is_emlmr;
   u_int8_t isi_is_str;
   struct mlo_link_peer_info isi_link_info[IEEE80211_MAX_MLD_LINKS];
#endif /* WLAN_FEATURE_11BE_MLO */
};

#endif
