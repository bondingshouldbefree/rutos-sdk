#!/bin/sh

PROC_MASK="f"

# Since EDMA has broken RSS, it is disabled.
# We make sure it's replaced it with RPS:
for dev in eth0 eth1
do
	for rxq in /sys/class/net/${dev}/queues/rx-*
	do
		echo $PROC_MASK > $rxq/rps_cpus
	done
done

# In the same vein, we also enable threaded NAPI:
echo 1 > /sys/class/net/eth0/threaded
