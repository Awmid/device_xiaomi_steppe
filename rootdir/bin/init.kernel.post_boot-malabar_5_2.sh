#=============================================================================
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# All rights reserved.
# Confidential and Proprietary - Qualcomm Technologies, Inc.
#=============================================================================

rev=`cat /sys/devices/soc0/revision`

# Configure RT parameters:
# Long running RT task detection is confined to consolidated builds.
# Set RT throttle runtime to 50ms more than long running RT
# task detection time.
# Set RT throttle period to 100ms more than RT throttle runtime.
long_running_rt_task_ms=1200
sched_rt_runtime_ms=`expr $long_running_rt_task_ms + 50`
sched_rt_runtime_us=`expr $sched_rt_runtime_ms \* 1000`
sched_rt_period_ms=`expr $sched_rt_runtime_ms + 100`
sched_rt_period_us=`expr $sched_rt_period_ms \* 1000`
echo $sched_rt_period_us > /proc/sys/kernel/sched_rt_period_us
echo $sched_rt_runtime_us > /proc/sys/kernel/sched_rt_runtime_us

if [ -d /proc/sys/walt ]; then
	# configure maximum frequency when CPUs are partially halted
	echo 2147483647 > /proc/sys/walt/sched_max_freq_partial_halt

	# Core control parameters for Silver
	echo 1 > /sys/devices/system/cpu/cpu0/core_ctl/enable
	echo 3 > /sys/devices/system/cpu/cpu0/core_ctl/min_cpus
	echo 60 > /sys/devices/system/cpu/cpu0/core_ctl/busy_up_thres
	echo 40 > /sys/devices/system/cpu/cpu0/core_ctl/busy_down_thres
	echo 100 > /sys/devices/system/cpu/cpu0/core_ctl/offline_delay_ms
	echo 8 > /sys/devices/system/cpu/cpu0/core_ctl/task_thres
	echo 0 0 0 1 1 > /sys/devices/system/cpu/cpu0/core_ctl/not_preferred
	echo 0x1F > /sys/devices/system/cpu/cpu0/core_ctl/nrrun_cpu_mask
	echo 0x60 > /sys/devices/system/cpu/cpu0/core_ctl/nrrun_cpu_misfit_mask
	echo 0x00 > /sys/devices/system/cpu/cpu0/core_ctl/assist_cpu_mask
	echo 0x00 > /sys/devices/system/cpu/cpu0/core_ctl/assist_cpu_misfit_mask

	# Disable Core control parameter for gold
	echo 0 > /sys/devices/system/cpu/cpu5/core_ctl/enable

	# Configure Single Boost Thread
	echo 0 > /proc/sys/walt/sched_sbt_delay_windows
	echo 0x00 > /proc/sys/walt/sched_sbt_pause_cpus

	# Setting b.L scheduler parameters
	echo 71 65 > /proc/sys/walt/cluster0/sched_background_updownmigrate
	echo 71 65 > /proc/sys/walt/cluster0/sched_foreground_updownmigrate
	echo 71 65 > /proc/sys/walt/cluster0/sched_other_cgroup_updownmigrate
	echo 71 65 > /proc/sys/walt/cluster0/sched_topapp_updownmigrate

	echo 85 > /proc/sys/walt/sched_group_downmigrate
	echo 100 > /proc/sys/walt/sched_group_upmigrate
	echo 1 > /proc/sys/walt/sched_walt_rotate_big_tasks
	echo 400000000 > /proc/sys/walt/sched_coloc_downmigrate_ns
	echo 0 > /proc/sys/walt/sched_coloc_busy_hysteresis_enable_cpus
	echo 255 > /proc/sys/walt/sched_util_busy_hysteresis_enable_cpus
	echo 40 > /proc/sys/walt/sched_cluster_util_thres_pct
	echo 30 > /proc/sys/walt/sched_idle_enough

	#Set early upmigrate tunables
	sched_upmigrate=`cat /proc/sys/walt/sched_upmigrate`
	sched_downmigrate=`cat /proc/sys/walt/sched_downmigrate`
	sched_upmigrate=${sched_upmigrate:0:2}
	sched_downmigrate=${sched_downmigrate:0:2}
	gold_early_upmigrate=`expr \( 1024 \* 100 \) \/ $sched_upmigrate`
	gold_early_downmigrate=`expr \( 1024 \* 100 \) \/ $sched_downmigrate`
	echo $gold_early_downmigrate > /proc/sys/walt/sched_early_downmigrate
	echo $gold_early_upmigrate > /proc/sys/walt/sched_early_upmigrate

	# Enable Gold CPUs for pipeline
	echo 56 > /proc/sys/walt/sched_pipeline_cpus
	echo 1 > /proc/sys/walt/sched_pipeline_force_config

	# Turn off scheduler boost at the end
	echo 0 > /proc/sys/walt/sched_boost

	echo 1 > /proc/sys/walt/sched_conservative_pl

	echo 0 1804800 6 2611200 7 2611200 8 2611200 10 2611200 > /proc/sys/walt/cluster0/smart_freq/legacy_freq_levels
	echo 0 2054400 6 3244800 7 3244800 8 3244800 10 3244800 > /proc/sys/walt/cluster1/smart_freq/legacy_freq_levels

	echo 1110000 0 0 0 0 0 0 > /proc/sys/walt/input_boost/input_boost_freq

	echo 120 > /proc/sys/walt/input_boost/input_boost_ms

	echo "walt" > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
	echo "walt" > /sys/devices/system/cpu/cpufreq/policy5/scaling_governor

	echo 0 > /sys/devices/system/cpu/cpufreq/policy0/walt/down_rate_limit_us
	echo 0 > /sys/devices/system/cpu/cpufreq/policy0/walt/up_rate_limit_us
	echo 0 > /sys/devices/system/cpu/cpufreq/policy5/walt/down_rate_limit_us
	echo 0 > /sys/devices/system/cpu/cpufreq/policy5/walt/up_rate_limit_us

	echo 0 > /sys/devices/system/cpu/cpufreq/policy0/walt/pl
	echo 0 > /sys/devices/system/cpu/cpufreq/policy5/walt/pl

	echo 85 > /sys/devices/system/cpu/cpufreq/policy0/walt/hispeed_load
	echo 85 > /sys/devices/system/cpu/cpufreq/policy5/walt/hispeed_load

	echo 0 > /sys/devices/system/cpu/cpufreq/policy0/walt/boost
	echo -6 > /sys/devices/system/cpu/cpufreq/policy5/walt/boost

	echo 614400 > /sys/devices/system/cpu/cpufreq/policy0/walt/rtg_boost_freq
	echo 0 > /sys/devices/system/cpu/cpufreq/policy5/walt/rtg_boost_freq
	echo 1094000 > /sys/devices/system/cpu/cpufreq/policy0/walt/hispeed_freq
	echo 1190000 > /sys/devices/system/cpu/cpufreq/policy5/walt/hispeed_freq

else
	echo "schedutil" > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
	echo "schedutil" > /sys/devices/system/cpu/cpufreq/policy5/scaling_governor
	echo 1 > /proc/sys/kernel/sched_pelt_multiplier
fi

	echo 672000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
	echo 691200 > /sys/devices/system/cpu/cpufreq/policy5/scaling_min_freq
	echo "0:672000 5:691200" > /data/vendor/perfd/default_scaling_min_freq

# Reset the RT boost, which is 1024 (max) by default.
echo 0 > /proc/sys/kernel/sched_util_clamp_min_rt_default

# cpuset parameters
echo 0-3 > /dev/cpuset/background/cpus
echo 0-3 > /dev/cpuset/system-background/cpus

# configure bus-dcvs
bus_dcvs="/sys/devices/system/cpu/bus_dcvs"

for device in $bus_dcvs/*
do
cat $device/hw_min_freq > $device/boost_freq
done

for ddrbw in $bus_dcvs/DDR/*bwmon-ddr
do
echo "1144 1720 2086 2929 3879 5161 5931 6515 8136" > $ddrbw/mbps_zones
echo 4 > $ddrbw/sample_ms
echo 68 > $ddrbw/io_percent
echo 20 > $ddrbw/hist_memory
echo 80 > $ddrbw/down_thres
echo 0 > $ddrbw/guard_band_mbps
echo 250 > $ddrbw/up_scale
echo 1600 > $ddrbw/idle_mbps
echo 48 > $ddrbw/window_ms
done

for l3gold in $bus_dcvs/L3/*gold
do
echo 4000 > $l3gold/ipm_ceil
done

for qosgold in $bus_dcvs/DDRQOS/*gold
do
echo 4000 > $qosgold/ipm_ceil
done

echo s2idle > /sys/power/mem_sleep
echo N > /sys/devices/system/cpu/qcom_lpm/parameters/sleep_disabled

echo 4 > /proc/sys/kernel/printk

# Change console log level as per console config property
console_config=`getprop persist.vendor.console.silent.config`
case "$console_config" in
	"1")
		echo "Enable console config to $console_config"
		echo 0 > /proc/sys/kernel/printk
	;;
	*)
		echo "Enable console config to $console_config"
	;;
esac

setprop vendor.post_boot.parsed 1
