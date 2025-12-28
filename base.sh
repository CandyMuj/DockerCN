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
debian() {
    # 移除默认源
    rm -f /etc/apt/sources.list.d/debian.sources 2>/dev/null

    # 设置系统apt镜像源
    if [ "$OS_VERSION_CODENAME" = "bullseye" ] \
       || [ "$OS_VERSION_CODENAME" = "bookworm" ] \
       || [ "$OS_VERSION_CODENAME" = "trixie" ] \
      ; then
        cat > /etc/apt/sources.list << EOF
deb https://mirrors.aliyun.com/debian/ $OS_VERSION_CODENAME main non-free contrib
# deb-src https://mirrors.aliyun.com/debian/ $OS_VERSION_CODENAME main non-free contrib
deb https://mirrors.aliyun.com/debian-security/ $OS_VERSION_CODENAME-security main
# deb-src https://mirrors.aliyun.com/debian-security/ $OS_VERSION_CODENAME-security main
deb https://mirrors.aliyun.com/debian/ $OS_VERSION_CODENAME-updates main non-free contrib
# deb-src https://mirrors.aliyun.com/debian/ $OS_VERSION_CODENAME-updates main non-free contrib
# deb https://mirrors.aliyun.com/debian/ $OS_VERSION_CODENAME-backports main non-free contrib
# deb-src https://mirrors.aliyun.com/debian/ $OS_VERSION_CODENAME-backports main non-free contrib
EOF
    elif [ "$OS_VERSION_CODENAME" = "buster" ]; then
        cat > /etc/apt/sources.list << 'EOF'
deb https://mirrors.aliyun.com/debian-archive/debian/ buster main non-free contrib
deb https://mirrors.aliyun.com/debian-archive/debian-security buster/updates main
deb https://mirrors.aliyun.com/debian-archive/debian/ buster-updates main non-free contrib
# deb-src https://mirrors.aliyun.com/debian-archive/debian/ buster main non-free contrib
# deb-src https://mirrors.aliyun.com/debian-archive/debian-security buster/updates main
# deb-src https://mirrors.aliyun.com/debian-archive/debian/ buster-updates main non-free contrib
EOF
    elif [ "$OS_VERSION_CODENAME" = "stretch" ]; then
        cat > /etc/apt/sources.list << 'EOF'
deb https://mirrors.aliyun.com/debian-archive/debian stretch main contrib non-free
# deb https://mirrors.aliyun.com/debian-archive/debian stretch-proposed-updates main non-free contrib
# deb https://mirrors.aliyun.com/debian-archive/debian stretch-backports main non-free contrib
deb https://mirrors.aliyun.com/debian-archive/debian-security stretch/updates main contrib non-free
# deb-src https://mirrors.aliyun.com/debian-archive/debian stretch main contrib non-free
# deb-src https://mirrors.aliyun.com/debian-archive/debian stretch-proposed-updates main contrib non-free
# deb-src https://mirrors.aliyun.com/debian-archive/debian stretch-backports main contrib non-free
# deb-src https://mirrors.aliyun.com/debian-archive/debian-security stretch/updates main contrib non-free
EOF
    else
        return 1
    fi
}

#------------------ Ubuntu
ubuntu() {
    # 移除默认源
    rm -f /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null

    # 设置系统apt镜像源
    if [ "$OS_VERSION_CODENAME" = "noble" ] \
       || [ "$OS_VERSION_CODENAME" = "lunar" ] \
       || [ "$OS_VERSION_CODENAME" = "jammy" ] \
       || [ "$OS_VERSION_CODENAME" = "focal" ] \
       || [ "$OS_VERSION_CODENAME" = "bionic" ] \
      ; then
        cat > /etc/apt/sources.list << EOF
deb https://mirrors.aliyun.com/ubuntu/ $OS_VERSION_CODENAME main restricted universe multiverse
# deb-src https://mirrors.aliyun.com/ubuntu/ $OS_VERSION_CODENAME main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ $OS_VERSION_CODENAME-security main restricted universe multiverse
# deb-src https://mirrors.aliyun.com/ubuntu/ $OS_VERSION_CODENAME-security main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ $OS_VERSION_CODENAME-updates main restricted universe multiverse
# deb-src https://mirrors.aliyun.com/ubuntu/ $OS_VERSION_CODENAME-updates main restricted universe multiverse
# deb https://mirrors.aliyun.com/ubuntu/ $OS_VERSION_CODENAME-proposed main restricted universe multiverse
# deb-src https://mirrors.aliyun.com/ubuntu/ $OS_VERSION_CODENAME-proposed main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ $OS_VERSION_CODENAME-backports main restricted universe multiverse
# deb-src https://mirrors.aliyun.com/ubuntu/ $OS_VERSION_CODENAME-backports main restricted universe multiverse
EOF
    else
        return 1
    fi
}



#-------------------------------------- 主程序入口
# 获取当前系统发行版，以执行不同系统的专属优化
if [ -f /etc/os-release ]; then
    OS_ID=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')
    OS_NAME=$(awk -F= '/^NAME=/{print $2}' /etc/os-release | tr -d '"')
    OS_VERSION_ID=$(awk -F= '/^VERSION_ID=/{print $2}' /etc/os-release | tr -d '"')
    OS_VERSION=$(awk -F= '/^VERSION=/{print $2}' /etc/os-release | tr -d '"')
    OS_VERSION_CODENAME=$(awk -F= '/^VERSION_CODENAME=/{print $2}' /etc/os-release | tr -d '"')
    echo "发行版信息↓\n\tID: $OS_ID\tNAME: $OS_NAME\n\tVERSION_ID: $OS_VERSION_ID\tVERSION: $OS_VERSION\tVERSION_CODENAME: $OS_VERSION_CODENAME"

    if [ "$OS_ID" = "ubuntu" ]; then
        ubuntu
    elif [ "$OS_ID" = "debian" ]; then
        debian
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
