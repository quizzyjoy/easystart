# HarmonyOS UX 设计指导与趣开发 EasyStart 达标映射

> 来源：HarmonyOS 官方设计指导（MCP `harmonyos_developer_knowledge` 检索，2026-10-04）
> v3.5.1（2026-10-04）完成第一轮对照审计：逐条核对官方原文与 趣开发 EasyStart 代码事实，修正 3 处失实映射（窗口圆角/最小字号/系统材质来源）。
> v3.6（2026-10-04）审计组 2（设计令牌）：字阶对齐官方《文本排版》phone 阶（22/28/32 Apple 借位档归位为 24/30/38/48）；字重使用律改官方指派（Title=Bold、Display=Light、Caption=Medium）；卡片圆角 24→16 对齐官方《圆角参数》并恢复「层级正相关」。
> - 设计理念：《HarmonyOS应用生态概述》4.2 设计套件（One / Harmonious / Universe）
> - 体验标准：《通用应用UX体验标准》《大屏应用UX体验标准》《PC/智慧屏标准》
> - 最佳实践：《智感握姿》《沉浸光感》
> 本文档是 趣开发 EasyStart 的 UX 契约：fork 新项目时按 §3 清单逐项验收。

## 1. 设计理念（One Harmonious Universe）

**One · 万物归一，回归本源**
以人为本的设计，通过严谨的人因实验探究体验背后的人因，结论融入设计。系统表现符合人的本质需求：
- 各种大小的文字**清晰易读**，图标**精确而清晰**，色彩**舒适而协调**，动效**流畅而生动**
- 界面元素**层次清晰**，巧妙突出重要内容，传达**可交互**的感觉
- 系统表现是**直觉的**，用户无需思考；操作符合本能，用智能化技术主动适应用户习惯

**Harmonious · 一生为二，平衡共生**
在物理世界找到数字世界的映射——光影、材质等设计转化到界面中，带来高品质视觉享受；物理世界的体验记忆帮助用户快速理解界面元素并完成操作。（沉浸光感材质 = 此理念的直接落地）

**Universe · 三生万物，演化自如**
多设备体验在**一致性与差异性**中取得平衡：
- **一致性**：界面元素设计与交互方式尽量保持一致，减少学习成本
- **差异性**：不同设备在屏幕尺寸、交互方式、使用场景、用户人群上差异化设计

**四大基本要素**（高端精致设计体验）：**独特、简洁、品质、统一**。

## 2. 趣开发 EasyStart 已落地的设计能力

| 能力 | 落地位置 | 对应理念 |
|---|---|---|
| 沉浸光感材质 | 入口页 HdsNavigation.titleBar / HdsTabs.barFloatingStyle（`systemMaterialEffect` ADAPTIVE/IMMERSIVE + `barOverlap` + 渐变模糊 `ScrollEffectType.GRADIENT_BLUR`） | Harmonious（光影材质映射） |
| 智感握姿 | HdsTabs `barFloatingStyle({ adaptToHandedness: true })`，页签栏跟随交互手 | One（主动适应用户习惯） |
| 悬浮页签 | `barFloatingStyle` + `barBottomMargin = 窗口小白条避让高度` | Universe + 系统特性「界面布局适配底部导航条」 |
| 全场景自适应 | BreakpointManager（UIContext 断点）+ HdsTabs barPosition 随断点切换 + HdsNavigation Stack/Split 模式 | Universe（一致性与差异性平衡） |
| 深浅色 | AppScope base/dark 双份 color.json（49 设计令牌 + 20 图表色卡），系统栏字色联动 | 品质 |
| 层级/可交互传达 | AppZIndex 刻度 + 交互态 4 色令牌 + 阴影令牌 | One（层次清晰、传达可交互） |
| 响应式避让 | WindowAdapter（状态栏/小白条/挖孔三源取最大）+ enableComponentSafeArea | 系统特性适配 |
| 分层图标 | AppScope `layered_image.json` 前景+背景双图层 | 应用图标规范 |
| 设置两级 IA（v3.12 独立子页；v3.14 两级化；**v3.28 fork 完备轮**） | 设置不占主 Tab：titleBar 菜单槽齿轮（`sys.symbol.gearshape_fill`，所有 tab 常显，v3.12.1）→ HdsNavDestination 设置子页。**v3.28 起主页完备 IA**：应用头（图标 64vp 圆角 + 应用名 + 版本）→ 账号卡占位（person_crop_circle_fill + 「点击登录」→ 账号子页）→ 组·外观与通用（主题外观 paintbrush_fill 后缀实时显示模式／通用设置 slider_horizontal_2）→ 组·互动与反馈（公告 bell／版本日志 doc_text_badge_clock／帮助与反馈 envelope_badge_adiowaves／分享 share 系统面板／开发者团队 person_2）→ 组·关于（关于本应用／隐私政策／用户协议／第三方 SDK 清单 checkmark_circle／开源许可）→ 页脚（版权行「© 年份 应用名」格式资源 + 备案行留空即隐藏）。子页族：主题外观（显示模式 SuffixSelect／强调色）、通用设置（语言/字体/触感/常亮/屏幕方向/清缓存/**系统设置跳转行 gearshape**）、账号（登录表单+注销合规行占位）、公告/版本日志/帮助反馈/开发者（**rawfile JSON 数据驱动**，解析失败空态兜底）、法律三子页（privacy/terms/sdk）。行一律官方 **HdsListItemCard + PrefixIcon（sys.symbol.*）+ Suffix* 系列槽位**，`app_bg_card`+AppRadius.XL 卡片；目的地经 **SettingsDestination 统一装配**（12 路由标题+titleBar ADAPTIVE+避让，入口 pageMap 单分支）；titleBar 走域 `$r` 资源、内容放域 rawfile；TV 自绘 header 圆形齿轮，手表不接入。偏好经 SettingsViewModel 即写即存、AppBootstrap 冷启动恢复。**v3.30 schema 化**：组/行/控件由 rawfile/settings_schema.json 定义（fork 改 JSON 零代码，行型七类 × 组型两类），行图标 **chip 彩底贴片**（36vp 圆形 chart_c01~c20 色板底，PrefixCustomBuilder 官方槽，深浅双份令牌随动），深链 target 支持设置子页直达 | One（全局入口位置一致）+ Harmonious（HDS 卡片原生感）+ Universe（三端同构、手表按形态裁剪） |

## 3. UX 体验标准验收清单（fork 后逐项过）

### 3.1 通用标准（有量化指标的重点项）

| 标准 | 量化要求 | 趣开发 EasyStart 现状 |
|---|---|---|
| 点击热区 | **≥ 40vp×40vp** | ✅ `AppSize.TOUCH_MIN = 40`（v3.5 由 24 上调，零消费方无迁移）；STANDARD 48 / COMFORT 56 |
| 层级页面转场 | 手机/平板层级切换用**左右平移**转场 | ✅ HdsNavigation 默认转场 |
| 底部导航条适配 | 布局避开小白条 | ✅ barBottomMargin 动态取避让高度；WindowAdapter.bottomAvoidVp |
| 挖孔适配 | 布局适配摄像头挖孔 | ✅ WindowAdapter TYPE_CUTOUT 取最大 |
| 深色模式 | 深色下显示正常 | ✅ base/dark 双令牌 |
| 状态栏适配 | 状态栏随内容避让/联动 | ✅ 沉浸式避让 + 字色联动 |
| 多尺寸屏 | 不同屏幕尺寸良好显示 | ✅ 断点体系 + 一多装配 |
| 返回操作 | 全屏界面提供返回/关闭/取消 | ✅ HdsNavDestination titleBar 自带返回 |
| 全局设置入口 | 设置入口位置一致、热区达标、不占用主导航页签 | ✅ v3.12 起 titleBar 齿轮（所有 tab 常显，v3.12.1；≥40vp 热区；TV 为 AppSize.TOUCH_COMFORT 圆形按钮）；设置页为独立子页而非 Tab；v3.14 两级 IA（主页两入口行 + 外观/通用两子页 + 关于三子页）真机浅/深色、中英双语、横竖屏旋转与冷启动恢复回归通过 |
| 设置项交互范式 | 开关/单选/文本值/跳转各行型视觉与交互统一、即时反馈、重启项明确提示 | ✅ v3.13：SuffixSwitch（即时生效）/ SuffixSelect（当前项蓝高亮）/ SuffixTextAndArrow（版本号、缓存大小）/ 清缓存原生 AlertDialog + Toast；跟随系统语言等需重启项弹重启 Toast；v3.14 屏幕方向 SuffixSelect 三选（跟随/竖屏/横屏）即时旋转 + 冷启动恢复（仅 phone/tablet 呈现，2in1/TV 自有旋转语义）；⚠ 已知现象：HDS SuffixSelect 弹层在行靠近屏幕底部约 1/4 区域时不展开，滚到中部正常（疑 HDS 锚点避让，v3.14 方向行在 64% 处未复现，观察中） |
| 手势冲突 | 自定义手势不与系统手势冲突 | ⚠️ fork 后自查（模板无自定义手势） |
| 转场动效时长 / 启动页 | 满足官方时长要求 | ⚠️ fork 后用 DevEco Testing 验收 |
| 最小字号 / 对比度 / 图标最小尺寸 | 官方仅要求"满足最小字号/对比度/最小图标尺寸"，**未公开具体阈值**；官方字阶表 watch 端含 Caption_M=10 / Caption_S=8 → 穿戴入口 CAPTION_XS=10 **合规** | ✅ 令牌体系已对齐官方字阶（AppFontSize v3.6：10/12/14/16/18/20/24/30/38/48）；图标用 SymbolGlyph 矢量 |
| 界面图标清晰度 / 文字粗细 | 满足要求 | ✅ SymbolGlyph 矢量图标 + AppFontWeight 刻度 |

### 3.2 大屏（折叠屏 / 平板 / PC）标准

| 标准 | 量化要求 | 趣开发 EasyStart 现状 |
|---|---|---|
| 折叠屏各形态 | 展开/折叠/悬停显示正常 | ✅ HoverStore 折痕+折叠形态实采；⚠️ 悬停态 UX fork 后自查 |
| 弹出框高度（展开态） | 符合官方要求 | ⚠️ AppSheet/AppDialog fork 后按细则复核 |
| 应用左右边距 | 符合官方要求 | ✅ DesignToken.screenEdgePadding 断点分档 |
| 窗口圆角 | **16vp**（官方原文仅"窗口圆角要求16vp"，属大屏多窗/悬浮窗形态要求） | ⚠️ 与应用内弹窗圆角是两回事：对话框体系走 AppRadius.XXXL=24（官方 dialog level12），**不可**拿 AppRadius.XL=16 冒充达标；fork 后做多窗/悬浮窗适配时按 16vp 复核 |
| 鼠标 hover 反馈 | 可交互控件提供悬浮视觉反馈 | ✅ **v3.31 起真正接线**：卡片走 `hoverEffect(HoverEffect.Highlight)`，PC 入口根 `onHover → HoverStore.reportHover`（`HoverStore.isHover` 首次有真实来源）。此前「HoverStore + 令牌」只是备着、零消费方。范围仅 2in1 入口（其余端无鼠标语义）。**bp_2in1 模拟器已验证**（`uinput -M` 悬停卡片出现高亮浮起）；2in1 实机建议补一轮目视 |
| 键盘焦点导航 | 主任务流支持 Tab/方向键走焦 | ⚠️ fork 后自查 |
| 窗口响应式（PC） | 调节窗口内容保持 | ✅ PcIndex 断点逻辑保留（窗口拉窄回 sm/md） |

### 3.3 纯净与性能红线（上架检测项）

- 禁止全屏隐藏导航栏/状态栏；禁止延迟关闭界面
- 广告关闭按钮不得过小、广告标识尺寸合规
- 权限申请最小化、不提前批量申请；拒绝权限不得退出应用；图库/联系人/音频一律用 picker
- 后台不可见动效及时停止资源；退后台禁止使用传感器
- 运行稳定无闪退卡死；64 位 so（元服务禁止 so）
- 官方清单另含**元服务专属项**（侧滑返回无拦截/胶囊/底部导航栏/元服务图标），趣开发 EasyStart 为完整应用不适用；fork 出元服务时需补验

## 4. 高端精致能力索引（按需接入）

| 能力 | 版本 | 适用 |
|---|---|---|
| 响应式布局 | 5.0 | ✅ 已内建（断点 + 栅格 + 拉伸） |
| HDR Vivid | 5.0 | 图像/视频高动态范围呈现（媒体类应用） |
| 折叠屏悬停 | 5.0 | 悬停态分屏交互（拍摄/视频通话场景） |
| 动态照片 | 5.0 | 拍摄活照片 |
| 大图预览画中画 | 6.0 | 全景照片沉浸浏览+放大（无黑边；3 秒无操作消失） |
| 视频/图片超分辨率 | 6.0 | 低分辨率素材画质增强 |
| 互动卡片（3D Live） | 6.0 | 桌面 3D 互动卡片（多设备桌面） |
| 沉浸式系统材质 | 6.1 | ✅ 已内建（hdsMaterial ADAPTIVE/IMMERSIVE；反色/赋色/交互效果/阴影可再定制）。**来源注**：出自 HDS SDK `SystemMaterialParams`（@since 6.1.0(23)），非白皮书高端精致章节条目 |

## 5. 检测工具

- **HiSmartPerf Device**：FPS/CPU/GPU/RAM 实时监测（hap 悬浮窗 + daemon 命令行）
- **wukong**：稳定性压测（随机/专项/专注测试，控件注入+遍历截图）
- **DevEco Testing**：稳定性/性能功耗/回归/应用基础质量一键执行
