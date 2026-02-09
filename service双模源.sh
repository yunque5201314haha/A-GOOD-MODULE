#!/system/bin/sh
MODDIR=${0%/*}
chmod 755 "$0"
chmod 755 "$MODDIR/action.sh" 2>/dev/null

MODE_FILE="$MODDIR/current_mode"
RUN_MODE_FILE="$MODDIR/run_mode"  # 模式文件
TEMP_PATH="/proc/shell-temp"
REAL_SOC="/sys/class/oplus_chg/battery/chip_soc"
SYS_SOC="/sys/class/power_supply/battery/capacity"
STEP_CHG_PATH="/sys/class/power_supply/battery/step_charging_enabled"

RUN_MODE=2
if [ -f "$RUN_MODE_FILE" ]; then
    RUN_MODE=$(cat "$RUN_MODE_FILE")
fi

chmod 666 "$MODE_FILE" 2>/dev/null
[ ! -f "$MODE_FILE" ] && echo "34000" > "$MODE_FILE"
CURRENT_GEAR=""
CURRENT_GEAR=$(cat "$MODE_FILE" 2>/dev/null || echo "34000")

while [ "$(getprop sys.boot_completed 2>/dev/null)" != "1" ]; do sleep 1; done
sleep 15

echo 1 > /proc/game_opt/disable_cpufreq_limit 2>/dev/null
chmod 444 /proc/game_opt/disable_cpufreq_limit 2>/dev/null

if [ -f "$REAL_SOC" ]; then
    mount --bind "$REAL_SOC" "$SYS_SOC" 2>/dev/null
fi

if [ -f "$STEP_CHG_PATH" ]; then
    chmod 666 "$STEP_CHG_PATH" 2>/dev/null
fi

LAST_STATE=""
BAT_THERMAL_MATCH="batt*|battery*|batt_therm|battery_therm|pmic_batt|fuel_gauge"

fake_battery_temp() {
    local TEMP_VAL=$1
    local temp_c=$((TEMP_VAL / 1000))
    for tz in /sys/class/thermal/*; do
        [ -f "$tz/type" ] && [ -w "$tz/emul_temp" ] || continue
        local TYPE=$(cat "$tz/type" 2>/dev/null)
        if echo "$TYPE" | grep -qE "$BAT_THERMAL_MATCH"; then
            echo "$TEMP_VAL" > "$tz/emul_temp" 2>/dev/null
        fi
    done
    setprop persist.sys.battery.temp "$TEMP_VAL" 2>/dev/null
    [ -w "/sys/class/power_supply/battery/temp" ] && echo "$temp_c" > "/sys/class/power_supply/battery/temp" 2>/dev/null
    [ -w "/sys/class/power_supply/battery/batt_temp" ] && echo "$temp_c" > "/sys/class/power_supply/battery/batt_temp" 2>/dev/null
    [ -w "/sys/class/power_supply/battery/battery_temp" ] && echo "$temp_c" > "/sys/class/power_supply/battery/battery_temp" 2>/dev/null
    setprop sys.battery.temp "$temp_c" 2>/dev/null
    setprop vendor.battery.temp "$temp_c" 2>/dev/null
}

restore_battery_temp() {
    for tz in /sys/class/thermal/*; do
        [ -f "$tz/type" ] && [ -w "$tz/emul_temp" ] || continue
        local TYPE=$(cat "$tz/type" 2>/dev/null)
        if echo "$TYPE" | grep -qE "$BAT_THERMAL_MATCH"; then
            echo "" > "$tz/emul_temp" 2>/dev/null
        fi
    done
    setprop persist.sys.battery.temp "" 2>/dev/null
    setprop sys.battery.temp "" 2>/dev/null
    setprop vendor.battery.temp "" 2>/dev/null
}

if [ "$RUN_MODE" = "1" ]; then
    setprop persist.vendor.thermal.enable 0 2>/dev/null
    setprop vendor.thermal.enable 0 2>/dev/null
    setprop sys.thermal.enable 0 2>/dev/null
    stop thermal-engine 2>/dev/null
    stop vendor.thermal-engine 2>/dev/null
    killall -9 thermal-engine vendor.thermal-engine 2>/dev/null

    while true; do
        [ -w "$STEP_CHG_PATH" ] && echo "0" > "$STEP_CHG_PATH" 2>/dev/null

        STATUS=""
        STATUS=$(cat /sys/class/power_supply/battery/status 2>/dev/null)
        [ -z "$STATUS" ] && STATUS="Discharging"

        if [ "$STATUS" = "Charging" ] || [ "$STATUS" = "Full" ]; then
            CURRENT_GEAR=$(cat "$MODE_FILE" 2>/dev/null || echo "34000")
            if [ -w "$TEMP_PATH" ]; then
                for i in 0 1 2 3 4 5 6 7 8 9; do
                    echo "$i $CURRENT_GEAR" > "$TEMP_PATH" 2>/dev/null
                done
            fi
            fake_battery_temp "$CURRENT_GEAR"

            if [ "$LAST_STATE" != "1" ]; then
                TEMP_SHOW=$((CURRENT_GEAR / 1000))
                su -lp 2000 -c "cmd notification post -S bigtext -t '欧加真温度伪装(激进模式)' -i file:///data/local/tmp/Temp.png -I file:///data/local/tmp/Temp.png TagBattery '当前伪装温度: ${TEMP_SHOW}°C | 运行中'"
                LAST_STATE="1"
            fi
        else
            if [ "$LAST_STATE" != "2" ]; then
                if [ -w "$TEMP_PATH" ]; then
                    for i in 0 1 2 3 4 5 6 7 8 9; do
                        echo "$i 0" > "$TEMP_PATH" 2>/dev/null
                    done
                fi
                restore_battery_temp
                su 2000 -c "cmd notification cancel TagBattery" >/dev/null 2>&1
                LAST_STATE="2"
            fi
        fi

        sleep 10
    done

else
    while true; do
        [ -w "$STEP_CHG_PATH" ] && echo "0" > "$STEP_CHG_PATH" 2>/dev/null

        STATUS=""
        STATUS=$(cat /sys/class/power_supply/battery/status 2>/dev/null)
        [ -z "$STATUS" ] && STATUS="Discharging"

        if [ "$STATUS" = "Charging" ] || [ "$STATUS" = "Full" ]; then
            if [ "$LAST_STATE" != "1" ]; then
                setprop persist.vendor.thermal.enable 0 2>/dev/null
                setprop vendor.thermal.enable 0 2>/dev/null
                setprop sys.thermal.enable 0 2>/dev/null
                stop thermal-engine 2>/dev/null
                stop vendor.thermal-engine 2>/dev/null
                killall -9 thermal-engine vendor.thermal-engine 2>/dev/null
                LAST_STATE="1"
                CURRENT_GEAR=$(cat "$MODE_FILE" 2>/dev/null || echo "34000")
                TEMP_SHOW=$((CURRENT_GEAR / 1000))
                su -lp 2000 -c "cmd notification post -S bigtext -t '欧加真仅充电温度伪装' -i file:///data/local/tmp/Temp.png -I file:///data/local/tmp/Temp.png TagBattery '当前伪装温度: ${TEMP_SHOW}°C | 温度伪装正在运行'"
            fi
            CURRENT_GEAR=$(cat "$MODE_FILE" 2>/dev/null || echo "34000")
            if [ -w "$TEMP_PATH" ]; then
                for i in 0 1 2 3 4 5 6 7 8 9; do
                    echo "$i $CURRENT_GEAR" > "$TEMP_PATH" 2>/dev/null
                done
            fi
            fake_battery_temp "$CURRENT_GEAR"

        else
            if [ "$LAST_STATE" != "2" ]; then
                setprop persist.vendor.thermal.enable 1 2>/dev/null
                setprop vendor.thermal.enable 1 2>/dev/null
                setprop sys.thermal.enable 1 2>/dev/null
                start thermal-engine 2>/dev/null
                start vendor.thermal-engine 2>/dev/null
                su 2000 -c "cmd notification cancel TagBattery" >/dev/null 2>&1
                LAST_STATE="2"
                if [ -w "$TEMP_PATH" ]; then
                    for i in 0 1 2 3 4 5 6 7 8 9; do
                        echo "$i 0" > "$TEMP_PATH" 2>/dev/null
                    done
                fi
                restore_battery_temp
            fi
        fi

        sleep 10
    done
fi
