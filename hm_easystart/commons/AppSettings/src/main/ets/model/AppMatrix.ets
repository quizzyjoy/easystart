/**
 * 「应用矩阵」数据（v3.60）：设置页展示的趣开发系列应用。
 *
 * 单一数据源：新增/下线应用只改本文件，视图不写死条目。
 * 图标素材取自各应用仓库的方角完整图，已缩到 512 放入本域 media：
 * - 趣开发 EasyStart    ← AppScope/media/app_logo（back + fore 合成）
 * - 随易数学 EasyMath   ← EasyMath/Resource/app_icon/app_icon_agc.png（AGC 上架图）
 * - 临境声场 VibeStereo ← EasyMusic 母版 icon 的 default
 * - 随易工具箱 EasyTools ← AppIcon_EasyTools_default
 *
 * 每条还带三样东西（v3.60 新增）：
 * - `siteUrl`：产品官网，本应用点击直接打开它；其它应用在介绍弹窗里也提供入口；
 * - `introLines`：介绍弹窗的分段正文（真实介绍，非占位）；
 * - `introImage`：介绍弹窗里的产品截图（来自各自仓库的市场素材）。
 *
 * 应用状态决定"**打不开时**去哪"（真机已安装时一律先直接打开，见 AppsView.handleOpen）：
 * - SELF：本应用 → 打开产品官网；
 * - PUBLISHED：应用内详情页 → 应用市场 → 介绍弹窗；
 * - UNPUBLISHED：直接弹介绍弹窗（含官网入口）。
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
  /** 产品官网（本应用被点击时直接打开它；其它应用在介绍弹窗里提供入口）。 */
  siteUrl: string;
  /** 介绍弹窗的正文段落（真实介绍，按段展示）。 */
  introLines: string[];
  /** 介绍弹窗里的产品截图（本域 media）。 */
  introImage: Resource;
  /** QQ 交流群号（空串 = 不展示群区块；数易 / 临境声场有）。 */
  qqGroupNumber: string;
  /** 一键加群链接（qm.qq.com 短链）。 */
  qqJoinUrl: string;
  /** 是否有可展示的群二维码（仅临境声场有对应素材；没有时不渲染图，避免标题不匹配）。 */
  qqHasQr: boolean;
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
        'HarmonyOS「一次开发、四端部署」模板：手机 / 折叠屏、2in1、平板 TV、手表四入口共用一个工程。',
        '示例 Tab 展示组件与场景，学习 Tab 内置开发教程（ArkTS、主题、依赖、文档同步），开发工具 Tab 提供图标合成、Symbol 能力等实用工具。',
        '分层为 quizzyjoy 三库（Foundation / Platform / VitalUI）→ commons 应用域 → features 业务域 → product 四端装配。'
      ],
      introImage: $r('app.media.app_easystart'),
      qqGroupNumber: '',
      qqJoinUrl: '',
      qqHasQr: false
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
        '数易 · 数学看得见：面向学生与自学者的数学工具与学习应用。',
        '覆盖求导、积分、矩阵运算、公式手册与函数图像拟合，结果附带求解步骤；二元空间曲面可视化让抽象概念可看可转。',
        '内置题库与每日一题，做题进度与积分体系联动；服务卡片可在桌面直接查看闯关进度。'
      ],
      introImage: $r('app.media.intro_easymath'),
      qqGroupNumber: '650941843',
      qqJoinUrl: 'https://qm.qq.com/q/cvI2ZxU81O',
      qqHasQr: false
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
        '临境声场 · 让声音被看见：本地音乐播放器与音频可视化应用。',
        '读取本地曲库播放，实时频谱与项目 M（projectM）风格的可视化预设，随节拍起伏；支持横屏沉浸与多端适配。',
        '当前处于内测阶段，尚未在应用市场正式上架；可先通过产品官网了解进展并获取内测入口。'
      ],
      introImage: $r('app.media.intro_vibestereo'),
      qqGroupNumber: '650941843',
      qqJoinUrl: 'https://qm.qq.com/q/cvI2ZxU81O',
      qqHasQr: true
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
        '随易工具箱：把开发者日常零碎需求收进一个应用，随取随用。',
        '覆盖哈希与摘要、编码解码（Base64 / URL / Hex）、ID 生成（UUID / 雪花）、正则测试与 JSON 格式化等常用工具。',
        '首页按「推荐 / 我的收藏」组织，常用工具可收藏置顶；当前尚未正式上架，可先通过产品官网了解功能清单。'
      ],
      introImage: $r('app.media.intro_easytools'),
      qqGroupNumber: '',
      qqJoinUrl: '',
      qqHasQr: false
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
