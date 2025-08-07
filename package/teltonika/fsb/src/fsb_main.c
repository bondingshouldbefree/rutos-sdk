/* SPDX-License-Identifier: GPL-2.0-only */
#include <linux/module.h>
#include <linux/slab.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <linux/uaccess.h>
#include <linux/version.h>

#include "fsb.h"

#define FSB_PROC_ROOT "bootconfig"

static fsb_context *fsb_ctx = NULL;

#if LINUX_VERSION_CODE < KERNEL_VERSION(5,17,0)
#define pde_data PDE_DATA
#endif

static int fsb_proc_slotprio_show(struct seq_file *m, void *v)
{
	fsb_slotinfo *slot;

	slot = m->private;
	seq_printf(m, "%d\n", (unsigned)slot->priority);
	return 0;
}

static int fsb_proc_slotprio_open(struct inode *inode, struct file *file)
{
	return single_open(file, fsb_proc_slotprio_show, pde_data(inode));
}

static ssize_t fsb_proc_slotprio_write(struct file *file,
				       const char __user *buf, size_t count,
				       loff_t *pos)
{
	fsb_slotinfo *slot;
	char kbuf[64];
	size_t len;
	int ret;
	unsigned long val;

	slot = pde_data(file_inode(file));

	len = min(count, sizeof(kbuf) - 1);
	ret = copy_from_user(kbuf, buf, len);
	if (ret)
		return -EFAULT;

	kbuf[len] = '\0';

	ret = kstrtoul(kbuf, 0, &val);
	if (ret)
		return -EINVAL;

	fsb_dbg("parsed value: %ld\n", val);

	if (val > 15)
		return -EINVAL;

	slot->priority = val;

	return count;
}

static const struct proc_ops fsb_proc_slotprio_fops = {
	.proc_open = fsb_proc_slotprio_open,
	.proc_read = seq_read,
	.proc_lseek = seq_lseek,
	.proc_release = single_release,
	.proc_write = fsb_proc_slotprio_write,
};

static int fsb_proc_slottries_show(struct seq_file *m, void *v)
{
	fsb_slotinfo *slot;

	slot = m->private;
	seq_printf(m, "%d\n", (unsigned)slot->tries_remaining);
	return 0;
}

static int fsb_proc_slottries_open(struct inode *inode, struct file *file)
{
	return single_open(file, fsb_proc_slottries_show, pde_data(inode));
}

static ssize_t fsb_proc_slottries_write(struct file *file,
				       const char __user *buf, size_t count,
				       loff_t *pos)
{
	fsb_slotinfo *slot;
	char kbuf[64];
	size_t len;
	int ret;
	unsigned long val;

	slot = pde_data(file_inode(file));

	len = min(count, sizeof(kbuf) - 1);
	ret = copy_from_user(kbuf, buf, len);
	if (ret)
		return -EFAULT;

	kbuf[len] = '\0';

	ret = kstrtoul(kbuf, 0, &val);
	if (ret)
		return -EINVAL;

	fsb_dbg("parsed value: %ld\n", val);

	if (val > 15)
		return -EINVAL;

	slot->tries_remaining = val;

	return count;
}

static const struct proc_ops fsb_proc_slottries_fops = {
	.proc_open = fsb_proc_slottries_open,
	.proc_read = seq_read,
	.proc_lseek = seq_lseek,
	.proc_release = single_release,
	.proc_write = fsb_proc_slottries_write,
};

static int fsb_proc_slotsuccess_show(struct seq_file *m, void *v)
{
	fsb_slotinfo *slot;

	slot = m->private;
	seq_printf(m, "%d\n", (unsigned)slot->successful_boot);
	return 0;
}

static int fsb_proc_slotsuccess_open(struct inode *inode, struct file *file)
{
	return single_open(file, fsb_proc_slotsuccess_show, pde_data(inode));
}

static ssize_t fsb_proc_slotsuccess_write(struct file *file,
				       const char __user *buf, size_t count,
				       loff_t *pos)
{
	fsb_slotinfo *slot;
	char kbuf[64];
	size_t len;
	int ret;
	unsigned long val;

	slot = pde_data(file_inode(file));

	len = min(count, sizeof(kbuf) - 1);
	ret = copy_from_user(kbuf, buf, len);
	if (ret)
		return -EFAULT;

	kbuf[len] = '\0';

	ret = kstrtoul(kbuf, 0, &val);
	if (ret)
		return -EINVAL;

	fsb_dbg("parsed value: %ld\n", val);

	if (val > 1)
		return -EINVAL;

	slot->successful_boot = val;

	return count;
}

static const struct proc_ops fsb_proc_slotsuccess_fops = {
	.proc_open = fsb_proc_slotsuccess_open,
	.proc_read = seq_read,
	.proc_lseek = seq_lseek,
	.proc_release = single_release,
	.proc_write = fsb_proc_slotsuccess_write,
};

static int fsb_proc_slotforce_show(struct seq_file *m, void *v)
{
	fsb_slotinfo *slot;

	slot = m->private;
	seq_printf(m, "%d\n", (unsigned)slot->force);
	return 0;
}

static int fsb_proc_slotforce_open(struct inode *inode, struct file *file)
{
	return single_open(file, fsb_proc_slotforce_show, pde_data(inode));
}

static ssize_t fsb_proc_slotforce_write(struct file *file,
				       const char __user *buf, size_t count,
				       loff_t *pos)
{
	fsb_slotinfo *slot;
	char kbuf[64];
	size_t len;
	int ret;
	unsigned long val;

	slot = pde_data(file_inode(file));

	len = min(count, sizeof(kbuf) - 1);
	ret = copy_from_user(kbuf, buf, len);
	if (ret)
		return -EFAULT;

	kbuf[len] = '\0';

	ret = kstrtoul(kbuf, 0, &val);
	if (ret)
		return -EINVAL;

	fsb_dbg("parsed value: %ld\n", val);

	if (val > 1)
		return -EINVAL;

	slot->force = val;

	return count;
}

static const struct proc_ops fsb_proc_slotforce_fops = {
	.proc_open = fsb_proc_slotforce_open,
	.proc_read = seq_read,
	.proc_lseek = seq_lseek,
	.proc_release = single_release,
	.proc_write = fsb_proc_slotforce_write,
};


static int fsb_proc_chosen_show(struct seq_file *m, void *v)
{
	fsb_context *ctx;

	ctx = m->private;
	seq_printf(m, "%s\n", fsb_slot_str(ctx->config_active.chosen));
	return 0;
}

static int fsb_proc_chosen_open(struct inode *inode, struct file *file)
{
	return single_open(file, fsb_proc_chosen_show, pde_data(inode));
}

static const struct proc_ops fsb_proc_chosen_fops = {
	.proc_open = fsb_proc_chosen_open,
	.proc_read = seq_read,
	.proc_lseek = seq_lseek,
	.proc_release = single_release,
};

static ssize_t fsb_proc_commit_write(struct file *file, const char __user *buf,
				     size_t count, loff_t *pos)
{
	fsb_context *ctx;
	char kbuf[64];
	size_t len;
	int ret;
	unsigned long val;

	ctx = pde_data(file_inode(file));

	len = min(count, sizeof(kbuf) - 1);
	ret = copy_from_user(kbuf, buf, len);
	if (ret)
		return -EFAULT;

	kbuf[len] = '\0';

	ret = kstrtoul(kbuf, 0, &val);
	if (ret)
		return -EINVAL;

	fsb_dbg("parsed value: %ld\n", val);
	fsb_config_dbg(&ctx->config_new);

	if (val != 1)
		return -EINVAL;

	ret = fsb_context_save(ctx);
	if (ret)
		return -EIO;

	return count;
}

static const struct proc_ops fsb_proc_commit_fops = {
	.proc_open = simple_open,
	.proc_write = fsb_proc_commit_write,
};

static int fsb_proc_slot_setup(int slot, struct proc_dir_entry *proc_root)
{
	struct proc_dir_entry *proc_dir;
	struct proc_dir_entry *proc_entry;

	proc_dir = proc_mkdir(fsb_slot_str(slot), proc_root);
	if (!proc_dir)
		return -ENOMEM;

	proc_entry = proc_create_data("priority", 0644, proc_dir,
				      &fsb_proc_slotprio_fops,
				      &(fsb_ctx->config_new.slots[slot]));
	if (!proc_entry)
		return -ENOMEM;

	proc_entry = proc_create_data("tries_remaining", 0644, proc_dir,
				      &fsb_proc_slottries_fops,
				      &(fsb_ctx->config_new.slots[slot]));
	if (!proc_entry)
		return -ENOMEM;

	proc_entry = proc_create_data("successful_boot", 0644, proc_dir,
				      &fsb_proc_slotsuccess_fops,
				      &(fsb_ctx->config_new.slots[slot]));
	if (!proc_entry)
		return -ENOMEM;

	proc_entry = proc_create_data("force", 0644, proc_dir,
				      &fsb_proc_slotforce_fops,
				      &(fsb_ctx->config_new.slots[slot]));
	if (!proc_entry)
		return -ENOMEM;

	return 0;
}

static int fsb_proc_tree_setup(void)
{
	struct proc_dir_entry *proc_root;
	struct proc_dir_entry *proc_entry;
	int ret;
	int i;

	proc_root = proc_mkdir(FSB_PROC_ROOT, NULL);
	if (!proc_root)
		return -ENOMEM;

	for (i = 0; i < FSB_CONFIG_NUM_SLOTS; i++) {
		ret = fsb_proc_slot_setup(i, proc_root);
		if (ret)
			return ret;
	}

	proc_entry = proc_create_data("chosen", 0444, proc_root,
				      &fsb_proc_chosen_fops, fsb_ctx);
	if (!proc_entry)
		return -ENOMEM;

	proc_entry = proc_create_data("commit", 0200, proc_root,
				      &fsb_proc_commit_fops, fsb_ctx);
	if (!proc_entry)
		return -ENOMEM;

	return 0;
}

static void fsb_proc_tree_teardown(void)
{
	remove_proc_subtree(FSB_PROC_ROOT, NULL);
}

static void fsb_module_exit(void)
{
	fsb_dbg("module_exit\n");

	fsb_proc_tree_teardown();
	kfree(fsb_ctx);
}

static int __init fsb_module_init(void)
{
	int ret = 0;

	fsb_dbg("module_init\n");

	fsb_ctx = (fsb_context *)kzalloc(sizeof(fsb_context), GFP_KERNEL);
	if (!fsb_ctx) {
		fsb_err("Failed to allocate fsb context\n");
		return -ENOMEM;
	}

	fsb_context_load(fsb_ctx);
	fsb_info("chosen slot: %s\n", fsb_slot_str(fsb_ctx->config_active.chosen));
	fsb_config_dbg(&fsb_ctx->config_active);

	ret = fsb_proc_tree_setup();
	if (ret)
		goto cleanup;

	return 0;
cleanup:
	fsb_module_exit();
	return ret;
}

module_init(fsb_module_init);
module_exit(fsb_module_exit);

MODULE_LICENSE("GPL");
