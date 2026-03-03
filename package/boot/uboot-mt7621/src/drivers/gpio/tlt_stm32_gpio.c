
#include <common.h>
#include <dm.h>
#include <i2c.h>
#include <log.h>
#include <asm-generic/gpio.h>
#include <asm/global_data.h>
#include <linux/bitops.h>

DECLARE_GLOBAL_DATA_PTR;

#define CMD_GPIO	     0x06
#define CMD_FW		     0xFD
#define GET_FW_VERSION	     0x01
#define GPIO_STATE_HIGH	     0x1E
#define GPIO_STATE_LOW	     0x9F
#define GPIO_VALUE_SET_LOW   0x00
#define GPIO_VALUE_SET_HIGH  0x01
#define GPIO_VALUE_GET	     0x02
#define GPIO_MODE_SET_OUTPUT 0x04
#define GPIO_MODE_SET_INPUT  0x05

struct i2c_frame {
	u8 length;
	u8 command;
	u8 data[8];
};

struct tlt_stm_chip {
	unsigned int out; /* software latch */
};

bool init_failed = 0;

static int tlt_stm_gpio_get_function(struct udevice *dev, unsigned int offset)
{
	struct tlt_stm_chip *plat = dev_get_plat(dev);
	if (plat->out & BIT(offset))
		return GPIOF_OUTPUT;
	else
		return GPIOF_INPUT;
}

static int tlt_stm_get_value(struct udevice *dev, unsigned int offset)
{
	struct i2c_frame *req;
	u8 buf[sizeof(struct i2c_frame)];
	int ret;

	if (init_failed)
		return 0;

	req	     = (struct i2c_frame *)buf;
	req->length  = 2;
	req->command = CMD_GPIO;
	req->data[0] = offset;
	req->data[1] = GPIO_VALUE_GET;

	ret = dm_i2c_write(dev, req->length, &buf[1], req->length + 1);
	if (ret) {
		printf("%s i2c write failed\n", __func__);
		return ret;
	}

	ret = dm_i2c_read(dev, 0, buf, 0x1);
	if (ret) {
		printf("%s i2c read failed\n", __func__);
		return ret;
	}

	switch (buf[0]) {
	case GPIO_STATE_HIGH:
		return 1;
	case GPIO_STATE_LOW:
		return 0;
	}

	return -EIO;
}

static int tlt_stm_set_value(struct udevice *dev, unsigned int offset,
			     int value)
{
	struct i2c_frame *req;
	u8 buf[sizeof(struct i2c_frame)];
	int ret;

	if (init_failed)
		return 0;

	req	     = (struct i2c_frame *)buf;
	req->length  = 2;
	req->command = CMD_GPIO;
	req->data[0] = offset;
	req->data[1] = value ? GPIO_VALUE_SET_HIGH : GPIO_VALUE_SET_LOW;

	ret = dm_i2c_write(dev, req->length, &buf[1], req->length + 1);

	if (ret) {
		printf("%s i2c write failed\n", __func__);
		return ret;
	}
	return 0;
}

static int tlt_stm_direction_input(struct udevice *dev, unsigned offset)
{
	struct tlt_stm_chip *plat = dev_get_plat(dev);
	int status		  = 0;

	plat->out |= BIT(offset);
	//	status = tlt_stm_i2c_write(dev, plat->out);

	return status;
}

static int tlt_stm_direction_output(struct udevice *dev, unsigned int offset,
				    int value)
{
	struct tlt_stm_chip *plat = dev_get_plat(dev);
	int ret			  = 0;

	if (value)
		plat->out |= BIT(offset);
	else
		plat->out &= ~BIT(offset);

	ret = tlt_stm_set_value(dev, offset, value);

	return ret;
}

static int tlt_stm_ofdata_plat(struct udevice *dev)
{
	struct tlt_stm_chip *plat     = dev_get_plat(dev);
	struct gpio_dev_priv *uc_priv = dev_get_uclass_priv(dev);

	int n_latch;

	/*
	 * Number of pins depends on the expander device and is specified
	 * in the struct udevice_id (as in the Linue kernel).
	 */
	uc_priv->gpio_count = dev_get_driver_data(dev) * 8;
	uc_priv->bank_name  = "STM";

	n_latch	  = fdtdec_get_uint(gd->fdt_blob, dev_of_offset(dev),
				    "lines-initial-states", 0);
	plat->out = ~n_latch;

	return 0;
}

static int tlt_stm_gpio_probe(struct udevice *dev)
{
	struct i2c_frame *req;
	u8 buf[64];
	int ret;

	req	     = (struct i2c_frame *)buf;
	req->length  = 1;
	req->command = CMD_FW;
	req->data[0] = GET_FW_VERSION;

	ret = dm_i2c_write(dev, req->length, &buf[1], req->length + 1);
	if (ret) {
		goto fault;
	}

	ret = dm_i2c_read(dev, 0, buf, 0x1);
	if (ret) {
		goto fault;
	}

	ret = dm_i2c_read(dev, 0, buf, buf[0]);
	if (ret) {
		goto fault;
	}

	printf("STM: v%s \n", &buf[1]);
	init_failed = 0;
	return 0;
fault:
	init_failed = 1;
	printf("STM: not found \n");
	return ret;
}

static const struct dm_gpio_ops tlt_stm_gpio_ops = {
	.direction_input  = tlt_stm_direction_input,
	.direction_output = tlt_stm_direction_output,
	.get_value	  = tlt_stm_get_value,
	.set_value	  = tlt_stm_set_value,
	.get_function	  = tlt_stm_gpio_get_function,
};

static const struct udevice_id tlt_stm_gpio_ids[] = {
	{ .compatible = "tlt,rut204-stm", .data = 2 },
	{}
};

U_BOOT_DRIVER(tlt_stm_gpio) = {
	.name	    = "tlt_stm_gpio",
	.id	    = UCLASS_GPIO,
	.ops	    = &tlt_stm_gpio_ops,
	.of_match   = tlt_stm_gpio_ids,
	.of_to_plat = tlt_stm_ofdata_plat,
	.probe	    = tlt_stm_gpio_probe,
	.plat_auto  = sizeof(struct tlt_stm_chip),
};
