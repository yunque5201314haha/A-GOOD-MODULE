#!/system/bin/sh 
MODDIR=${0%/*}

ui_print() {
    echo "$1"
}

clear_key_buffer() {
    timeout 0.1 getevent -ql >/dev/null 2>&1
}

ksu_get_key() {
    clear_key_buffer  
    local key=""
    local timeout_counter=0
    while [ -z "$key" ]; do
        key=$(getevent -qlc 1 2>/dev/null | awk '{print $3}' | grep -E 'KEY_VOLUMEUP|KEY_VOLUMEDOWN' | head -n1)
        if [ -z "$key" ]; then
            sleep 0.2
            timeout_counter=$((timeout_counter + 1))
            if [ $timeout_counter -ge 150 ]; then
                ui_print "⚠️  超时未操作，默认选择模式1"
                echo "KEY_VOLUMEUP"
                return
            fi
        fi
    done
    echo "$key"
}

ui_print "🚀 模块安装确认"
ui_print "============================================="
ui_print "  音量+ = 继续刷入 | 自动清除冲突模块"
ui_print "  音量- = 取消安装 | 不做任何修改"
ui_print "============================================="

confirm_key=$(ksu_get_key)
if [ "$confirm_key" = "KEY_VOLUMEDOWN" ]; then
    ui_print "⚠️ 安装已取消"
    exit 1
fi

clear_key_buffer

ui_print ""
ui_print "⏳ 请准备选择模式..."
sleep 1

ui_print ""
ui_print "🚀 请选择运行模式"
ui_print "============================================="
ui_print " 音量+ = 模式1（激进：日常删温控,充电伪装温度并删温控）"
ui_print " 音量- = 模式2（安全：仅充电时生效）"
ui_print "============================================="

mode_key=$(ksu_get_key)
if [ "$mode_key" = "KEY_VOLUMEUP" ]; then
    ui_print "✅ 已选择：模式1（激进）"
    mkdir -p "$MODDIR" 2>/dev/null
    echo "1" > "$MODDIR/run_mode"
    chmod 644 "$MODDIR/run_mode" 2>/dev/null
else
    ui_print "✅ 已选择：模式2（安全）"
    mkdir -p "$MODDIR" 2>/dev/null
    echo "2" > "$MODDIR/run_mode"
    chmod 644 "$MODDIR/run_mode" 2>/dev/null
fi

if [ -f "$MODDIR/run_mode" ]; then
    ui_print "✅ run_mode文件已生成：$(cat $MODDIR/run_mode)"
else
    ui_print "❌ 警告：run_mode文件创建失败"
    echo "2" > "$MODDIR/run_mode"
    ui_print "✅ 已创建默认模式2"
fi

ui_print "✅ 已确认安装，释放资源文件..."
mkdir -p /data/local/tmp 2>/dev/null
cp -f "$MODDIR"/Temp.png /data/local/tmp/ >/dev/null 2>&1
chmod 644 /data/local/tmp/Temp.png 2>/dev/null

ui_print "正在排查冲突"

CONFLICT1="/data/adb/modules/extreme_gt"
CONFLICT2="/data/adb/modules/murongruyan"
CONFLICT3="/data/adb/modules/Lucky_Control"

if [ -d "$CONFLICT1" ]; then
    ui_print "⚠️  检测到冲突模块"
    touch "$CONFLICT1/remove"
    ui_print "✅ 已标记卸载"
fi

if [ -d "$CONFLICT2" ]; then
    ui_print "⚠️  检测到冲突模块"
    touch "$CONFLICT2/remove"
    ui_print "✅ 已标记卸载"
fi

if [ -d "$CONFLICT3" ]; then
    ui_print "⚠️  检测到冲突模块"
    touch "$CONFLICT3/remove"
    ui_print "✅ 已标记卸载"
fi

ui_print "✅ 安装完成！"
exit 0