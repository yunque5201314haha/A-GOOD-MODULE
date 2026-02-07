#!/system/bin/sh
MODDIR=${0%/*}
chmod 755 "$0"
chmod 755 "$MODDIR/action.sh" 2>/dev/null
MODE_FILE="$MODDIR/current_mode"
TEMP_PATH="/proc/shell-temp"
REAL_SOC="/sys/class/oplus_chg/battery/chip_soc"
SYS_SOC="/sys/class/power_supply/battery/capacity"
STEP_CHG_PATH="/sys/class/power_supply/battery/step_charging_enabled"

chmod 666 "$MODE_FILE" 2>/dev/null  # 强制赋读写权限，避免系统回收
[ ! -f "$MODE_FILE" ] && echo "34000" > "$MODE_FILE"  # 仅文件不存在时写默认值，不覆盖已有值
CURRENT_GEAR=$(cat "$MODE_FILE" 2>/dev/null)


while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 1; done
sleep 15


echo 1 > /proc/game_opt/disable_cpufreq_limit 2>/dev/null
chmod 444 /proc/game_opt/disable_cpufreq_limit 2>/dev/null
if [ -f "$REAL_SOC" ]; then
    mount --bind "$REAL_SOC" "$SYS_SOC" 2>/dev/null
fi
if [ -f "$STEP_CHG_PATH" ]; then
    chmod 666 "$STEP_CHG_PATH" 2>/dev/null
fi
LAST_STATE=0

# 电池温控节点匹配（欧加全系适配）
BAT_THERMAL_MATCH="batt*|battery*|batt_therm|battery_therm|pmic_batt|fuel_gauge"
# 电池温度伪装函数
fake_battery_temp() {
    local TEMP_VAL=$1
    for tz in /sys/class/thermal/*; do
        [ -f "$tz/type" ] && [ -w "$tz/emul_temp" ] || continue
        local TYPE=$(cat "$tz/type" 2>/dev/null)
        echo "$TYPE" | grep -qE "$BAT_THERMAL_MATCH" && echo "$TEMP_VAL" > "$tz/emul_temp" 2>/dev/null
    done
    setprop persist.sys.battery.temp "$TEMP_VAL" 2>/dev/null
}

restore_battery_temp() {
    for tz in /sys/class/thermal/*; do
        [ -f "$tz/type" ] && [ -w "$tz/emul_temp" ] || continue
        local TYPE=$(cat "$tz/type" 2>/dev/null)
        echo "$TYPE" | grep -qE "$BAT_THERMAL_MATCH" && echo "" > "$tz/emul_temp" 2>/dev/null
    done
    setprop persist.sys.battery.temp "" 2>/dev/null
}

while true; do
    if [ -w "$STEP_CHG_PATH" ]; then
        echo "0" > "$STEP_CHG_PATH"
    fi
    STATUS=$(cat /sys/class/power_supply/battery/status 2>/dev/null)
    if [ "$STATUS" = "Charging" ] || [ "$STATUS" = "Full" ]; then
        if [ "$LAST_STATE" != "1" ]; then
            stop thermal-engine
            stop vendor.thermal-engine
            LAST_STATE=1
            CURRENT_GEAR=$(cat "$MODE_FILE" 2>/dev/null)
            TEMP_SHOW=$((CURRENT_GEAR / 1000))
            NOTIFY_TEXT="当前伪装温度: ${TEMP_SHOW}°C | 温度伪装正在运行"
            su 2000 -c "
            cmd notification post \
            -S messaging \
            --conversation '欧加真温度伪装' \
            --message '$NOTIFY_TEXT' \
            thermal_mode '$RANDOM'
            " >/dev/null 2>&1
        fi
        CURRENT_GEAR=$(cat "$MODE_FILE" 2>/dev/null)
        if [ -w "$TEMP_PATH" ]; then
            for i in 0 1 2 3 4 5 6 7 8 9; do
                echo "$i $CURRENT_GEAR" > "$TEMP_PATH"
            done
        fi
        fake_battery_temp "$CURRENT_GEAR"
    else
        if [ "$LAST_STATE" != "2" ]; then
            start thermal-engine
            start vendor.thermal-engine
            LAST_STATE=2
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
