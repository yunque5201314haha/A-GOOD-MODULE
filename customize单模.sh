#!/system/bin/sh 
MODPATH="${1}"

ui_print() {
    echo "$1"
}

ksu_get_key() {
    timeout 10 getevent -qlc 1 | awk '{print $3}' | grep -E 'KEY_VOLUMEUP|KEY_VOLUMEDOWN' | head -n1
}

show_install_confirm() {
    ui_print "============================================="
    ui_print "  音量+ = 继续刷入 | 自动清除冲突模块"
    ui_print "  音量- = 取消安装 | 不做任何修改"
    ui_print "============================================="

    while :; do 
        local key=$(ksu_get_key)
        [ -n "$key" ] && break 
        sleep 0.1 
    done 

    if [ "$key" = "KEY_VOLUMEDOWN" ]; then
        ui_print "⚠️ 安装已取消"
        exit 1
    fi
}

ui_print "🚀 模块安装确认"
show_install_confirm

ui_print "✅ 已确认安装，释放资源文件..."
mkdir -p /data/local/tmp 2>/dev/null
cp -f "$MODPATH"/Temp.png /data/local/tmp/ >/dev/null 2>&1
chmod 777 /data/local/tmp/Temp.png 2>/dev/null

ui_print "正在排查冲突"

CONFLICT1="/data/adb/modules/extreme_gt"
CONFLICT2="/data/adb/modules/murongruyan"

if [ -d "$CONFLICT1" ]; then
    ui_print "⚠️  检测到冲突"
    touch "$CONFLICT1/remove"
    ui_print "✅ 已标记卸载"
fi

if [ -d "$CONFLICT2" ]; then
    ui_print "⚠️  检测到冲突"
    touch "$CONFLICT2/remove"
    ui_print "✅ 已标记卸载"
fi

ui_print "✅ 继续安装模块"

exit 0
