# 学桥 ScholarBridge

Windows 本地中英双向翻译，面向微信交流，以及论文写作。优先使用本地 Hy-MT2 1.8B 模型，无需 API Key。

当前为 0.3.3 测试版，原创部分保留版权，见 [RIGHTS.md](RIGHTS.md)。公开查看源码不代表本项目已采用开源许可证。第三方组件适用各自许可。

## 安装与使用

接收者下载 Releases 中 `ScholarBridge-0.3.3-Desktop-Setup.exe` 和 `SHA256SUMS.txt`，核对后运行安装器。安装包内含模型、llama.cpp 和 Node.js。需要 Windows 10/11 x64、.NET Framework 4.8，建议 8 GB 内存、4 GB 可用磁盘。

详细步骤见 [安装与使用说明](release/安装与使用说明.md)。安装包包含桌面翻译和可选 Word 侧栏，**当前不含原生输入法**，原因与后续方案见 [发布说明](release/发布说明.md)。Word 使用当前用户开发清单及本机 HTTPS，不是 AppSource 商店安装。

- 工作台切换中译英／英译中，选择五种学科模式。
- 微信复制英文后，默认 Ctrl+Alt+R 呼出阅读浮窗；发送英文可从工作台翻译后复制粘贴。
- Word 单段普通正文选区翻译、预览、确认替换或插入；不支持整篇论文或复杂对象批量翻译。
- 学科、论文范围与方向可配置的术语；快捷键冲突提示；暖白与浅灰绿界面。
- 数字、单位、引用和锁定术语检查；这些保护不能证明语义准确，学术发表前仍需审校。

## 源码与构建

- `src/`：C# 桌面程序、共享翻译核心和合成测试。
- `word-web/`：Office.js 侧栏与本机 HTTPS 服务。
- `ime/`：原生输入法源码，当前不属于可分发安装器。
- `tools/`：本机模型下载、配置及验证脚本。
- `release/`：白名单打包脚本、安装器脚本、版权及使用说明。
- `docs/`：现有评测与验证范围。

构建 C#：Windows 自带 .NET Framework C# 编译器，执行 `powershell -ExecutionPolicy Bypass -File build.ps1`。确定性核心测试可执行 `dist/ScholarBridge.exe --self-test` 并读取 `artifacts/self-test.txt`。启动本地模型还需运行 `tools/download_local.py`（Python 3），该脚本会核对下载 SHA256。程序使用的模型与运行库不是源码仓库的一部分。

安装包重建见 [发布说明](release/发布说明.md)。原生输入法还依赖 `build-ime.ps1` 指定的 LLVM-MinGW、nlohmann/json 和 Rime 开发头文件；这些第三方构建依赖需单独准备，源码包不包含工具链或运行库。当前不提供输入法二进制的直接发布流程。

本仓库不包含个人配置、Rime 学习词库、本机证书、私钥、模型、运行库、测试截图或开发二进制。历史开发功能说明见 [DEVELOPMENT.md](DEVELOPMENT.md)，其中的本机安装路径与原生输入法状态不代表当前发行包功能。

### 本机输入法常用字词排序

同一拼音下按选用次数优先、同频最近优先；重启保留，空格和数字键等操作不变。原Rime学习数据保留，新精确计数从启用后积累。记录只在本机 data/rime/scholar_frequency.userdb，不能随源码或安装包分享。实现及范围见[常用字词排序说明](docs/常用字词排序说明.md)。隔离54项检查和本机空会话初始化通过。本功能属于原生输入法，仍不在当前桌面与Word安装包中。
## 免费与赞助配置

软件免费使用。0.3.3主窗口预留单个可关闭的静态赞助卡片，当前默认隐藏。没有广告SDK、联网投放、展示或点击统计；不使用输入内容做广告定向，断网不影响翻译，点击链接必须确认。详见 release/安装与使用说明.md。

发布者仅在审核真实赞助商、文案和网站后修改 release/sponsor.json 并重新打包。字段：Enabled=true；Sponsor为1–32字；Message为1–100字；Url为默认443端口HTTPS域名，无账户、查询参数和片段，不得包含用户数据；StartsUtc与EndsUtc使用 yyyy-MM-ddTHH:mm:ssZ 格式（UTC）。空配置、损坏配置和启动时不在有效期内的配置不显示。关闭后本次运行不再显示。原生输入法分发授权及安装器商用条款仍需另行处理。
