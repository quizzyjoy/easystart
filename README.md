# 趣开发 EasyStart

面向 HarmonyOS 开发者的**多端开发参考工具**：把「一多」布局、设计令牌、组件范式与设备能力做成可浏览、可对照、可在真机验证的示例。

一套可 fork 的 HarmonyOS 工程骨架，覆盖手机 / 折叠屏 / 平板 / 电脑 / 手表 / 智慧屏。

## 特性

- **一多布局**：断点驱动 + 响应式令牌，四端入口共享同一套业务代码
- **设计令牌**：字阶 / 圆角 / 间距 / 描边 / 阴影 / 触摸目标 / 色板全量可视化
- **组件范式**：反馈流、数据看板、表单、列表四态、搜索、折叠屏悬停分屏等场景示例
- **能力封装**：HDS 原生组件、折叠态与折痕感知、窗口适配、分享、剪贴板、设备能力检测

## 快速开始

### 环境

| 项 | 要求 |
|---|---|
| DevEco Studio | 6.1.0 及以上（或 26.x） |
| HarmonyOS SDK | 6.1.0(23) 起，推荐 26.0.0 |
| Node.js | 18+ |

### 导入与构建

1. 用 DevEco Studio 打开 `hm_easystart/` 目录
2. 首次构建前配置签名：`File → Project Structure → Signing Configs`，生成你自己的调试签名
3. 回到 `hm_easystart/build-profile.json5`，把 `products[0].signingConfig` 指向该签名（取消默认注释）
4. 选择目标模块（`entry` / `entry_pc` / `entry_tv` / `entry_wearable`）后 Build

命令行构建：

```bash
cd hm_easystart
./hvigorw assembleHap
```

> **签名说明**：本仓库**不提供任何签名材料**。`signingConfigs` 默认为空数组，未配签名时只能产出未签名包。

### 运行

```bash
hdc install entry-default-signed.hap
hdc shell aa start -a EntryAbility -b com.quizzyjoy.easystart
```

## 仓库结构

```
EasyStart/
├── hm_easystart/            # HarmonyOS 模板线（四端入口）
│   ├── quizzyjoy/           # 组织级三库：Foundation / Platform / VitalUI（下游只消费）
│   ├── commons/             # 应用级：AppBootstrap / AppRoutes / AppSettings / AppComponent …
│   ├── features/            # 业务域：HomeFeature / DemoFeature / WidgetCommon
│   └── product/             # 入口 HAP：entry / entry_pc / entry_tv / entry_wearable
├── docs/                    # 技术文档（快速启动 / 架构指南 / UX / 参考盘点）
├── 教程/                     # 教程集：每个专题一个目录（当前：主题）
└── plan/                    # 内部规划区（.gitignore 忽略，不随公开仓分发）
```

分层约定：`product → features → commons → quizzyjoy`，单向依赖；`quizzyjoy/` 作为组织级上游，下游应用只消费、不就地修改。

## 文档

- [快速启动](docs/快速启动.md) —— 环境要求、构建命令、`AppBootstrap` 装配链、fork 清单
- [鸿蒙工程目录设计指南](docs/鸿蒙工程目录设计指南.md) —— 分层与目录、能力封装、设计令牌、HDS 实践
- [UX 设计指导](docs/UX设计指导.md) —— 设计理念、原生感体验标准与验收清单
- [权威参考与开源项目盘点](docs/权威参考与开源项目盘点.md) —— 官方文档、示例仓、开源依赖索引
- **[主题 · 换肤实战教程](教程/主题/主题.md)** —— 四层颜色模型（静态令牌 / AttributeModifier / 运行时主题 / 系统组件默认色）+ 9 个真机实测坑位，13 章正文与 16 张截图
- [教程集目录](教程/README.md) —— 全部专题教程索引与新教程落盘约定

## License

[Apache License 2.0](LICENSE) © 2026 闫东阳
