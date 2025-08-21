// SPDX-License-Identifier: GPL-2.0
//
// LED Kernel net activity triger controlled by PHY
//
// Derived from ledtrig-netdev.c which is:
//  Copyright 2017 Ben Whitten <ben.whitten@gmail.com>
//  Copyright 2007 Oliver Jowett <oliver@opencloud.com>

#include <linux/slab.h>
#include <linux/ctype.h>
#include <linux/device.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/leds.h>
#include <linux/module.h>
#include "../leds.h"

struct led_hw_phy_data {
	struct led_classdev *led_cdev;
	unsigned long mode;
	bool hw_control;
};

static void set_baseline_state(struct led_hw_phy_data *trigger_data)
{
	struct led_classdev *led_cdev = trigger_data->led_cdev;

	/* Already validated, hw control is possible with the requested mode */
	if (trigger_data->hw_control) {
		led_cdev->hw_control_set(led_cdev, trigger_data->mode);
		return;
	}
}

static bool supports_hw_control(struct led_classdev *led_cdev)
{
	if (!led_cdev->hw_control_get || !led_cdev->hw_control_set ||
	    !led_cdev->hw_control_is_supported)
		return false;

	return !strcmp(led_cdev->hw_control_trigger, "netdev") || !strcmp(led_cdev->hw_control_trigger, "hw-phy");
}


static bool can_hw_control(struct led_hw_phy_data *trigger_data)
{
	struct led_classdev *led_cdev = trigger_data->led_cdev;
	int ret;

	if (!supports_hw_control(led_cdev))
		return false;


	/* Check if the requested mode is supported */
	ret = led_cdev->hw_control_is_supported(led_cdev, trigger_data->mode);
	/* Fall back to software blinking if not supported */
	if (ret == -EOPNOTSUPP)
		return false;

	if (ret) {
		dev_warn(led_cdev->dev,
			 "Current mode check failed with error %d\n", ret);
		return false;
	}

	return true;
}

static ssize_t hw_phy_led_attr_show(struct device *dev, char *buf,
				    enum led_trigger_netdev_modes attr)
{
	struct led_hw_phy_data *trigger_data = led_trigger_get_drvdata(dev);
	int bit;

	switch (attr) {
	case TRIGGER_NETDEV_LINK:
	case TRIGGER_NETDEV_LINK_10:
	case TRIGGER_NETDEV_LINK_100:
	case TRIGGER_NETDEV_LINK_1000:
	case TRIGGER_NETDEV_LINK_2500:
	case TRIGGER_NETDEV_LINK_5000:
	case TRIGGER_NETDEV_LINK_10000:
	case TRIGGER_NETDEV_HALF_DUPLEX:
	case TRIGGER_NETDEV_FULL_DUPLEX:
	case TRIGGER_NETDEV_TX:
	case TRIGGER_NETDEV_RX:
		bit = attr;
		break;
	default:
		return -EINVAL;
	}

	return sprintf(buf, "%u\n", test_bit(bit, &trigger_data->mode));
}

static ssize_t hw_phy_led_attr_store(struct device *dev, const char *buf,
				     size_t size, enum led_trigger_netdev_modes attr)
{
	struct led_hw_phy_data *trigger_data = led_trigger_get_drvdata(dev);
	unsigned long state, mode = trigger_data->mode;
	int ret;
	int bit;

	ret = kstrtoul(buf, 0, &state);
	if (ret)
		return ret;

	switch (attr) {
	case TRIGGER_NETDEV_LINK:
	case TRIGGER_NETDEV_LINK_10:
	case TRIGGER_NETDEV_LINK_100:
	case TRIGGER_NETDEV_LINK_1000:
	case TRIGGER_NETDEV_LINK_2500:
	case TRIGGER_NETDEV_LINK_5000:
	case TRIGGER_NETDEV_LINK_10000:
	case TRIGGER_NETDEV_HALF_DUPLEX:
	case TRIGGER_NETDEV_FULL_DUPLEX:
	case TRIGGER_NETDEV_TX:
	case TRIGGER_NETDEV_RX:
		bit = attr;
		break;
	default:
		return -EINVAL;
	}

	if (state)
		set_bit(bit, &mode);
	else
		clear_bit(bit, &mode);

	if (test_bit(TRIGGER_NETDEV_LINK, &mode) &&
	    (test_bit(TRIGGER_NETDEV_LINK_10, &mode) ||
	     test_bit(TRIGGER_NETDEV_LINK_100, &mode) ||
	     test_bit(TRIGGER_NETDEV_LINK_1000, &mode) ||
	     test_bit(TRIGGER_NETDEV_LINK_2500, &mode) ||
	     test_bit(TRIGGER_NETDEV_LINK_5000, &mode) ||
	     test_bit(TRIGGER_NETDEV_LINK_10000, &mode)))
		return -EINVAL;

	trigger_data->mode = mode;
	trigger_data->hw_control = can_hw_control(trigger_data);

	set_baseline_state(trigger_data);

	return size;
}

#define DEFINE_NETDEV_TRIGGER(trigger_name, trigger) \
	static ssize_t trigger_name##_show(struct device *dev, \
		struct device_attribute *attr, char *buf) \
	{ \
		return hw_phy_led_attr_show(dev, buf, trigger); \
	} \
	static ssize_t trigger_name##_store(struct device *dev, \
		struct device_attribute *attr, const char *buf, size_t size) \
	{ \
		return hw_phy_led_attr_store(dev, buf, size, trigger); \
	} \
	static DEVICE_ATTR(trigger_name, 0664, trigger_name##_show, trigger_name##_store)

DEFINE_NETDEV_TRIGGER(link, TRIGGER_NETDEV_LINK);
DEFINE_NETDEV_TRIGGER(link_10, TRIGGER_NETDEV_LINK_10);
DEFINE_NETDEV_TRIGGER(link_100, TRIGGER_NETDEV_LINK_100);
DEFINE_NETDEV_TRIGGER(link_1000, TRIGGER_NETDEV_LINK_1000);
DEFINE_NETDEV_TRIGGER(link_2500, TRIGGER_NETDEV_LINK_2500);
DEFINE_NETDEV_TRIGGER(link_5000, TRIGGER_NETDEV_LINK_5000);
DEFINE_NETDEV_TRIGGER(link_10000, TRIGGER_NETDEV_LINK_10000);
DEFINE_NETDEV_TRIGGER(half_duplex, TRIGGER_NETDEV_HALF_DUPLEX);
DEFINE_NETDEV_TRIGGER(full_duplex, TRIGGER_NETDEV_FULL_DUPLEX);
DEFINE_NETDEV_TRIGGER(tx, TRIGGER_NETDEV_TX);
DEFINE_NETDEV_TRIGGER(rx, TRIGGER_NETDEV_RX);

static ssize_t offloaded_show(struct device *dev,
			      struct device_attribute *attr, char *buf)
{
	struct led_hw_phy_data *trigger_data = led_trigger_get_drvdata(dev);

	return sprintf(buf, "%d\n", trigger_data->hw_control);
}

static DEVICE_ATTR_RO(offloaded);

static struct attribute *hw_phy_trig_attrs[] = {
	&dev_attr_link.attr,
	&dev_attr_link_10.attr,
	&dev_attr_link_100.attr,
	&dev_attr_link_1000.attr,
	&dev_attr_link_2500.attr,
	&dev_attr_link_5000.attr,
	&dev_attr_link_10000.attr,
	&dev_attr_full_duplex.attr,
	&dev_attr_half_duplex.attr,
	&dev_attr_rx.attr,
	&dev_attr_tx.attr,
	&dev_attr_offloaded.attr,
	NULL
};
ATTRIBUTE_GROUPS(hw_phy_trig);

static int hw_phy_trig_activate(struct led_classdev *led_cdev)
{
	struct led_hw_phy_data *trigger_data;
	unsigned long mode = 0;
	int rc;

	trigger_data = kzalloc(sizeof(struct led_hw_phy_data), GFP_KERNEL);
	if (!trigger_data)
		return -ENOMEM;

	trigger_data->led_cdev = led_cdev;
	trigger_data->mode = 0;
	if (supports_hw_control(led_cdev)) {
		trigger_data->hw_control = true;

		rc = led_cdev->hw_control_get(led_cdev, &mode);
		if (!rc)
			trigger_data->mode = mode;
	}

	led_set_trigger_data(led_cdev, trigger_data);
	
	if (led_cdev->brightness_set_blocking) {
		led_cdev->brightness_set_blocking(led_cdev, LED_OFF);
	}

	set_baseline_state(trigger_data);

	return rc;
}

static void hw_phy_trig_deactivate(struct led_classdev *led_cdev)
{
	struct led_hw_phy_data *trigger_data = led_get_trigger_data(led_cdev);

	led_set_brightness(led_cdev, LED_OFF);
	kfree(trigger_data);
}

static struct led_trigger hw_phy_led_trigger = {
	.name = "hw-phy",
	.activate = hw_phy_trig_activate,
	.deactivate = hw_phy_trig_deactivate,
	.groups = hw_phy_trig_groups,
};

module_led_trigger(hw_phy_led_trigger);

MODULE_DESCRIPTION("Hw-Phy LED trigger");
MODULE_LICENSE("GPL v2");
