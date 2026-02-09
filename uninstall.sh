#!/system/bin/sh

start thermal-engine 2>/dev/null
start vendor.thermal-engine 2>/dev/null
start horae 2>/dev/null
start oplus_horae 2>/dev/null
setprop persist.vendor.thermal.enable 1
setprop vendor.thermal.enable 1
setprop sys.thermal.enable 1
start thermal-engine
start vendor.thermal-engine

exit 0