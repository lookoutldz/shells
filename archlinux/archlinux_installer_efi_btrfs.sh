#!/bin/sh

# 默认的设备和分区变量
EFI_PARTITION=""
SWAP_PARTITION=""
LINUXROOT_PARTITION=""
# 可选参数
BTRFS_LABEL="myarch"
HOST_NAME="myarch"
DEFAULT_USER="archer"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
  case "$1" in
    --efi=*)
      EFI_PARTITION="${1#*=}"
      ;;
    --swap=*)
      SWAP_PARTITION="${1#*=}"
      ;;
    --linuxroot=*)
      LINUXROOT_PARTITION="${1#*=}"
      ;;
    --btrfslabel=*)
      BTRFS_LABEL="${1#*=}"
      ;;
    --hostname=*)
      HOST_NAME="${1#*=}"
      ;;
    --defaultuser=*)
      DEFAULT_USER="${1#*=}"
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
  shift
done

# 检查是否提供了必要的参数
if [[ -z "$EFI_PARTITION" || -z "$SWAP_PARTITION" || -z "$LINUXROOT_PARTITION" ]]; then
  echo "Missing required parameters, please provide --efi, --swap end --linuxroot devices paratemers."
  exit 1
fi

# 输出提供的参数
echo "EFI partition (will be mounted on /boot): $EFI_PARTITION"
echo "Swap partition: $SWAP_PARTITION"
echo "Linuxroot partition (will be mounted on /): $LINUXROOT_PARTITION"
echo "Btrfs partition label: $BTRFS_LABEL"
echo "Hostname: $HOST_NAME"
echo "Default user: $DEFAULT_USER"

# 格式化分区
mkfs.fat -F32 $EFI_PARTITION && \
mkswap $SWAP_PARTITION  && \
mkfs.btrfs -L $BTRFS_LABEL $LINUXROOT_PARTITION && \

# 创建 btrfs 子卷
mount -t btrfs -o compress=zstd $LINUXROOT_PARTITION /mnt  && \
btrfs subvolume create /mnt/@ && \
btrfs subvolume create /mnt/@home && \
btrfs subvolume list -p /mnt && \
umount /mnt && \

# 挂载并启用
mount -t btrfs -o subvol=/@,compress=zstd $LINUXROOT_PARTITION /mnt && \
mount -t btrfs -o subvol=/@home,compress=zstd $LINUXROOT_PARTITION /mnt/home --mkdir && \
mount $EFI_PARTITION /mnt/boot --mkdir && \
swapon $SWAP_PARTITION && \

# 正式安装(可根据自己的需要更改初始包, 比如 amd 处理器的机器将 intel-ucode 换成 amd-ucode)
sed -i '10 i Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch' /etc/pacman.d/mirrorlist  && \
pacman-key --init && pacman -Sy archlinux-keyring && \
pacman -Syy  && \
pacstrap -K /mnt base linux linux-firmware base-devel linux-headers \
  networkmanager dhcpcd openssh vim git curl wget lsof htop tree zsh zsh-completions lm_sensors \
  grub efibootmgr intel-ucode bluez bluez-utils man-db man-pages && \

# 写入 fstab
genfstab -U /mnt >> /mnt/etc/fstab  && \
cat /mnt/etc/fstab  && \

# 安装初步完成, 进入配置环节, 检查配置脚本存在性以决定是否自动配置
INIT_SCRIPT="archlinux_initializer_efi.sh"
if [ -e $INIT_SCRIPT ]; then
    chmod +x $INIT_SCRIPT && \
    cp $INIT_SCRIPT /mnt && \
    arch-chroot /mnt /$INIT_SCRIPT --hostname=$HOST_NAME --defaultuser=$DEFAULT_USER
else
    echo "Initial script $INIT_SCRIPT does not exist, use 'arch-chroot /mnt' get into linux and setting manually."
fi

# 完成
echo "Completed!"
