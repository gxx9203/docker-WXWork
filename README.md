[![Docker Image](https://img.shields.io/badge/docker%20image-available-green.svg)](https://hub.docker.com/r/boringcat/wechat/)


**感谢[bestwu](https://github.com/bestwu)提供的[deepin-wine](https://github.com/bestwu/docker-wine)镜像**

在此基础上修改`Dockerfile`与`entrypoint.sh`得到企业微信的docker镜像

---

本镜像基于[深度操作系统](https://www.deepin.org/download/)

## 更新版本

### 2021/02/20
  * 更新wxwork 到3.1.2.2211 
  * 需要自己本地build image 
  * 
```bash
    docker build -t=wine_wxwork .
    
    docker run -d --name wechat --device /dev/snd --ipc host \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v $HOME/WXWork:/WXWork \
    -v $HOME:/HostHome \
    -v $HOME/wine-WXWork:/home/wechat/.deepinwine/Deepin-WXWork \
    -e DISPLAY=unix$DISPLAY \
    -e XMODIFIERS=@im=fcitx \
    -e QT_IM_MODULE=fcitx \
    -e GTK_IM_MODULE=fcitx \
    -e AUDIO_GID=`getent group audio | cut -d: -f3` \
    -e GID=`id -g` \
    -e UID=`id -u` \
    -e DPI=96 \
    -e WAIT_FOR_SLEEP=1 \
     wine_wxwork
```

### 2020/04/09
  * 更换wine配置（巨型镜像警告）
  * 内置版本更新到 3.0.14.1205 
  * 别更新到 3.0.16.1608 会报wlanapi.dll错误

<details>
 <summary>2020/03/13</summary>
 
  * 解决了退出时符合值不为0的问题  
  * 尝试解决挂载WXWork不生效的问题   
    * 原因: 企业微信认为 C:\users\wechat\Document\WXWork (/home/wechat/WXWork) 不可读
    * 当前版本尝试方案: 使用 wechat 用户创建软链接
    * 最终解决方案: 将 WXWork 挂在至 /home/wechat/WXWork

</details>

<details>
 <summary>2020/03/11</summary>
 
  * 优化了关闭检测，现在不会因为自动更新重启微信导致容器退出了(递归溢出警告)  
  * 允许传递参数给企业微信
  
</details>

<details>
 <summary>2020/03/06</summary>
 
  * 匹配了HIDPI, 只需要在 environment 中传入 DPI=%d  
  目前能做到持久化企业微信时每次修改DPI的值也能生效
  * 解决了容器关闭慢的问题
  * 挂载 `/home/wechat/.deepinwine/Deepin-WXWork` 时貌似不会覆盖已有文件，可以利用这点更新企业微信
  * 目前无法启动企业微信的更新程序，但是启动时的自动更新可以（？？？？？），如有需要请解压企业微信最新的安装包然后覆盖文件夹内容就行
  * RO挂载持久化目前看来不可能，因为企业微信有启动时的自动更新和我的DPI调整脚本

</details>

<details>
 <summary>2020/02/23</summary>
 
* 没有测试能否在docker内启动更新，可以选择将wine文件夹挂载出来，然后手动覆盖最新版企业微信  
* 尚未解明deepin-wine在什么条件下会重新解压应用到 `/home/wechat/.deepinwine` 中。如果要挂载 `/home/wechat/.deepinwine` 建议在确保有备份的情况下挂载，或者判断不需要写入权限时以`ro`挂载  

</details>

## **注意事项**
### `entrypoint.sh`
* 使用 host 网络时会出现无法联网的问题，尚未清楚到底是Wine企业微信的问题还是基础容器的问题 (exec进去ping和wget是可以的)
* 启动时会使用chmod命令替换 /WXWork /home/wechat 的所有者为 `$GID:$UID`
* 启动时会使用chmod命令替换 /home/wechat/.deepinwine 下**所有目录和文件**的所有者为 `$GID:$UID` 持久化时需要注意 **!!!!!!**
* 如果遇到挂载WXWork不生效的问题，即Host的WXWork目录下无文件，可以通过在企业微信内配置“文件存储”的位置来解决  
  非持久化可能存在问题，建议使用持久化

### 非Gnome用户？
如果你遇到这个情况：
```
X Error of failed request: BadWindow (invalid Window parameter)
Major opcode of failed request: 20 (X_GetProperty)
Resource id in failed request: 0x0
Serial number of failed request: 10
Current serial number in output stream: 10
```
请参考：  
[AUR (en) - deepin.com.qq.office](https://aur.archlinux.org/packages/deepin.com.qq.office/#comment-678293-content)  
[运行不出界面 · Issue #2 · bestwu/docker-qq](https://github.com/bestwu/docker-qq/issues/2)  

## 准备工作

### 确保系统运行的是X11服务
``` sh
$ echo $XDG_SESSION_TYPE
x11
```

### 允许所有用户访问X11服务
运行命令:

```bash
$ xhost +
```

#### 添加后还是看不到界面？
参考这个issue的解决方案： [xhost +x 了，但是没有界面 · Issue #8 · bestwu/docker-qq](https://github.com/bestwu/docker-qq/issues/8)  
或 20200421 复制的内容： 
> 试试禁用“MIT-SHM”共享X进程内存的功能
> 
> 具体操作：
> 
> vi /etc/X11/xorg.conf
> 
> 增加：
> 
> Section "Extensions"  
> &nbsp;&nbsp;Option "MIT-SHM" "Disable"  
> EndSection

### 查看系统audio gid

```bash
$ getent group audio | cut -d ":" -f3
```

Archlinux 结果：

```bash
995
```

## 运行

### docker-compose

```yml
version: '2'
services:
  wechat:
    image: boringcat/wechat:work
    hostname: WXWork    # 可选，用于好看
    devices:
      - /dev/snd        # 声音设备
    volumes:
      - /tmp/.X11-unix:/tmp/.X11-unix
      - $HOME/WXWork:/WXWork
      - $HOME:/HostHome # 可选，用于发送文件
      - $HOME/wine-WXWork:/home/wechat/.deepinwine/Deepin-WXWork # 可选，建议，用于持久化 例如：更新企业微信
    ipc: host
    environment:
      DISPLAY: unix$DISPLAY
      QT_IM_MODULE: fcitx
      XMODIFIERS: "@im=fcitx"
      GTK_IM_MODULE: fcitx
      AUDIO_GID: 995 # 可选 默认995（Archlinux） 主机audio gid 解决声音设备访问权限问题
      GID: 1000 # 可选 默认1000 主机当前用户 gid 解决挂载目录访问权限问题
      UID: 1000 # 可选 默认1000 主机当前用户 uid 解决挂载目录访问权限问题
      DPI: 96 # 可选 默认96 
      WAIT_FOR_SLEEP: 5 # 可选 用于启动与退出时检测PID的间隔
```

或

```bash
    docker run -d --name wechat --device /dev/snd --ipc host \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v $HOME/WXWork:/WXWork \
    -v $HOME:/HostHome \
    -v $HOME/wine-WXWork:/home/wechat/.deepinwine/Deepin-WXWork \
    -e DISPLAY=unix$DISPLAY \
    -e XMODIFIERS=@im=fcitx \
    -e QT_IM_MODULE=fcitx \
    -e GTK_IM_MODULE=fcitx \
    -e AUDIO_GID=`getent group audio | cut -d: -f3` \
    -e GID=`id -g` \
    -e UID=`id -u` \
    -e DPI=96 \
    -e WAIT_FOR_SLEEP=1 \
    boringcat/wechat:work
```

## 配置解释
### hostname
![好看.jpg](images/2020-03-13%2009-30-49%20的屏幕截图.png)  
![好看2.jpg](images/2020-03-13%2009-30-43%20的屏幕截图.png)

### volumes: $HOME:/HostHome
![HostHome](images/2020-03-13&#32;09-40-12&#32;的屏幕截图.png)  
![Home](images/2020-03-13&#32;09-41-10&#32;的屏幕截图.png)
