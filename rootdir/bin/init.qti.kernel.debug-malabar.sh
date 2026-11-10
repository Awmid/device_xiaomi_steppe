#=============================================================================
#  Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
#  All rights reserved.
#  Confidential and Proprietary - Qualcomm Technologies, Inc.
#=============================================================================

enable_tracing_events()
{
    # clock
    echo 1 > /sys/kernel/tracing/events/power/clock_set_rate/enable
    echo 1 > /sys/kernel/tracing/events/power/clock_enable/enable
    echo 1 > /sys/kernel/tracing/events/power/clock_disable/enable
    echo 1 > /sys/kernel/tracing/events/power/cpu_frequency/enable
    # regulator
    echo 1 > /sys/kernel/tracing/events/regulator/enable
    # fastrpc
    echo 1 > /sys/kernel/tracing/events/fastrpc/enable

    #EMMC
    echo 1 > /sys/kernel/tracing/events/mmc/mmc_request_start/enable
    echo 1 > /sys/kernel/tracing/events/mmc/mmc_request_done/enable

    echo 4096 > /sys/kernel/tracing/buffer_size_kb
    echo 1 > /sys/kernel/tracing/tracing_on
}

# function to enable ftrace events
enable_ftrace_event_tracing()
{
    # bail out if its perf config
    if [ "$debug_build" = false ]
    then
        return
    fi

    # bail out if ftrace events aren't present
    if [ ! -d /sys/kernel/tracing/events ]
    then
        return
    fi

    enable_tracing_events
}

enable_stm_events()
{
    # bail out if its perf config
    if [ "$debug_build" = false ]
    then
        return
    fi
    # bail out if coresight isn't present
    if [ ! -d /sys/bus/coresight ]
    then
        return
    fi
    # bail out if ftrace events aren't present
    if [ ! -d /sys/kernel/tracing/events ]
    then
        return
    fi

   echo "configure trace sink settings"
   echo 1 > /sys/bus/coresight/reset_source_sink
   echo mem > /sys/bus/coresight/devices/tmc_etr0/out_mode
   echo 1 > /sys/bus/coresight/devices/tmc_etr0/enable_sink
   echo 0x2000000 > /sys/bus/coresight/devices/tmc_etr0/buffer_size
   echo coresight-stm > /sys/class/stm_source/ftrace/stm_source_link
   echo 1 > /sys/bus/coresight/devices/stm0/enable_source
   echo 1 > /sys/kernel/tracing/tracing_on
   echo 0 > /sys/bus/coresight/devices/stm0/hwevent_enable
   enable_tracing_events
}

config_dcc_core()
{
    echo 0xF86004C  > $DCC_PATH/config
    echo 0xF800024  > $DCC_PATH/config
    echo 0xF800040  > $DCC_PATH/config
    echo 0xF80004C  > $DCC_PATH/config
    echo 0xF800054  > $DCC_PATH/config
    echo 0xF810024  > $DCC_PATH/config
    echo 0xF810040  > $DCC_PATH/config
    echo 0xF81004C  > $DCC_PATH/config
    echo 0xF810054  > $DCC_PATH/config
    echo 0xF820024  > $DCC_PATH/config
    echo 0xF820040  > $DCC_PATH/config
    echo 0xF82004C  > $DCC_PATH/config
    echo 0xF820054  > $DCC_PATH/config
    echo 0xF830024  > $DCC_PATH/config
    echo 0xF830040  > $DCC_PATH/config
    echo 0xF83004C  > $DCC_PATH/config
    echo 0xF830054  > $DCC_PATH/config
    echo 0xF840024  > $DCC_PATH/config
    echo 0xF840040  > $DCC_PATH/config
    echo 0xF84004C  > $DCC_PATH/config
    echo 0xF840054  > $DCC_PATH/config
    echo 0xF850024  > $DCC_PATH/config
    echo 0xF850040  > $DCC_PATH/config
    echo 0xF85004C  > $DCC_PATH/config
    echo 0xF850054  > $DCC_PATH/config
    echo 0xF860024  > $DCC_PATH/config
    echo 0xF860040  > $DCC_PATH/config
    echo 0xF860054  > $DCC_PATH/config
    echo 0xF870024  > $DCC_PATH/config
    echo 0xF870040  > $DCC_PATH/config
    echo 0xF87004C  > $DCC_PATH/config
    echo 0xF870054  > $DCC_PATH/config
    echo 0xF880024  > $DCC_PATH/config
    echo 0xF880040  > $DCC_PATH/config
    echo 0xF880098  > $DCC_PATH/config
    echo 0xF8801B4 3 > $DCC_PATH/config
    echo 0xF880200  > $DCC_PATH/config
    echo 0xFA80000 2 > $DCC_PATH/config
    echo 0xFA80000 2 > $DCC_PATH/config
    echo 0xFA8003C  > $DCC_PATH/config
    echo 0xFA84000 2 > $DCC_PATH/config
    echo 0xFA8403C  > $DCC_PATH/config
    echo 0xFA88000 2 > $DCC_PATH/config
    echo 0xFA8803C  > $DCC_PATH/config
    echo 0x0f40003c > $DCC_PATH/config

    #CPR
    echo 0x1648000 2 > $DCC_PATH/config
    echo 0x16480E0  > $DCC_PATH/config
    echo 0x1648100  > $DCC_PATH/config
    echo 0x1648120  > $DCC_PATH/config
    echo 0x1648140  > $DCC_PATH/config
    echo 0x1648200  > $DCC_PATH/config
    echo 0x164880C 4 > $DCC_PATH/config
    echo 0x164B280  > $DCC_PATH/config
    echo 0x164B288  > $DCC_PATH/config
    echo 0x164C000 2 > $DCC_PATH/config
    echo 0x164C0E0  > $DCC_PATH/config
    echo 0x164C100  > $DCC_PATH/config
    echo 0x164C120  > $DCC_PATH/config
    echo 0x164C140  > $DCC_PATH/config
    echo 0x164C200  > $DCC_PATH/config
    echo 0x164C80C 4 > $DCC_PATH/config
    echo 0x164F280  > $DCC_PATH/config
    echo 0x164F288  > $DCC_PATH/config
    echo 0x599A000 2 > $DCC_PATH/config
    echo 0x599A0E0  > $DCC_PATH/config
    echo 0x599A100  > $DCC_PATH/config
    echo 0x599A120  > $DCC_PATH/config
    echo 0x599A140  > $DCC_PATH/config
    echo 0x599A200  > $DCC_PATH/config
    echo 0x599A80C 4 > $DCC_PATH/config
    echo 0x599D280  > $DCC_PATH/config
    echo 0x599D288  > $DCC_PATH/config
    #systemparameters
    echo 0x0F900C00  > $DCC_PATH/config
    echo 0x0FB00000  > $DCC_PATH/config
    echo 0x0FBA0000  > $DCC_PATH/config
    echo 0x0F800000  > $DCC_PATH/config
    echo 0x0F810000  > $DCC_PATH/config
    echo 0x0F820000  > $DCC_PATH/config
    echo 0x0F830000  > $DCC_PATH/config
    echo 0x0F840000  > $DCC_PATH/config
    echo 0x0F850000  > $DCC_PATH/config
    echo 0x0F860000  > $DCC_PATH/config
    echo 0x0F870000  > $DCC_PATH/config
    echo 0x0FD91000  > $DCC_PATH/config
    echo 0x0FD92000  > $DCC_PATH/config
    echo 0x0F880000  > $DCC_PATH/config
    echo 0x0FD90000  > $DCC_PATH/config
    echo 0x0F900C18 > $DCC_PATH/config
    echo 0x0FD9134C > $DCC_PATH/config
    echo 0x0FD9234C > $DCC_PATH/config
    echo 0x0FD9034C > $DCC_PATH/config
    echo 0xFBA3A84 > $DCC_PATH/config
    echo 0xFBA3A88 > $DCC_PATH/config
    echo 0xFBA3A8C > $DCC_PATH/config
    echo 0xFD91020 > $DCC_PATH/config
    echo 0xFD92020 > $DCC_PATH/config
    echo 0xFD90020 > $DCC_PATH/config
}

config_dcc_ppat()
{
    echo 0xFA90004  > $DCC_PATH/config
    echo 0xFA92004  > $DCC_PATH/config
    echo 0xFA94004  > $DCC_PATH/config
    echo 0xFB00000 66 > $DCC_PATH/config
    echo 0xFB00110 2 > $DCC_PATH/config
    echo 0xFBA3A8C  > $DCC_PATH/config
    echo 0xFD80000 7 > $DCC_PATH/config
    echo 0xFD8018C  > $DCC_PATH/config
    echo 0xFD80200  > $DCC_PATH/config
    echo 0xFD98010 2 > $DCC_PATH/config
    echo 0xFD98024  > $DCC_PATH/config
}

config_dcc_modem_rsc()
{
    echo 0x6080304  > $DCC_PATH/config
    echo 0x608030C  > $DCC_PATH/config
    echo 0x6082028  > $DCC_PATH/config
    echo 0x6140208 3 > $DCC_PATH/config
    echo 0x6140228 3 > $DCC_PATH/config
    echo 0x6140248 3 > $DCC_PATH/config
    echo 0x6140268 3 > $DCC_PATH/config
    echo 0x6140400 3 > $DCC_PATH/config
    echo 0x6200208 3 > $DCC_PATH/config
    echo 0x6200228 3 > $DCC_PATH/config
    echo 0x6200248 3 > $DCC_PATH/config
    echo 0x6200268 3 > $DCC_PATH/config
    echo 0x6200400 3 > $DCC_PATH/config
}

config_dcc_tsens()
{
    echo 0x4410004 1 > $DCC_PATH/config
    echo 0x4411014 1 > $DCC_PATH/config
    echo 0x44110E0 1 > $DCC_PATH/config
    echo 0x44110EC 1 > $DCC_PATH/config
    echo 0x44110A0 16 > $DCC_PATH/config
    echo 0x44110E8 1 > $DCC_PATH/config
    echo 0x441113C 1 > $DCC_PATH/config
    echo 0xFB784A0 12 > $DCC_PATH/config
    echo 0xFB78520 1 > $DCC_PATH/config
    echo 0xFB78524 1 > $DCC_PATH/config
    echo 0xFB78588 1 > $DCC_PATH/config
    echo 0xFB78D10  12 > $DCC_PATH/config
    echo 0xFB78F90  10 > $DCC_PATH/config
    echo 0xFB79010  10 > $DCC_PATH/config
    echo 0xFB79A10  8 > $DCC_PATH/config
}

config_dcc_cpr()
{
    echo 0x1B442C8  > $DCC_PATH/config
    echo 0x1B442D8 25 > $DCC_PATH/config
    #echo 0x2BD80000 2 > $DCC_PATH/config
    echo 0x2BD800E0  > $DCC_PATH/config
    echo 0x2BD80100  > $DCC_PATH/config
    echo 0x2BD80120  > $DCC_PATH/config
    echo 0x2BD80140  > $DCC_PATH/config
    echo 0x2BD80200  > $DCC_PATH/config
    echo 0x2BD8080C 4 > $DCC_PATH/config
    echo 0x2BD83280  > $DCC_PATH/config
    echo 0x2BD83288  > $DCC_PATH/config
}
config_dcc_gpu()
{
    echo 0x5900000  > $DCC_PATH/config
    echo 0x5900008  > $DCC_PATH/config
    echo 0x5900060 4 > $DCC_PATH/config
    echo 0x590007c 20 > $DCC_PATH/config
    echo 0x59000e0 5 > $DCC_PATH/config
    echo 0x5900108  > $DCC_PATH/config
    echo 0x5900110  > $DCC_PATH/config
    echo 0x590011c  > $DCC_PATH/config
    echo 0x5900124 2 > $DCC_PATH/config
    echo 0x5900140  > $DCC_PATH/config
    echo 0x5900158  > $DCC_PATH/config
    echo 0x59002b4 2 > $DCC_PATH/config
    echo 0x59002c0  > $DCC_PATH/config
    echo 0x59002d0  > $DCC_PATH/config
    echo 0x59002e0  > $DCC_PATH/config
    echo 0x59002f0  > $DCC_PATH/config
    echo 0x5900300  > $DCC_PATH/config
    echo 0x5900310  > $DCC_PATH/config
    echo 0x5900320  > $DCC_PATH/config
    echo 0x5900330  > $DCC_PATH/config
    echo 0x5900340  > $DCC_PATH/config
    echo 0x5900350  > $DCC_PATH/config
    echo 0x5900360  > $DCC_PATH/config
    echo 0x5900370  > $DCC_PATH/config
    echo 0x5900380  > $DCC_PATH/config
    echo 0x5900390  > $DCC_PATH/config
    echo 0x59003a0  > $DCC_PATH/config
    echo 0x59003b0  > $DCC_PATH/config
    echo 0x59003c0  > $DCC_PATH/config
    echo 0x59003d0  > $DCC_PATH/config
    echo 0x59003e0  > $DCC_PATH/config
    echo 0x5900400  > $DCC_PATH/config
    echo 0x5900410 8 > $DCC_PATH/config
    echo 0x590043c 15 > $DCC_PATH/config
    echo 0x5900800 14 > $DCC_PATH/config
    echo 0x5900840 4 > $DCC_PATH/config
    echo 0x5900854  > $DCC_PATH/config
    echo 0x5900860 38 > $DCC_PATH/config
    echo 0x5901444  > $DCC_PATH/config
    echo 0x590201c  > $DCC_PATH/config
    echo 0x590f000  > $DCC_PATH/config
    echo 0x590f114 3 > $DCC_PATH/config
    echo 0x597e648 2 > $DCC_PATH/config
    echo 0x597e658 9 > $DCC_PATH/config
    echo 0x597e7c0  > $DCC_PATH/config
    echo 0x598ec0c  > $DCC_PATH/config
    echo 0x598ec14 2 > $DCC_PATH/config
    echo 0x598ec30 3 > $DCC_PATH/config
    echo 0x598ec40 4 > $DCC_PATH/config
    echo 0x598ec54  > $DCC_PATH/config
    echo 0x5990000 15 > $DCC_PATH/config
    echo 0x5991000 15 > $DCC_PATH/config
    echo 0x5994000 2 > $DCC_PATH/config
    echo 0x5995000 2 > $DCC_PATH/config
    echo 0x599500c  > $DCC_PATH/config
    echo 0x5996000 2 > $DCC_PATH/config
    echo 0x599600c  > $DCC_PATH/config
    echo 0x5997000 2 > $DCC_PATH/config
    echo 0x599700c  > $DCC_PATH/config
    echo 0x5998000 2 > $DCC_PATH/config
    echo 0x599800c  > $DCC_PATH/config
    echo 0x5999000 4 > $DCC_PATH/config
    echo 0x5999048 8 > $DCC_PATH/config
    echo 0x599906c 2 > $DCC_PATH/config
    echo 0x59990a4 3 > $DCC_PATH/config
    echo 0x59990b4  > $DCC_PATH/config
    echo 0x59990c8 12 > $DCC_PATH/config
    echo 0x59990fc 5 > $DCC_PATH/config
    echo 0x5999114 2 > $DCC_PATH/config
    echo 0x599912c 3 > $DCC_PATH/config
    echo 0x5999140  > $DCC_PATH/config
    echo 0x5999148 2 > $DCC_PATH/config
    echo 0x599915c 3 > $DCC_PATH/config
    echo 0x5999184  > $DCC_PATH/config
    echo 0x59991a0 14 > $DCC_PATH/config
    echo 0x59991dc 2 > $DCC_PATH/config
    echo 0x59991e8 7 > $DCC_PATH/config
    echo 0x5999240  > $DCC_PATH/config
    echo 0x599e000  > $DCC_PATH/config
    echo 0x599e040 5 > $DCC_PATH/config
    echo 0x599e080 5 > $DCC_PATH/config
    echo 0x599e0cc 6 > $DCC_PATH/config
    echo 0x599e144  > $DCC_PATH/config
}

config_dcc_pcu()
{
    echo 0xF80004C  > $DCC_PATH/config
    echo 0xF81004C  > $DCC_PATH/config
    echo 0xF82004C  > $DCC_PATH/config
    echo 0xF83004C  > $DCC_PATH/config
    echo 0xF84004C  > $DCC_PATH/config
    echo 0xF85004C  > $DCC_PATH/config
    echo 0xF86004C  > $DCC_PATH/config
    echo 0xF87004C  > $DCC_PATH/config
    echo 0xF800024  > $DCC_PATH/config
    echo 0xF800040  > $DCC_PATH/config
    echo 0xF800054  > $DCC_PATH/config
    echo 0xF810024  > $DCC_PATH/config
    echo 0xF810040  > $DCC_PATH/config
    echo 0xF810054  > $DCC_PATH/config
    echo 0xF820024  > $DCC_PATH/config
    echo 0xF820040  > $DCC_PATH/config
    echo 0xF820054  > $DCC_PATH/config
    echo 0xF830024  > $DCC_PATH/config
    echo 0xF830040  > $DCC_PATH/config
    echo 0xF830054  > $DCC_PATH/config
    echo 0xF840024  > $DCC_PATH/config
    echo 0xF840040  > $DCC_PATH/config
    echo 0xF840054  > $DCC_PATH/config
    echo 0xF850024  > $DCC_PATH/config
    echo 0xF850040  > $DCC_PATH/config
    echo 0xF850054  > $DCC_PATH/config
    echo 0xF860024  > $DCC_PATH/config
    echo 0xF860040  > $DCC_PATH/config
    echo 0xF860054  > $DCC_PATH/config
    echo 0xF870024  > $DCC_PATH/config
    echo 0xF870040  > $DCC_PATH/config
    echo 0xF870054  > $DCC_PATH/config
    echo 0xF880024  > $DCC_PATH/config
    echo 0xF880040  > $DCC_PATH/config
    echo 0xF880098  > $DCC_PATH/config
    echo 0xF8801B4 3 > $DCC_PATH/config
    echo 0xF880200  > $DCC_PATH/config
    echo 0xFA80000 2 > $DCC_PATH/config
    echo 0xFA8003C  > $DCC_PATH/config
    echo 0xFA84000 2 > $DCC_PATH/config
    echo 0xFA8403C  > $DCC_PATH/config
    echo 0xFA88000 2 > $DCC_PATH/config
    echo 0xFA8803C  > $DCC_PATH/config
}

config_dcc_lpass()
{
    echo 0xA400304 3 > $DCC_PATH/config
    echo 0xA402028  > $DCC_PATH/config
    echo 0xA4C0208 3 > $DCC_PATH/config
    echo 0xA4C0228 3 > $DCC_PATH/config
    echo 0xA4C0248 3 > $DCC_PATH/config
    echo 0xA4C0268 3 > $DCC_PATH/config
    echo 0xA4C0404 2 > $DCC_PATH/config
    echo 0xA751024  > $DCC_PATH/config
    echo 0xA751044 2 > $DCC_PATH/config
    echo 0xA751058 2 > $DCC_PATH/config
    echo 0xA75106C 2 > $DCC_PATH/config
    echo 0xA751080 2 > $DCC_PATH/config
    echo 0xA900208 3 > $DCC_PATH/config
    echo 0xA900228 3 > $DCC_PATH/config
    echo 0xA900248 3 > $DCC_PATH/config
    echo 0xA900268 3 > $DCC_PATH/config
    echo 0xA900408  > $DCC_PATH/config
}

config_dcc_ddr()
{
    echo 0x4480040 2 > $DCC_PATH/config
    echo 0x4480810 2 > $DCC_PATH/config
    echo 0x4488100 > $DCC_PATH/config
    echo 0x4488400 2 > $DCC_PATH/config
    echo 0x4488410 > $DCC_PATH/config
    echo 0x4488420 2 > $DCC_PATH/config
    echo 0x4488430 2 > $DCC_PATH/config
    echo 0x4488440 2 > $DCC_PATH/config
    echo 0x4488450 > $DCC_PATH/config
    echo 0x448c100 > $DCC_PATH/config
    echo 0x448c400 2 > $DCC_PATH/config
    echo 0x448c410 > $DCC_PATH/config
    echo 0x448c420 2 > $DCC_PATH/config
    echo 0x448c430 2 > $DCC_PATH/config
    echo 0x448c440 2 > $DCC_PATH/config
    echo 0x448c450 > $DCC_PATH/config
    echo 0x4490100 > $DCC_PATH/config
    echo 0x4490400 2 > $DCC_PATH/config
    echo 0x4490410 > $DCC_PATH/config
    echo 0x4490420 2 > $DCC_PATH/config
    echo 0x4490430 2 > $DCC_PATH/config
    echo 0x4490440 2 > $DCC_PATH/config
    echo 0x4490450 > $DCC_PATH/config
    echo 0x4494100 > $DCC_PATH/config
    echo 0x4494400 2 > $DCC_PATH/config
    echo 0x4494410 > $DCC_PATH/config
    echo 0x4494420 2 > $DCC_PATH/config
    echo 0x4494430 2 > $DCC_PATH/config
    echo 0x4494440 2 > $DCC_PATH/config
    echo 0x4494450 > $DCC_PATH/config
    echo 0x4498100 > $DCC_PATH/config
    echo 0x4498400 2 > $DCC_PATH/config
    echo 0x4498410 > $DCC_PATH/config
    echo 0x4498420 2 > $DCC_PATH/config
    echo 0x4498430 2 > $DCC_PATH/config
    echo 0x4498440 2 > $DCC_PATH/config
    echo 0x4498450 > $DCC_PATH/config
    echo 0x449c400 2 > $DCC_PATH/config
    echo 0x449c420 2 > $DCC_PATH/config
    echo 0x449c430 > $DCC_PATH/config
    echo 0x449c440 2 > $DCC_PATH/config
    echo 0x449c450 > $DCC_PATH/config
    echo 0x44a0400 2 > $DCC_PATH/config
    echo 0x44a0420 2 > $DCC_PATH/config
    echo 0x44a0430 > $DCC_PATH/config
    echo 0x44a0440 2 > $DCC_PATH/config
    echo 0x44a0450 > $DCC_PATH/config
    echo 0x44a4100 > $DCC_PATH/config
    echo 0x44a4400 2 > $DCC_PATH/config
    echo 0x44a4410 > $DCC_PATH/config
    echo 0x44a4420 2 > $DCC_PATH/config
    echo 0x44a4430 2 > $DCC_PATH/config
    echo 0x44a4440 2 > $DCC_PATH/config
    echo 0x44a4450 > $DCC_PATH/config
    echo 0x44b0020 > $DCC_PATH/config
    echo 0x44b0100 > $DCC_PATH/config
    echo 0x44b0120 5 > $DCC_PATH/config
    echo 0x44b0140 > $DCC_PATH/config
    echo 0x44b0450 > $DCC_PATH/config
    echo 0x44b0500 > $DCC_PATH/config
    echo 0x44b0520 > $DCC_PATH/config
    echo 0x44b0560 > $DCC_PATH/config
    echo 0x44b05a0 > $DCC_PATH/config
    echo 0x44b0710 > $DCC_PATH/config
    echo 0x44b0720 > $DCC_PATH/config
    echo 0x44b0a40 > $DCC_PATH/config
    echo 0x44b1800 > $DCC_PATH/config
    echo 0x44b408c > $DCC_PATH/config
    echo 0x44b409c 3 > $DCC_PATH/config
    echo 0x44b40b8 > $DCC_PATH/config
    echo 0x44b5070 2 > $DCC_PATH/config
    echo 0x44bc020 > $DCC_PATH/config
    echo 0x44bc100 > $DCC_PATH/config
    echo 0x44bc120 4 > $DCC_PATH/config
    echo 0x44bc140 > $DCC_PATH/config
    echo 0x44bc450 > $DCC_PATH/config
    echo 0x44bc500 > $DCC_PATH/config
    echo 0x44bc520 > $DCC_PATH/config
    echo 0x44bc560 > $DCC_PATH/config
    echo 0x44bc5a0 > $DCC_PATH/config
    echo 0x44bc710 > $DCC_PATH/config
    echo 0x44bc720 > $DCC_PATH/config
    echo 0x44bca40 > $DCC_PATH/config
    echo 0x44bd800 > $DCC_PATH/config
    echo 0x44c008c > $DCC_PATH/config
    echo 0x44c009c 3 > $DCC_PATH/config
    echo 0x44c00b8 > $DCC_PATH/config
    echo 0x44c1070 2 > $DCC_PATH/config
    echo 0x44c8220 > $DCC_PATH/config
    echo 0x44c8400 7 > $DCC_PATH/config
    echo 0x44c8420 9 > $DCC_PATH/config
    echo 0x44c9800 > $DCC_PATH/config
    echo 0x44d0000 > $DCC_PATH/config
    echo 0x44d0020 > $DCC_PATH/config
    echo 0x44d0030 > $DCC_PATH/config
    echo 0x44d0100 > $DCC_PATH/config
    echo 0x44d0108 2 > $DCC_PATH/config
    echo 0x44d0400 > $DCC_PATH/config
    echo 0x44d0410 > $DCC_PATH/config
    echo 0x44d0420 > $DCC_PATH/config
    echo 0x44d1800 > $DCC_PATH/config
    echo 0x450002c 2 > $DCC_PATH/config
    echo 0x4500094 > $DCC_PATH/config
    echo 0x450009c > $DCC_PATH/config
    echo 0x45000c4 2 > $DCC_PATH/config
    echo 0x45003dc > $DCC_PATH/config
    echo 0x45005d8 > $DCC_PATH/config
    echo 0x450202c 2 > $DCC_PATH/config
    echo 0x4502094 > $DCC_PATH/config
    echo 0x450209c > $DCC_PATH/config
    echo 0x45020c4 2 > $DCC_PATH/config
    echo 0x45023dc > $DCC_PATH/config
    echo 0x45025d8 > $DCC_PATH/config
    echo 0x450302c 2 > $DCC_PATH/config
    echo 0x4503094 > $DCC_PATH/config
    echo 0x450309c > $DCC_PATH/config
    echo 0x45030c4 2 > $DCC_PATH/config
    echo 0x45033dc > $DCC_PATH/config
    echo 0x45035d8 > $DCC_PATH/config
    echo 0x4506028 2 > $DCC_PATH/config
    echo 0x4506044 > $DCC_PATH/config
    echo 0x4506094 > $DCC_PATH/config
    echo 0x45061dc > $DCC_PATH/config
    echo 0x45061ec > $DCC_PATH/config
    echo 0x4506608 > $DCC_PATH/config
    echo 0x450702c 2 > $DCC_PATH/config
    echo 0x4507094 > $DCC_PATH/config
    echo 0x450709c > $DCC_PATH/config
    echo 0x45070c4 2 > $DCC_PATH/config
    echo 0x45073dc > $DCC_PATH/config
    echo 0x45075d8 > $DCC_PATH/config
    echo 0x450902c 2 > $DCC_PATH/config
    echo 0x4509094 > $DCC_PATH/config
    echo 0x450909c > $DCC_PATH/config
    echo 0x45090c4 2 > $DCC_PATH/config
    echo 0x45093dc > $DCC_PATH/config
    echo 0x45095d8 > $DCC_PATH/config
    echo 0x450a02c 2 > $DCC_PATH/config
    echo 0x450a094 3 > $DCC_PATH/config
    echo 0x450a0c4 2 > $DCC_PATH/config
    echo 0x450a3dc > $DCC_PATH/config
    echo 0x450a5d8 > $DCC_PATH/config

    echo 0x4480000 > $DCC_PATH/config
    echo 0x4488000 > $DCC_PATH/config
    echo 0x44a0000 > $DCC_PATH/config
    echo 0x448c000 > $DCC_PATH/config
    echo 0x449c000 > $DCC_PATH/config
    echo 0x4494000 > $DCC_PATH/config
    echo 0x4490000 > $DCC_PATH/config
    echo 0x44a4000 > $DCC_PATH/config
    echo 0x4498000 > $DCC_PATH/config
    echo 0x44b1000 > $DCC_PATH/config
    echo 0x44b4000 > $DCC_PATH/config
    echo 0x44b0000 > $DCC_PATH/config
    echo 0x44b5000 > $DCC_PATH/config
    echo 0x44bd000 > $DCC_PATH/config
    echo 0x44c0000 > $DCC_PATH/config
    echo 0x44bc000 > $DCC_PATH/config
    echo 0x44c1000 > $DCC_PATH/config
    echo 0x44d1000 > $DCC_PATH/config
    echo 0x44c9000 > $DCC_PATH/config
    echo 0x44c8000 > $DCC_PATH/config
    echo 0x4414000 > $DCC_PATH/config
    echo 0x4500000 > $DCC_PATH/config
    echo 0x4506000 > $DCC_PATH/config
    echo 0x4502000 > $DCC_PATH/config
    echo 0x4503000 > $DCC_PATH/config
    echo 0x4507000 > $DCC_PATH/config
    echo 0x4509000 > $DCC_PATH/config
    echo 0x450a000 > $DCC_PATH/config
    echo 0x447D000 > $DCC_PATH/config
    echo 0x447D100 > $DCC_PATH/config
    echo 0x447D200 > $DCC_PATH/config

    echo 0x0447D000 > $DCC_PATH/config
    echo 0x0447D100 > $DCC_PATH/config
    echo 0x0447D200 > $DCC_PATH/config
    echo 0x04481000 > $DCC_PATH/config
    echo 0x04482000 > $DCC_PATH/config
    echo 0x04483000 > $DCC_PATH/config
    echo 0x04484000 > $DCC_PATH/config
    echo 0x04486000 > $DCC_PATH/config
    echo 0x04488000 > $DCC_PATH/config
    echo 0x04489000 > $DCC_PATH/config
    echo 0x0448C000 > $DCC_PATH/config
    echo 0x0448D000 > $DCC_PATH/config
    echo 0x04490000 > $DCC_PATH/config
    echo 0x04491000 > $DCC_PATH/config
    echo 0x04494000 > $DCC_PATH/config
    echo 0x04495000 > $DCC_PATH/config
    echo 0x04498000 > $DCC_PATH/config
    echo 0x04499000 > $DCC_PATH/config
    echo 0x0449C000 > $DCC_PATH/config
    echo 0x0449D000 > $DCC_PATH/config
    echo 0x044A0000 > $DCC_PATH/config
    echo 0x044A1000 > $DCC_PATH/config
    echo 0x044A4000 > $DCC_PATH/config
    echo 0x044A5000 > $DCC_PATH/config
    echo 0x044B0000 > $DCC_PATH/config
    echo 0x044B1000 > $DCC_PATH/config
    echo 0x044B2000 > $DCC_PATH/config
    echo 0x044B4000 > $DCC_PATH/config
    echo 0x044B5000 > $DCC_PATH/config
    echo 0x044B6000 > $DCC_PATH/config
    echo 0x044B7000 > $DCC_PATH/config
    echo 0x044BC000 > $DCC_PATH/config
    echo 0x044BD000 > $DCC_PATH/config
    echo 0x044BE000 > $DCC_PATH/config
    echo 0x044C0000 > $DCC_PATH/config
    echo 0x044C1000 > $DCC_PATH/config
    echo 0x044C2000 > $DCC_PATH/config
    echo 0x044C3000 > $DCC_PATH/config
    echo 0x044C8000 > $DCC_PATH/config
    echo 0x044C9000 > $DCC_PATH/config
    echo 0x044D0000 > $DCC_PATH/config
    echo 0x044D1000 > $DCC_PATH/config
    echo 0x04500000 > $DCC_PATH/config
    echo 0x04502000 > $DCC_PATH/config
    echo 0x04503000 > $DCC_PATH/config
    echo 0x04506000 > $DCC_PATH/config
    echo 0x04507000 > $DCC_PATH/config
    echo 0x04509000 > $DCC_PATH/config
    echo 0x0450A000 > $DCC_PATH/config
    echo 0x0450E000 > $DCC_PATH/config
    echo 0x0451E000 > $DCC_PATH/config
    echo 0x0451F000 > $DCC_PATH/config
}
config_dcc_wpss()
{
    echo 0x5600304  > $DCC_PATH/config
    echo 0x5602028  > $DCC_PATH/config
    echo 0x56B0208 3 > $DCC_PATH/config
    echo 0x56B0228 3 > $DCC_PATH/config
    echo 0x56B0248 3 > $DCC_PATH/config
    echo 0x56B0268 3 > $DCC_PATH/config
    echo 0x56B0400 3 > $DCC_PATH/config
    echo 0x5700208 3 > $DCC_PATH/config
    echo 0x5700228 3 > $DCC_PATH/config
    echo 0x5700248 3 > $DCC_PATH/config
    echo 0x5700268 3 > $DCC_PATH/config
    echo 0x5700400 3 > $DCC_PATH/config
}

config_dcc_lpm()
{
    echo 0x0FD8010C  > $DCC_PATH/config
    echo 0xF880044 3 > $DCC_PATH/config
    echo 0xF880054  > $DCC_PATH/config
    echo 0xF88006C 5 > $DCC_PATH/config
    echo 0xFD800EC  > $DCC_PATH/config
    echo 0xFD800FC  > $DCC_PATH/config
    echo 0xFD90348 2 > $DCC_PATH/config
    echo 0xFD91060 8 > $DCC_PATH/config
    echo 0xFD91348 2 > $DCC_PATH/config
    echo 0xFD92064 8 > $DCC_PATH/config
    echo 0xFD92348 2 > $DCC_PATH/config
}

config_noc_debug_chain()
{
   echo 0x9 > $DCC_PATH/loop
   echo 0x1902010 2 > $DCC_PATH/config
   echo 0x1 > $DCC_PATH/loop
   
   #config_noc_DebugChain_south
   echo 0x2 > $DCC_PATH/loop
   echo 0x1902110 2 > $DCC_PATH/config
   echo 0x1 > $DCC_PATH/loop
   
   #config_system_noc_DebugChain_center
   echo 0x14 > $DCC_PATH/loop
   echo 0x1882010 2 > $DCC_PATH/config
   echo 0x1 > $DCC_PATH/loop

   #config_system_noc_DebugChain_mmnoc_hf
   echo 0x3 > $DCC_PATH/loop
   echo 0x1882090 2 > $DCC_PATH/config
   echo 0x1 > $DCC_PATH/loop
   
   #config_system_noc_DebugChain_mmnoc_sf
   echo 0x3 > $DCC_PATH/loop
   echo 0x1882110 2 > $DCC_PATH/config
   echo 0x1 > $DCC_PATH/loop
   
   #config_system_noc_DebugChain_south
   echo 0x3 > $DCC_PATH/loop
   echo 0x1882190 2 > $DCC_PATH/config
   echo 0x1 > $DCC_PATH/loop
   
   #config_system_noc_DebugChain_wpss
   echo 0x2 > $DCC_PATH/loop
   echo 0x1882290 2 > $DCC_PATH/config
   echo 0x1 > $DCC_PATH/loop
}

config_dcc_timer()
{
    echo 0xF421000 2 > $DCC_PATH/config
}

dcc_async_package()
{
    echo 0x08004FB0 0xc5acce55 > $DCC_PATH/config_write
    echo 0x0800408c 0xfff > $DCC_PATH/config_write
    echo 0x08004FB0 0x0 > $DCC_PATH/config_write
}
enable_dcc()
{
    DCC_PATH="/sys/bus/platform/devices/80ff000.dcc_v2"
    soc_version=`cat /sys/devices/soc0/revision`
    soc_version=${soc_version/./}

    if [ ! -d $DCC_PATH ]; then
        echo "DCC does not exist on this build."
        return
    fi

    echo 0 > $DCC_PATH/enable
    echo 1 > $DCC_PATH/config_reset
    echo 2 > $DCC_PATH/curr_list
    echo cap > $DCC_PATH/func_type
    echo sram > $DCC_PATH/data_sink

    config_dcc_timer
    config_dcc_core
    config_dcc_modem_rsc
    config_dcc_ddr
    config_noc_debug_chain
    config_dcc_lpass
    config_dcc_timer

    # echo 1 > /sys/bus/coresight/devices/coresight-tpdm-dcc/enable_source
    echo 3 > $DCC_PATH/curr_list
    echo cap > $DCC_PATH/func_type
    echo sram > $DCC_PATH/data_sink
    # dcc_async_package
    config_dcc_timer
    config_dcc_gpu
    config_dcc_ppat
    config_dcc_cpr
    config_dcc_pcu
    config_dcc_tsens
    config_dcc_wpss
    config_dcc_lpm
    config_dcc_timer

    echo  1 > $DCC_PATH/enable
}

enable_core_hang_config()
{
    CORE_PATH="/sys/devices/system/cpu/hang_detect_core"
    if [ ! -d $CORE_PATH ]; then
        echo "CORE hang does not exist on this build."
        return
    fi

    #set the threshold to max
    echo 0xffffffff > $CORE_PATH/threshold

    #To enable core hang detection
    #It's a boolean variable. Do not use Hex value to enable/disable
    echo 1 > $CORE_PATH/enable
}

adjust_permission()
{
    #add permission for block_size, mem_type, mem_size nodes to collect diag over QDSS by ODL
    #application by "oem_2902" group
    #WTFEAT-142743 p-tanyizhe.lx, modify, 20260225, add off modem log start.
    chown -h root.oem_2902 /sys/devices/platform/soc/8048000.tmc/tmc_etr0/block_size
    chmod 777 /sys/devices/platform/soc/8048000.tmc/tmc_etr0/block_size
    chown -h root.oem_2902 /sys/devices/platform/soc/8048000.tmc/tmc_etr0/buffer_size
    chmod 660 /sys/devices/platform/soc/8048000.tmc/tmc_etr0/buffer_size
    chmod 660 /sys/devices/platform/soc/8048000.tmc/tmc_etr0/out_mode
    chmod 777 /sys/devices/platform/soc/8048000.tmc/tmc_etr0/enable_sink
    chmod 660 /sys/devices/platform/soc/soc:modem_diag/modem-diag/enable_source
    #WTFEAT-142743 p-tanyizhe.lx, modify, 20260225, add off modem log end.
    chgrp shell /sys/bus/coresight/devices/*/enable_source
    chmod 660 /sys/bus/coresight/devices/*/enable_source
    chgrp shell /sys/bus/coresight/devices/*/enable_sink
    chmod 660 /sys/bus/coresight/devices/*/enable_sink
    chgrp shell /sys/bus/coresight/devices/etm*/reset
    chmod 660 /sys/bus/coresight/devices/etm*/reset
    chmod 660 /dev/stm0
    chgrp system /dev/stm0
}

enable_schedstats()
{
    # bail out if its perf config
    if [ "$debug_build" = false ]
    then
        return
    fi

    if [ -f /proc/sys/kernel/sched_schedstats ]
    then
        echo 1 > /proc/sys/kernel/sched_schedstats
    fi
}

enable_modem_tpdm()
{
    # bail out if its perf config
    if [ "$debug_build" = false ]
    then
        return
    fi

    echo 1 >/sys/bus/coresight/devices/coresight-tpdm-modem-1/enable_source
    qdss_qmi_helper modem tpdm 0x02 dataset 0x04 enable
    qdss_qmi_helper modem tpdm 0x02 cmb_param 0x0B 0x00
    echo 1 >/sys/bus/coresight/devices/coresight-tpdm-modem-2/enable_source
    qdss_qmi_helper modem tpdm 0x1B dataset 0x04 enable
    qdss_qmi_helper modem tpdm 0x1B cmb_param 0x0B 0x00
    echo 1 >/sys/bus/coresight/devices/coresight-tpdm-modem-3/enable_source
    qdss_qmi_helper modem tpdm 0x42 dataset 0x04 enable
    qdss_qmi_helper modem tpdm 0x42 cmb_param 0x0B 0x00
    echo 1 >/sys/bus/coresight/devices/coresight-tpdm-modem-4/enable_source
    qdss_qmi_helper modem tpdm 0x70 dataset 0x04 enable
    qdss_qmi_helper modem tpdm 0x70 cmb_param 0x0B 0x00
}

enable_buses_and_interconnect_tracefs_debug()
{
    tracefs=/sys/kernel/tracing

    # enable tracing for consolidate/debug builds, where debug_build is set true
    if [ "$debug_build" = true ]
    then
        setprop persist.vendor.tracing.enabled 1
    fi

    if [ -d $tracefs ] && [ "$(getprop persist.vendor.tracing.enabled)" -eq "1" ]; then
        mkdir $tracefs/instances/hsuart
        #UART
        echo 800 > $tracefs/instances/hsuart/buffer_size_kb
        echo 1 > $tracefs/instances/hsuart/events/serial/enable
        echo 1 > $tracefs/instances/hsuart/tracing_on

        #SPI
        mkdir $tracefs/instances/spi_qup
        echo 20 > $tracefs/instances/spi_qup/buffer_size_kb
        echo 1 > $tracefs/instances/spi_qup/events/qup_spi_trace/enable
        echo 1 > $tracefs/instances/spi_qup/tracing_on

        #I2C
        mkdir $tracefs/instances/i2c_qup
        echo 20 > $tracefs/instances/i2c_qup/buffer_size_kb
        echo 1 > $tracefs/instances/i2c_qup/events/qup_i2c_trace/enable
        echo 1 > $tracefs/instances/i2c_qup/tracing_on

        #SLIMBUS
        mkdir $tracefs/instances/slimbus
        echo 1 > $tracefs/instances/slimbus/events/slimbus/slimbus_dbg/enable
        echo 1 > $tracefs/instances/slimbus/tracing_on

        #CLOCK, REGULATOR, INTERCONNECT, RPMH
        mkdir $tracefs/instances/clock_reg
        echo 1 > $tracefs/instances/clock_reg/events/clk/enable
        echo 1 > $tracefs/instances/clock_reg/events/regulator/enable
        echo 1 > $tracefs/instances/clock_reg/events/interconnect/enable
        echo 1 > $tracefs/instances/clock_reg/events/rpmh/enable
        echo 1 > $tracefs/instances/clock_reg/tracing_on
    fi
}

create_stp_policy()
{
    mkdir /config/stp-policy/stm0:p_ost.policy
    chmod 661 /config/stp-policy/stm0:p_ost.policy
    mkdir /config/stp-policy/stm0:p_ost.policy/default
    chmod 660 /config/stp-policy/stm0:p_ost.policy/default
    echo ftrace > /config/stp-policy/stm0:p_ost.policy/default/entity
    mkdir /config/stp-policy/stm0:p_ost.policy/diag/
    echo diag >/config/stp-policy/stm0:p_ost.policy/diag/entity
    chmod 661 /config/stp-policy/stm0:p_ost.policy/diag/
}

#function to enable cti flush for etf
enable_cti_flush_for_etf()
{
    if [ "$debug_build" != true ]; then
        return
    fi
    echo 1 > /sys/bus/coresight/devices/tmc_etf0/stop_on_flush
    echo 1 >/sys/bus/coresight/devices/cti_qdss_cti/enable
    echo 0 53 >/sys/bus/coresight/devices/cti_qdss_cti/channels/trigin_attach
    echo 0 1 >/sys/bus/coresight/devices/cti_qdss_cti/channels/trigout_attach
}

find_build_type()
{
    linux_banner=`cat /proc/version`
    if [[ "$linux_banner" == *"-consolidate"* ]] || [[ "$linux_banner" == *"-debug"* ]]
    then
        debug_build=true
    fi
}

ftrace_disable=`getprop persist.debug.ftrace_events_disable`
debug_build=false
enable_debug()
{
    echo "malabar debug"
    echo "Enabling STM events on malabar."
    find_build_type
    create_stp_policy
    adjust_permission
    enable_stm_events
    enable_cti_flush_for_etf
    if [ "$ftrace_disable" != "Yes" ]; then
        enable_ftrace_event_tracing
        enable_buses_and_interconnect_tracefs_debug
    fi
    enable_core_hang_config
    enable_dcc
    enable_schedstats
    #setprop ro.dbg.coresight.stm_cfg_done 1

    if [ -d $tracefs ] && [ "$(getprop persist.vendor.tracing.enabled)" -eq "1" ]; then
        mkdir $tracefs/instances/hsuart
        #UART
        echo 800 > $tracefs/instances/hsuart/buffer_size_kb
        echo 1 > $tracefs/instances/hsuart/events/serial/enable
        echo 1 > $tracefs/instances/hsuart/tracing_on

        #SPI
        mkdir $tracefs/instances/spi_qup
        echo 20 > $tracefs/instances/spi_qup/buffer_size_kb
        echo 1 > $tracefs/instances/spi_qup/events/qup_spi_trace/enable
        echo 1 > $tracefs/instances/spi_qup/tracing_on

        #I2C
        mkdir $tracefs/instances/i2c_qup
        echo 20 > $tracefs/instances/i2c_qup/buffer_size_kb
        echo 1 > $tracefs/instances/i2c_qup/events/qup_i2c_trace/enable
        echo 1 > $tracefs/instances/i2c_qup/tracing_on

        #GENI_COMMON
        mkdir $tracefs/instances/qupv3_common
        echo 20 > $tracefs/instances/qupv3_common/buffer_size_kb
        echo 1 > $tracefs/instances/qupv3_common/events/qup_common_trace/enable
        echo 1 > $tracefs/instances/qupv3_common/tracing_on

        #SLIMBUS
        mkdir $tracefs/instances/slimbus
        echo 20 > $tracefs/instances/slimbus/buffer_size_kb
        echo 1 > $tracefs/instances/slimbus/events/slimbus/slimbus_dbg/enable
        echo 1 > $tracefs/instances/slimbus/tracing_on
    fi
    enable_modem_tpdm
}

enable_debug
