#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/version.h>
#include <linux/gpio.h>
#include <linux/interrupt.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
#include <linux/kobject.h>
#include <linux/sysfs.h>
#include <linux/ktime.h>
#include <linux/spinlock.h>
#include <linux/gpio/driver.h>

// #define DEBUG // Enable debug

#ifdef DEBUG
#define DEBUG_MESSAGE(...) pr_warn("pulse-counter: " __VA_ARGS__)
#else
#define DEBUG_MESSAGE(...)
#endif

#define INFO_MESSAGE(...) pr_info("pulse-counter: " __VA_ARGS__)
#define ERROR_MESSAGE(...) pr_err("pulse-counter: " __VA_ARGS__)

#define IRQF_TRIGGER_BOTH (IRQF_TRIGGER_RISING | IRQF_TRIGGER_FALLING)
#define MAX_GPIO_PINS 10 // Maximum number of GPIO pins

struct gpio_ctx {
	unsigned int pin;
	unsigned int irq;
	atomic64_t pulse_count;
	atomic64_t pulse_count_r;
	atomic64_t debounce_count;
	unsigned int debounce_time_ms;
	ktime_t last_interrupt_time;
	irq_handler_t handler_threaded;
	struct kobject kobj;
	unsigned int edge_type;
};

static struct gpio_ctx *gpio_ctxs[MAX_GPIO_PINS];
static struct kobject pulse_kobj = { 0 };


static irqreturn_t gpio_irq_handler_threaded(int irq, void *ptr)
{
	struct gpio_ctx *ctx = ptr;
	ktime_t now;
	int val;
	val = gpio_get_value_cansleep(ctx->pin);
	if ((ctx->edge_type & IRQF_TRIGGER_RISING && val) ||
	    (ctx->edge_type & IRQF_TRIGGER_FALLING && !val)) {
		now = ktime_get();
		if (ktime_after(now,
				ktime_add(ctx->last_interrupt_time,
					  ms_to_ktime(ctx->debounce_time_ms)))) {
			atomic64_inc(&ctx->pulse_count);
			atomic64_inc(&ctx->pulse_count_r);
			ctx->last_interrupt_time = now;
		} else {
			atomic64_inc(&ctx->debounce_count);
		}
	}
	return IRQ_HANDLED;
}
static irqreturn_t gpio_irq_handler(int irq, void *ptr)
{
	struct gpio_ctx *ctx = ptr;
	ktime_t now;
	int val;
	val = gpio_get_value(ctx->pin);
	if ((ctx->edge_type & IRQF_TRIGGER_RISING && val) ||
	    (ctx->edge_type & IRQF_TRIGGER_FALLING && !val)) {
		now = ktime_get();
		if (ktime_after(now,
				ktime_add(ctx->last_interrupt_time,
					  ms_to_ktime(ctx->debounce_time_ms)))) {
			atomic64_inc(&ctx->pulse_count);
			atomic64_inc(&ctx->pulse_count_r);
			ctx->last_interrupt_time = now;
		} else {
			atomic64_inc(&ctx->debounce_count);
		}
	}
	return IRQ_HANDLED;
}


static ssize_t pulse_count_show(struct kobject *kobj,
				struct kobj_attribute *attr, char *buf)
{
	ssize_t len = 0;
	u64 val;
	struct gpio_ctx *ctx = container_of(kobj, struct gpio_ctx, kobj);
	val = atomic64_read(&ctx->pulse_count);
	len = sprintf(buf, "%llu\n", val);
	return len;
}

static ssize_t debounce_count_show(struct kobject *kobj,
				   struct kobj_attribute *attr, char *buf)
{
	ssize_t len = 0;
	u64 val;
	struct gpio_ctx *ctx = container_of(kobj, struct gpio_ctx, kobj);

	val = atomic64_read(&ctx->debounce_count);
	len = sprintf(buf, "%llu\n", val);
	return len;
}

static ssize_t reset_pulse_count_show(struct kobject *kobj,
				      struct kobj_attribute *attr, char *buf)
{
	ssize_t len = 0;
	u64 val;
	struct gpio_ctx *ctx = container_of(kobj, struct gpio_ctx, kobj);

	val = atomic64_read(&ctx->pulse_count_r);
	len = sprintf(buf, "%llu\n", val);
	atomic64_set(&ctx->pulse_count_r, 0);
	atomic64_set(&ctx->debounce_count, 0);
	return len;
}

static ssize_t debounce_time_show(struct kobject *kobj,
				  struct kobj_attribute *attr, char *buf)
{
	ssize_t len = 0;
	struct gpio_ctx *ctx = container_of(kobj, struct gpio_ctx, kobj);

	len = sprintf(buf, "%u\n", ctx->debounce_time_ms);
	return len;
}

static ssize_t gpio_value_show(struct kobject *kobj,
			       struct kobj_attribute *attr, char *buf)
{
	ssize_t len = 0;
	struct gpio_ctx *ctx = container_of(kobj, struct gpio_ctx, kobj);

	len = sprintf(buf, "%d\n", gpio_get_value_cansleep(ctx->pin));
	return len;
}

static ssize_t debounce_time_store(struct kobject *kobj,
				   struct kobj_attribute *attr, const char *buf,
				   size_t count)
{
	int new_debounce_time_ms;
	struct gpio_ctx *ctx = container_of(kobj, struct gpio_ctx, kobj);

	sscanf(buf, "%u", &new_debounce_time_ms);
	if (new_debounce_time_ms >= 0) {
		ctx->debounce_time_ms = new_debounce_time_ms;
	}
	return count;
}

static ssize_t edge_type_show(struct kobject *kobj, struct kobj_attribute *attr,
			      char *buf)
{
	struct gpio_ctx *ctx = container_of(kobj, struct gpio_ctx, kobj);
	ssize_t len = 0;

	len = sprintf(buf, "%u\n", ctx->edge_type);
	return len;
}

static ssize_t edge_type_store(struct kobject *kobj,
			       struct kobj_attribute *attr, const char *buf,
			       size_t count)
{
	struct gpio_ctx *ctx = container_of(kobj, struct gpio_ctx, kobj);
	unsigned int new_edge_type, result;

	sscanf(buf, "%u", &new_edge_type);
	if (new_edge_type == IRQF_TRIGGER_RISING ||
	    new_edge_type == IRQF_TRIGGER_FALLING ||
	    new_edge_type == IRQF_TRIGGER_BOTH) {
		free_irq(ctx->irq, ctx);
		ctx->irq = gpio_to_irq(ctx->pin);
		result = request_threaded_irq(ctx->irq, gpio_irq_handler,
					      ctx->handler_threaded,
					      new_edge_type,
					      "gpio_pulse_counter", ctx);
		if (result == 0) {
			ctx->edge_type = new_edge_type;
		}
	}
	return count;
}

static ssize_t pulse_count_store(struct kobject *kobj,
				 struct kobj_attribute *attr, const char *buf,
				 size_t count)
{
	u64 new_pulse_count;
	struct gpio_ctx *ctx = container_of(kobj, struct gpio_ctx, kobj);

	sscanf(buf, "%llu", &new_pulse_count);
	atomic64_set(&ctx->pulse_count, new_pulse_count);
	return count;
}

static struct kobj_attribute pulse_count_attr =
	__ATTR(pulse_count, 0660, pulse_count_show, pulse_count_store);
static struct kobj_attribute reset_pulse_count_attr =
	__ATTR(reset_pulse_count, 0440, reset_pulse_count_show, NULL);
static struct kobj_attribute debounce_time_attr =
	__ATTR(debounce_time, 0660, debounce_time_show, debounce_time_store);
static struct kobj_attribute edge_type_attr =
	__ATTR(edge_type, 0660, edge_type_show, edge_type_store);
static struct kobj_attribute debounce_count_attr =
	__ATTR(debounce_count, 0440, debounce_count_show, NULL);
static struct kobj_attribute gpio_value_attr =
	__ATTR(gpio_value, 0440, gpio_value_show, NULL);

static struct attribute *pin_attrs[] = { &pulse_count_attr.attr,
					 &reset_pulse_count_attr.attr,
					 &debounce_time_attr.attr,
					 &edge_type_attr.attr,
					 &debounce_count_attr.attr,
					 &gpio_value_attr.attr,
					 NULL };

static struct attribute_group pin_attr_group = {
	.attrs = pin_attrs,
};


#if LINUX_VERSION_CODE >= KERNEL_VERSION(6,2,0)
static void pc_kobj_get_ownership(const struct kobject *kobj, kuid_t *uid, kgid_t *gid)
#else
static void pc_kobj_get_ownership(struct kobject *kobj, kuid_t *uid, kgid_t *gid)
#endif
{
	(void)kobj;

	*uid = GLOBAL_ROOT_UID;
	*gid = GLOBAL_GPIO_GID;
}

static struct kobj_type pc_kobj_ktype = {
	.sysfs_ops	= &kobj_sysfs_ops,
	.get_ownership = &pc_kobj_get_ownership,
};

static int get_gpio_by_name(const char *gpio_name)
{
	struct gpio_chip *gc = NULL;
	int chip_index = 0, gpio;
	while ((gc = gpiochip_find_by_id(chip_index))) {
		gpio = tlt_gpio_get_line_by_name(gc, gpio_name);
		if (gpio >= 0) {
			return gpio + gc->base;
		}
		chip_index++;
	}
	return -EINVAL;
}

static int add_gpio_ctx(unsigned int pin, const char *name)
{
	int i, result;
	char dir_name[32];
	struct gpio_ctx *ctx;

	for (i = 0; i < MAX_GPIO_PINS; i++) {
		if (gpio_ctxs[i] != NULL) {
			continue;
		}

		ctx = kzalloc(sizeof(struct gpio_ctx), GFP_KERNEL);
		if (!ctx) {
			return -ENOMEM;
		}
		INFO_MESSAGE("Adding GPIO pin %d to slot %d name %s\n", pin, i,
			     name);

		ctx->pin = pin;
		ctx->irq = gpio_to_irq(pin);
		ctx->debounce_time_ms = 1;
		ctx->last_interrupt_time = ktime_set(0, 0);
		ctx->edge_type = IRQF_TRIGGER_RISING;

		gpio_ctxs[i] = ctx;

		snprintf(dir_name, sizeof(dir_name), "%s", name);
		result = kobject_init_and_add(&ctx->kobj, &pc_kobj_ktype,
					      &pulse_kobj, dir_name);
		if (result) {
			ERROR_MESSAGE("Failed to create kobject %d\n", result);
			goto fail_kobject;
		}

		result = sysfs_create_group(&ctx->kobj, &pin_attr_group);
		if (result) {
			ERROR_MESSAGE("Failed to create sysfs group %d\n",
				      result);
			goto fail_sysfs;
		}

		ctx->handler_threaded = gpio_irq_handler_threaded;

		result = request_threaded_irq(ctx->irq, gpio_irq_handler,
					      ctx->handler_threaded,
					      IRQF_TRIGGER_RISING,
					      "gpio_pulse_counter", ctx);

		if (result) {
			ERROR_MESSAGE("Failed to request IRQ no %d result %d\n",
				      ctx->irq, result);
			goto fail_sysfs;
		}

		INFO_MESSAGE(
			"GPIO pin name %s number %d irq %d added to slot %d\n",
			name, pin, ctx->irq, i);
		return 0;
	fail_sysfs:
		kobject_put(&ctx->kobj); // Release kobject
	fail_kobject:
		kfree(ctx); // Free allocated memory
		gpio_ctxs[i] = NULL;
		return result;
	}
	return -ENOMEM;
}

static void remove_gpio_ctx(unsigned int pin)
{
	int i;
	for (i = 0; i < MAX_GPIO_PINS; i++) {
		if (gpio_ctxs[i] != NULL && gpio_ctxs[i]->pin == pin) {
			free_irq(gpio_ctxs[i]->irq, gpio_ctxs[i]);
			kobject_put(&gpio_ctxs[i]->kobj);
			kfree(gpio_ctxs[i]);
			gpio_ctxs[i] = NULL;
			INFO_MESSAGE("GPIO pin %d removed from slot %d\n", pin,
				     i);
			break;
		}
	}
}

static ssize_t gpio_pins_store(struct kobject *kobj,
			       struct kobj_attribute *attr, const char *buf,
			       size_t count)
{
	int new_gpio_pin;
	int result;
	char pin_name[32];

	sscanf(buf, "%31s", pin_name);
	new_gpio_pin = get_gpio_by_name(pin_name);

	if (new_gpio_pin < 0) {
		ERROR_MESSAGE("Failed to get GPIO pin by name %s\n", pin_name);
		return -EINVAL;
	}

	result = gpio_request(new_gpio_pin, "pulse_counter");
	if (result) {
		ERROR_MESSAGE("Failed to request GPIO pin %d, result %d\n",
			      new_gpio_pin, result);
		return result;
	}

	result = gpio_direction_input(new_gpio_pin);
	if (result) {
		gpio_free(new_gpio_pin);
		return result;
	}
	result = add_gpio_ctx(new_gpio_pin, pin_name);
	if (result) {
		gpio_free(new_gpio_pin);
		return result;
	}

	return count;
}

static ssize_t gpio_pins_remove(struct kobject *kobj,
				struct kobj_attribute *attr, const char *buf,
				size_t count)
{
	int remove_gpio_pin;
	char pin_name[32];

	sscanf(buf, "%31s", pin_name);
	remove_gpio_pin = get_gpio_by_name(pin_name);

	if (remove_gpio_pin < 0) {
		ERROR_MESSAGE("Failed to get GPIO pin by name %s\n", pin_name);
		return -EINVAL;
	}

	remove_gpio_ctx(remove_gpio_pin);
	gpio_free(remove_gpio_pin);

	return count;
}

static struct kobj_attribute gpio_pins_add_attr =
	__ATTR(gpio_pins_add, 0660, NULL, gpio_pins_store);
static struct kobj_attribute gpio_pins_remove_attr =
	__ATTR(gpio_pins_remove, 0660, NULL, gpio_pins_remove);

static struct attribute *attrs[] = {
	&gpio_pins_add_attr.attr,
	&gpio_pins_remove_attr.attr,
	NULL,
};

static struct attribute_group attr_group = {
	.attrs = attrs,
};

static int __init pulse_counter_init(void)
{
	int result = 0, i;

	for (i = 0; i < MAX_GPIO_PINS; i++) {
		gpio_ctxs[i] = NULL;
	}

	kobject_init(&pulse_kobj, &pc_kobj_ktype);

	result = kobject_add(&pulse_kobj, kernel_kobj, "pulse_counter");
	if (result) {
		pr_warn("%s: kobject_add error: %d\n", __func__, result);
		kobject_put(&pulse_kobj);
	}

	result = sysfs_create_group(&pulse_kobj, &attr_group);
	if (result) {
		kobject_put(&pulse_kobj);
		return result;
	}

	INFO_MESSAGE("module loaded\n");
	return 0;
}

static void __exit pulse_counter_exit(void)
{
	int i;

	for (i = 0; i < MAX_GPIO_PINS; i++) {
		if (gpio_ctxs[i] != NULL) {
			free_irq(gpio_ctxs[i]->irq, gpio_ctxs[i]);
			gpio_free(gpio_ctxs[i]->pin);
			kobject_put(&gpio_ctxs[i]->kobj);
			kfree(gpio_ctxs[i]);
			gpio_ctxs[i] = NULL;
		}
	}

	sysfs_remove_group(&pulse_kobj, &attr_group);
	kobject_put(&pulse_kobj);
	INFO_MESSAGE("module unloaded\n");
}

module_init(pulse_counter_init);
module_exit(pulse_counter_exit);

MODULE_AUTHOR("Virginijus Bieliauskas <virginijus.bieliauskas@teltonika.lt>");
MODULE_DESCRIPTION("A Universal Pulse Counter GPIO Kernel Module");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("1.0");
