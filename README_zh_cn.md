 **简体中文** || [ **English** ](README.md)
 
# KernelSU_Oneplus_martini_Guide
一加9RT(martini)[MT2110/MT2111]的KernelSU编译指南

## 警告 :warning: :warning: :warning:
- 1.在刷机之前请务必备份官方的boot.img！！！你可以使用[ssut/payload-dumper-go](https://github.com/ssut/payload-dumper-go.git)从ROM包的`payload.bin`中提取镜像。（必须从和当前系统相同版本的ROM包提取）
- 2.我不是这些内核的作者，因此我不会在本仓库发布任何编译产物，请你自行fork本仓库（同步到你的私人仓库更好），然后自行运行工作流编译内核。
- 3."如果你不是内核作者，使用他人的劳动成果构建 KernelSU，请仅供自己使用，不要分享给别人，这是对原作者的劳动成果的尊重。" --[xiaoleGun/KernelSU_Action](https://github.com/xiaoleGun/KernelSU_Action.git)

## 支持的系统

| 工作流名称 | 源码地址 | 分支 | 内核作者 | 备注 |
|:--:|:--:|:--:|:--:|:--:|
| Pixel Experience | [PixelExperience-Devices/kernel_oneplus_martini](https://github.com/PixelExperience-Devices/kernel_oneplus_martini.git) | thirteen | [inferno0230](https://github.com/inferno0230) | 不支持ColorOS和OOS。 |
| Pixel OS | [beet-stuffs/android_kernel_oneplus_sm8350](https://github.com/beet-stuffs/android_kernel_oneplus_sm8350.git) | fourteen-qpr2 | [bheatleyyy](https://github.com/bheatleyyy) | 不支持ColorOS和OOS。 |
| Pixel OS SUSFS | [natsumerinchan/android_kernel_oneplus_sm8350](https://github.com/natsumerinchan/android_kernel_oneplus_sm8350.git) | fourteen-qpr3 | [bheatleyyy](https://github.com/bheatleyyy) | 由本人基于[beet-stuffs/android_kernel_oneplus_sm8350](https://github.com/beet-stuffs/android_kernel_oneplus_sm8350.git)修改，添加了[SUSFS](https://gitlab.com/simonpunk/susfs4ksu)和path_umount功能。不支持ColorOS和OOS。 |

## 如何编译
### 1.Github Action
Fork这个仓库并在Action运行工作流。
如果你没看到Action这个标签栏,请到`settings`-`actions`-`General`把Actions permissions设置为'Allow all actions and reusable workflows'

![Github Action](https://user-images.githubusercontent.com/64072399/216762170-8cce9b81-7dc1-4e7d-a774-b05f281a9bff.png)

```
Run ncipollo/release-action@v1
Error: Error 403: Resource not accessible by integration
```
如果你在尝试上传到Release时看到这个报错,请到 `settings`-`actions`-`General`把 Workflow permissions设置为'Read and write permissions'.

### 2.在电脑上编译

`debian_build.sh` :用于Debian系发行版(如Debian,Ubuntu等)

`arch_build.sh` :用于Arch系发行版(如Arch Linux,Manjaro等)


- `export SETUP_KERNELSU=true` (如果你不想把KernelSU集成进内核，请把它设置为`false`)

## 食用指南
### 1.如何刷入
- 1.下载并安装 [KernelSU Manager](https://github.com/tiann/KernelSU/actions/workflows/build-manager.yml)。不建议安装除了`main`以外的分支，因为它们可能无法正常工作。 
- 2.下载 [platform-tools](https://developer.android.com/studio/releases/platform-tools) (不要从Ubuntu 20.04源安装)
- 3.重启到Recovery Sideload模式,刷入"xxx-v5.4.xxx-xxxxxxxx.zip"
```
adb reboot sideload
adb sideload ./xxx-v5.4.xxx-xxxxxxxx.zip
```

### 2.更新时可能遇到的问题
你可能会遇上手机进入fastbootd或recovery后无法连接电脑的情况, 请进入bootloader 重新刷入官方boot.img
```
adb reboot bootloader
fastboot flash boot ./boot.img
fastboot reboot recovery
```
现在你可以继续更新了

### 3.如何卸载
刷回官方的boot.img即可
```
adb reboot bootloader
fastboot flash boot ./boot.img
```

### 4.如何将更新同步到你的私有仓库
使用Github Desktop将你的私有仓库克隆到本地，然后进入目录并打开终端。

```
// 将主线分支同步到仓库

git remote add Celica https://github.com/natsumerinchan/KernelSU_Oneplus_martini_Guide.git //仅在第一次更新时需要这一步

git fetch Celica main
```

```
// 从主线仓库cherry-pick提交到你的私有仓库

git cherry-pick <commit id>
```

再用Github Desktop将提交上传到Github

## Credits and Thanks
* [tiann/KernelSU](https://github.com/tiann/KernelSU.git): A Kernel based root solution for Android GKI
* [beet-stuffs/android_kernel_oneplus_sm8350](https://github.com/beet-stuffs/android_kernel_oneplus_sm8350.git): PixelOS kernel for OnePlus 9RT 5G (martini)
* [PixelExperience-Devices/kernel_oneplus_martini](https://github.com/PixelExperience-Devices/kernel_oneplus_martini.git): Pixel Experience kernel for OnePlus 9RT (martini)
* [Gainss/Action_Kernel](https://github.com/Gainss/Action_Kernel.git): Kernel Action template
* [xiaoleGun/KernelSU_action](https://github.com/xiaoleGun/KernelSU_action.git): Action for Non-GKI Kernel has some common and requires knowledge of kernel and Android to be used.
* [osm0sis/AnyKernel3](https://github.com/osm0sis/AnyKernel3.git): Flashable Zip Template for Kernel Releases with Ramdisk Modifications
* [@Dreamail](https://github.com/Dreamail): This [commit](https://github.com/tiann/KernelSU/commit/bf87b134ded3b81a864db20d8d25d0bfb9e74ebe) fix error for non-GKI kernel
