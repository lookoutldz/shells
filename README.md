# shells

脚本集散中心

**导航**
```
shells
├── LICENSE
├── README.md
└── archlinux
    ├── archlinux_initializer_efi.sh
    └── archlinux_installer_efi_btrfs.sh
```

新年新气象, 当然也要新系统, 本 repo 将从 ArchLinux 系统安装与配置脚本开始, 记录日常与生产中好用实用的脚本.

## archlinux

安装脚本: [archlinux_installer_efi_btrfs.sh](./archlinux/archlinux_installer_efi_btrfs.sh)

配置脚本: [archlinux_initializer_efi.sh](./archlinux/archlinux_initializer_efi.sh)

### 使用方法(ArchLinux 安装步骤)

1. 将脚本丢入 U 盘 (不可与安装介质同一个)

2. 在进入安装介质时确保 U 盘成功插入并识别, 假设设备名为 ``/dev/sdb1``

3. 先进行分区操作, 推荐使用 ``cfdisk`` 工具, 最终需要有 ``EFI``, ``swap``, ``/`` 分区, 假设三个区的设备名称分别为 ``/dev/sda1``, ``/dev/sda2``, ``/dev/sda3``

4. 挂载 U 盘: ``mount /dev/sdb1 sdb1 --mkdir``

5. 进入 U 盘执行脚本: ``./archlinux_installer_efi_btrfs.sh --efi=/dev/sda1 --swap=/dev/sda2 --linuxroot=/dev/sda3``, 中途只需点几下回车, 或是设定 root 和默认用户的密码

6. 完成后执行 ``exit`` 回到介质, ``umount /mnt`` 从介质卸载主分区, ``reboot`` 重启就能进入新装好的 Archlinux.

### 参数说明

必要参数:

* ``--efi``: EFI 分区设备名称
* ``--swap``: 交换分区设备名称
* ``--linuxroot``: / 分区设备名称

可选参数:

* ``--btrfslabel``: Btrfs 分区标签, 默认为 ``myarch``
* ``--hostname``: 主机名, 默认为 ``myarch``
* ``--defaultuser``: 用户名, 默认为 ``archer``

### 额外说明

* 在同文件夹下时, install 脚本默认会自动调用 initializer 脚本完成初始化工作
* 脚本会在目标系统生成 @, @home, @snapshots 三个 btrfs 子卷
* 脚本与安装的目标系统都使用了中科大的镜像源做加速, 可自行修改更换
* 默认安装了网络、蓝牙、vim、git 等常用包, 完整安装列表请直接查看脚本, 可根据需要自行增减
* 启用多种语言支持, 默认使用 en_SG.UTF-8 作 locale 以方便纯 tty 玩家, 桌面玩家可自行改为 zh_CN 或其它
* 默认启用 dhcp 网络发现 与 ssh 远程登录
* 已经安装好 yay 😍
* 默认使用 grub 引导系统, 并且❗❗❗**安装时会格式化 efi 分区**, **双系统或多系统请勿使用本脚本❗❗❗**

💯
