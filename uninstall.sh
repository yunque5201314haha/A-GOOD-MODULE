#!/system/bin/sh

start thermal-engine 2>/dev/null
start vendor.thermal-engine 2>/dev/null
start horae 2>/dev/null
start oplus_horae 2>/dev/null

su 2000 -c "cmd notification cancel thermal_mode" >/dev/null 2>&1

exit 0