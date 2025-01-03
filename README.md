<h1 align="center">JellyFin HarmonyOS</h1>
<h3 align="center">Part of the <a href="https://jellyfin.org">Jellyfin Project</a></h3>

---

<p align="center">
<img alt="Logo Banner" src="https://raw.githubusercontent.com/jellyfin/jellyfin-ux/master/branding/SVG/banner-logo-solid.svg?sanitize=true"/>
<br/>
<br/>
<a href="https://github.com/chashaochang/JellyFin_HarmonyOS">
<img alt="GPL 2.0 License" src="https://img.shields.io/github/license/jellyfin/jellyfin-android.svg"/>
</a>

Jellyfin_HarmonyOS 是一款 HarmonyOS 应用，可连接到 Jellyfin 实例并与官方 Web 客户端集成。具体功能实现参考了安卓端开源代码

## 简单说两句
写这个东西是出于学习的目的,为了提高自己的鸿蒙开发能力,为了小众圈子能用上鸿蒙版的软件,也为了促进鸿蒙生态发展出一份力.

PS:闲暇时间写的,禁止催更!

## 进度
由于本人对项目也不是完全了解,具体都有什么功能也说不准

### 已完成

- 连接到服务器
- 切换服务器
- 发现本地设备
- 简单的播放
- 记录播放进度
- 支持ass/srt字幕

### 未完成/规划中
完善播放器基本功能(目前主要任务)

- 播放器控制UI界面(做成国内爱优腾风格,复合国人使用习惯)
- 倍速
- 切换音轨
- 切换字幕
- 切换清晰度
- 上一集/下一集(可能延到下一期做)

🧬 效果图
------------

|                            连接到服务器                            |                              现有服务器                              |
|:------------------------------------------------------------:|:---------------------------------------------------------------:|
| <img src="screenshots/connect.jpg" width="200" alt="连接到服务器"> | <img src="screenshots/findserver.jpg" width="200" alt="现有服务器"> |

## 代码相关

- 服务器相关操作,把Jellyfin的<a href="https://github.com/jellyfin/jellyfin-sdk-typescript">TypeScript SDK</a>进行鸿蒙化后使用
- 播放器经过尝试后采用<a href="https://ohpm.openharmony.cn/#/cn/detail/@ohos%2Fijkplayer">ijkPlayer</a>
- 播放控制页基于开源库<a href="https://gitee.com/openharmony-tpc/openharmony_tpc_samples/tree/master/GSYVideoPlayer">GSYVideoPlayer</a>修改

感谢开源大佬们的无私奉献!