#! /vendor/bin/sh
#=============================================================================
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries. 
# SPDX-License-Identifier: BSD-3-Clause-Clear
#=============================================================================

MemTotalStr=`cat /proc/meminfo | grep MemTotal`
MemTotal=${MemTotalStr:16:8}
THRESHOLD=5000000
if [ "$MemTotal" -lt "$THRESHOLD" ]; then
        stop vendor.qti.AvfQcvmManager
        stop vendor.qtvm.proxyclient-service
fi
