# 本地运行环境来源

学桥原创代码位于 `src/`。本目录下载的第三方程序与模型分别遵守自身许可证；后续分发安装包时应一并包含相应许可证。

## llama.cpp

- 官方项目：https://github.com/ggml-org/llama.cpp
- 下载版本：b11617，Windows CPU x64。
- 下载文件：llama-b11617-bin-win-cpu-x64.zip。
- SHA-256：1bad07f7993889a1f7431ad647904294f56919bf0bc84f4021327db1641a411c。
- 许可证：MIT；发行包中的依赖许可应保留。

## 腾讯 Hy-MT2

- 官方模型：https://huggingface.co/tencent/Hy-MT2-1.8B-GGUF
- 固定仓库修订：a0c709d9fac510f2c807aa3af52872340dc37a4a。
- 文件：Hy-MT2-1.8B-Q4_K_M.gguf，1,133,080,448 字节。
- SHA-256：dc5f44fcf1fa496ee7ad725982c0c8c553a4de00259b53af84c4b89fb0c06699。
- 模型页面标注许可证：Apache-2.0。正式重新分发前应随模型附带官方许可文件及必要声明。

Windows／Microsoft Office 是用户环境提供的运行依赖，不随本项目分发。

## 新输入法依赖

- librime 1.17.0：https://github.com/rime/librime ，BSD-3-Clause。Windows x64 MSVC 发行包 SHA-256：7478c7caa4ff6b37de86daba1f7ce4a994a4f5ba24872a820fb2b3a9b01fed15。仅 x64 Rime 主机加载该 DLL；x86 TIP 通过本机管道访问它。
- rime-pinyin-simp：https://github.com/rime/rime-pinyin-simp ，修订 0c6861ef7420ee780270ca6d993d18d4101049d0，许可见 runtime/ime/rime-pinyin-simp-LICENSE。
- rime-prelude：https://github.com/rime/rime-prelude ，修订 082425ea0684bca36474415d4a0e8db9b016487e，许可见 runtime/ime/rime-prelude-LICENSE。
- nlohmann/json 3.12.0：https://github.com/nlohmann/json ，MIT。json.hpp SHA-256：aaf127c04cb31c406e5b04a63f1ae89369fccde6d8fa7cdda1ed4f32dfc5de63。源文件保留许可说明。
- LLVM-MinGW 20261006：https://github.com/mstorsjo/llvm-mingw ，仅用于构建；工具链及其运行库遵循随包许可证。项目中工具链目录不进入源码提交。压缩包 SHA-256：317492c456aa27ee607a5919f1d2d38dcdc1112516a24d0bf4b00d078f52d17a。

Word 侧栏通过微软官方 CDN 加载 Office.js，不将该 SDK 随本项目重新分发。Node.js 是用户环境提供的运行依赖。word/ 内实验性的 Office COM interop 不属于当前默认交付路径。

当前开始制作桌面与 Word 安装包，实际随包组件见 release/THIRD_PARTY_DESKTOP.md。原生输入法暂不包含在该安装包内。现用 Rime 构建的 version-info 还包含 librime-lua、librime-octagram、librime-predict；其中 octagram 固定修订 dfcc151 的许可证是 GPLv3，不能只按 librime 主库 BSD-3-Clause 描述整个组合。来源：https://github.com/lotem/librime-octagram/blob/dfcc151/LICENSE 。输入法二进制重新分发需先确定对应源码及授权方案，或构建不含该插件的引擎并重新验证。
