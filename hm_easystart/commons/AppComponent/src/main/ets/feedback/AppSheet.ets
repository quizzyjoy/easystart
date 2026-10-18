import { AppFontSize, AppFontWeight, AppRadius, AppShadow, AppSpacing } from '@quizzyjoy/foundation';

/** 应用级 Sheet 配置（bindSheet 选项的应用预设，未提供项走本应用默认）。 */
export interface AppSheetConfig {
  /** 首档高度档（默认 LARGE，二档恒 MEDIUM） */
  detent?: SheetSize;
  /** 关闭回调 */
  onDisappear?: () => void;
}

/**
 * AppSheet —— 应用级通用半模态容器（v3.4，参考 EasyMath appSheetOptions 工厂模式）。
 *
 * 【落位注释：为什么在 AppComponent 而 CommonColorPickerSheet 在 VitalUI？】
 * 本组件承载**本应用的 sheet 统一规范**：底色 bg_elevated（浮层底档）、detents 双档
 * 策略、dragBar + 底部形态、标题栏结构（标题 + 右侧关闭钮）——换一个 app 这些
 * 规范就变 → 应用级 AppComponent。CommonColorPickerSheet 是取色器域件（组织级
 * VitalUI，随取色器跨 app 复用）；SheetOptions/SheetSize/SheetType 均为全局类型，
 * 本文件零 @kit。
 *
 * 用法：宿主 `bindSheet($$this.show, this.sheetBuilder, AppSheetOptions.bind({...))` +
 * 内容用 AppSheetContainer（标题栏 + 内容插槽，关闭经 @Event onClose 上抛宿主置 false）。
 */
export class AppSheetOptions {
  /** 生成应用规范 bindSheet 选项（elevated 底色、双档 detents、dragBar）。 */
  static bind(config?: AppSheetConfig): SheetOptions {
    const options: SheetOptions = {
      detents: config?.detent !== undefined ? [config.detent, SheetSize.MEDIUM] : [SheetSize.LARGE, SheetSize.MEDIUM],
      showClose: false,
      preferType: SheetType.BOTTOM,
      dragBar: true,
      backgroundColor: $r('app.color.app_bg_elevated'),
      onDisappear: (): void => {
        if (config?.onDisappear !== undefined) {
          config.onDisappear();
        }
      }
    };
    return options;
  }
}

/**
 * AppSheetContainer —— sheet 内容容器：标题栏（标题 + 关闭钮）+ 内容插槽。
 * 【落位注释】标题栏字号/排布/关闭交互属应用规范；关闭动作经 @Event onClose
 * 上抛宿主（宿主持 bindSheet 显隐状态），组件不自持窗口状态。
 */
@ComponentV2
export struct AppSheetContainer {
  @Param sheetTitle: string = '';
  @BuilderParam contentBuilder: () => void = this.emptyContent;
  @Event onClose: () => void = () => {
  };

  @Builder
  emptyContent() {
  }

  build() {
    Column() {
      Row({ space: AppSpacing.SM }) {
        Text(this.sheetTitle)
          .fontSize(AppFontSize.TITLE)
          .fontWeight(AppFontWeight.BOLD)
          .fontColor($r('app.color.app_text_primary'))
          .layoutWeight(1)
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(AppFontSize.TITLE)
          .fontColor([$r('app.color.app_text_secondary')])
          .padding(AppSpacing.MD)
          .borderRadius(AppRadius.FULL)
          .onClick(() => {
            this.onClose();
          })
      }
      .width('100%')
      .padding({ left: AppSpacing.LG, right: AppSpacing.LG, top: AppSpacing.MD, bottom: AppSpacing.SM })
      Divider()
        .color($r('app.color.app_divider'))
      Column() {
        this.contentBuilder()
      }
      .width('100%')
      .layoutWeight(1)
      .padding(AppSpacing.LG)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg_elevated'))
    .shadow(AppShadow.SM)
  }
}
