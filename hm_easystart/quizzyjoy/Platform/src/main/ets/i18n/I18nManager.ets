import { i18n, intl } from '@kit.LocalizationKit';
import { Logger } from '@quizzyjoy/foundation';

const DOMAIN: string = 'platform';
const TAG: string = 'I18nManager';

/** 支持的语言。 */
export enum LangType {
  ZH_HANS = 'zh-Hans',
  EN_US = 'en-US'
}

/** 默认地区 */
const DEFAULT_REGION: string = 'CN';

/**
 * 国际化管理（i18n）。
 *
 * 约定：
 * - 文案一律走资源 `$r('app.string.xxx')`，并补齐 base / zh_CN / en_US 目录；
 * - 与语言强相关的格式化（日期、货币、数字）用 intl，不要手写拼接。
 */
export class I18nManager {
  static getSystemLanguage(): string {
    try {
      return i18n.System.getSystemLanguage();
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `getSystemLanguage failed: ${err}`);
      return LangType.ZH_HANS;
    }
  }

  static getSystemRegion(): string {
    try {
      return i18n.System.getSystemRegion();
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `getSystemRegion failed: ${err}`);
      return DEFAULT_REGION;
    }
  }

  /** 当前是否 24 小时制（手表/时钟类页面常用）。 */
  static is24HourClock(): boolean {
    try {
      return i18n.System.is24HourClock();
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `is24HourClock failed: ${err}`);
      return true;
    }
  }

  /** RTL 语言判断（用于布局镜像）。 */
  static isRTL(language: string): boolean {
    const rtlLangs: string[] = ['ar', 'fa', 'he', 'ur'];
    return rtlLangs.indexOf(language) >= 0;
  }

  /** 数字本地化格式化。 */
  static formatNumber(value: number, locale: string = 'zh-CN'): string {
    try {
      return new intl.NumberFormat(locale).format(value);
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `formatNumber failed: ${err}`);
      return `${value}`;
    }
  }

  /** 日期本地化格式化。 */
  static formatDate(date: Date, locale: string = 'zh-CN'): string {
    try {
      // @ohos.intl 的 DateTimeFormat 自 API 20 弃用，官方替代为标准全局 Intl.DateTimeFormat
      return new Intl.DateTimeFormat(locale).format(date);
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `formatDate failed: ${err}`);
      return date.toISOString();
    }
  }

  static describe(): string {
    const lang: string = I18nManager.getSystemLanguage();
    Logger.debug(DOMAIN, TAG, `locale=${lang} region=${I18nManager.getSystemRegion()}`);
    return lang;
  }

  /**
   * 跟随系统的偏好语言保留值：setAppPreferredLanguage('default') 清除应用偏好，
   * 界面恢复跟随系统语言（官方说明：重启后生效）。
   */
  static readonly LANGUAGE_FOLLOW_SYSTEM: string = 'default';

  /**
   * 设置应用偏好语言（仅影响本应用，不改变系统语言设置）。
   * - 具体语言（如 LangType.ZH_HANS / LangType.EN_US）：设置后界面即时切换；
   * - LANGUAGE_FOLLOW_SYSTEM（'default'）：清除偏好、恢复跟随系统，重启后生效。
   *
   * 不持久化——默认值与偏好读写由应用装配层（AppBootstrap）负责，
   * Manager 只做系统 API 的无策略封装。
   *
   * @returns 是否调用成功（失败已内部降级记 WARN，不抛异常）
   */
  static setPreferredLanguage(language: string): boolean {
    try {
      i18n.System.setAppPreferredLanguage(language);
      Logger.info(DOMAIN, TAG, `setAppPreferredLanguage=${language}`);
      return true;
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `setAppPreferredLanguage failed: ${JSON.stringify(err)}`);
      return false;
    }
  }

  /**
   * 获取系统记录的应用偏好语言。
   * 注意：未设置偏好时系统返回值依版本而异，设置页的「当前选中项」回显
   * 应以应用自有偏好（PreferencesStore）为准，本接口仅作系统侧查询/调试。
   */
  static getPreferredLanguage(): string {
    try {
      return i18n.System.getAppPreferredLanguage();
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `getAppPreferredLanguage failed: ${JSON.stringify(err)}`);
      return I18nManager.LANGUAGE_FOLLOW_SYSTEM;
    }
  }
}
