/**
 * 「应用矩阵」数据（v3.50）：设置页展示的趣开发系列应用。
 *
 * 单一数据源：新增/下线应用只改本文件，视图不写死条目。
 * 图标素材取自各应用仓库的 `default`（方形完整图），已缩到 512 放入本域 media：
 * - 趣开发 EasyStart    ← AppIcon_EasyStart_default
 * - 随易数学 EasyMath   ← EasyMath/Resource/app_icon/app_icon_default.png
 * - 临境声场 VibeStereo ← EasyMusic/Market/02_母版/icon/appicon_vibestereo_default.png
 * - 随易工具箱 EasyTools ← AppIcon_EasyTools_default
 *
 * 应用状态决定点击行为（回退链见 Platform 的 AppLauncher）：
 * - SELF：本应用，跳「关于本应用」；
 * - PUBLISHED：先尝试拉起，失败打开应用市场详情；
 * - UNPUBLISHED：未上架，直接弹介绍弹窗（当前为占位）。
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
  /** 介绍弹窗正文（纯文本：弹窗只吃 string，未上架时占位用）。 */
  intro: string;
}

/**
 * 应用矩阵数据源。
 *
 * 注意：EasyMath 的**工程内** bundleName 仍是模板残留（com.ydy.myapplication），
 * 其 README 声明的上架标识是 com.quizzyjoy.easymath，两者不一致——这里按上架
 * 标识填写（回退链会自然降级到"打开市场详情"，包名对不上时由市场提示）。
 */
export class AppMatrix {
  private static readonly ENTRIES: AppMatrixEntry[] = [
    {
      id: 'easystart',
      name: $r('app.string.apps_easystart_name'),
      desc: $r('app.string.apps_easystart_desc'),
      bundleName: 'com.quizzyjoy.easystart',
      icon: $r('app.media.app_easystart'),
      status: AppEntryStatus.SELF,
      statusLabel: $r('app.string.apps_status_self'),
      intro: '四端模板与组件演示应用：示例 Tab 展示组件与场景，学习 Tab 内置开发教程，' +
        '开发工具 Tab 提供图标合成、Symbol 能力等实用工具。'
    },
    {
      id: 'easymath',
      name: $r('app.string.apps_easymath_name'),
      desc: $r('app.string.apps_easymath_desc'),
      bundleName: 'com.quizzyjoy.easymath',
      icon: $r('app.media.app_easymath'),
      status: AppEntryStatus.PUBLISHED,
      statusLabel: $r('app.string.apps_status_published'),
      intro: '数学学习应用：题库、教材精选与每日一题，内容生产型。'
    },
    {
      id: 'vibestereo',
      name: $r('app.string.apps_vibestereo_name'),
      desc: $r('app.string.apps_vibestereo_desc'),
      bundleName: 'com.quizzyjoy.vibestereo',
      icon: $r('app.media.app_vibestereo'),
      status: AppEntryStatus.PUBLISHED,
      statusLabel: $r('app.string.apps_status_published'),
      intro: '音乐可视化播放器：本地曲库播放与频谱可视化，支持多端适配。'
    },
    {
      id: 'easytools',
      name: $r('app.string.apps_easytools_name'),
      desc: $r('app.string.apps_easytools_desc'),
      bundleName: 'com.quizzyjoy.easytools',
      icon: $r('app.media.app_easytools'),
      status: AppEntryStatus.PUBLISHED,
      statusLabel: $r('app.string.apps_status_published'),
      intro: '随易工具箱：哈希、编解码、ID 生成、正则与 JSON 等开发者常用小工具集合。'
    }
  ];

  /** 全部条目（顺序即展示顺序）。 */
  static all(): AppMatrixEntry[] {
    return AppMatrix.ENTRIES;
  }
}
