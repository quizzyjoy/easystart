# 趣开发 EasyStart · HarmonyOS 多端工程蓝图模板

> **一次开发，多端部署** —— 手机 / 平板·折叠 / 2in1 / TV / 手表，一套工程四个入口。
> API 23 基线 · 状态管理 V2 · HarmonyOS Design（HDS）原生组件 · ArkTS。
>
> 仓库 **EasyStart**（多模板线），本模板线目录 **hm_easystart**；产品名 **趣开发 EasyStart**（原 `hm_blueprint`，2026-10-14 正式定名）；当前版本 **v3.33（versionCode 1000021）**。

趣开发 EasyStart 不是示例合集，而是一套可直接 **fork** 的 HarmonyOS 应用**工程骨架 + 架构宪法**：自带分层边界、设计令牌体系、启动装配链、完备设置页与运行时换肤能力，并在手机 / 折叠 / 2in1 / TV / 手表五种形态上验证过「一次开发、多端部署」。

本仓是蓝图模板的**权威上游**；`quizzyjoy/` 三库为跨 app 组织级资产，下游 fork 应用只消费、无权修改。

---

## 特性一览

- **四端一仓**：`product/` 下 `entry`（手机 / 平板）、`entry_pc`（2in1）、`entry_tv`、`entry_wearable` 四个 HAP 入口，断点（xs/sm/md/lg）驱动响应式适配；手表入口纯原生原语、不依赖重组件以压体积。
- **跨 app 三库分层**（`quizzyjoy/`，`@quizzyjoy/*`）：
  - `Foundation` —— 日志 / 异常原语 / Result / 工具 / 数值设计令牌，**零依赖**；
  - `Platform` —— **所有 `@ohos` / `@kit` 系统调用的唯一发生地**（断点 / 主题 / 权限 / 网络 / 存储 / 国际化 / 窗口 / 方向 / 屏幕 / 震动 / 分享 / 市场 …）；
  - `VitalUI` —— 通用组件、图表、取色器、动效与主题（仅依赖 Foundation）。
- **应用级公共层**（`commons/`，`@easystart/*`）：`AppCommon`（启动装配，仅编排）、`AppPreferences`（偏好持久化契约，零依赖）、`AppRoutes`（路由名注册表）、`AppSettings`（完备设置页）、`AppComponent`（应用组件 + 主题化控件工厂）。
- **AppBootstrap 装配链**：入口 Ability 只调四个静态方法（`prepare / attachWindow / detachWindow / destroy`）即完成主题、环境、存储、网络、断点、安全区、方向、屏幕与用户偏好（含强调色）的初始化与冷启动恢复。
- **设计令牌 + 双主题机制**：深浅色跟随系统（49 色 base/dark 双份资源）＋ 用户自由强调色（`UiThemeManager` 接受任意 `#RRGGBB`，取色器选色、收藏、持久化）。
- **主题化控件工厂**：`AppToggle / AppSlider / AppProgress / AppCheckbox / AppRadio / AppSegment` 等选中态统一绑定强调色，自由页面换肤全局生效（弥补 ArkUI 原生控件选中色不随运行时换肤的缺口）。
- **完备设置页模板**：设置是**独立子页**而非 Tab，titleBar 齿轮常显进入；两级信息架构——「主题外观」「通用设置」两个二级子页 ＋ 关于 / 隐私政策 / 用户协议 / 开源许可；内置显示模式、语言、触感反馈、屏幕常亮、屏幕方向、清除缓存、应用市场跳转等范式。
- **HDS 原生感**：以 `@kit.UIDesignKit` 官方 HDS 组件（HdsNavigation / HdsTabs / HdsListItemCard …）为表现范式，HDS 不适用处走「例外登记制」。
- **MVVM feature 示范 + 基建演示画廊**：`HomeFeature` 是三分包示范，`DemoFeature` 聚合组件画廊 / 设备能力面板 / 场景范式，fork 后替换或整删。

## 目录结构（本目录即工程根；仓级文档见 `../docs/`）

```
.
├── AppScope/            # 应用级配置 + 颜色设计令牌（base/dark 双份）
├── quizzyjoy/           # ★ 跨 app 共享三库（@quizzyjoy/*，组织级资产；下游 fork 只读）
│   ├── Foundation/      #   日志 / 异常 / Result / 工具 / 数值令牌   （零依赖）
│   ├── Platform/        #   所有系统 @ohos/@kit 调用唯一发生地
│   └── VitalUI/         #   通用组件 / 图表 / 取色器 / 动效 / 主题
├── commons/             # 应用级公共层（HAR，@easystart/*，fork 时整体换作用域）
│   ├── AppCommon/       #   AppBootstrap 启动装配（仅编排）
│   ├── AppPreferences/  #   偏好持久化契约：偏好键 / 字号系数 / 强调色校验（零依赖）
│   ├── AppRoutes/       #   AppRoute 路由名注册表（零依赖）
│   ├── AppSettings/     #   设置域：主页 + 外观/通用两子页 + 关于三子页
│   └── AppComponent/    #   SnackBar/Dialog/Sheet + modifier + control/ 控件工厂
├── features/
│   ├── HomeFeature/     #   MVVM 三分包示范（fork 后替换为真实 feature）
│   └── DemoFeature/     #   基建演示聚合（fork 后整删）
├── product/             # 入口层（HAP × 4，按设备形态拆分）
│   ├── entry/           #   手机 / 平板 / 折叠
│   ├── entry_pc/        #   2in1
│   ├── entry_tv/        #   TV
│   └── entry_wearable/  #   手表（纯原生单页）
├── VersionFile.json5    # 三方依赖版本单一事实源
└── build-profile.json5
```

依赖方向严格单向：`product/* → features/* | AppCommon → Platform → Foundation`；`VitalUI` 仅依赖 Foundation。

## 分层与「三库修改权」（务必先读）

- **在下游 fork 应用里，`quizzyjoy/` 三库只读**：不新增文件、不改既有文件、不在其 `Index.ets` 加导出；缺陷与增强需求回本上游仓按模板轮次演进。
- 应用自有的通用封装放 `commons/`（应用级 `@<应用名>/*`），不要就地改三库。落位判据与四档分流（域内 `util/` → 应用级 common → 提上游）见 **[`docs/鸿蒙工程目录设计指南.md`](../docs/鸿蒙工程目录设计指南.md) §12.3 与 §17**。
- feature 之间禁止互相引用；跨页跳转一律走 `RouterManager.push(AppRoute.X)`，不裸用 `pushPath`。

## 环境要求

- [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/)（本机为 26 版）与 HarmonyOS SDK，**API 23 基线**（真机 API 26 兼容）。
- `ohpm` 包管理器；命令行构建用 DevEco 自带 `devecocli`。
- 三方库版本统一在根 `VersionFile.json5`，各 `oh-package.json5` 以 `@param:` 注入。

## 快速开始

```bash
# 1) 安装依赖（ohpm 不在 PATH 时用 DevEco 内置绝对路径）
ohpm install

# 2) 命令行一次构建四端（多 entry 必须显式列出模块，产出 4 个签名 HAP）
devecocli build --modules entry entry_pc entry_tv entry_wearable
```

或在 DevEco Studio 中：

1. **打开**：File → Open 选择本工程目录 `hm_easystart/`（`build-profile.json5` 所在处），等待 Sync。
2. **签名（必做）**：仓内 `signingConfigs` 指向模板作者本机的 debug 材料，**新环境必然失效**。进入 File → Project Structure → Signing Configs，勾选 **Automatically generate signature** 自动生成；或手动替换证书 / Profile / keystore 三路径与密码。
3. **运行**：选择目标设备（四端模拟器或真机）与对应 entry（`entry` / `entry_pc` / `entry_tv` / `entry_wearable`），点 Run。

命令行安装 / 运行到指定设备、release 混淆构建等见 [`docs/快速启动.md`](../docs/快速启动.md) §2。

## fork 为新应用

完整逐项清单（10 步）见 [`docs/快速启动.md`](../docs/快速启动.md) §10，关键动作：

1. 改 `AppScope/app.json5` 的 `bundleName` / `vendor` / `versionName` 与图标；改三语 `app_name`。
2. **重新配置签名**（同上）。
3. **换肤只改一处**：`AppScope/resources/{base,dark}/element/color.json` 的主题三件套 `qj_brand / qj_brand_light / qj_on_brand`，其余 46 色通用契约不动。
4. **包作用域整体替换（方向勿反）**：`@easystart/*` → `@<新应用>/*`（各 `oh-package.json5` 的 name、依赖方、全部 import）；**`@quizzyjoy/*` 三库原样保留、禁止改名或改内容**。
5. 删除 `features/DemoFeature`、把 `HomeFeature` 替换为真实业务 feature；保留 `AppSettings / AppRoutes / AppComponent / AppCommon` 作为应用级公共起点。
6. 四端构建 SUCCESS + 模拟器 / 真机冒烟。

## 文档

完整索引见 **[`docs/README.md`](../docs/README.md)**，核心几份：

| 文档 | 内容 |
|---|---|
| [docs/快速启动.md](../docs/快速启动.md) | 结构 / 构建运行 / 能力速查 / **fork 清单** |
| [docs/鸿蒙工程目录设计指南.md](../docs/鸿蒙工程目录设计指南.md) | **架构宪法**：分层、三库修改权、令牌、能力、HDS 例外、版本验证史 |
| [docs/UX设计指导.md](../docs/UX设计指导.md) | 设计理念与 HarmonyOS 原生感体验验收清单 |
| [docs/git_constraints.md](../docs/git_constraints.md) | 版本号与提交约束 |
| [docs/TODO.md](../docs/TODO.md) | 模板演进台账（每条 TODO 的设计与实施结果） |
| [docs/design-guide.html](../docs/design-guide.html) | 指南的可视化 HTML 快照（含四端设备形态图，以 Markdown 为准） |

## 当前状态说明

- 本仓于 **2026-10-09** 由 PartyNow 单仓中的 `hm_blueprint/` 经 `git filter-repo` 剥离独立，**保留了模板完整演进史**；origin 已配置为局域网 Gitea 私仓 `app_EasyStart.git`（Win / Mac 双端协作），**公网开源暂缓**（计划与清理清单见 [docs/TODO.md](../docs/TODO.md) TODO-002；推公网前须过 [docs/git_constraints.md](../docs/git_constraints.md) §12 硬门槛）。
- **品牌正名（2026-10-14，v3.25）**：产品名 **趣开发 EasyStart**（原 `hm_blueprint`）——`bundleName` = `com.quizzyjoy.easystart`、`vendor` = `quizzyjoy`、三语 `app_name` = 趣开发 / EasyStart、应用级作用域 `@easystart/*`（组织级 `@quizzyjoy/*` 保留）。克隆 / fork 后仍请按 fork 清单改为你自己的标识。
- 根 `build-profile.json5` 的签名块是模板作者**本机 debug 占位**，克隆后必须重配（见快速开始）。
- 版本演进见《指南》§0 与 [docs/TODO.md](../docs/TODO.md)；当前 **v3.33 / 1000021**。
