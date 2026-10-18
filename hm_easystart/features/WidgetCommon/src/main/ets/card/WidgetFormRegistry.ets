import { common, PreferencesStore } from '@quizzyjoy/platform';
import { CardLayout } from './CardViewData';

/**
 * 卡片 formId → 规格注册表（v3.27）。
 *
 * 【为什么需要】`onUpdateForm(formId)` / `onSizeChanged` 只拿到 formId、拿不到规格；
 * 载荷必须按规格给（宽卡错用紧凑布局会明显劣化）。故 `onAddForm` 时把
 * `formId → 规格` 登记进 preferences（跨进程可读），后续刷新时查回。
 *
 * 【独立偏好文件（v3.27.1 真机实测修正）】注册表原本与应用设置**同文件**，
 * 导致 UI 进程为读最新注册表必须丢缓存 → 会把应用设置实例一起打 detached（禁忌）。
 * 现独立到 `easystart_widget` 文件：注册表是**卡片进程写、UI 进程读**的跨进程数据，
 * 丢缓存只影响本文件、与应用设置实例互不牵连。
 *
 * 【存储形态】单键聚合为 `id1:1,id2:0` 字符串（layout 1 = 宽卡）——
 * 避免依赖「枚举全部键」的 API，保持 Platform 同步链的最小面。
 *
 * 【进程语义】卡片进程读写传 `dropCache=true`；UI 进程读用 `listForUi`（仅丢注册表文件缓存）。
 */
const REGISTRY_FILE_NAME: string = 'easystart_widget';
const KEY_FORMS: string = 'card.forms';

/** 已注册卡片条目。 */
export class WidgetFormEntry {
  formId: string = '';
  layout: CardLayout = CardLayout.COMPACT;

  constructor(formId: string, layout: CardLayout) {
    this.formId = formId;
    this.layout = layout;
  }
}

function parseForms(raw: string): WidgetFormEntry[] {
  const entries: WidgetFormEntry[] = [];
  if (raw.length === 0) {
    return entries;
  }
  const parts: string[] = raw.split(',');
  for (let i = 0; i < parts.length; i++) {
    const seg: string = parts[i];
    const idx: number = seg.indexOf(':');
    if (idx <= 0) {
      continue;
    }
    const id: string = seg.substring(0, idx);
    const isWide: boolean = seg.substring(idx + 1) === '1';
    entries.push(new WidgetFormEntry(id, isWide ? CardLayout.WIDE : CardLayout.COMPACT));
  }
  return entries;
}

function serializeForms(entries: WidgetFormEntry[]): string {
  const parts: string[] = [];
  for (let i = 0; i < entries.length; i++) {
    const entry: WidgetFormEntry = entries[i];
    parts.push(`${entry.formId}:${entry.layout === CardLayout.WIDE ? '1' : '0'}`);
  }
  return parts.join(',');
}

export class WidgetFormRegistry {
  private static load(context: common.Context, dropCache: boolean): WidgetFormEntry[] {
    if (dropCache) {
      PreferencesStore.dropCache(context, REGISTRY_FILE_NAME);
    } else {
      PreferencesStore.initSync(context, REGISTRY_FILE_NAME);
    }
    return parseForms(PreferencesStore.getStringSync(KEY_FORMS, ''));
  }

  private static save(entries: WidgetFormEntry[]): void {
    PreferencesStore.putSync(KEY_FORMS, serializeForms(entries));
  }

  /** 登记或更新某卡片规格（`onAddForm` / `onSizeChanged`；卡片进程）。 */
  static upsert(context: common.Context, formId: string, layout: CardLayout, dropCache: boolean): void {
    if (formId.length === 0) {
      return;
    }
    const current: WidgetFormEntry[] = WidgetFormRegistry.load(context, dropCache);
    const next: WidgetFormEntry[] = [];
    for (let i = 0; i < current.length; i++) {
      if (current[i].formId !== formId) {
        next.push(current[i]);
      }
    }
    next.push(new WidgetFormEntry(formId, layout));
    WidgetFormRegistry.save(next);
  }

  /** 注销（`onRemoveForm`；卡片进程）。 */
  static remove(context: common.Context, formId: string, dropCache: boolean): void {
    const current: WidgetFormEntry[] = WidgetFormRegistry.load(context, dropCache);
    const next: WidgetFormEntry[] = [];
    for (let i = 0; i < current.length; i++) {
      if (current[i].formId !== formId) {
        next.push(current[i]);
      }
    }
    WidgetFormRegistry.save(next);
  }

  /** 查某卡片当前规格（`onUpdateForm`；卡片进程）。 */
  static layoutOf(context: common.Context, formId: string, dropCache: boolean): CardLayout {
    const current: WidgetFormEntry[] = WidgetFormRegistry.load(context, dropCache);
    for (let i = 0; i < current.length; i++) {
      if (current[i].formId === formId) {
        return current[i].layout;
      }
    }
    return CardLayout.COMPACT;
  }

  /**
   * UI 进程读取全部已注册卡片（应用内主动刷新用）。
   *
   * **只丢注册表文件缓存**（`easystart_widget`）——卡片进程是写入方，UI 进程必须丢缓存
   * 才能看到新注册/注销；该操作不触碰应用设置文件实例（v3.27.1 真机实测修正）。
   */
  static listForUi(context: common.Context): WidgetFormEntry[] {
    return WidgetFormRegistry.load(context, true);
  }
}
