/* SPDX-License-Identifier: GPL-2.0
 *
 * Texas Instruments TLA2021 12-bit hwmon ADC driver
 *
 * Copyright (C) 2019 Koninklijke Philips N.V.
 * Copyright (C) 2025 Teltonika Networks.
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/hwmon.h>
#include <linux/slab.h>
#include <linux/i2c.h>
#include <linux/err.h>
#include <linux/device.h>
#include <linux/of.h>
#include <linux/of_device.h>
#include <linux/delay.h>

#define TLA2021_DATA	       0x00
#define TLA2021_DATA_RES_MASK  GENMASK(15, 4)
#define TLA2021_DATA_RES_SHIFT 4

#define TLA2021_CONF		0x01
#define TLA2021_CONF_OS_MASK	BIT(15)
#define TLA2021_CONF_OS_SHIFT	15
#define TLA2021_CONF_MUX_MASK	GENMASK(14, 12)
#define TLA2021_CONF_MUX_SHIFT	12
#define TLA2021_CONF_PGA_MASK	GENMASK(11, 9)
#define TLA2021_CONF_PGA_SHIFT	9
#define TLA2021_CONF_MODE_MASK	BIT(8)
#define TLA2021_CONF_MODE_SHIFT 8
#define TLA2021_CONF_DR_MASK	GENMASK(7, 5)
#define TLA2021_CONF_DR_SHIFT	5

#define TLA2021_CONV_RETRY 10

struct tla2021_data {
	struct i2c_client *client;
	struct mutex lock;
};

static int tla2021_get(struct i2c_client *client, u8 addr, u16 mask, u16 shift, u16 *val)
{
	int ret;
	u16 data;

	ret = i2c_smbus_read_word_swapped(client, addr);
	if (ret < 0)
		return ret;

	data = ret;
	*val = (mask & data) >> shift;

	return 0;
}

static int tla2021_set(struct i2c_client *client, u8 addr, u16 mask, u16 shift, u16 val)
{
	int ret;
	u16 data;
	ret = i2c_smbus_read_word_swapped(client, addr);

	if (ret < 0)
		return ret;

	data = ret;
	data &= ~mask;
	data |= mask & (val << shift);

	ret = i2c_smbus_write_word_swapped(client, addr, data);

	return ret;
}

static int tla2021_wait(struct i2c_client *client)
{
	int ret;
	unsigned int retry = TLA2021_CONV_RETRY;
	u16 status;

	do {
		if (!--retry)
			return -EIO;
		ret = tla2021_get(client, TLA2021_CONF, TLA2021_CONF_OS_MASK, TLA2021_CONF_OS_SHIFT, &status);
		if (ret < 0)
			return ret;
		if (!status)
			usleep_range(25, 1000);
	} while (!status);

	return ret;
}

static int tla2021_singleshot_conv(struct i2c_client *client, int *val)
{
	int ret;
	u16 data;
	s16 tmp;

	ret = tla2021_set(client, TLA2021_CONF, TLA2021_CONF_MODE_MASK, TLA2021_CONF_MODE_SHIFT, 1);
	if (ret < 0)
		return ret;

	ret = tla2021_set(client, TLA2021_CONF, TLA2021_CONF_MUX_MASK, TLA2021_CONF_MUX_SHIFT, 0);
	if (ret < 0)
		return ret;

	ret = tla2021_set(client, TLA2021_CONF, TLA2021_CONF_OS_MASK, TLA2021_CONF_OS_SHIFT, 1);
	if (ret < 0)
		return ret;

	ret = tla2021_wait(client);
	if (ret < 0)
		return ret;

	ret = tla2021_get(client, TLA2021_DATA, TLA2021_DATA_RES_MASK, TLA2021_DATA_RES_SHIFT, &data);
	if (ret < 0)
		return ret;

	tmp  = (s16)(data << TLA2021_DATA_RES_SHIFT);
	*val = tmp >> TLA2021_DATA_RES_SHIFT;
	return 0;
}

static int tla2021_read(struct device *dev, enum hwmon_sensor_types type, u32 attr, int channel, long *val)
{
	struct tla2021_data *data = dev_get_drvdata(dev);
	int raw_val, ret;

	mutex_lock(&data->lock);
	ret = tla2021_singleshot_conv(data->client, &raw_val);
	mutex_unlock(&data->lock);

	if (raw_val < 0 || ret < 0) {
		*val = 0;
	} else {
		/* old ADC MCP3021 K = 0,1282, new ADC TLA2021 K = 0,07969814
		* Ratio of old/new is 1,608, so multiply raw value by 1,608 for same value in iomand
		*/
		*val = (raw_val * 1608) / 1000;
	}

	return 0;
}

static umode_t tla2021_is_visible(const void *data, enum hwmon_sensor_types type, u32 attr, int channel)
{
	if (type == hwmon_in && attr == hwmon_in_input)
		return 0444;
	return 0;
}

static const struct hwmon_ops tla2021_hwmon_ops = {
	.is_visible = tla2021_is_visible,
	.read	    = tla2021_read,
};

static const struct hwmon_channel_info *tla2021_info[] = { HWMON_CHANNEL_INFO(in, HWMON_I_INPUT), NULL };

static const struct hwmon_chip_info tla2021_chip_info = {
	.ops  = &tla2021_hwmon_ops,
	.info = tla2021_info,
};

static int tla2021_probe(struct i2c_client *client)
{
	struct tla2021_data *data;
	struct device *hwmon_dev;
	int ret, idx;
	u16 status;

	data = devm_kzalloc(&client->dev, sizeof(*data), GFP_KERNEL);
	if (!data)
		return -ENOMEM;

	data->client = client;
	i2c_set_clientdata(client, data);

	//ADC not always respond to first data request, when booting. Second request seems to be successful.
	for (idx = 0; idx < 3; idx++) {
		ret = tla2021_get(client, TLA2021_CONF, TLA2021_CONF_OS_MASK, TLA2021_CONF_OS_SHIFT, &status);

		if (!ret)
			break;
		usleep_range(100, 1000);
	}

	if (ret < 0)
		return -ENODEV;

	dev_info(&client->dev, "Found ADC: TLA2021");
	mutex_init(&data->lock);

	hwmon_dev =
		devm_hwmon_device_register_with_info(&client->dev, "tla2021", data, &tla2021_chip_info, NULL);
	return PTR_ERR_OR_ZERO(hwmon_dev);
}

static void tla2021_remove(struct i2c_client *client)
{
	struct tla2021_data *data = i2c_get_clientdata(client);
	hwmon_device_unregister(&client->dev);
}

static const struct i2c_device_id tla2021_id[] = { { "tla2021", 0 }, {} };
MODULE_DEVICE_TABLE(i2c, tla2021_id);

static const struct of_device_id tla2021_of_match[] = { { .compatible = "ti,tla2021" }, {} };
MODULE_DEVICE_TABLE(of, tla2021_of_match);

static struct i2c_driver tla2021_driver = {
    .driver = {
        .name = "tla2021",
        .of_match_table = of_match_ptr(tla2021_of_match),
    },
    .probe = tla2021_probe,
    .remove = tla2021_remove,
    .id_table = tla2021_id,
};

module_i2c_driver(tla2021_driver);

MODULE_AUTHOR("Ibtsam Haq <ibtsam.haq@philips.com>");
MODULE_AUTHOR("Teltonika Networks");
MODULE_DESCRIPTION("Texas Instruments TLA2021 12-bit hwmon driver");
MODULE_LICENSE("GPL v2");
