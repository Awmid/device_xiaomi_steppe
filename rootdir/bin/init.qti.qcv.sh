#! /vendor/bin/sh
#=============================================================================
# Copyright (c) 2020, 2021 Qualcomm Technologies, Inc.
# All Rights Reserved.
# Confidential and Proprietary - Qualcomm Technologies, Inc.
#=============================================================================

if ! read -r soc_id < /sys/devices/soc1/soc_id 2>/dev/null; then
    read -r soc_id < /sys/devices/soc0/soc_id 2>/dev/null
fi

if ! read -r chip_id < /sys/devices/soc1/chip_id 2>/dev/null; then
    read -r chip_id < /sys/devices/soc0/chip_id 2>/dev/null
fi

# Set base props (guard against empty to avoid useless setprop)
[ -n "$soc_id" ]  && setprop ro.vendor.qti.soc_id "$soc_id"
[ -n "$chip_id" ] && setprop ro.vendor.qti.soc_model "$chip_id"

case "$soc_id" in
  707|708)
    setprop ro.vendor.qti.soc_name art
    ;;
  660|661|704|743)
    setprop ro.vendor.qti.soc_name canoe
    setprop ro.vendor.media_performance_class 35
    ;;
  722|723)
    setprop ro.vendor.qti.soc_name whale
    setprop ro.vendor.media_performance_class 35
    ;;
  724|744)
    setprop ro.vendor.qti.soc_name chora
    ;;
  733|757)
    setprop ro.vendor.qti.soc_name malabar
    ;;
  685|727|764)
    setprop ro.vendor.qti.soc_name alor
    setprop ro.vendor.media_performance_class 35
    ;;
  618|639)
    setprop ro.vendor.qti.soc_name sun
    setprop ro.vendor.media_performance_class 35
    ;;
  557|577)
    setprop ro.vendor.qti.soc_name pineapple
    setprop ro.vendor.media_performance_class 34
    ;;
  475|499|497|498|515)
    setprop ro.vendor.qti.soc_name yupik
    setprop ro.vendor.qti.soc_model SM7325
    ;;
  575)
    setprop ro.vendor.qti.soc_name yupik
    setprop ro.vendor.qti.soc_model QCS5430
    ;;
  576)
    setprop ro.vendor.qti.soc_name yupik
    setprop ro.vendor.qti.soc_model QCM5430
    ;;
  555)
    setprop ro.vendor.qti.soc_name hamoa
    ;;
  568|602)
    setprop ro.vendor.qti.soc_name ravelin
    setprop ro.vendor.qti.soc_model SM4450
    ;;
  673)
    setprop ro.vendor.qti.soc_name seraph
    setprop ro.vendor.qti.soc_model SAR2230P
    ;;
  672)
    setprop ro.vendor.qti.soc_name seraph
    setprop ro.vendor.qti.soc_model SAR1250P
    ;;
  736|737)
    setprop ro.vendor.qti.soc_name pikachu
    ;;
  415|439)
    setprop ro.vendor.qti.soc_name lahaina
    setprop ro.vendor.qti.soc_model SM8350
    ;;
  756|758)
    setprop ro.vendor.qti.soc_name shikra
    ;;
esac

exit 0
