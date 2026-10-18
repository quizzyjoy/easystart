import { formBindingData, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import type { common } from '@kit.AbilityKit';
import { Logger } from '@quizzyjoy/foundation';
import {
  buildWidgetCardDataAsync,
  toCardPayload,
  WidgetFormEntry,
  WidgetFormRegistry
} from '@easystart/widget-common';

const DOMAIN: string = 'app';
const TAG: string = 'WidgetRefresher';

/**
 * 服务卡片「应用内主动刷新」（入口装配层，v3.27）。
 *
 * 【为什么在入口层】`@kit.FormKit` 的卡片接口是脆弱系统能力调用，
 * 按分层纪律留在 product 入口层；WidgetCommon 只产出纯数据（零 @kit）。
 *
 * 【触发时机】应用切后台（onBackground）——用户改完设置离开应用时，
 * 立刻把最新偏好推给已添加的卡片，不必等 form_config 的 30min 定时刷新。
 * 推送走 `formProvider.updateForm`（卡片提供方主动更新自己的卡片；
 * 本 SDK 未提供 `formHost`，provider 侧接口即官方主动刷新路径）。
 *
 * 【进程语义（v3.27.1 真机实测修正）】本类跑在 **UI 进程**：
 * - 注册表读用 `WidgetFormRegistry.listForUi`——**只丢注册表独立文件的缓存**
 *   （卡片进程是写入方，不丢就读不到新注册卡片）；
 * - 偏好值读用 `buildWidgetCardDataAsync`——走与「设置页写入」**同一个实例**的异步链，
 *   天然最新；UI 进程**禁止**丢应用设置文件的缓存（会打 detached、写入不落盘）。
 */
export class WidgetRefresher {
  /** 刷新全部已注册卡片；无卡片时静默返回。 */
  static async refreshAll(context: common.UIAbilityContext): Promise<void> {
    try {
      const forms: WidgetFormEntry[] = WidgetFormRegistry.listForUi(context);
      if (forms.length === 0) {
        return;
      }
      for (let i = 0; i < forms.length; i++) {
        const entry: WidgetFormEntry = forms[i];
        const payload: Record<string, string> =
          toCardPayload(await buildWidgetCardDataAsync(context, entry.layout));
        await formProvider.updateForm(entry.formId, formBindingData.createFormBindingData(payload));
      }
      Logger.info(DOMAIN, TAG, `refreshAll done, count=${forms.length}`);
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      Logger.warn(DOMAIN, TAG, `refreshAll failed: ${error.message}`);
    }
  }
}
