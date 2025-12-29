#!/bin/bash


#-------------------------------------- 通用优化
# 设置别名
cat > ~/.bashrc << 'EOF'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias grep='grep --color=auto'
alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alF'
alias ls='ls --color=auto'
EOF



#-------------------------------------- 针对不同系统的优化
#------------------ Debian
# stretch     9
# buster      10
# bullseye    11
# bookworm    12
# trixie      13
# 从 Debian 12 开始，其软件源配置文件变更为 DEB822 格式
debian() {
    # 设置系统apt镜像源
    if [ "$OS_VERSION_CODENAME" = "stretch" ]; then
        rm -f /etc/apt/sources.list.d/debian.sources 2>/dev/null
        cat > /etc/apt/sources.list << EOF
deb http$1://mirrors.aliyun.com/debian-archive/debian stretch main contrib non-free
deb http$1://mirrors.aliyun.com/debian-archive/debian-security stretch/updates main contrib non-free
EOF
    elif [ "$OS_VERSION_CODENAME" = "buster" ]; then
        rm -f /etc/apt/sources.list.d/debian.sources 2>/dev/null
        cat > /etc/apt/sources.list << EOF
deb http$1://mirrors.aliyun.com/debian-archive/debian/ buster main non-free contrib
deb http$1://mirrors.aliyun.com/debian-archive/debian-security buster/updates main
deb http$1://mirrors.aliyun.com/debian-archive/debian/ buster-updates main non-free contrib
EOF
    elif [ "$OS_VERSION_CODENAME" = "bullseye" ]; then
        rm -f /etc/apt/sources.list.d/debian.sources 2>/dev/null
        cat > /etc/apt/sources.list << EOF
deb http$1://mirrors.aliyun.com/debian/ bullseye main non-free contrib
deb http$1://mirrors.aliyun.com/debian-security/ bullseye-security main
deb http$1://mirrors.aliyun.com/debian/ bullseye-updates main non-free contrib
EOF
    elif [ "$OS_VERSION_CODENAME" = "bookworm" ] \
       || [ "$OS_VERSION_CODENAME" = "trixie" ] \
      ; then
        rm -f /etc/apt/sources.list 2>/dev/null
        sed -i 's|deb.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list.d/debian.sources
    else
        return 1
    fi
}

#------------------ Ubuntu
# bionic  18.04
# focal   20.04
# jammy   22.04
# lunar   23.04   2024年1月停止支持，阿里源提示找不到存储库，清华源直接没有这个版本
# noble   24.04
# 从 Ubuntu 24.04 开始，Ubuntu 的软件源配置文件变更为 DEB822 格式
ubuntu() {
    # 设置系统apt镜像源
    if [ "$OS_VERSION_CODENAME" = "bionic" ] \
       || [ "$OS_VERSION_CODENAME" = "focal" ] \
       || [ "$OS_VERSION_CODENAME" = "jammy" ] \
       || [ "$OS_VERSION_CODENAME" = "noble" ] \
      ; then
        rm -f /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null
        cat > /etc/apt/sources.list << EOF
deb http$1://mirrors.aliyun.com/ubuntu/ $OS_VERSION_CODENAME main restricted universe multiverse
deb http$1://mirrors.aliyun.com/ubuntu/ $OS_VERSION_CODENAME-security main restricted universe multiverse
deb http$1://mirrors.aliyun.com/ubuntu/ $OS_VERSION_CODENAME-updates main restricted universe multiverse
deb http$1://mirrors.aliyun.com/ubuntu/ $OS_VERSION_CODENAME-backports main restricted universe multiverse
EOF
    else
        return 1
    fi
}



#-------------------------------------- 主程序入口
# 获取当前系统发行版，以执行不同系统的专属优化
if [ -f /etc/os-release ]; then
    OS_ID=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')
    OS_ID_LIKE=$(awk -F= '/^ID_LIKE=/{print $2}' /etc/os-release | tr -d '"')
    OS_NAME=$(awk -F= '/^NAME=/{print $2}' /etc/os-release | tr -d '"')
    OS_VERSION_ID=$(awk -F= '/^VERSION_ID=/{print $2}' /etc/os-release | tr -d '"')
    OS_VERSION=$(awk -F= '/^VERSION=/{print $2}' /etc/os-release | tr -d '"')
    OS_VERSION_CODENAME=$(awk -F= '/^VERSION_CODENAME=/{print $2}' /etc/os-release | tr -d '"')
    echo "发行版信息↓"
    printf "\tID: $OS_ID    ID_LIKE: $OS_ID_LIKE    NAME: $OS_NAME\n"
    printf "\tVERSION_ID: $OS_VERSION_ID    VERSION: $OS_VERSION    VERSION_CODENAME: $OS_VERSION_CODENAME\n"

    if [ "$OS_ID" = "ubuntu" ] \
       || [ "$OS_ID" = "debian" ] \
      ; then
        # 后面这个命令，用作检测当前系统是否支持https的apt源
        $OS_ID $(command -v update-ca-certificates >/dev/null 2>&1 && echo "s" || echo "")
    else
        echo "暂不支持此发行版的优化"
        exit 1
    fi

    # 判断是否优化成功
    if [ $? -eq 0 ]; then
        echo "优化成功!"
    else
        echo "优化失败! 暂不支持的发行版版本 → $OS_VERSION_CODENAME"
        exit 1
    fi
else
    echo "无法读取发行版文件 /etc/os-release"
    exit 1
fi
