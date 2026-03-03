/*
 * iwinfo - Wireless Information Library - QCAWifi Backend
 *
 *   Copyright (c) 2013 The Linux Foundation. All rights reserved.
 *   Copyright (C) 2009-2010 Jo-Philipp Wich <xm@subsignal.org>
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
 * This file is based on: src/iwinfo_madwifi.c
 */

#include "iwinfo_wext.h"
#include "api/qcawifi.h"

#include "iwinfo_nl80211.h"

#include <string.h>

/*
 * Madwifi ISO 3166 to Country/Region Code mapping.
 */

static struct ISO3166_to_CCode
{
	u_int16_t iso3166;
	u_int16_t ccode;
} CountryCodes[] = {
	{ 0x3030 /* 00 */,   0 }, /* World */
	{ 0x4145 /* AE */, 784 }, /* U.A.E. */
	{ 0x414C /* AL */,   8 }, /* Albania */
	{ 0x414D /* AM */,  51 }, /* Armenia */
	{ 0x4152 /* AR */,  32 }, /* Argentina */
	{ 0x4154 /* AT */,  40 }, /* Austria */
	{ 0x4155 /* AU */,  36 }, /* Australia */
	{ 0x415A /* AZ */,  31 }, /* Azerbaijan */
	{ 0x4245 /* BE */,  56 }, /* Belgium */
	{ 0x4247 /* BG */, 100 }, /* Bulgaria */
	{ 0x4248 /* BH */,  48 }, /* Bahrain */
	{ 0x424E /* BN */,  96 }, /* Brunei Darussalam */
	{ 0x424F /* BO */,  68 }, /* Bolivia */
	{ 0x4252 /* BR */,  76 }, /* Brazil */
	{ 0x4259 /* BY */, 112 }, /* Belarus */
	{ 0x425A /* BZ */,  84 }, /* Belize */
	{ 0x4341 /* CA */, 124 }, /* Canada */
	{ 0x4348 /* CH */, 756 }, /* Switzerland */
	{ 0x434C /* CL */, 152 }, /* Chile */
	{ 0x434E /* CN */, 156 }, /* People's Republic of China */
	{ 0x434F /* CO */, 170 }, /* Colombia */
	{ 0x4352 /* CR */, 188 }, /* Costa Rica */
	{ 0x4359 /* CY */, 196 }, /* Cyprus */
	{ 0x435A /* CZ */, 203 }, /* Czech Republic */
	{ 0x4445 /* DE */, 276 }, /* Germany */
	{ 0x444B /* DK */, 208 }, /* Denmark */
	{ 0x444F /* DO */, 214 }, /* Dominican Republic */
	{ 0x445A /* DZ */,  12 }, /* Algeria */
	{ 0x4543 /* EC */, 218 }, /* Ecuador */
	{ 0x4545 /* EE */, 233 }, /* Estonia */
	{ 0x4547 /* EG */, 818 }, /* Egypt */
	{ 0x4553 /* ES */, 724 }, /* Spain */
	{ 0x4649 /* FI */, 246 }, /* Finland */
	{ 0x464F /* FO */, 234 }, /* Faeroe Islands */
	{ 0x4652 /* FR */, 250 }, /* France */
	{ 0x4652 /* FR */, 255 }, /* France2 */
	{ 0x4742 /* GB */, 826 }, /* United Kingdom */
	{ 0x4745 /* GE */, 268 }, /* Georgia */
	{ 0x4752 /* GR */, 300 }, /* Greece */
	{ 0x4754 /* GT */, 320 }, /* Guatemala */
	{ 0x484B /* HK */, 344 }, /* Hong Kong S.A.R., P.R.C. */
	{ 0x484E /* HN */, 340 }, /* Honduras */
	{ 0x4852 /* HR */, 191 }, /* Croatia */
	{ 0x4855 /* HU */, 348 }, /* Hungary */
	{ 0x4944 /* ID */, 360 }, /* Indonesia */
	{ 0x4945 /* IE */, 372 }, /* Ireland */
	{ 0x494C /* IL */, 376 }, /* Israel */
	{ 0x494E /* IN */, 356 }, /* India */
	{ 0x4951 /* IQ */, 368 }, /* Iraq */
	{ 0x4952 /* IR */, 364 }, /* Iran */
	{ 0x4953 /* IS */, 352 }, /* Iceland */
	{ 0x4954 /* IT */, 380 }, /* Italy */
	{ 0x4A4D /* JM */, 388 }, /* Jamaica */
	{ 0x4A4F /* JO */, 400 }, /* Jordan */
	{ 0x4A50 /* JP */, 392 }, /* Japan */
	{ 0x4A50 /* JP */, 393 }, /* Japan (JP1) */
	{ 0x4A50 /* JP */, 394 }, /* Japan (JP0) */
	{ 0x4A50 /* JP */, 395 }, /* Japan (JP1-1) */
	{ 0x4A50 /* JP */, 396 }, /* Japan (JE1) */
	{ 0x4A50 /* JP */, 397 }, /* Japan (JE2) */
	{ 0x4A50 /* JP */, 399 }, /* Japan (JP6) */
	{ 0x4A50 /* JP */, 900 }, /* Japan */
	{ 0x4A50 /* JP */, 901 }, /* Japan */
	{ 0x4A50 /* JP */, 902 }, /* Japan */
	{ 0x4A50 /* JP */, 903 }, /* Japan */
	{ 0x4A50 /* JP */, 904 }, /* Japan */
	{ 0x4A50 /* JP */, 905 }, /* Japan */
	{ 0x4A50 /* JP */, 906 }, /* Japan */
	{ 0x4A50 /* JP */, 907 }, /* Japan */
	{ 0x4A50 /* JP */, 908 }, /* Japan */
	{ 0x4A50 /* JP */, 909 }, /* Japan */
	{ 0x4A50 /* JP */, 910 }, /* Japan */
	{ 0x4A50 /* JP */, 911 }, /* Japan */
	{ 0x4A50 /* JP */, 912 }, /* Japan */
	{ 0x4A50 /* JP */, 913 }, /* Japan */
	{ 0x4A50 /* JP */, 914 }, /* Japan */
	{ 0x4A50 /* JP */, 915 }, /* Japan */
	{ 0x4A50 /* JP */, 916 }, /* Japan */
	{ 0x4A50 /* JP */, 917 }, /* Japan */
	{ 0x4A50 /* JP */, 918 }, /* Japan */
	{ 0x4A50 /* JP */, 919 }, /* Japan */
	{ 0x4A50 /* JP */, 920 }, /* Japan */
	{ 0x4A50 /* JP */, 921 }, /* Japan */
	{ 0x4A50 /* JP */, 922 }, /* Japan */
	{ 0x4A50 /* JP */, 923 }, /* Japan */
	{ 0x4A50 /* JP */, 924 }, /* Japan */
	{ 0x4A50 /* JP */, 925 }, /* Japan */
	{ 0x4A50 /* JP */, 926 }, /* Japan */
	{ 0x4A50 /* JP */, 927 }, /* Japan */
	{ 0x4A50 /* JP */, 928 }, /* Japan */
	{ 0x4A50 /* JP */, 929 }, /* Japan */
	{ 0x4A50 /* JP */, 930 }, /* Japan */
	{ 0x4A50 /* JP */, 931 }, /* Japan */
	{ 0x4A50 /* JP */, 932 }, /* Japan */
	{ 0x4A50 /* JP */, 933 }, /* Japan */
	{ 0x4A50 /* JP */, 934 }, /* Japan */
	{ 0x4A50 /* JP */, 935 }, /* Japan */
	{ 0x4A50 /* JP */, 936 }, /* Japan */
	{ 0x4A50 /* JP */, 937 }, /* Japan */
	{ 0x4A50 /* JP */, 938 }, /* Japan */
	{ 0x4A50 /* JP */, 939 }, /* Japan */
	{ 0x4A50 /* JP */, 940 }, /* Japan */
	{ 0x4A50 /* JP */, 941 }, /* Japan */
	{ 0x4B45 /* KE */, 404 }, /* Kenya */
	{ 0x4B50 /* KP */, 408 }, /* North Korea */
	{ 0x4B52 /* KR */, 410 }, /* South Korea */
	{ 0x4B52 /* KR */, 411 }, /* South Korea */
	{ 0x4B57 /* KW */, 414 }, /* Kuwait */
	{ 0x4B5A /* KZ */, 398 }, /* Kazakhstan */
	{ 0x4C42 /* LB */, 422 }, /* Lebanon */
	{ 0x4C49 /* LI */, 438 }, /* Liechtenstein */
	{ 0x4C54 /* LT */, 440 }, /* Lithuania */
	{ 0x4C55 /* LU */, 442 }, /* Luxembourg */
	{ 0x4C56 /* LV */, 428 }, /* Latvia */
	{ 0x4C59 /* LY */, 434 }, /* Libya */
	{ 0x4D41 /* MA */, 504 }, /* Morocco */
	{ 0x4D43 /* MC */, 492 }, /* Principality of Monaco */
	{ 0x4D4B /* MK */, 807 }, /* the Former Yugoslav Republic of Macedonia */
	{ 0x4D4F /* MO */, 446 }, /* Macau */
	{ 0x4D58 /* MX */, 484 }, /* Mexico */
	{ 0x4D59 /* MY */, 458 }, /* Malaysia */
	{ 0x4E49 /* NI */, 558 }, /* Nicaragua */
	{ 0x4E4C /* NL */, 528 }, /* Netherlands */
	{ 0x4E4F /* NO */, 578 }, /* Norway */
	{ 0x4E5A /* NZ */, 554 }, /* New Zealand */
	{ 0x4F4D /* OM */, 512 }, /* Oman */
	{ 0x5041 /* PA */, 591 }, /* Panama */
	{ 0x5045 /* PE */, 604 }, /* Peru */
	{ 0x5048 /* PH */, 608 }, /* Republic of the Philippines */
	{ 0x504B /* PK */, 586 }, /* Islamic Republic of Pakistan */
	{ 0x504C /* PL */, 616 }, /* Poland */
	{ 0x5052 /* PR */, 630 }, /* Puerto Rico */
	{ 0x5054 /* PT */, 620 }, /* Portugal */
	{ 0x5059 /* PY */, 600 }, /* Paraguay */
	{ 0x5141 /* QA */, 634 }, /* Qatar */
	{ 0x524F /* RO */, 642 }, /* Romania */
	{ 0x5255 /* RU */, 643 }, /* Russia */
	{ 0x5341 /* SA */, 682 }, /* Saudi Arabia */
	{ 0x5345 /* SE */, 752 }, /* Sweden */
	{ 0x5347 /* SG */, 702 }, /* Singapore */
	{ 0x5349 /* SI */, 705 }, /* Slovenia */
	{ 0x534B /* SK */, 703 }, /* Slovak Republic */
	{ 0x5356 /* SV */, 222 }, /* El Salvador */
	{ 0x5359 /* SY */, 760 }, /* Syria */
	{ 0x5448 /* TH */, 764 }, /* Thailand */
	{ 0x544E /* TN */, 788 }, /* Tunisia */
	{ 0x5452 /* TR */, 792 }, /* Turkey */
	{ 0x5454 /* TT */, 780 }, /* Trinidad y Tobago */
	{ 0x5457 /* TW */, 158 }, /* Taiwan */
	{ 0x5541 /* UA */, 804 }, /* Ukraine */
	{ 0x554B /* UK */, 826 }, /* United Kingdom */
	{ 0x5553 /* US */, 840 }, /* United States */
	{ 0x5553 /* US */, 842 }, /* United States (Public Safety)*/
	{ 0x5559 /* UY */, 858 }, /* Uruguay */
	{ 0x555A /* UZ */, 860 }, /* Uzbekistan */
	{ 0x5645 /* VE */, 862 }, /* Venezuela */
	{ 0x564E /* VN */, 704 }, /* Viet Nam */
	{ 0x5945 /* YE */, 887 }, /* Yemen */
	{ 0x5A41 /* ZA */, 710 }, /* South Africa */
	{ 0x5A57 /* ZW */, 716 }, /* Zimbabwe */
};

static char * qcawifi_name_to_iface(const char *ifname)
{
	if (!strcmp(ifname, "radio0")) {
		return "wifi0";
	} else if (!strcmp(ifname, "radio1")) {
		return "wifi1";
	} else {
		return ifname;
	}
}

static int qcawifi_wrq(struct iwreq *wrq, const char *ifname, int cmd, void *data, size_t len)
{	
	strncpy(wrq->ifr_name, ifname, IFNAMSIZ);

	if (data != NULL) {
		if (len < IFNAMSIZ) {
			memcpy(wrq->u.name, data, len);
		} else {
			wrq->u.data.pointer = data;
			wrq->u.data.length = len;
		}
	}

	return iwinfo_ioctl(cmd, wrq);
}

static int get80211priv(const char *ifname, int op, void *data, size_t len)
{
	struct iwreq iwr;

	if (qcawifi_wrq(&iwr, ifname, op, data, len) < 0)
		return -1;

	return iwr.u.data.length;
}

static char * qcawifi_isvap(const char *ifname, const char *wifiname)
{
	int fd, ln;
	char path[64];
	char *ret = NULL;
	static char name[IFNAMSIZ];

	if (strlen(ifname) <= 9) {
		snprintf(path, sizeof(path), "/sys/class/net/%s/parent", ifname);

		if ((fd = open(path, O_RDONLY)) > -1) {
			if (wifiname != NULL) {
				if (read(fd, name, strlen(wifiname)) == strlen(wifiname))
					ret = strncmp(name, wifiname, strlen(wifiname))
						? NULL : name;
			} else if ((ln = read(fd, name, IFNAMSIZ)) >= 4) {
				name[ln-1] = 0;
				ret = name;
			}

			(void) close(fd);
		}
	}

	return ret;
}

static int qcawifi_iswifi(const char *ifname)
{
	int fd, ln;
	int ret = 0;
	char prot[16];
	char path[128];

	/* qcawifi has a "hwcaps" file in wifiN sysfs to define the
	 * protocol actually supported by the hardware */
	snprintf(path, sizeof(path), "/sys/class/net/%s/hwcaps", ifname);

	if ((fd = open(path, O_RDONLY)) > -1) {
		if (ln = read(fd, prot, sizeof(prot)))
			ret = !strncmp(prot, "802.11", 6);

		close(fd);
	}

	return ret;
}

static int qcawifi_probe(const char *ifname)
{
	return ( !!qcawifi_isvap(qcawifi_name_to_iface(ifname), NULL) || !strncmp(ifname, "radio", 5) );
}

static void qcawifi_close(void)
{
	/* Nop */
}

static int qcawifi_get_mode(const char *ifname, int *buf)
{
	return nl80211_ops.mode(qcawifi_name_to_iface(ifname), buf);
}

static int qcawifi_get_ssid(const char *ifname, char *buf)
{
	return wext_ops.ssid(ifname, buf);
}

static int qcawifi_get_bssid(const char *ifname, char *buf)
{
	return nl80211_ops.bssid(qcawifi_name_to_iface(ifname), buf);
}

static int qcawifi_get_center_chan1(const char *ifname, int *buf)
{
	// TODO
	return -1;
}

static int qcawifi_get_center_chan2(const char *ifname, int *buf)
{
	// TODO
	return -1;
}	

static int qcawifi_get_channel(const char *ifname, int *buf)
{
	return nl80211_ops.channel(qcawifi_name_to_iface(ifname), buf);
}

static int qcawifi_get_frequency(const char *ifname, int *buf)
{
	return nl80211_ops.frequency(qcawifi_name_to_iface(ifname), buf);
}

static int qcawifi_get_txpower(const char *ifname, int *buf)
{
	DIR *proc;
	struct dirent *e;

	ifname = qcawifi_name_to_iface(ifname);

	if (qcawifi_iswifi(ifname)) {
		if ((proc = opendir("/sys/class/net/")) == NULL)
			return -1;

		while ((e = readdir(proc)) != NULL) {
			if (!!qcawifi_isvap(e->d_name, ifname)) {
				return nl80211_ops.txpower(e->d_name, buf);
			}
		}
		closedir(proc);

		return -1;
	}

	return nl80211_ops.txpower(ifname, buf);
}

static int qcawifi_get_bitrate(const char *ifname, int *buf)
{
	unsigned int mode, len, rate, rate_count;
	uint8_t tmp[24*1024];
	uint8_t *cp;
	struct iwreq wrq;
	struct ieee80211req_sta_info *si;

	ifname = qcawifi_name_to_iface(ifname);

	if (!qcawifi_isvap(ifname, NULL)) 
		return -1;

	/* Calculate bitrate average from associated stations */
	rate = rate_count = 0;

	if ((len = get80211priv(ifname, IEEE80211_IOCTL_STA_INFO, tmp, 24*1024)) > 0) {
		cp = tmp;

		while (len >= sizeof(struct ieee80211req_sta_info)) {
			si = (struct ieee80211req_sta_info *) cp;

			if (si->isi_txratekbps == 0)
				rate += ((si->isi_rates[si->isi_txrate] & IEEE80211_RATE_VAL) / 2) * 1000;
			else
				rate += si->isi_txratekbps;

			cp   += si->isi_len;
			len  -= si->isi_len;
			rate_count++;
		};

		*buf = (rate == 0 || rate_count == 0) ? 0 : (rate / rate_count);

		return 0;
	}

	return -1;
}

static int qcawifi_get_signal(const char *ifname, int *buf)
{
	unsigned int mode, len, signal, signal_count;
	uint8_t tmp[24*1024];
	uint8_t *cp;
	struct iwreq wrq;
	struct ieee80211req_sta_info *si;

	ifname = qcawifi_name_to_iface(ifname);

	if (!qcawifi_isvap(ifname, NULL))
		return -1;

	signal = signal_count = 0;

	if ((len = get80211priv(ifname, IEEE80211_IOCTL_STA_INFO, tmp, 24*1024)) > 0) {
		cp = tmp;

		while (len >= sizeof(struct ieee80211req_sta_info)) {
			si = (struct ieee80211req_sta_info *) cp;

			if (si->isi_rssi > 0) {
				signal_count++;
				signal -= (si->isi_rssi - 95);
			}

			cp   += si->isi_len;
			len  -= si->isi_len;
		}

		*buf = (signal == 0 || signal_count == 0) ? 0 : -(signal / signal_count);
		return 0;
	}

	return -1;
}

static int qcawifi_get_noise(const char *ifname, int *buf)
{
	return wext_ops.noise(ifname, buf);
}

static int qcawifi_get_quality(const char *ifname, int *buf)
{
	unsigned int mode, len, quality, quality_count;
	uint8_t tmp[24*1024];
	uint8_t *cp;
	struct iwreq wrq;
	struct ieee80211req_sta_info *si;

	ifname = qcawifi_name_to_iface(ifname);

	if (!qcawifi_isvap(ifname, NULL)) 
		return -1;

	quality = quality_count = 0;

	if ((len = get80211priv(ifname, IEEE80211_IOCTL_STA_INFO, tmp, 24*1024)) > 0) {
		cp = tmp;

		while (len >= sizeof(struct ieee80211req_sta_info)) {
			si = (struct ieee80211req_sta_info *) cp;

			if (si->isi_rssi > 0) {
				quality_count++;
				quality += si->isi_rssi;
			}

			cp   += si->isi_len;
			len  -= si->isi_len;
		}

		*buf = (quality == 0 || quality_count == 0) ? 0 : (quality / quality_count);
		return 0;
	}

	return -1;
}

static int qcawifi_get_quality_max(const char *ifname, int *buf)
{
	return wext_ops.quality_max(ifname, buf);
}

static int qcawifi_get_htmodelist(const char *ifname, int *buf)
{
	return nl80211_ops.htmodelist(qcawifi_name_to_iface(ifname), buf);
}

static int qcawifi_get_htmode(const char *ifname, int *buf)
{
	return nl80211_ops.htmode(qcawifi_name_to_iface(ifname), buf);
}

static int qcawifi_get_encryption(const char *ifname, char *buf)
{
	return nl80211_ops.encryption(ifname, buf);
}

static int qcawifi_get_assoclist(const char *ifname, char *buf, int *len)
{
	int bl, tl, noise;
	uint8_t *cp;
	uint8_t tmp[24*1024];
	struct ieee80211req_sta_info *si;
	struct iwinfo_assoclist_entry entry;

	ifname = qcawifi_name_to_iface(ifname);

	if (!qcawifi_isvap(ifname, NULL)) 
		return -1;

	if ((tl = get80211priv(ifname, IEEE80211_IOCTL_STA_INFO, tmp, 24*1024)) > 1) {
		cp = tmp;
		bl = 0;

		if (qcawifi_get_noise(ifname, &noise))
			noise = 0;

		while (tl >= sizeof(struct ieee80211req_sta_info)) {
			si = (struct ieee80211req_sta_info *) cp;

			memset(&entry, 0, sizeof(entry));

			entry.signal = (si->isi_rssi - 95);
			entry.noise  = noise;
			memcpy(entry.mac, &si->isi_macaddr, 6);

			entry.inactive = si->isi_inact * 1000;

			entry.tx_packets = (si->isi_txseqs[0] & IEEE80211_SEQ_SEQ_MASK)
				>> IEEE80211_SEQ_SEQ_SHIFT;

			entry.rx_packets = (si->isi_rxseqs[0] & IEEE80211_SEQ_SEQ_MASK)
				>> IEEE80211_SEQ_SEQ_SHIFT;

			if (si->isi_txratekbps == 0)
				entry.tx_rate.rate = (si->isi_rates[si->isi_txrate] & IEEE80211_RATE_VAL)/2 * 1000;
			else
				entry.tx_rate.rate = si->isi_txratekbps;

			entry.rx_rate.rate = si->isi_rxratekbps;

			entry.rx_rate.mcs = -1;
			entry.tx_rate.mcs = -1;

			memcpy(&buf[bl], &entry, sizeof(struct iwinfo_assoclist_entry));

			bl += sizeof(struct iwinfo_assoclist_entry);
			cp += si->isi_len;
			tl -= si->isi_len;
		}

		*len = bl;
		return 0;
	}

	return -1;
}

static int qcawifi_get_txpwrlist(const char *ifname, char *buf, int *len)
{
	return nl80211_ops.txpwrlist(qcawifi_name_to_iface(ifname), buf, len);
}

static int qcawifi_get_scan(const char *ifname, char *buf, int *len,
							int (*scan_func)(const char *, char *, int *))
{
	int ret = -1;
	char *res;
	DIR *proc;
	struct dirent *e;

	ifname = qcawifi_name_to_iface(ifname);

	/* We got a wifiX device passed, try to lookup a vap on it */
	if (qcawifi_iswifi(ifname))
	{
		if ((proc = opendir("/sys/class/net/")) != NULL) {
			while ((e = readdir(proc)) != NULL) {
				if (!!qcawifi_isvap(e->d_name, ifname)) {
					if (iwinfo_ifup(e->d_name)) {
						ret = scan_func(e->d_name, buf, len);
						break;
					}
				}
			}

			closedir(proc);
		}

		/* Still nothing found, try to create a vap */
		if (ret == -1) {
			if ((res = nl80211_ifadd(ifname)) != NULL) {
				ret = scan_func(res, buf, len);

				nl80211_ifdel(res);
			}
		}
	} else if (!!qcawifi_isvap(ifname, NULL)) { /* Got athX device? */
		ret = scan_func(ifname, buf, len);
	}

	return ret;
}

static int qcawifi_get_scanlist(const char *ifname, char *buf, int *len)
{
	return qcawifi_get_scan(ifname, buf, len, nl80211_ops.scanlist);
}

static int qcawifi_get_scan_results(const char *ifname, char *buf, int *len)
{
	return qcawifi_get_scan(ifname, buf, len, nl80211_ops.scan_results);
}

static int qcawifi_get_freqlist(const char *ifname, char *buf, int *len)
{
	return nl80211_ops.freqlist(qcawifi_name_to_iface(ifname), buf, len);
}

static int qcawifi_get_country(const char *ifname, char *buf)
{
	
	int i, fd, ccode = -1;
	char buffer[34];
	char *wifi = qcawifi_iswifi(ifname)
		? (char *)ifname : qcawifi_isvap(ifname, NULL);

	struct ISO3166_to_CCode *e;

	if (wifi) {
		snprintf(buffer, sizeof(buffer), "/proc/sys/dev/%s/countrycode", wifi);

		if ((fd = open(buffer, O_RDONLY)) > -1) {
			memset(buffer, 0, sizeof(buffer));

			if (read(fd, buffer, sizeof(buffer)-1) > 0)
				ccode = atoi(buffer);

			close(fd);
		}
	}

	for (i = 0; i < (sizeof(CountryCodes)/sizeof(CountryCodes[0])); i++) {
		e = &CountryCodes[i];

		if (e->ccode == ccode) {
			sprintf(buf, "%c%c", e->iso3166 / 256, e->iso3166 % 256);
			return 0;
		}
	}

	return -1;
}

static int qcawifi_get_countrylist(const char *ifname, char *buf, int *len)
{
	
	int i, count;
	struct ISO3166_to_CCode *e, *p = NULL;
	struct iwinfo_country_entry *c = (struct iwinfo_country_entry *)buf;

	count = 0;

	for( int i = 0; i < (sizeof(CountryCodes)/sizeof(CountryCodes[0])); i++ ) {
		e = &CountryCodes[i];

		if (!p || (e->iso3166 != p->iso3166)) {
			c->iso3166 = e->iso3166;
			snprintf(c->ccode, sizeof(c->ccode), "%i", e->ccode);

			c++;
			count++;
		}

		p = e;
	}

	*len = (count * sizeof(struct iwinfo_country_entry));
	return 0;
}

static int qcawifi_get_hwmodelist(const char *ifname, int *buf)
{
	return nl80211_ops.hwmodelist(qcawifi_name_to_iface(ifname), buf);
}

static int qcawifi_get_mbssid_support(const char *ifname, int *buf)
{
	return -1;
}

static int qcawifi_get_phyname(const char *ifname, char *buf)
{
	return nl80211_ops.phyname(qcawifi_name_to_iface(ifname), buf);
}

static int qcawifi_get_hardware_id(const char *ifname, char *buf)
{
	return nl80211_ops.hardware_id(qcawifi_name_to_iface(ifname), buf);
}

static const struct iwinfo_hardware_entry *
qcawifi_get_hardware_entry(const char *ifname)
{
	struct iwinfo_hardware_id id;
	ifname = qcawifi_name_to_iface(ifname);

	if (qcawifi_get_hardware_id(ifname, (char *)&id))
		return NULL;

	return iwinfo_hardware(&id);
}

static int qcawifi_get_hardware_name(const char *ifname, char *buf)
{
	sprintf(buf, "Generic Atheros");

	return 0;
}

static int qcawifi_get_txpower_offset(const char *ifname, int *buf)
{
	const struct iwinfo_hardware_entry *hw;
	ifname = qcawifi_name_to_iface(ifname);

	if (!(hw = qcawifi_get_hardware_entry(ifname)))
		return -1;

	*buf = hw->txpower_offset;
	return 0;
}

static int qcawifi_get_frequency_offset(const char *ifname, int *buf)
{
	const struct iwinfo_hardware_entry *hw;

	ifname = qcawifi_name_to_iface(ifname);

	if (!(hw = qcawifi_get_hardware_entry(ifname)))
		return -1;

	*buf = hw->frequency_offset;
	return 0;
}

const struct iwinfo_ops qcawifi_ops = {
	.name             = "qcawifi",
	.probe            = qcawifi_probe,
	.channel          = qcawifi_get_channel,
	.center_chan1	  = qcawifi_get_center_chan1,
	.center_chan2	  = qcawifi_get_center_chan2,
	.frequency        = qcawifi_get_frequency,
	.frequency_offset = qcawifi_get_frequency_offset,
	.txpower          = qcawifi_get_txpower,
	.txpower_offset   = qcawifi_get_txpower_offset,
	.bitrate          = qcawifi_get_bitrate,
	.signal           = qcawifi_get_signal,
	.noise            = qcawifi_get_noise,
	.quality          = qcawifi_get_quality,
	.quality_max      = qcawifi_get_quality_max,
	.mbssid_support   = qcawifi_get_mbssid_support,
	.hwmodelist       = qcawifi_get_hwmodelist,
	.htmodelist       = qcawifi_get_htmodelist,
	.htmode		  = qcawifi_get_htmode,
	.mode             = qcawifi_get_mode,
	.ssid             = qcawifi_get_ssid,
	.bssid            = qcawifi_get_bssid,
	.country          = qcawifi_get_country,
	.hardware_id      = qcawifi_get_hardware_id,
	.hardware_name    = qcawifi_get_hardware_name,
	.encryption       = qcawifi_get_encryption,
	.phyname	  = qcawifi_get_phyname,
	.assoclist        = qcawifi_get_assoclist,
	.txpwrlist        = qcawifi_get_txpwrlist,
	.scanlist         = qcawifi_get_scanlist,
	.freqlist         = qcawifi_get_freqlist,
	.countrylist      = qcawifi_get_countrylist,
	.scan_results     = qcawifi_get_scan_results,
	.close            = qcawifi_close
};
