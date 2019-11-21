#!/bin/bash
#=================================================
#   Description: termux.sh
#   Lisence: MIT
#   Version: 0.9
#   Author: P3TERX
#   Blog: https://p3terx.com
#=================================================
sh_ver=0.9
SHELLRC="$HOME/.${SHELL##*/}rc"
[ $(uname -o) != Android -a $EUID != 0 ] && SUDO=sudo
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
INFO="[${Green_font_prefix}信息${Font_color_suffix}]"
ERROR="[${Red_font_prefix}错误${Font_color_suffix}]"
TIP="[${Green_font_prefix}注意${Font_color_suffix}]"

Check_Installed() {
    echo -e "${INFO} 检查依赖软件包..."
    [[ $(apt list 2>/dev/null | grep installed | grep git) ]] || (
        echo -e "${INFO} 未安装 Git，开始安装..."
        $SUDO sh -c "apt update && apt install -y git"
    )
    [[ $(apt list 2>/dev/null | grep installed | grep curl) ]] || (
        echo -e "${INFO} 未安装 cURL，开始安装..."
        $SUDO sh -c "apt update && apt install -y curl"
    )
}

in_Keyboard() {
    mkdir -p $HOME/.termux && echo "extra-keys = [['ESC','/','-','HOME','UP','END','PGUP','DEL'],['TAB','CTRL','ALT','LEFT','DOWN','RIGHT','PGDN','BKSP']]" >$HOME/.termux/termux.properties
    [ $? == 0 ] && echo -e "${INFO} 增强功能按键设置成功！若显示异常请重启 Termux App "
    termux-reload-settings
}

un_Keyboard() {
    rm -f $HOME/.termux/termux.properties && echo -e "${INFO} 已还原默认功能按键！若显示异常请重启 Termux App "
    termux-reload-settings
}

Keyboard() {
    if [ -e $HOME/.termux/termux.properties ]; then
        read -e -p "${TIP} 确定要用那么难用的默认功能按键？ [y/N] :" yn
        [[ -z "${yn}" ]] && yn="n"
        if [[ $yn == [Yy] ]]; then
            un_Keyboard
        else
            echo && echo -e "    已取消..." && exit 0
        fi
    else
        in_Keyboard
    fi
}

in_tnua() {
    echo -e "${INFO} 备份源列表文件..."
    cp $PREFIX/etc/apt/sources.list $PREFIX/etc/apt/sources.list.bak
    [ $? == 0 ] && echo -e "${INFO} 备份成功！" || (
        echo -e "${ERROR} 文件被你吃了吗？"
        exit 1
    )
    echo -e "${INFO} 开始更换清华大学镜像源..."
    sed -i 's@^\(deb.*stable main\)$@#\1\ndeb https://mirrors.tuna.tsinghua.edu.cn/termux stable main@' $PREFIX/etc/apt/sources.list
    [ $? == 0 ] && echo -e "${INFO} 更换成功！" || (
        echo -e "${ERROR} 文件被你吃了吗？"
        exit 1
    )
}

un_tuna() {
    echo -e "${INFO} 恢复官方源..."
    mv $PREFIX/etc/apt/sources.list.bak $PREFIX/etc/apt/sources.list
    [ $? == 0 ] && echo -e "${INFO} 恢复成功！" || $(
        echo -e "${ERROR} 文件被你吃了吗？"
        exit 1
    )
}

tuna() {
    [[ $(grep tsinghua $PREFIX/etc/apt/sources.list) ]] && un_tuna || in_tnua
}

in_Oh_My_Zsh() {
    echo -e "${INFO} 开始安装 Oh My Zsh ..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended
    git clone https://github.com/zsh-users/zsh-syntax-highlighting $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-completions $HOME/.oh-my-zsh/custom/plugins/zsh-completions
    [[ -z $(grep "autoload -U compinit && compinit" $HOME/.zshrc) ]] && echo "autoload -U compinit && compinit" >> $HOME/.zshrc
    sed -i '/^ZSH_THEME=/c\ZSH_THEME="ys"' $HOME/.zshrc
    if [ $(uname -o) != Android ]; then
        sed -i '/^plugins=/c\plugins=(git sudo z command-not-found zsh-syntax-highlighting zsh-autosuggestions zsh-completions)' $HOME/.zshrc
    else
        sed -i '/^plugins=/c\plugins=(git z zsh-syntax-highlighting zsh-autosuggestions zsh-completions)' $HOME/.zshrc
    fi
    [ $(uname -o) != Android ] && chsh -s $(which zsh) || chsh -s zsh
    [ $? == 0 ] && echo -e "${INFO} Oh My Zsh 安装成功！"
    zsh
}

un_Oh_My_Zsh() {
    read -e -p "${TIP} 确定要卸载 Oh My Zsh ？ [y/N] :" yn
    [[ -z "${yn}" ]] && yn="n"
    if [[ $yn == [Yy] ]]; then
        echo -e "${INFO} 正在卸载 Oh My Zsh ..."
        rm -rf $HOME/.oh-my-zsh
        rm -f $HOME/.zsh* $HOME/.z $HOME/.zcom*
        echo -e "${INFO} Oh My Zsh 已卸载"
    else
        echo && echo -e "    已取消..." && exit 0
    fi
}

Oh_My_Zsh() {
    if [ -e $HOME/.oh-my-zsh ]; then
        un_Oh_My_Zsh
    else
        echo -e "${INFO} 开始安装 Zsh ..."
        if [[ $(apt list 2>/dev/null | grep installed | grep zsh) ]]; then
            echo -e "${INFO} Zsh 已安装，跳过..."
            [[ $(apt list 2>/dev/null | grep installed | grep command-not-found) ]] || (
                echo -e "${INFO} 未安装 command-not-found，开始安装..."
                $SUDO sh -c "apt update && apt install -y command-not-found && apt update"
            )
        else
            $SUDO sh -c "apt update && apt install -y zsh command-not-found && apt update" && echo -e "${INFO} Zsh 安装成功！"
        fi
        in_Oh_My_Zsh
    fi
}

in_Oh_My_Tmux() {
    echo -e "${INFO} 开始安装 Oh My Tmux ..."
    git clone https://github.com/gpakosz/.tmux.git $HOME/.tmux
    ln -sf .tmux/.tmux.conf $HOME/.tmux.conf
    cp .tmux/.tmux.conf.local $HOME
    [ $? == 0 ] && echo -e "${INFO} Oh My Tmux 安装成功！"
}

un_Oh_My_Tmux() {
    read -e -p "${TIP} 确定要卸载 Oh My Tmux ？ [y/N] :" yn
    [[ -z "${yn}" ]] && yn="n"
    if [[ $yn == [Yy] ]]; then
        echo -e "${INFO} 正在卸载 Oh My Tmux ..."
        rm -rf $HOME/.tmux $HOME/.tmux.conf $HOME/.tmux.conf.local && echo -e "${INFO} Oh My Tmux 已卸载"
    else
        echo && echo -e "    已取消..." && exit 0
    fi
}

Oh_My_Tmux() {
    if [ -e $HOME/.tmux ]; then
        un_Oh_My_Tmux
    else
        echo -e "${INFO} 开始安装 Tmux ..."
        if [[ $(apt list 2>/dev/null | grep installed | grep tmux) ]]; then
            echo -e "${INFO} Tmux 已安装，跳过..."
        else
            $SUDO sh -c "apt update && apt install tmux" && echo -e "${INFO} Tmux 安装成功！"
        fi
        in_Oh_My_Tmux
    fi
}

in_SpaceVim() {
    echo -e "${INFO} 开始安装 SpaceVim ..."
    curl -sLf https://spacevim.org/install.sh | bash && echo -e "${INFO} SpaceVim 安装成功！"
}

un_SpaceVim() {
    read -e -p "${TIP} 确定要卸载 SpaceVim ？ [y/N] :" yn
    [[ -z "${yn}" ]] && yn="n"
    if [[ $yn == [Yy] ]]; then
        echo -e "${INFO} 正在卸载 SpaceVim ..."
        curl -sLf https://spacevim.org/install.sh | bash -s -- -u
        rm -rf $HOME/.SpaceVim $HOME/.SpaceVim.d
        [ $? == 0 ] && echo -e "${INFO} SpaceVim 已卸载"
    else
        echo && echo -e "    已取消..." && exit 0
    fi
}

SpaceVim() {
    if [ -e $HOME/.SpaceVim ]; then
        un_SpaceVim
    else
        echo -e "${INFO} 开始安装 Vim ..."
        if [[ $(apt list 2>/dev/null | grep installed | grep vim) ]]; then
            echo -e "${INFO} Vim 已安装，跳过..."
        else
            $SUDO sh -c "apt update && apt install vim" && echo -e "${INFO} Vim 安装成功！"
        fi
        in_SpaceVim
    fi
}

logoin() {
    echo && echo -e " 问候语设置

 ${Green_font_prefix} 1.${Font_color_suffix} ${logoin_status}

 ${Green_font_prefix} 2.${Font_color_suffix} 自定义问候语

————————————" && echo
    read -e -p " 请输入数字 [0-2]:" num
    case "$num" in
    1)
        if [ -e $HOME/.hushlogin ]; then
            rm -f $HOME/.hushlogin && echo -e "${INFO} 问候语已显示"
        else
            touch $HOME/.hushlogin && echo -e "${INFO} 问候语已隐藏"
        fi
        ;;
    2)
        [[ $(apt list 2>/dev/null | grep installed | grep nano) ]] || (
            echo -e "${INFO} 未安装 nano 编辑器，开始安装..."
            $SUDO sh -c "apt update && apt install nano"
        )
        nano $PREFIX/etc/motd
        ;;
    *)
        echo "请输入正确数字 [1-2]"
        ;;
    esac
}

start_sshd() {
    [[ -z $(grep sshd ${SHELLRC}) ]] && (echo "sshd" >>${SHELLRC} && echo -e "${INFO} SSH 服务端自启设置成功！") || echo -e "${INFO} 已经是开启状态了哦~别闹~"
}

poweron_sshd() {
    mkdir -p $HOME/.termux/boot
    echo 'termux-wake-lock; sshd' >$HOME/.termux/boot/start-sshd && echo -e "${INFO} SSH 服务端开机自启设置成功！"
}

storage() {
    if [[ $(ls /sdcard) ]]; then
        echo -e "${ERROR} 外置存储访问权限早就开启了，不要搞事！"
        exit 1
    else
        echo -e "${INFO} 正在开启外置存储访问权限..."
        echo -e "${TIP} 请点击“允许”。"
        termux-setup-storage && echo -e "${INFO} 外置存储访问权限开启成功！"
    fi
}

[ -e $HOME/.termux/termux.properties ] && Keyboard_status="恢复默认功能按键" || Keyboard_status="设置增强功能按键"
[[ $(grep tsinghua $PREFIX/etc/apt/sources.list) ]] && tuna_status="恢复 Termux 官方源" || tuna_status="使用清华大学镜像源"
[ -e $HOME/.oh-my-zsh ] && Oh_My_Zsh_status="卸载 Oh My Zsh" || Oh_My_Zsh_status="安装 Oh My Zsh"
[ -e $HOME/.tmux ] && Oh_My_Tmux_status="卸载 Oh My Tmux" || Oh_My_Tmux_status="安装 Oh My Tmux"
[ -e $HOME/.SpaceVim ] && SpaceVim_status="卸载 SpaceVim" || SpaceVim_status="安装 SpaceVim"
[ -e $HOME/.hushlogin ] && logoin_status="显示问候语" || logoin_status="隐藏问候语"

if [ $(uname -o) != Android ]; then
    echo && echo -e " WSL.sh ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- \033[1;35mP3TERX.COM\033[0m --

 ${Green_font_prefix} 1.${Font_color_suffix} ${Oh_My_Zsh_status}

 ${Green_font_prefix} 2.${Font_color_suffix} ${Oh_My_Tmux_status}

 ${Green_font_prefix} 3.${Font_color_suffix} ${SpaceVim_status}

————————————" && echo
    read -e -p " 请输入数字 [1-3]:" num
    case "$num" in
    0)
        Check_Installed
        Oh_My_Zsh
        Oh_My_Tmux
        ;;
    1)
        Check_Installed
        Oh_My_Zsh
        ;;
    2)
        Check_Installed
        Oh_My_Tmux
        ;;
    3)
        Check_Installed
        SpaceVim
        ;;
    *)
        echo "请输入正确数字 [0-5]"
        ;;
    esac
else
    echo && echo -e " Termux.sh ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- \033[1;35mP3TERX.COM\033[0m --

 ${Green_font_prefix} 1.${Font_color_suffix} ${Keyboard_status}

 ${Green_font_prefix} 2.${Font_color_suffix} ${tuna_status}

 ${Green_font_prefix} 3.${Font_color_suffix} ${Oh_My_Zsh_status}

 ${Green_font_prefix} 4.${Font_color_suffix} ${Oh_My_Tmux_status}

 ${Green_font_prefix} 5.${Font_color_suffix} ${SpaceVim_status}

 ${Green_font_prefix} 6.${Font_color_suffix} 问候语设置

 ${Green_font_prefix} 7.${Font_color_suffix} 配置 SSH 服务端自启

 ${Green_font_prefix} 8.${Font_color_suffix} 开启外置存储访问权限

————————————" && echo
    read -e -p " 请输入数字 [1-8]:" num
    case "$num" in
    0)
        Check_Installed
        Oh_My_Zsh
        Oh_My_Tmux
        ;;
    1)
        Keyboard
        ;;
    2)
        tuna
        ;;
    3)
        Check_Installed
        Oh_My_Zsh
        ;;
    4)
        Check_Installed
        Oh_My_Tmux
        ;;
    5)
        Check_Installed
        SpaceVim
        ;;
    6)
        logoin
        ;;
    7)
        start_sshd
        poweron_sshd
        ;;
    8)
        storage
        ;;
    *)
        echo "请输入正确数字 [1-8]"
        ;;
    esac
fi
