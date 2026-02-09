#!/system/bin/sh
MODDIR=${0%/*}
MODE_FILE="$MODDIR/current_mode"

DEF_RUN_MODE="2"

get_current_run_mode() {
  if [ -f "$RUN_MODE_FILE" ]; then
    cat "$RUN_MODE_FILE"
  else
    echo "$DEF_RUN_MODE"
  fi
}

switch_run_mode() {
  echo "============================================="
  echo " 切换【运行模式】（重启生效）"
  echo " 音量+ = 狂暴模式（日常删温控,充电伪装温度并删温控）"
  echo " 音量- = 安全模式（仅充电生效）"
  echo "============================================="

  choice=""
  while [ -z "$choice" ]; do
    event=$(getevent -lqt 2>&1 | head -1)
    if echo "$event" | grep -q "KEY_VOLUMEUP"; then
      choice="1"
    elif echo "$event" | grep -q "KEY_VOLUMEDOWN"; then
      choice="2"
    fi
    sleep 0.1
  done

  echo "$choice" > "$RUN_MODE_FILE"
  echo "============================================="
  if [ "$choice" = "1" ]; then
    echo " ✅ 已切换为：狂暴模式(1)"
    echo "重启手机生效"
  else
    echo " ✅ 已切换为：安全模式(2)"
    echo "重启手机生效"
  fi
  echo " ℹ️ 重启后生效！"
  echo
}

# 选择温度档位
choose_temp_mode() {
  CUR_TEMP=$(cat "$MODE_FILE" 2>/dev/null)
  [ -z "$CUR_TEMP" ] && CUR_TEMP="34000"

  echo "********************************************"
  echo "- 当前温度值: $CUR_TEMP"
  echo "- 选择温控温度："
  echo "按音量+  狂暴温度 (34000)"
  echo "按音量-  普通温度 (37000)"
  echo "可通过修改模块目录下current_mode自定义"
  echo "********************************************"

  choice=""
  while [ -z "$choice" ]; do
    event=$(getevent -lqt 2>&1 | head -1)
    if echo "$event" | grep -q "KEY_VOLUMEUP"; then
      choice="34000"
      echo "- 已选择：狂暴温度 (34000)"
      echo "下次充电生效"
    elif echo "$event" | grep -q "KEY_VOLUMEDOWN"; then
      choice="37000"
      echo "- 已选择：普通温度 (37000)"
      echo "下次充电生效"
    fi
  done

  echo "$choice" > "$MODE_FILE"
  NEW_TEMP="$choice"
}

# ==================== 主菜单 ====================
echo "============================================="
echo "  模式选择菜单"
echo "  音量+ = 切换【温度档位】"
echo "  音量- = 切换【运行模式】"
echo "============================================="

menu_choice=""
while [ -z "$menu_choice" ]; do
  event=$(getevent -lqt 2>&1 | head -1)
  if echo "$event" | grep -q "KEY_VOLUMEUP"; then
    menu_choice="temp"
  elif echo "$event" | grep -q "KEY_VOLUMEDOWN"; then
    menu_choice="runmode"
  fi
  sleep 0.1
done

if [ "$menu_choice" = "runmode" ]; then
  switch_run_mode
else
  choose_temp_mode

  STATUS=$(cat /sys/class/power_supply/battery/status 2>/dev/null)
  if [ "$STATUS" = "Charging" ] || [ "$STATUS" = "Full" ]; then
    for i in 0 1 2 3 4 5 6 7 8 9; do
      if [ -w "/proc/shell-temp" ]; then
        echo "$i $NEW_TEMP" > "/proc/shell-temp"
      fi
    done
    echo "- 温控参数已应用: $NEW_TEMP"
  else
    echo "- 当前未充电，模式已保存: $NEW_TEMP"
    echo "- 充电时自动应用"
  fi
fi

echo "5秒后退出"
sleep 5
