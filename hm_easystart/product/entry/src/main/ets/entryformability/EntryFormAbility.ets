import { formBindingData, formInfo, formProvider, FormExtensionAbility } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import type { Want } from '@kit.AbilityKit';
import { Logger } from '@quizzyjoy/foundation';
import { buildWidgetCardData, CardLayout, toCardPayload, WidgetFormRegistry } from '@easystart/widget-common';

const DOMAIN: string = 'feature';
const TAG: string = 'EntryFormAbility';

/**
 * 服务卡片 FormExtensionAbility（v3.27 接业务）。
 *
 * 职责边界：本层只做 **FormKit 调用 + 载荷推送**；展示数据的组装在
 * `@easystart/widget-common`（多入口共享，零 @kit）。
 *
 * 生命周期要点：
 * - `onAddForm` 必须**同步返回**载荷 → 数据组装走 Platform 的同步偏好链（dropCache 读最新）；
 * - `onAddForm` 同时把 `formId → 规格` 登记进注册表：`onUpdateForm`/`onSizeChanged`
 *   只有 formId、拿不到规格，UI 进程主动刷新也要靠它；
 * - `onSizeChanged` 是 2×2 ↔ 2×4 切换的唯一入口（不处理会导致宽卡错用紧凑布局）。
 */

/** 尺寸 → 规格（DIMENSION_KEY 在部分设备/版本以字符串下发，必须先 Number() 归一）。 */
function layoutOfDimension(dimensionValue: Object): CardLayout {
  const dim: number = typeof dimensionValue === 'number' ? dimensionValue : Number(dimensionValue);
  return dim === formInfo.FormDimension.Dimension_2_4 ? CardLayout.WIDE : CardLayout.COMPACT;
}

export default class EntryFormAbility extends FormExtensionAbility {
  /** 取出 formId（FormParam.IDENTITY_KEY）。 */
  private formIdOf(want: Want): string {
    const params: Record<string, Object> | undefined = want.parameters;
    if (params === undefined) {
      return '';
    }
    const idValue: Object | undefined = params[formInfo.FormParam.IDENTITY_KEY];
    return typeof idValue === 'string' ? idValue : '';
  }

  /** 取出卡片规格（FormParam.DIMENSION_KEY）。 */
  private layoutOfWant(want: Want): CardLayout {
    const params: Record<string, Object> | undefined = want.parameters;
    if (params === undefined) {
      return CardLayout.COMPACT;
    }
    const dimValue: Object | undefined = params[formInfo.FormParam.DIMENSION_KEY];
    return dimValue === undefined ? CardLayout.COMPACT : layoutOfDimension(dimValue);
  }

  onAddForm(want: Want): formBindingData.FormBindingData {
    const formId: string = this.formIdOf(want);
    const layout: CardLayout = this.layoutOfWant(want);
    Logger.info(DOMAIN, TAG, `onAddForm formId=${formId} layout=${layout}`);
    WidgetFormRegistry.upsert(this.context, formId, layout, true);
    const payload: Record<string, string> =
      toCardPayload(buildWidgetCardData(this.context, layout));
    return formBindingData.createFormBindingData(payload);
  }

  onUpdateForm(formId: string): void {
    const layout: CardLayout = WidgetFormRegistry.layoutOf(this.context, formId, true);
    Logger.info(DOMAIN, TAG, `onUpdateForm formId=${formId} layout=${layout}`);
    this.pushForm(formId, layout);
  }

  onSizeChanged(formId: string, newDimension: formInfo.FormDimension, newRect: formInfo.Rect): void {
    const layout: CardLayout = layoutOfDimension(newDimension);
    Logger.info(DOMAIN, TAG, `onSizeChanged formId=${formId} layout=${layout}`);
    WidgetFormRegistry.upsert(this.context, formId, layout, true);
    this.pushForm(formId, layout);
  }

  onRemoveForm(formId: string): void {
    Logger.info(DOMAIN, TAG, `onRemoveForm formId=${formId}`);
    WidgetFormRegistry.remove(this.context, formId, true);
  }

  onCastToNormalForm(formId: string): void {
    Logger.info(DOMAIN, TAG, `onCastToNormalForm formId=${formId}`);
  }

  /** 卡片是否可创建（READY = 立即可用）。 */
  onAcquireFormState(want: Want): formInfo.FormState {
    Logger.info(DOMAIN, TAG, 'onAcquireFormState');
    return formInfo.FormState.READY;
  }

  /** 重推卡片载荷（onUpdateForm / onSizeChanged 共用）。 */
  private pushForm(formId: string, layout: CardLayout): void {
    const payload: Record<string, string> =
      toCardPayload(buildWidgetCardData(this.context, layout));
    formProvider.updateForm(formId, formBindingData.createFormBindingData(payload))
      .catch((err: BusinessError) => {
        Logger.warn(DOMAIN, TAG, `updateForm failed: ${formId} ${err.message}`);
      });
  }
}
