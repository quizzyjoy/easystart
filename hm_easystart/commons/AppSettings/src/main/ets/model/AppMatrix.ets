/**
 * 「应用矩阵」数据（v3.61）：设置页展示的趣开发系列应用。
 *
 * 单一数据源：新增/下线应用只改本文件，视图不写死条目。
 * 图标素材取自各应用仓库的方角完整图，已缩到 512 放入本域 media。
 *
 * 每条带四组内容（弹窗分段的素材来源，v3.61）：
 * - `introLines`：**段 1 简介**（图文简介，配段 1 的产品官网按钮）；
 * - `introImage`：段 1 的产品截图；
 * - `qqGroupNumber` / `qqJoinUrl` / `qqHasQr`：**段 2 交流群**（空群号 = 无此段）；
 * - `featureLines`：**段 3 详情与特性**，内容取自产品官网各产品页的介绍卡片
 *   （https://quizzyjoy.com/products/<slug>），逐条对应官网上的模块标题与说明。
 *
 * 段数由数据决定：数易 / 临境声场三段（简介 · 交流群 · 详情），
 * 趣开发 / 随易工具箱两段（简介 · 详情）。
 *
 * 应用状态只决定"**打不开时**去哪"（真机已安装时一律先直接打开，见 AppsView.handleOpen）：
 * - SELF：本应用 → 打开产品官网；
 * - PUBLISHED：应用内详情页 → 应用市场 → 介绍弹窗；
 * - UNPUBLISHED：直接弹介绍弹窗。
 */
export enum AppEntryStatus {
  /** 当前应用本身。 */
  SELF = 'self',
  /** 已上架应用市场。 */
  PUBLISHED = 'published',
  /** 未上架（点击弹介绍弹窗）。 */
  UNPUBLISHED = 'unpublished'
}

/** 应用矩阵中的一条。 */
export interface AppMatrixEntry {
  /** 稳定 id（视图回调用）。 */
  id: string;
  /** 展示名（域三语资源键）。 */
  name: ResourceStr;
  /** 一句话说明（域三语资源键）。 */
  desc: ResourceStr;
  /** 包名 / 上架标识。 */
  bundleName: string;
  /** 方形图标（本域 media）。 */
  icon: Resource;
  /** 状态。 */
  status: AppEntryStatus;
  /** 状态标签文案（域三语资源键）。 */
  statusLabel: ResourceStr;
  /** 产品官网（段 1 的「打开产品官网」按钮；本应用被点击时也直接打开它）。 */
  siteUrl: string;
  /** 段 1 简介段落。 */
  introLines: string[];
  /** 段 1 的产品截图（本域 media）。 */
  introImage: Resource;
  /** 段 2：QQ 交流群号（空串 = 无交流群段）。 */
  qqGroupNumber: string;
  /** 段 2：一键加群短链（空串时按钮改为「复制群号」）。 */
  qqJoinUrl: string;
  /** 段 2：是否有群二维码（仅临境声场有对应素材）。 */
  qqHasQr: boolean;
  /** 段 3：详情与特性（取自官网产品页介绍卡片）。 */
  featureLines: string[];
  /**
   * AppGallery 内测邀请链接（空串 = 无内测入口）。
   *
   * 邀测链接必须在**浏览器**里打开并登录华为账号后点「参加」，应用内无法代替这一步，
   * 所以视图侧只做「打开浏览器」，失败才降级为复制链接（见 AppsView.joinInviteTest）。
   */
  inviteTestUrl: string;
}

/**
 * 应用矩阵数据源。
 *
 * 注意：EasyMath 的**工程内** bundleName 仍是模板残留（com.ydy.myapplication），
 * 其 README 声明的上架标识是 com.quizzyjoy.easymath，两者不一致——这里按上架
 * 标识填写（回退链会自然降级到"打开市场详情"，包名对不上时由市场提示）。
 */
export class AppMatrix {
  /** 本应用的产品官网（点本应用时打开）。 */
  static readonly SELF_SITE: string = 'https://quizzyjoy.com/products/easystart';

  private static readonly ENTRIES: AppMatrixEntry[] = [
    {
      id: 'easystart',
      name: $r('app.string.apps_easystart_name'),
      desc: $r('app.string.apps_easystart_desc'),
      bundleName: 'com.quizzyjoy.easystart',
      icon: $r('app.media.app_easystart'),
      status: AppEntryStatus.SELF,
      statusLabel: $r('app.string.apps_status_self'),
      siteUrl: 'https://quizzyjoy.com/products/easystart',
      introLines: [
        '鸿蒙多端应用工程蓝图：一次开发，多端部署。趣开发系列每一款产品，都从这套骨架生长而来。',
        '把多端适配、深浅色主题、字体缩放、断点布局、启动装配这些「每款应用都要、却不必每款重写」的能力，沉淀为一份可整体 fork 的工程骨架与架构宪法。',
        '能力在一条产品线上验证过，就能同步到全部产品；fork 后从第一行代码起，就自带完整的多端能力与工程纪律。'
      ],
      introImage: $r('app.media.app_easystart'),
      qqGroupNumber: '',
      qqJoinUrl: '',
      qqHasQr: false,
      inviteTestUrl: 'https://appgallery.huawei.com/link/invite-test-wap?taskId=bcac60cb4d546202fdaf9488186e9000&invitationCode=26ytUct6qgi',
      featureLines: [
        '四端一仓：product 下 entry（手机与平板折叠）、entry_pc（2in1）、entry_tv、entry_wearable 四个 HAP 入口，断点 xs/sm/md/lg 驱动响应式适配；手表入口纯原生原语控制体积。',
        '三大共享库：Foundation（日志、异常、Result、数值令牌，零依赖）· Platform（所有系统调用的唯一发生地）· VitalUI（通用组件、图表、取色器、动效与主题）。',
        'AppBootstrap 装配链：入口 Ability 只调四个静态方法，即完成主题、环境、存储、网络、断点、安全区、方向与用户偏好的初始化与冷启动恢复。',
        '49 色双套令牌：深浅色跟随系统，用户可用取色器自由换强调色，选中态全局联动，弥补原生控件不随运行时换肤的缺口。',
        '完备设置页：主题外观、通用设置、关于、隐私政策、用户协议、开源许可，两级信息架构开箱即用。',
        'MVVM 三分包示范：HomeFeature 演示视图、视图模型、数据三分包与路由注册表纪律，feature 之间零互相引用。',
        '工程纪律：三库只读（下游只消费不修改）· 应用级封装进 commons · 跨页跳转一律走路由注册表 · 任何依赖变更后必须全量四端构建通过才算完成。'
      ]
    },
    {
      id: 'easymath',
      name: $r('app.string.apps_easymath_name'),
      desc: $r('app.string.apps_easymath_desc'),
      bundleName: 'com.quizzyjoy.easymath',
      icon: $r('app.media.app_easymath'),
      status: AppEntryStatus.PUBLISHED,
      statusLabel: $r('app.string.apps_status_published'),
      siteUrl: 'https://quizzyjoy.com/products/easymath',
      introLines: [
        '把数学变成可以上手玩的东西：可交互函数图像 + 结构化教材，让抽象概念看得见、转得动。',
        '覆盖函数空间、参数动画、学习空间、数学之美、数学工具、闯关练习六大板块，手机 / 平板 / 2in1 同一套体验。',
        '已上架华为应用市场，中英双语，支持「问小艺」学习伙伴联动。'
      ],
      introImage: $r('app.media.intro_easymath'),
      qqGroupNumber: '823435665',
      qqJoinUrl: 'https://qun.qq.com/universal-share/share?ac=1&authKey=34vRPe2I1zFqlwqWzcobb6qLeIuYEdlCLHZs10CVk66yddzuwBuS0W8%2BpcrRHuNu&busi_data=eyJncm91cENvZGUiOiI4MjM0MzU2NjUiLCJ0b2tlbiI6InQ5VGxGRkhlSzFDTUNCOS90VitFVUJwcW9KVXloYzhTMXJ1ZExUMU1IYVIwdzBHL2JkVERjOG1pNURuWFdFZmIiLCJ1aW4iOiIzMDE0NTUxMzI5In0%3D&data=mtaiah60J05b9jEsEOUCRkzbJC77f-z45bFZQNPBU2R4eo932VzKUGYCZvVLoT4eLU-LRMwMmyNebg4YObTfFA&svctype=4&tempid=h5_group_info',
      qqHasQr: false,
      // 已正式上架，无需内测入口
      inviteTestUrl: '',
      featureLines: [
        '函数空间：2D 多曲线叠加、缩放平移，公式输入 / 表格粘贴 / 手动打点 / 随机样本四种数据来源，线性、多项式、高斯拟合，网格、散点、置信区间、残差图层独立开关；3D 曲面随手势旋转缩放，附等高线视图。',
        '参数动画：输入含参表达式 y = a·sin(bx + c)，勾选参数即出现滑块面板，图像随参数平滑变化——函数族不再靠背，一遍动画建立直觉。',
        '学习空间：书架到目录两级浏览，五科教材到齐（概率论与数理统计 111 节、初识数学 84 节等），定义、定理、例题统一卡片家族，例题可展开收起，全部内容经双重复核校验。',
        '数学之美：傅里叶级数一步步逼近方波，分形结构无限展开，李萨如图形随频率比旋转，全部实时渲染。',
        '数学工具：科学计算器、矩阵与行列式运算、解方程、求导数、公式手册、公式格式转换、单位换算，课后验算一站完成。',
        '闯关练习：关卡制答题与三星结算，函数专题题目配合函数空间即查即验，刷题不脱离图像。',
        '问小艺 · 学习伙伴（试验性）：教程每一节都有一张「问小艺」卡片，一键唤起小艺智能体「数易」直接提问；智能体不可用时问题自动复制到剪贴板。',
        '多端与无障碍：平板与 2in1 分栏自适应、屏幕自动旋转，函数空间支持鼠标滚轮缩放，全局字号五档即时生效，中英双语与深浅色主题。'
      ]
    },
    {
      id: 'vibestereo',
      name: $r('app.string.apps_vibestereo_name'),
      desc: $r('app.string.apps_vibestereo_desc'),
      bundleName: 'com.quizzyjoy.vibestereo',
      icon: $r('app.media.app_vibestereo'),
      status: AppEntryStatus.UNPUBLISHED,
      statusLabel: $r('app.string.apps_status_unpublished'),
      siteUrl: 'https://quizzyjoy.com/products/easymusic',
      introLines: [
        '让音乐被看见：克拉德尼波场、粒子海浪、核反应堆三大主视觉，把声音的频率与能量实时画进画面。',
        'HarmonyOS 原生 + 自研 FFT 引擎，本地曲库播放与频谱可视化一体化，横屏沉浸与多端断点适配。',
        '当前为邀测阶段（v1.0.0.003），可先通过产品官网了解进展并获取邀测入口。'
      ],
      introImage: $r('app.media.intro_vibestereo'),
      qqGroupNumber: '650941843',
      qqJoinUrl: 'https://qun.qq.com/universal-share/share?ac=1&authKey=yUqxmTK4inoxzae56voDLI0YhrO8dVe5r6t3Lw3lMfu0G2xP47Rm2Z%2FkMyFwCeWh&busi_data=eyJncm91cENvZGUiOiI2NTA5NDE4NDMiLCJ0b2tlbiI6IjNPRUpaaHg1a2VESm56RmxDWGtEUHRQN3ZER1RxdFk0M3J3Zy9LK1dZc3BGOENIeHBKMjZmNmZpUExiUDBGaloiLCJ1aW4iOiIzMDE0NTUxMzI5In0%3D&data=f8IANPw1YSaA_0JCky5IiRBudvwkFcq5YCGMk1FofnRuyDO0CckE5tLa3cYhiVLJx44ks2gq8SbyHVtRKRmJjQ&svctype=4&tempid=h5_group_info',
      qqHasQr: true,
      inviteTestUrl: 'https://appgallery.huawei.com/link/invite-test-wap?taskId=1101c3ea46f5a39d28e3006c914ec67f&invitationCode=84w2KO3o2IR',
      featureLines: [
        '克拉德尼波场：声学经典实验的数字化重现——薄板上的沙粒随频率在共振图案间流动重组，每一个频段都有自己的几何指纹。',
        '粒子海浪：数万粒子组成的能量场，随节拍涨落、随频段分层，预算分档保证长时间播放依旧满帧。',
        '核反应堆：环形堆芯中的链式脉冲，低音触发轰击，高频点亮外围，声音的能量层级一眼可读。',
        '频谱管线：基于 kiss_fft 的跨端共享频谱引擎，经 NAPI 接口契约接入 ArkUI 渲染层，逐帧驱动主视觉。',
        '频谱后处理：平滑、归一化与分频映射，让画面跟随音乐而非噪声抖动。',
        '性能分档：粒子预算与光效层级按设备能力分档，中端机型也能稳定流畅。',
        '视效定制：视效模式内自由切换主视觉、调整色彩与光晕，播放界面即所见即所得。',
        '三线并行：HarmonyOS 主线（API 23 基线、target 26，深浅色双主题与多端断点）· OpenHarmony 移植线（API 14 与 KaihongOS）· Android 线（与鸿蒙线共享同一套频谱引擎）。'
      ]
    },
    {
      id: 'easytools',
      name: $r('app.string.apps_easytools_name'),
      desc: $r('app.string.apps_easytools_desc'),
      bundleName: 'com.quizzyjoy.easytools',
      icon: $r('app.media.app_easytools'),
      status: AppEntryStatus.UNPUBLISHED,
      statusLabel: $r('app.string.apps_status_unpublished'),
      siteUrl: 'https://quizzyjoy.com/products/easytools',
      introLines: [
        '从《随易》进化的效率工具箱：随机决策与实用小工具的集合，首页搜索直达，即点即用。',
        '不注册、不联网，四大工具域共 57 项规划，随手一个决定都能更快落地。',
        '当前处于开发中，可先通过产品官网了解功能清单与上线进度。'
      ],
      introImage: $r('app.media.intro_easytools'),
      qqGroupNumber: '',
      qqJoinUrl: '',
      qqHasQr: false,
      inviteTestUrl: 'https://appgallery.huawei.com/link/invite-test-wap?taskId=f543287125d84579f04a3e3d85b8236d&invitationCode=3FHSl1fSvwk',
      featureLines: [
        '随机决策 9 项（首波迁移）：抛硬币、掷骰子、随机数、吃什么、颜色搭配、随机旅行、ABCD 选择器、随机名字、每日一句，从日常小纠结到课堂抽查一把抓。',
        '计算转换 13 项规划：进制转换、密码生成、文字计数，以及计算、编码、文本方向的扩展工具，覆盖学习与工作中的高频换算。',
        '生活工具 12 项规划：节拍器、计分器等生活场景小工具，规则简单、打开即用，不注册、不联网。',
        '传感工具 9 项规划：手电筒（含 SOS）、摩斯密码（编码与震动播放）、二维码生成与识别——扫码走系统安全引擎，生成走系统组件，零三方依赖。',
        '血统与分工：随易工具箱是已上架应用《随易》的工具侧续作。2026 年 10 月《随易》能力一分为二——工具能力由本应用接棒，趣味玩法与卡片、手表端由「派对时间」继承，两款产品独立演进。',
        '工程进度：骨架已对齐多端蓝图 v3.10（13 模块、四端入口），随机算法 / 手电筒 / 扫码 / 剪贴板等平台封装完成，正按四个业务域分波迁移工具，每波全量构建通过再进下一波。'
      ]
    }
  ];

  /** 全部条目（顺序即展示顺序）。 */
  static all(): AppMatrixEntry[] {
    return AppMatrix.ENTRIES;
  }

  /** 按 id 取一条（找不到返回第一条，避免调用方判空分支过多）。 */
  static byId(id: string): AppMatrixEntry {
    for (const entry of AppMatrix.ENTRIES) {
      if (entry.id === id) {
        return entry;
      }
    }
    return AppMatrix.ENTRIES[0];
  }
}
