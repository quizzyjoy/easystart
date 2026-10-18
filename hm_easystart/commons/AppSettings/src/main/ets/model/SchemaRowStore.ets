import { PreferencesStore } from '@quizzyjoy/platform';
import { SchemaRowDef } from './SettingsSchema';

/**
 * schema 通用行偏好底座（v3.30，TODO-021）：
 * switch / select / slider 三类通用行的键值态 + 持久化 + 变更钩子 + 动作注册表。
 *
 * - 内建偏好（settings.* 六键）不走本通道——仍由 SettingsViewModel + Manager
 *   即时生效链收口（v3.30 口径：行为零改，仅外壳 schema 化）；
 * - fork 业务行（如 EasyMath「练习挑战域」）用任意 prefKey 读写，
 *   联动逻辑（如切域刷服务卡片）经 SettingsSchemaHooks.register 注册；
 * - V2：@ObservedV2 + @Trace Map（键值级观察，渲染层在元素参数内直读 Map）。
 */
@ObservedV2
export class SchemaRowStore {
  private static instance: SchemaRowStore | undefined = undefined;

  static getInstance(): SchemaRowStore {
    if (SchemaRowStore.instance === undefined) {
      SchemaRowStore.instance = new SchemaRowStore();
    }
    return SchemaRowStore.instance;
  }

  @Trace boolValues: Map<string, boolean> = new Map<string, boolean>();
  @Trace numberValues: Map<string, number> = new Map<string, number>();

  /** 渲染前装载本页通用行初值（内建行不经过本 store）。 */
  async loadRows(rows: SchemaRowDef[]): Promise<void> {
    for (const row of rows) {
      if (row.prefKey.length === 0) {
        continue;
      }
      if (row.type === 'switch') {
        this.boolValues.set(row.prefKey, await PreferencesStore.getBool(row.prefKey, row.defaultBool()));
      } else if (row.type === 'select' || row.type === 'slider') {
        this.numberValues.set(row.prefKey, await PreferencesStore.getNumber(row.prefKey, row.defaultNumber()));
      }
    }
  }

  /** 开关行写入：@Trace 键值更新 + 持久化 + 钩子触发。 */
  setBool(key: string, value: boolean): void {
    this.boolValues.set(key, value);
    PreferencesStore.put(key, value);
    SettingsSchemaHooks.fire(key, value);
  }

  /** 档位行写入（select 索引 / slider 数值）。 */
  setNumber(key: string, value: number): void {
    this.numberValues.set(key, value);
    PreferencesStore.put(key, value);
    SettingsSchemaHooks.fire(key, value);
  }

  /** 滑条拖动中的即时值更新（仅 @Trace 键值，不落盘不触发钩子）；拖动结束由 setNumber 持久化。 */
  setNumberLive(key: string, value: number): void {
    this.numberValues.set(key, value);
  }
}

/**
 * 通用行变更钩子注册表：fork 在 Ability / AppBootstrap 注册业务联动。
 * 例：SettingsSchemaHooks.register('challenge_domain', (v) => refreshCards())。
 */
export class SettingsSchemaHooks {
  private static callbacks: Record<string, (value: boolean | number | string) => void> = {};

  static register(prefKey: string, callback: (value: boolean | number | string) => void): void {
    SettingsSchemaHooks.callbacks[prefKey] = callback;
  }

  static fire(prefKey: string, value: boolean | number | string): void {
    const callback: ((value: boolean | number | string) => void) | undefined = SettingsSchemaHooks.callbacks[prefKey];
    if (callback !== undefined) {
      callback(value);
    }
  }
}

/**
 * action 行动作注册表：内建 shareApp 由渲染层直接处理，fork 自定义动作在此注册。
 * 例：SettingsSchemaActions.register('openMarket', () => MarketHelper...openAppDetail())。
 */
export class SettingsSchemaActions {
  private static actions: Record<string, () => void> = {};

  static register(actionId: string, action: () => void): void {
    SettingsSchemaActions.actions[actionId] = action;
  }

  static run(actionId: string): void {
    const action: (() => void) | undefined = SettingsSchemaActions.actions[actionId];
    if (action !== undefined) {
      action();
    }
  }
}
