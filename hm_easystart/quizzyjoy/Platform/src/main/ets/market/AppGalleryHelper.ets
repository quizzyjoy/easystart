import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { appInfoManager, commentManager, privacyManager, updateManager } from '@kit.AppGalleryKit';
import { Logger } from '@quizzyjoy/foundation';
import { ErrorMapper } from '../error/ErrorMapper';
import { AppEnvManager } from '../device/AppEnvManager';
import { PrivacyLinks } from './PrivacyLinks';

const DOMAIN: string = 'platform';
const TAG: string = 'AppGalleryHelper';

/** 系统能力常量（`canIUse` 探测用，逐字对齐 SDK @syscap 声明）。 */
const SYSCAP_UPDATE: string = 'SystemCapability.AppGalleryService.Distribution.Update';
const SYSCAP_COMMENT: string = 'SystemCapability.AppGalleryService.Distribution.Comment';
const SYSCAP_PRIVACY: string = 'SystemCapability.AppGalleryService.PrivacyManager';
const SYSCAP_ICON: string = 'SystemCapability.AppGalleryService.AppInfoManager';

/** 检查更新节流：同一会话 30 分钟内不重复请求（服务侧 1009400006 也在限频）。 */
const UPDATE_CHECK_INTERVAL_MS: number = 30 * 60 * 1000;

/** 应用市场能力（用于能力探测与设备门控分派）。 */
export enum StoreSkill {
  UPDATE,
  COMMENT,
  PRIVACY,
  ICON
}

/**
 * 应用市场能力的**语义化结果**（v3.39）。
 *
 * UI 只消费本枚举，错误码不出 Platform（与 MarketHelper 同纪律：失败不抛异常）。
 */
export enum StoreCapabilityResult {
  /** 成功（更新：存在新版本；评分：弹窗已拉起；隐私：动作已执行）。 */
  OK,
  /** 检查更新：已是最新。 */
  UP_TO_DATE,
  /** 系统能力不支持 / 本应用未接入该服务（含未上架）。 */
  NOT_SUPPORTED,
  /** 未登录华为账号。 */
  NOT_SIGNED_IN,
  /** 已评过 / 一年内已评 / 评论次数达上限。 */
  ALREADY_DONE,
  /** 应用不在前台（检查更新要求前台）。 */
  NOT_FOREGROUND,
  /** 未同意隐私协议（需先走隐私同意流程）。 */
  PRIVACY_NOT_AGREED,
  /** 网络错误。 */
  NETWORK,
  /** 请求过于频繁（服务侧限频）。 */
  THROTTLED,
  /** 连接应用市场失败（未安装 / 未上架）。 */
  UNPUBLISHED,
  /** 未 attach（调用方漏掉 AppBootstrap 编排）。 */
  NOT_ATTACHED,
  /** 其他未识别失败。 */
  UNKNOWN
}

/** 官方隐私链接（同 AppPrivacyLinkType。 */
export enum StorePrivacyKind {
  STATEMENT = 1,
  USER_AGREEMENT = 2
}

/** 官方隐私链接条目。 */
export class StorePrivacyLink {
  readonly kind: StorePrivacyKind;
  readonly url: string;

  constructor(kind: StorePrivacyKind, url: string) {
    this.kind = kind;
    this.url = url;
  }
}

/**
 * 隐私签署记录（v3.54，来自 `privacyManager.getAppPrivacyResult()`）。
 *
 * 与 `StorePrivacyLink` 的区别：Link 是"协议地址"，本类记录是"用户签没签、何时签"。
 * 用于设置页展示隐私状态，避免用户不知道自己是否同意过。
 */
export class StorePrivacyRecord {
  /** 协议标识（`AppPrivacyResult.id`）。 */
  readonly id: string;
  /** 协议版本号。 */
  readonly versionCode: number;
  /** 是否已同意（`AppPrivacyResultType.FULL_MODE_AGREED`）。 */
  readonly agreed: boolean;
  /** 签署时间戳（毫秒；未签署时为 0）。 */
  readonly signingTimestamp: number;

  constructor(id: string, versionCode: number, agreed: boolean, signingTimestamp: number) {
    this.id = id;
    this.versionCode = versionCode;
    this.agreed = agreed;
    this.signingTimestamp = signingTimestamp;
  }
}

/**
 * 隐私状态的可解释结果（v3.57）。
 *
 * 之前的 `getPrivacyResults()` 只返回数组，空数组有三种完全不同的原因，
 * UI 只能笼统显示"未知"。这里把「为什么查不到」显式建模，让页面能给出准确说明：
 * - `UNSUPPORTED`：设备/形态不支持隐私托管能力（canIUse 为假、未 attach、手表端）；
 * - `NOT_SUBSCRIBED`：设备支持，但本应用未接入应用市场隐私托管服务
 *   （`getAppPrivacyResult` 抛 1006700003），此时系统里根本没有签署记录；
 * - `NO_RECORD`：接口可调用但返回空（应用已接入但用户尚未走过系统隐私弹窗）；
 * - `RECORDED`：拿到了记录，`agreed` 决定"已同意 / 未同意"。
 */
export enum StorePrivacyState {
  UNSUPPORTED = 'unsupported',
  NOT_SUBSCRIBED = 'notSubscribed',
  NO_RECORD = 'noRecord',
  RECORDED = 'recorded'
}

/** 隐私状态快照：状态 + 记录 + 原始错误码（便于日志与页面文案）。 */
export class StorePrivacySnapshot {
  readonly state: StorePrivacyState;
  readonly records: StorePrivacyRecord[];
  /** 业务错误码（0 = 无错误；1006700003 = 未接入托管服务）。 */
  readonly errorCode: number;

  constructor(state: StorePrivacyState, records: StorePrivacyRecord[], errorCode: number) {
    this.state = state;
    this.records = records;
    this.errorCode = errorCode;
  }
}



/** 动态图标条目。 */
export class StoreDynamicIcon {
  readonly iconId: string;
  readonly iconUrl: string;
  readonly enabled: boolean;

  constructor(iconId: string, iconUrl: string, enabled: boolean) {
    this.iconId = iconId;
    this.iconUrl = iconUrl;
    this.enabled = enabled;
  }
}

/**
 * 应用市场（AppGallery Kit）能力收口（v3.39）。
 *
 * 定位：**上架后能力**的唯一入口——检查更新 / 应用内评分 / 隐私链接与撤回 / 动态图标。
 * 四项能力都依赖 HMS 与「应用已上架」，本仓调试包大概率全程走降级分支，因此：
 *
 * 1. **先探测再调用**：`canIUse(syscap)` 为 false 直接返回 NOT_SUPPORTED，不赌异常；
 * 2. **双层异常处理**：同步接口（隐私三件套）包 try/catch，异步接口再 catch Promise；
 * 3. **错误码映射**：SDK 声明的 10094000xx / 10067xxx / 1021500xxx / 10068xxx 逐条翻译成
 *    语义枚举，日志留码、UI 只拿人话；
 * 4. **降级交给调用方**：本类不做 UI，调用方（设置页 / 关于页）拿到 NOT_SUPPORTED 等结果后
 *    自行回退（跳市场详情页 / 本地政策文本 / 隐藏入口），保证「点了有反应」。
 *
 * 生命周期：attach / detach 成对（AppBootstrap.prepare / destroy 编排）。
 */
export class AppGalleryHelper {
  private static instance: AppGalleryHelper | undefined = undefined;

  private context: common.UIAbilityContext | undefined = undefined;
  private lastUpdateCheckAt: number = 0;

  private constructor() {
  }

  static getInstance(): AppGalleryHelper {
    if (AppGalleryHelper.instance === undefined) {
      AppGalleryHelper.instance = new AppGalleryHelper();
    }
    return AppGalleryHelper.instance;
  }

  attach(context: common.UIAbilityContext): void {
    this.context = context;
    Logger.info(DOMAIN, TAG, 'attached');
  }

  detach(): void {
    this.context = undefined;
    this.lastUpdateCheckAt = 0;
    Logger.info(DOMAIN, TAG, 'detached');
  }

  // ———————— 能力探测 ————————

  /** 系统是否提供该能力（canIUse 全局函数，API 12+）。 */
  isSupported(skill: StoreSkill): boolean {
    let syscap: string = SYSCAP_UPDATE;
    if (skill === StoreSkill.COMMENT) {
      syscap = SYSCAP_COMMENT;
    } else if (skill === StoreSkill.PRIVACY) {
      syscap = SYSCAP_PRIVACY;
    } else if (skill === StoreSkill.ICON) {
      syscap = SYSCAP_ICON;
    }
    try {
      return canIUse(syscap);
    } catch (err) {
      return false;
    }
  }

  /**
   * 设备形态门控（与 SDK device-define 矩阵一致，逐能力不同）。
   * 评分仅 phone / tablet / 2in1；隐私无 wearable；更新与图标不额外限制。
   */
  private deviceAllowed(skill: StoreSkill): boolean {
    const device: string = AppEnvManager.get().deviceType;
    if (skill === StoreSkill.COMMENT) {
      return device === 'phone' || device === 'tablet' || device === '2in1';
    }
    if (skill === StoreSkill.PRIVACY) {
      return device !== 'wearable';
    }
    return true;
  }

  /** 能力是否可用（系统能力 + 设备形态 + 已 attach 三者同时满足）。 */
  usable(skill: StoreSkill): boolean {
    return this.context !== undefined && this.deviceAllowed(skill) && this.isSupported(skill);
  }

  // ———————— 检查更新 ————————

  /**
   * 检查是否有新版本。
   *
   * 注意：`CheckUpdateResult.versionName/versionCode` 仅元服务返回，应用类只可靠
   * `updateAvailable`，所以 UI 文案用「发现新版本」而不是具体版本号。
   *
   * @param force true = 忽略 30 分钟节流（用户主动点击时用）
   */
  async checkUpdate(force: boolean): Promise<StoreCapabilityResult> {
    const context: common.UIAbilityContext | undefined = this.context;
    if (context === undefined) {
      return StoreCapabilityResult.NOT_ATTACHED;
    }
    if (!this.usable(StoreSkill.UPDATE)) {
      return StoreCapabilityResult.NOT_SUPPORTED;
    }
    const now: number = Date.now();
    if (!force && now - this.lastUpdateCheckAt < UPDATE_CHECK_INTERVAL_MS) {
      return StoreCapabilityResult.THROTTLED;
    }
    this.lastUpdateCheckAt = now;
    try {
      const result: updateManager.CheckUpdateResult = await updateManager.checkAppUpdate(context);
      if (result.updateAvailable === updateManager.UpdateAvailableCode.LATER_VERSION_EXIST) {
        Logger.info(DOMAIN, TAG, 'checkUpdate: later version exist');
        return StoreCapabilityResult.OK;
      }
      Logger.info(DOMAIN, TAG, 'checkUpdate: up to date');
      return StoreCapabilityResult.UP_TO_DATE;
    } catch (err) {
      return this.mapUpdateError(err, 'checkAppUpdate');
    }
  }

  /** 拉起系统升级弹框（用户主动点击后调用）。 */
  async showUpdateDialog(): Promise<StoreCapabilityResult> {
    const context: common.UIAbilityContext | undefined = this.context;
    if (context === undefined) {
      return StoreCapabilityResult.NOT_ATTACHED;
    }
    if (!this.usable(StoreSkill.UPDATE)) {
      return StoreCapabilityResult.NOT_SUPPORTED;
    }
    try {
      const code: updateManager.ShowUpdateResultCode = await updateManager.showUpdateDialog(context);
      if (code === updateManager.ShowUpdateResultCode.SHOW_DIALOG_SUCCESS) {
        return StoreCapabilityResult.OK;
      }
      // SHOW_DIALOG_FAILURE：系统侧拒绝（通常是已是最新 / 无升级包），按已最新处理
      return StoreCapabilityResult.UP_TO_DATE;
    } catch (err) {
      return this.mapUpdateError(err, 'showUpdateDialog');
    }
  }

  private mapUpdateError(err: Object, action: string): StoreCapabilityResult {
    const e: BusinessError = err as BusinessError;
    Logger.warn(DOMAIN, TAG, `${action} failed: ${ErrorMapper.fromBusiness(e, DOMAIN, action).toLog()}`);
    switch (e.code) {
      case 1009400003:
        return StoreCapabilityResult.NETWORK;
      case 1009400004:
        return StoreCapabilityResult.NOT_FOREGROUND;
      case 1009400005:
        return StoreCapabilityResult.PRIVACY_NOT_AGREED;
      case 1009400006:
        return StoreCapabilityResult.THROTTLED;
      case 1009400001:
      case 1009400002:
      case 1009400007:
        return StoreCapabilityResult.UNPUBLISHED;
      default:
        return StoreCapabilityResult.UNKNOWN;
    }
  }

  // ———————— 应用内评分 ————————

  /** 拉起应用内评分弹窗（不离开应用）。 */
  async showCommentDialog(): Promise<StoreCapabilityResult> {
    const context: common.UIAbilityContext | undefined = this.context;
    if (context === undefined) {
      return StoreCapabilityResult.NOT_ATTACHED;
    }
    if (!this.usable(StoreSkill.COMMENT)) {
      return StoreCapabilityResult.NOT_SUPPORTED;
    }
    try {
      await commentManager.showCommentDialog(context);
      Logger.info(DOMAIN, TAG, 'comment dialog shown');
      return StoreCapabilityResult.OK;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      Logger.warn(DOMAIN, TAG, `showCommentDialog failed: ${ErrorMapper.fromBusiness(e, DOMAIN, 'comment').toLog()}`);
      switch (e.code) {
        case 1021500006:
          return StoreCapabilityResult.NOT_SIGNED_IN;
        case 1021500007:
        case 1021500008:
        case 1021500009:
          return StoreCapabilityResult.ALREADY_DONE;
        case 1021500003:
        case 1021500002:
          return StoreCapabilityResult.UNPUBLISHED;
        default:
          return StoreCapabilityResult.UNKNOWN;
      }
    }
  }

  // ———————— 隐私管理 ————————

  /**
   * 读取官方隐私声明 / 用户协议链接（同步接口，必须包 try/catch）。
   * 未接入隐私托管服务时返回空数组（错误码 1006700003），调用方回退本地文本。
   */
  getPrivacyLinks(): StorePrivacyLink[] {
    const links: StorePrivacyLink[] = [];
    if (!this.usable(StoreSkill.PRIVACY)) {
      return links;
    }
    try {
      const info: privacyManager.AppPrivacyMgmtInfo = privacyManager.getAppPrivacyMgmtInfo();
      for (const item of info.privacyInfo) {
        if (item.url.length === 0) {
          continue;
        }
        if (item.type === privacyManager.AppPrivacyLinkType.PRIVACY_STATEMENT_LINK) {
          links.push(new StorePrivacyLink(StorePrivacyKind.STATEMENT, item.url));
        } else if (item.type === privacyManager.AppPrivacyLinkType.USER_AGREEMENT_LINK) {
          links.push(new StorePrivacyLink(StorePrivacyKind.USER_AGREEMENT, item.url));
        }
      }
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      Logger.warn(DOMAIN, TAG,
        `getAppPrivacyMgmtInfo failed: ${ErrorMapper.fromBusiness(e, DOMAIN, 'privacyLinks').toLog()}`);
    }
    return links;
  }

  /**
   * 取某一类协议链接（为空时才降级到本地离线文本）。
   *
   * 顺序（v3.52）：
   * 1. 应用市场隐私托管服务返回的**官方链接**（需已上架并接入该服务）；
   * 2. 内置**真实托管地址** `PrivacyLinks.hostedUrl(kind)`——未上架 / 服务不可用时的
   *    兜底，保证用户点开就能看到真实协议正文；
   * 3. 返回空串表示连常量都没有（理论上不会发生），调用方回退本地 rawfile 离线副本。
   */
  getPrivacyLink(kind: StorePrivacyKind): string {
    const links: StorePrivacyLink[] = this.getPrivacyLinks();
    for (const link of links) {
      if (link.kind === kind) {
        return link.url;
      }
    }
    return PrivacyLinks.hostedUrl(kind);
  }

  /**
   * 查询隐私政策签署结果（v3.54）。
   *
   * 未接入隐私托管服务时抛 1006700003，这里吞掉返回空数组（调用方按"未知"展示）。
   */
  getPrivacyResults(): StorePrivacyRecord[] {
    return this.getPrivacySnapshot().records;
  }

  /**
   * 查询隐私状态（v3.57）：把"查不到"的三种原因区分开。
   *
   * 真机实测：本模板未接入托管服务时 `getAppPrivacyResult()` 抛 1006700003，
   * 页面据此应显示「未接入隐私托管服务」而不是笼统的「未知」。
   */
  getPrivacySnapshot(): StorePrivacySnapshot {
    if (!this.usable(StoreSkill.PRIVACY)) {
      return new StorePrivacySnapshot(StorePrivacyState.UNSUPPORTED, [], 0);
    }
    const records: StorePrivacyRecord[] = [];
    try {
      const results: privacyManager.AppPrivacyResult[] = privacyManager.getAppPrivacyResult();
      for (const item of results) {
        records.push(new StorePrivacyRecord(
          item.id,
          item.versionCode,
          item.result === privacyManager.AppPrivacyResultType.FULL_MODE_AGREED,
          item.signingTimestamp !== undefined ? item.signingTimestamp : 0
        ));
      }
      const state: StorePrivacyState =
        records.length > 0 ? StorePrivacyState.RECORDED : StorePrivacyState.NO_RECORD;
      return new StorePrivacySnapshot(state, records, 0);
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      Logger.warn(DOMAIN, TAG,
        `getAppPrivacyResult failed: ${ErrorMapper.fromBusiness(e, DOMAIN, 'privacyResult').toLog()}`);
      return new StorePrivacySnapshot(StorePrivacyState.NOT_SUBSCRIBED, [], e.code);
    }
  }

  /**
   * 撤回隐私授权（用户在设置页主动撤回）。
   *
   * 后果：更新检查 / 评分等「上架后能力」会随之不可用（错误码 1009400005），
   * 需要重新同意隐私后才能恢复，UI 层必须先说明再执行。
   */
  revokePrivacyConsent(): StoreCapabilityResult {
    if (!this.usable(StoreSkill.PRIVACY)) {
      return StoreCapabilityResult.NOT_SUPPORTED;
    }
    try {
      privacyManager.disableService();
      Logger.info(DOMAIN, TAG, 'privacy consent revoked');
      return StoreCapabilityResult.OK;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      Logger.warn(DOMAIN, TAG, `disableService failed: ${ErrorMapper.fromBusiness(e, DOMAIN, 'revoke').toLog()}`);
      if (e.code === 1006700003) {
        return StoreCapabilityResult.NOT_SUPPORTED;
      }
      return StoreCapabilityResult.UNKNOWN;
    }
  }

  // ———————— 动态图标 ————————

  /** 查询可用动态图标（未配置 / 未上架时返回空数组）。 */
  async queryDynamicIcons(): Promise<StoreDynamicIcon[]> {
    const icons: StoreDynamicIcon[] = [];
    if (!this.usable(StoreSkill.ICON)) {
      return icons;
    }
    try {
      const list: appInfoManager.DynamicIconInfo[] = await appInfoManager.queryDynamicIcons();
      for (const item of list) {
        icons.push(new StoreDynamicIcon(item.iconId, item.iconUrl, item.enabled));
      }
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      Logger.warn(DOMAIN, TAG, `queryDynamicIcons failed: ${ErrorMapper.fromBusiness(e, DOMAIN, 'icons').toLog()}`);
    }
    return icons;
  }

  /** 切换到指定动态图标。 */
  async selectDynamicIcon(iconId: string): Promise<StoreCapabilityResult> {
    if (!this.usable(StoreSkill.ICON)) {
      return StoreCapabilityResult.NOT_SUPPORTED;
    }
    if (iconId.length === 0) {
      return StoreCapabilityResult.UNKNOWN;
    }
    try {
      await appInfoManager.selectDynamicIcon(iconId);
      Logger.info(DOMAIN, TAG, 'dynamic icon selected');
      return StoreCapabilityResult.OK;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      Logger.warn(DOMAIN, TAG, `selectDynamicIcon failed: ${ErrorMapper.fromBusiness(e, DOMAIN, 'selectIcon').toLog()}`);
      if (e.code === 1006800013) {
        // 当前使用系统主题图标，不允许切换
        return StoreCapabilityResult.NOT_SUPPORTED;
      }
      return StoreCapabilityResult.UNKNOWN;
    }
  }

  /** 恢复默认图标。 */
  async disableDynamicIcon(): Promise<StoreCapabilityResult> {
    if (!this.usable(StoreSkill.ICON)) {
      return StoreCapabilityResult.NOT_SUPPORTED;
    }
    try {
      await appInfoManager.disableDynamicIcon();
      Logger.info(DOMAIN, TAG, 'dynamic icon disabled');
      return StoreCapabilityResult.OK;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      Logger.warn(DOMAIN, TAG, `disableDynamicIcon failed: ${ErrorMapper.fromBusiness(e, DOMAIN, 'disableIcon').toLog()}`);
      return StoreCapabilityResult.UNKNOWN;
    }
  }
}
