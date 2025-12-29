#!/bin/bash


echo_help() {
    echo "Usage: $0 <option> <value>"
    printf "\t-b --base\t: * 需要构建的镜像类型，对应 base-xxx.sh 系列脚本\n"
    printf "\t-i --image\t: * 基于base使用的基础镜像，需要优化的镜像(一般是来自DockerHub的轻量镜像)\n"
    printf "\t-t --target\t: * 构建的产物，构建后的最终镜像(未指定tag，默认将为latest) imagename<:tag>\n"
    printf "\t-bf --platforms\t: 指定构建的平台，多个以','分隔，默认构建当前单一平台 注意：仅开启buildx时才会生效\n"
    printf "\t-bx --buildx\t: 使用buildx执行构建\n"
    printf "\t-bp --push\t: 构建后同时执行推送\n"
    printf "\t-h --help\t: 帮助信息\n"
}

check_option_value() {
    local option="$1"
    local value="$2"
    if [ -z "$value" ] || [ "${value#-}" != "$value" ]; then
        echo "Option $option requires an argument" >&2
        exit 1
    fi
}

# 初始化变量
v_base=""
v_image=""
v_target=""
v_platforms=""
v_buildx=false
v_push=false
# 解析参数
while [ $# -gt 0 ]; do
    case "$1" in
        -b|--base)
            check_option_value "$1" "$2"
            v_base="$2"
            shift 2
            ;;
        -i|--image)
            check_option_value "$1" "$2"
            v_image="$2"
            shift 2
            ;;
        -t|--target)
            check_option_value "$1" "$2"
            v_target="$2"
            shift 2
            ;;
        -bf|--platforms)
            check_option_value "$1" "$2"
            v_platforms="$2"
            shift 2
            ;;
        -bx|--buildx)
            v_buildx=true
            shift 1
            ;;
        -bp|--push)
            v_push=true
            shift 1
            ;;
        -h|--help)
            echo_help
            exit 0
            ;;
        *)
            echo "Invalid option: $1"
            echo_help
            exit 1
            ;;
    esac
done

# 校验参数
if [ -z "$v_base" ] || [ -z "$v_image" ] || [ -z "$v_target" ]; then
    echo "参数错误"
    echo_help
    exit 1
fi
if [ ! -f base-$v_base.sh ]; then
    echo "对应的base脚本不存在 base-$v_base.sh"
    exit 1
fi

#------------------ 组合构建命令
if [ $v_buildx = true ]; then
    build_cmd="docker buildx build"
else
    build_cmd="docker build"
fi
#--------- 添加 platform 参数
if [ $v_buildx = true ] && [ -n "$v_platforms" ]; then
    build_cmd="$build_cmd --platform $v_platforms"
fi
#--------- 添加 push 参数
if [ $v_push = true ]; then
    build_cmd="$build_cmd --push"
fi
#--------- 添加基础参数
build_cmd="$build_cmd --progress=plain -t $v_target -f"

# 执行构建
echo "执行镜像优化构建 base脚本: base-$v_base.sh 基础镜像: $v_image 最终镜像: $v_target\n构建命令: $(echo $build_cmd | xargs)"
# 设定工作目录(不在Dockerfile中使用WORKDIR，避免更改了原镜像的工作路径)
workdir=/cc-dockercn
cat << EOF | $build_cmd - .
FROM $v_image

#------------------ 通用优化
# 设置时区
# ENV TZ=UTC
# RUN ln -snf /usr/share/zoneinfo/\$TZ /etc/localtime && echo \$TZ > /etc/timezone

#------------------ 执行优化
COPY . $workdir
# 执行系统优化
RUN sh $workdir/base.sh
# 执行镜像优化
RUN sh $workdir/base-$v_base.sh
# 清理文件
RUN rm -rf $workdir
EOF
