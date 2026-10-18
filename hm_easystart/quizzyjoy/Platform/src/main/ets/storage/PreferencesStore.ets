import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import type { common } from '@kit.AbilityKit';
import { Logger } from '@quizzyjoy/foundation';
import { ErrorMapper } from '../error/ErrorMapper';

const DOMAIN: string = 'platform';
const TAG: string = 'PreferencesStore';

/** 默认偏好文件名 */
const DEFAULT_FILE_NAME: string = 'quizzyjoy_store';

/**
 * 首选项存储（键值型轻量持久化）。
 *
 * 适用：开关、颜色模式、语言、首次启动标记等小数据；
 * 不适用：结构化业务数据（请用 RDB / KVStore）。
 *
 * 用法：init(context) 一次（建议 UIAbility.onCreate）；随后 getXxx / put。
 * 读写失败一律内部降级（记日志、返回默认值），不向上抛。
 */
export class PreferencesStore {
  private static store: preferences.Preferences | null = null;
  /** 首次 init 的完成承诺（供页面读偏好前 await，见 ready()）。 */
  private static initPromise: Promise<void> | undefined = undefined;

  /** 初始化（幂等，并发调用复用同一承诺）。 */
  static init(context: common.UIAbilityContext,
    fileName: string = DEFAULT_FILE_NAME): Promise<void> {
    if (PreferencesStore.store !== null) {
      return Promise.resolve();
    }
    let pending: Promise<void> | undefined = PreferencesStore.initPromise;
    if (pending === undefined) {
      pending = PreferencesStore.doInit(context, fileName);
      PreferencesStore.initPromise = pending;
    }
    return pending;
  }

  /**
   * 等待初始化完成（幂等；从未 init 时立即 resolve）。
   *
   * 页面 aboutToAppear 可能早于 Ability.onCreate 里 init 的完成——深链冷启动
   * 直达设置子页时尤甚，此时 getXxx 直接返回默认值，表现为「落盘值不生效」
   * （实证：显示模式偏好为浅色，深链直达主题外观页仍显示「跟随系统」）。
   * 读偏好的页面应先 await 本方法。
   */
  static ready(): Promise<void> {
    const pending: Promise<void> | undefined = PreferencesStore.initPromise;
    return pending !== undefined ? pending : Promise.resolve();
  }

  private static async doInit(context: common.UIAbilityContext, fileName: string): Promise<void> {
    try {
      PreferencesStore.store = await preferences.getPreferences(context, fileName);
      Logger.info(DOMAIN, TAG, `init ok: ${fileName}`);
    } catch (err) {
      Logger.error(DOMAIN, TAG, `init failed: ${ErrorMapper.from(err, DOMAIN, 'init').toLog()}`);
    }
  }

  static async put(key: string, value: preferences.ValueType): Promise<void> {
    const store = PreferencesStore.store;
    if (store === null) {
      Logger.warn(DOMAIN, TAG, `not inited, put ignored: ${key}`);
      return;
    }
    try {
      await store.put(key, value);
      await store.flush();
    } catch (err) {
      Logger.error(DOMAIN, TAG, `put failed: ${key} ${ErrorMapper.from(err, DOMAIN, 'put').toLog()}`);
    }
  }

  static async getBool(key: string, defValue: boolean): Promise<boolean> {
    const store = PreferencesStore.store;
    if (store === null) {
      return defValue;
    }
    try {
      const value: preferences.ValueType = await store.get(key, defValue);
      if (typeof value === 'boolean') {
        return value;
      }
      return defValue;
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `getBool failed: ${key} ${ErrorMapper.from(err, DOMAIN, 'get').toLog()}`);
      return defValue;
    }
  }

  static async getString(key: string, defValue: string): Promise<string> {
    const store = PreferencesStore.store;
    if (store === null) {
      return defValue;
    }
    try {
      const value: preferences.ValueType = await store.get(key, defValue);
      if (typeof value === 'string') {
        return value;
      }
      return defValue;
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `getString failed: ${key} ${ErrorMapper.from(err, DOMAIN, 'get').toLog()}`);
      return defValue;
    }
  }

  static async getNumber(key: string, defValue: number): Promise<number> {
    const store = PreferencesStore.store;
    if (store === null) {
      return defValue;
    }
    try {
      const value: preferences.ValueType = await store.get(key, defValue);
      if (typeof value === 'number') {
        return value;
      }
      return defValue;
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `getNumber failed: ${key} ${ErrorMapper.from(err, DOMAIN, 'get').toLog()}`);
      return defValue;
    }
  }

  static async delete(key: string): Promise<void> {
    const store = PreferencesStore.store;
    if (store === null) {
      return;
    }
    try {
      await store.delete(key);
      await store.flush();
    } catch (err) {
      Logger.error(DOMAIN, TAG, `delete failed: ${key} ${ErrorMapper.from(err, DOMAIN, 'delete').toLog()}`);
    }
  }

  // ==================== 卡片（Extension）进程同步链（v3.27） ====================

  /**
   * 卡片进程专用同步实例：与上方异步 store **分离**，互不干扰。
   *
   * 为什么必须有独立同步链：
   * 1. `FormExtensionAbility.onAddForm` 必须**同步返回** formBindingData，异步链无法满足；
   * 2. 卡片进程拿到的 context 是 FormExtensionContext（不是 UIAbilityContext），故入参放宽为 `common.Context`；
   * 3. 卡片进程与 UI 进程**不共享内存态**（AppStorage / 单例都不通），只能直读 preferences，
   *    且必须 `dropCache` 才能读到 UI 进程刚落盘的值。
   */
  private static syncStore: preferences.Preferences | null = null;

  /** 同步取实例（幂等；Extension 进程与 UI 进程都可调用）。 */
  static initSync(context: common.Context, fileName: string = DEFAULT_FILE_NAME): boolean {
    try {
      PreferencesStore.syncStore = preferences.getPreferencesSync(context, { name: fileName });
      Logger.info(DOMAIN, TAG, `initSync ok: ${fileName}`);
      return true;
    } catch (err) {
      PreferencesStore.syncStore = null;
      Logger.error(DOMAIN, TAG, `initSync failed: ${fileName} ${ErrorMapper.from(err, DOMAIN, 'initSync').toLog()}`);
      return false;
    }
  }

  /**
   * 丢本进程缓存后重新取实例——**卡片/Extension 进程读跨进程最新值的唯一正确姿势**。
   *
   * ⚠️ **UI 进程禁用**：丢缓存会把持有同名文件的实例（如应用设置域自己的 Preferences）
   * 打成 detached，导致其后续写入不落盘（EasyMath 卡片实测教训）。
   * 因此调用点必须显式声明进程语义：`dropCache = 仅卡片进程 true`。
   */
  static dropCache(context: common.Context, fileName: string = DEFAULT_FILE_NAME): boolean {
    try {
      preferences.removePreferencesFromCacheSync(context, { name: fileName });
    } catch (err) {
      Logger.warn(DOMAIN, TAG,
        `dropCache failed: ${fileName} ${ErrorMapper.from(err, DOMAIN, 'dropCache').toLog()}`);
    }
    return PreferencesStore.initSync(context, fileName);
  }

  static getStringSync(key: string, defValue: string): string {
    const store = PreferencesStore.syncStore;
    if (store === null) {
      return defValue;
    }
    try {
      const value: preferences.ValueType = store.getSync(key, defValue);
      return typeof value === 'string' ? value : defValue;
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `getStringSync failed: ${key} ${ErrorMapper.from(err, DOMAIN, 'get').toLog()}`);
      return defValue;
    }
  }

  static getBoolSync(key: string, defValue: boolean): boolean {
    const store = PreferencesStore.syncStore;
    if (store === null) {
      return defValue;
    }
    try {
      const value: preferences.ValueType = store.getSync(key, defValue);
      return typeof value === 'boolean' ? value : defValue;
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `getBoolSync failed: ${key} ${ErrorMapper.from(err, DOMAIN, 'get').toLog()}`);
      return defValue;
    }
  }

  static getNumberSync(key: string, defValue: number): number {
    const store = PreferencesStore.syncStore;
    if (store === null) {
      return defValue;
    }
    try {
      const value: preferences.ValueType = store.getSync(key, defValue);
      return typeof value === 'number' ? value : defValue;
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `getNumberSync failed: ${key} ${ErrorMapper.from(err, DOMAIN, 'get').toLog()}`);
      return defValue;
    }
  }

  /** 同步写入 + 非阻塞 flush（卡片进程注册表等小数据；失败返回 false，不抛）。 */
  static putSync(key: string, value: preferences.ValueType): boolean {
    const store = PreferencesStore.syncStore;
    if (store === null) {
      Logger.warn(DOMAIN, TAG, `sync store not inited, putSync ignored: ${key}`);
      return false;
    }
    try {
      store.putSync(key, value);
      store.flush().then(() => {
      }).catch((err: BusinessError) => {
        Logger.warn(DOMAIN, TAG, `putSync flush failed: ${key} ${ErrorMapper.from(err, DOMAIN, 'put').toLog()}`);
      });
      return true;
    } catch (err) {
      Logger.error(DOMAIN, TAG, `putSync failed: ${key} ${ErrorMapper.from(err, DOMAIN, 'put').toLog()}`);
      return false;
    }
  }
}
