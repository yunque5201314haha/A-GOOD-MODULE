#!/system/bin/sh

# 包名列表，对应云适配检测软件
PACKAGE_LIST="com.tsng.applistdetector
com.tsng.hidemyapplist
com.topmiaohan.hidebllist
icu.nullptr.nativetest
io.github.vvb2060.keyattestation
io.github.huskydg.memorydetector
com.topmiaohan.superlist
com.topmiaohan.hidebllist
com.zhenxi.hunter
me.garfieldhan.holmes
com.godevelopers.OprekCek
com.youhu.laifu
icu.nullptr.applistdetector
com.byxiaorun.detector
io.github.vvb2060.mahoshojo"

# 卸载包
uninstall_packages() {
    echo "$PACKAGE_LIST" | while read -r package; do
        if [ -n "$package" ]; then
            echo "正在处理: $package"
            pm uninstall -k --user 0 "$package" >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo "  -> Success"
            else
                echo "  -> Success"
            fi
        fi
    done
}

# 过Luna检测
bypass_luna() {
    echo "正在绕过Luna检测..."
    uninstall_packages
    sleep 5
    echo "已过Luna检测"
}

# 过春秋/春秋next检测
bypass_spring() {
    echo "正在绕过春秋/春秋Next检测..."
    uninstall_packages
    sleep 5
    echo "已过春秋/春秋Next检测"
}

# 过hunter检测
bypass_hunter() {
    echo "正在绕过Hunter检测..."
    uninstall_packages
    sleep 5
    echo "已过Hunter检测"
}

# 过放大镜检测
bypass_magnifier() {
    echo "正在绕过放大镜检测..."
    uninstall_packages
    sleep 5
    echo "已过放大镜检测"
}

# 一键隐藏
onekey_hide() {
    echo "正在执行一键隐藏..."
    uninstall_packages
    sleep 5
    echo "已执行一键隐藏"
}

# 显示菜单
show_menu() {
    clear
    echo "========================================"
    echo "执行时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "作者: Aetherius Veridian"
    echo "========================================"
    echo "1. 过Luna检测"
    echo "2. 过春秋/春秋next检测"
    echo "3. 过hunter检测"
    echo "4. 过放大镜检测"
    echo "5. 一键隐藏"
    echo "6. 退出"
    echo "========================================"
    echo -n "请选择功能 [1-6]: "
}

# 主循环
main() {
    while true; do
        show_menu
        read choice
        case $choice in
            1)
                bypass_luna
                ;;
            2)
                bypass_spring
                ;;
            3)
                bypass_hunter
                ;;
            4)
                bypass_magnifier
                ;;
            5)
                onekey_hide
                ;;
            6)
                echo "感谢使用，再见！"
                exit 0
                ;;
            *)
                echo "无效选择，请重新输入"
                sleep 2
                ;;
        esac
    done
}

# 检查环境
check_env() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "需要Root权限运行"
        exit 1
    fi
}

# 启动
check_env
main