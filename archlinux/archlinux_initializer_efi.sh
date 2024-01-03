#!/bin/sh

# 所用参数
HOST_NAME="myarch"
DEFAULT_USER="archer"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
  case "$1" in
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

# 输出提供的参数
echo "Hostname: $HOST_NAME"
echo "Default user: $DEFAULT_USER"

# 主机名称设置
echo $HOST_NAME >> /etc/hostname && \
echo "127.0.1.1    $HOST_NAME.localdomain    $HOST_NAME" >> /etc/hosts

# 时区和语言设置
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
hwclock --systohc && \
sed -i -e 's/#\(en_US.UTF-8\)/\1/' \
       -e 's/#\(en_HK.UTF-8\)/\1/' \
       -e 's/#\(en_SG.UTF-8\)/\1/' \
       -e 's/#\(zh_CN.UTF-8\)/\1/' /etc/locale.gen && \
locale-gen && \
echo "LANG=en_SG.UTF-8" >> /etc/locale.conf

# 开启 ssh 登录
sed -i -e '/^#PasswordAuthentication/s/^#//' \
       -e '/^#PermitRootLogin/s/^#//' /etc/ssh/sshd_config && \
systemctl enable sshd

# 网络设置
systemctl enable dhcpcd
systemctl enable NetworkManager

# 换源
sed -i '10 i Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch' /etc/pacman.d/mirrorlist  && \
sed -i '$a\[archlinuxcn]' /etc/pacman.conf && \
sed -i '$a\Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch' /etc/pacman.conf && \
pacman -Sy && \
#pacman -Sy archlinuxcn-keyring

# 配置 grub 启动 
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB && \
grub-mkconfig -o /boot/grub/grub.cfg

# 创建默认用户
useradd -m -d /home/$DEFAULT_USER -s /bin/zsh $DEFAULT_USER && \
sed -i "83i $DEFAULT_USER ALL=(ALL:ALL) ALL" /etc/sudoers && \

# 设置 root 密码和默认用户的密码
echo "Setting password for root (you can reset later manually if getting wrong):" && \
passwd && \
echo "Setting password for $DEFAULT_USER (you can reset later manually if getting wrong):" && \
passwd $DEFAULT_USER && \

# 安装 yay
cd /opt && \
git clone https://aur.archlinux.org/yay.git && \
sudo chown -R $DEFAULT_USER:users ./yay && \
cd yay && \
sudo -u $DEFAULT_USER makepkg -si

# 配置完成, 回到介质请手动 umount /mnt 后重启, 即可进入新系统
echo "Setting new system completed."
echo "Now execute 'exit', 'umount /mnt' and 'reboot' manually to get into the new system."