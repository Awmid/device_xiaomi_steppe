#! /vendor/bin/sh
#=============================================================================
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# All Rights Reserved.
# Confidential and Proprietary - Qualcomm Technologies, Inc.
#=============================================================================

soc_id=`cat /sys/devices/soc0/soc_id` 2> /dev/null

#soc_id's SM8150:339, SM8250:356, SM8350:415, 439 and 456, HDK8150: 361
if [ "$soc_id" -eq 339 ] || [ "$soc_id" -eq 356 ] || [ "$soc_id" -eq 361 ] || [ "$soc_id" -eq 415 ] || [ "$soc_id" -eq 439 ] || [ "$soc_id" -eq 456 ]; then
    enable vendor.keymaster-sb-4-0
    start vendor.keymaster-sb-4-0
    enable vendor.authsecret.qti-1-0
    start vendor.authsecret.qti-1-0
#soc_ids SM8450: 457, 482, SM8550: 519, 536, 600, 601
elif [ "$soc_id" -eq 457 ] || [ "$soc_id" -eq 482 ] || [ "$soc_id" -eq 519 ] || [ "$soc_id" -eq 536 ] || [ "$soc_id" -eq 600 ] || [ "$soc_id" -eq 601 ]; then
    enable vendor.keymaster-sb-4-0
    start vendor.keymaster-sb-4-0
#soc_ids SM8850: 660, 661, SM8847: 722, 723
elif [ "$soc_id" -eq 660 ] || [ "$soc_id" -eq 661 ] || [ "$soc_id" -eq 722 ] || [ "$soc_id" -eq 723 ]; then
    # vendor.gatekeeper.is_security_level_spu will be set according to /vendor/build.prop
    : # This is an explicit no-operation command (NOP)
else
    setprop vendor.gatekeeper.is_security_level_spu 0
fi
