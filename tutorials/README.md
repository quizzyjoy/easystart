# 教程集

本目录收录 EasyStart 模板仓的**专题实战教程**。每篇教程对应一次真实开发过程：结论来自本仓代码与真机取证，踩坑都有可复现的现象与证据。

## 现有教程

| 教程 | 内容 | 规模 |
|---|---|---|
| [换肤实战教程](theme-skinning/换肤实战教程.md) | HarmonyOS 应用的四层颜色模型：静态令牌 / AttributeModifier / 运行时主题 / 系统组件默认色；13 章正文 + 9 个真机实测坑位 + 16 张截图 | 约 3400 行 |

## 组织约定

新增教程时按下面的结构落盘，保持各篇风格一致：

```
tutorials/
└── <topic>/                      # 专题目录，kebab-case
    ├── <标题>.md                  # 单篇教程正文（整合为一篇，不拆多文件）
    └── assets/                    # 该篇引用的截图，随仓入库
```

1. **一篇一个文件**：教程整合成单篇，两级目录放在正文开头，用显式锚点（`<a id="chNN"></a>`）保证跨平台跳转稳定。
2. **截图必须入库**：不要引用被 `.gitignore` 忽略的目录（如 `plan/`），否则 clone 后图全裂；统一放本篇 `assets/`，正文用相对路径 `assets/xxx.png`。
3. **每条结论带证据**：真机截图文件名，或可复现的命令。
4. **不臆造 API**：签名必须能在本仓源码或本机 SDK `d.ts` 中查到；查不到就标「需复核」，并列进文末清单。
5. **版本锚定**：教程开头写清对应 versionCode 区间，后续大改在该章末补「版本注记」。

## 相关文档

- [快速启动](../docs/快速启动.md) —— 环境、构建、`AppBootstrap` 装配链、fork 清单
- [鸿蒙工程目录设计指南](../docs/鸿蒙工程目录设计指南.md) —— 分层与目录、控件封装、设计令牌
- [UX 设计指导](../docs/UX设计指导.md) —— 设计理念与原生感验收标准
- [权威参考与开源项目盘点](../docs/权威参考与开源项目盘点.md) —— 官方文档与开源项目索引

## 开源仓库

- GitHub：<https://github.com/quizzyjoy/EasyStart>
- AtomGit：<https://atomgit.com/quizzyjoy/EasyStart>
- 镜像：GitCode <https://gitcode.com/quizzyjoy/easystart> · Gitee <https://gitee.com/quizzyjoy/easystart>
