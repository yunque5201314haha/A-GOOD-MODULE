#!/system/bin/sh
MODDIR=${0%/*}
MODE_FILE="$MODDIR/current_mode"

choose_mode() {
	echo "********************************************"
	echo "- 选择温控模式："
	echo "按音量+  狂暴模式 (34000)"
	echo "按音量-  普通模式 (37000)"
	echo "********************************************"
	choice=""
	while [ -z "$choice" ]; do
		event=$(getevent -lqt 2>&1 | head -1)
		if echo "$event" | grep -q "KEY_VOLUMEUP"; then
			choice="34000"
			echo "- 已选择：狂暴模式 (34000)"
		elif echo "$event" | grep -q "KEY_VOLUMEDOWN"; then
			choice="37000"
			echo "- 已选择：普通模式 (37000)"
		fi
	done
	echo "$choice" > "$MODE_FILE"
}

NEW_TEMP=$(cat "$MODE_FILE" 2>/dev/null)

if [ -z "$NEW_TEMP" ]; then
	choose_mode
	NEW_TEMP=$(cat "$MODE_FILE")
fi

STATUS=$(cat /sys/class/power_supply/battery/status 2>/dev/null)

if [ "$STATUS" = "Charging" ] || [ "$STATUS" = "Full" ]; then
	for i in 0 1 2 3 4 5 6 7 8 9; do
		if [ -w "/proc/shell-temp" ]; then
			echo "$i $NEW_TEMP" > "/proc/shell-temp"
		fi
	done
	echo "- 温控参数已应用: $NEW_TEMP"
else
	echo "- 当前未充电，模式已读取: $NEW_TEMP"
	echo "- 充电时自动应用"
fi
