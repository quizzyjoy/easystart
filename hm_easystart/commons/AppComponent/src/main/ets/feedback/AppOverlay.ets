import { AppSize, AppShadow } from '@quizzyjoy/foundation';
import { UIContext, ComponentContent } from '@quizzyjoy/platform';
import { UiThemeManager } from '@quizzyjoy/vitalui';

/**
 * 悬浮球内容参数（经 ComponentContent 注入全局 @Builder）。
 */
class AppFloatingBallContent {
  icon: Resource = $r('sys.symbol.questionmark_circle');
  onTap: () => void = () => {
  };
  offset: Position = { x: 0, y: 0 };
  /** 圆钮底色：@Builder 是顶层函数、不能读单例也不能用 this，故由 show() 侧读主题注入 */
  tint: ResourceColor = $r('app.color.qj_brand');
  /** 图标前景色（压在 tint 上，按主题亮度自动选深浅） */
  onTint: ResourceColor = $r('app.color.qj_on_brand');
}

/**
 * 全局 @Builder：悬浮球（品牌圆钮 + 图标，点击上抛 onTap）。
 * 外层 Column 撑满 + HitTestMode.Transparent 让空区事件透传到底层（仅悬浮球本体命中）。
 */
@Builder
function appFloatingBallBuilder(content: AppFloatingBallContent) {
  Column() {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph(content.icon)
        .fontSize(AppSize.ICON_LG)
        .fontColor([content.onTint])
    }
    .width(AppSize.TOUCH_STANDARD)
    .height(AppSize.TOUCH_STANDARD)
    .backgroundColor(content.tint)
    .shadow(AppShadow.MD)
    .onClick((): void => {
      content.onTap();
    })
  }
  .position(content.offset)
  .focusable(false)
  .width('100%')
  .height('100%')
  .hitTestBehavior(HitTestMode.Transparent)
}

/**
 * AppOverlay —— 应用级悬浮球（OverlayManager 常驻悬浮封装）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * OverlayManager 是系统浮层能力（Page 之上、Dialog 之下），其「品牌圆钮 + 图标 + 位置 +
 * 点击语义」是应用规范——本封装把 getOverlayManager + ComponentContent + add/remove
 * 收口为 show/dismiss 静态方法，换一个 app 悬浮球样式与交互就变 → 应用级。
 *
 * 【用法】AppOverlay.show(this.getUIContext(), $r('sys.symbol.gearshape_fill'),
 *   () => { ... }, { x: 16, y: 120 });
 *         关闭：AppOverlay.dismiss(this.getUIContext());
 *
 * 【@kit 纪律】ComponentContent/wrapBuilder 为全局类型；OverlayManager 经 uiContext
 * 方法获取（类型推断）；零直接 @kit import。
 */
export class AppOverlay {
  private static contentNode: ComponentContent<AppFloatingBallContent> | undefined = undefined;

  /** 显示悬浮球（重复调用先关闭旧的；offset 为绝对位置，默认右上角）。 */
  static show(uiContext: UIContext, icon: Resource, onTap: () => void, offset?: Position): void {
    AppOverlay.dismiss(uiContext);
    const content: AppFloatingBallContent = new AppFloatingBallContent();
    content.icon = icon;
    content.onTap = onTap;
    content.offset = offset ?? { x: 16, y: 120 };
    // 徽标色跟随运行时主题（v3.44）：顶层 @Builder 读不到单例，故在调用侧取值注入
    const theme: UiThemeManager = UiThemeManager.getInstance();
    content.tint = theme.brandColor();
    content.onTint = theme.onBrandColor();
    AppOverlay.contentNode = new ComponentContent(uiContext, wrapBuilder(appFloatingBallBuilder), content);
    uiContext.getOverlayManager().addComponentContent(AppOverlay.contentNode, 0);
  }

  /** 关闭悬浮球。 */
  static dismiss(uiContext: UIContext): void {
    if (AppOverlay.contentNode !== undefined) {
      uiContext.getOverlayManager().removeComponentContent(AppOverlay.contentNode);
      AppOverlay.contentNode = undefined;
    }
  }
}
