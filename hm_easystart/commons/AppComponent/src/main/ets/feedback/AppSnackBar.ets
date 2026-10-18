import {
  HdsSnackBar,
  SnackBarIconOptions,
  SnackBarIconType,
  SnackBarMessageOptions,
  SnackBarOperationOptions,
  SnackBarOperationType,
  SnackBarStyleOptions
} from '@kit.UIDesignKit';
import { SymbolGlyphModifier, UIContext } from '@kit.ArkUI';
import { ColorMetrics } from '@ohos.arkui.node';
import { CommonToast } from './CommonToast';

/**
 * AppSnackBar —— 应用级轻反馈条（v3.4，官方 HdsSnackBar 封装，参考 EasyMath 模式）。
 *
 * 【落位注释：为什么在 AppComponent 而不是 VitalUI？】
 * HdsSnackBar 是 HMS 侧组件（@since 6.0.0(20)，deviceTypes 不含 wearable），
 * 且本类的「四档语义时长」（成功 1.5s/警示 3s/错误 4.5s）与容器配色是**本应用的
 * 反馈规范**——换一个 app 这些决策就变（VitalUI 判据：纯结构原语才进组织级库）。
 * 故归 AppComponent（应用级组件公共包，§17.4 AppUI 档）。
 *
 * 【@kit 纪律】HdsSnackBar/SymbolGlyphModifier/ColorMetrics 为 UI 表现组件/类型，
 * 按 F16 应用级域包直接 import @kit.UIDesignKit/@kit.ArkUI/@ohos.arkui.node，
 * 不绕 Platform 转导出（v3.4「Platform 唯一 @kit 出口」倒挂已清账）。
 *
 * 【降级】wearable 不支持 HdsSnackBar（设备矩阵实测）——canIUse 守卫失败时
 * 降级 CommonToast（文本无图标），保证手表链路不崩。
 */
export class AppSnackBar {
  /** 四档语义驻留时长（ms）——本应用反馈规范：成功短驻 1.5s，错误长驻 4.5s。 */
  private static readonly DURATION_SUCCESS: number = 1500;
  private static readonly DURATION_WARNING: number = 3000;
  private static readonly DURATION_ERROR: number = 4500;
  private static readonly DURATION_INFO: number = 2000;

  /** 成功反馈（短驻留 1.5s，success 容器色）。 */
  static success(uiContext: UIContext, content: string, title?: string): void {
    AppSnackBar.show(uiContext, SnackBarIconType.SMALL, $r('sys.symbol.checkmark_circle'),
      $r('app.color.app_success'), content, title,
      $r('app.color.app_success_container'), AppSnackBar.DURATION_SUCCESS);
  }

  /** 警示反馈（3s，warning 容器色）。 */
  static warning(uiContext: UIContext, content: string, title?: string): void {
    AppSnackBar.show(uiContext, SnackBarIconType.SMALL, $r('sys.symbol.exclamationmark_triangle'),
      $r('app.color.app_warning'), content, title,
      $r('app.color.app_warning_container'), AppSnackBar.DURATION_WARNING);
  }

  /** 错误反馈（长驻留 4.5s，danger 容器色）。 */
  static error(uiContext: UIContext, content: string, title?: string): void {
    AppSnackBar.show(uiContext, SnackBarIconType.SMALL, $r('sys.symbol.xmark_circle'),
      $r('app.color.app_danger'), content, title,
      $r('app.color.app_danger_container'), AppSnackBar.DURATION_ERROR);
  }

  /** 中性信息反馈（2s，卡片底色）。 */
  static info(uiContext: UIContext, content: string, title?: string): void {
    AppSnackBar.show(uiContext, SnackBarIconType.SMALL, $r('sys.symbol.info_circle'),
      $r('app.color.app_info'), content, title,
      $r('app.color.app_bg_card'), AppSnackBar.DURATION_INFO);
  }

  /** 统一出口：构造图标/消息/操作/样式并拉起 HdsSnackBar；不支持时降级 Toast。 */
  private static show(uiContext: UIContext, iconType: SnackBarIconType, iconRes: Resource,
    iconColor: ResourceColor, content: string, title: string | undefined,
    backgroundRes: Resource, durationMs: number): void {
    if (!canIUse('SystemCapability.UIDesign.HDSPattern.Standard')) {
      CommonToast.info(content);
      return;
    }
    try {
      const icon: SnackBarIconOptions = {
        icon: iconRes,
        iconType: iconType,
        iconSymbolModifier: new SymbolGlyphModifier(iconRes).fontColor([iconColor])
      };
      const message: SnackBarMessageOptions = {
        content: content,
        title: title,
        contentColor: ColorMetrics.resourceColor(iconColor)
      };
      const operation: SnackBarOperationOptions = {
        operationType: SnackBarOperationType.CLOSE_BUTTON_ONLY
      };
      const style: SnackBarStyleOptions = {
        duration: durationMs,
        backgroundColor: ColorMetrics.resourceColor(backgroundRes)
      };
      const bar: HdsSnackBar = new HdsSnackBar(uiContext);
      bar.show(icon, message, operation, style);
    } catch (err) {
      // HdsSnackBar 面板服务异常时降级文本提示，不中断业务
      CommonToast.info(content);
    }
  }
}
