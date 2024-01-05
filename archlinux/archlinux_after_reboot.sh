#!/bin/zsh

# 所用参数
LINUXROOT_PARTITION="/dev/nvme0n1p3"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
  case "$1" in
    --linuxroot=*)
      LINUXROOT_PARTITION="${1#*=}"
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
  shift
done

# 启用温度传感器
sudo sensors-detect --auto

# 启用自动快照
# 配置 snapper, 删除默认子卷
sudo pacman -S pacman --needed && \
sudo snapper -c root create-config / && \
sudo btrfs subvolume delete /.snapshots && \
sudo mount -o subvolid=5 $LINUXROOT_PARTITION ~/rootsub && \
# 让 snapper 使用 @snapshots 子卷, 更新 fstab 文件
{head -n 9 /etc/fstab; tail -n 10 /etc/fstab;} > fstab.tmp && \
sed -i '12s#/home#/.snapshots#; 12s#257#258#; 12s#@home#@snapshots#' fstab.tmp && \
sudo rm /etc/fstab && sudo mv fstab.tmp /etc/fstab && \
sudo mkdir /.snapshots && \
sudo mount -a && \
sudo cat /etc/fstab && \
sudo chmod 750 /.snapshots && \
# 创建初始快照
sudo snapper create --description "Initial Snapshot By After Reboot."
# 开启Snapper自动快照和自动清理
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer