import { ActionCard, CommonButton, CommonTag, ButtonVariant, TagTone } from '@easystart/app-component';
import { AppFontSize, AppFontWeight, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, WindowAdapter } from '@quizzyjoy/platform';

/**
 * 无障碍示例页（独立页，v3.79）。
 *
 * 为什么必须独立成页：无障碍是"同一段界面、两套标注"的对照，
 * 塞进长页只能给一行说明；独立页才能把「错误标注 → 读屏念出来什么 → 正确标注」逐项摆开。
 *
 * 四件套：
 * - `accessibilityText`：读屏念的文案（组件本身没有文字时必须给）
 * - `accessibilityLevel`：'auto' 自动 / 'yes' 可聚焦 / 'no' 跳过
 * - `accessibilityGroup`：把图标+标题+描述合成**一个**焦点，而不是念三遍
 * - `accessibilityDescription`：补充说明（如"按两下可展开"）
 */
@ComponentV2
export struct A11ySampleView {
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  /** 是否启用正确标注（关掉时可直观看到"未标注"的界面） */
  @Local annotate: boolean = true;

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  @Builder
  sectionTitle(text: string) {
    Text(text)
      .fontSize(AppFontSize.TITLE_SM)
      .fontWeight(AppFontWeight.MEDIUM)
      .fontColor($r('app.color.app_text_primary'))
      .width('100%')
      .margin({ top: AppSpacing.SM, bottom: AppSpacing.XS })
  }

  @Builder
  label(text: string) {
    Text(text)
      .fontSize(AppFontSize.CAPTION)
      .fontColor($r('app.color.app_text_tertiary'))
      .width('100%')
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.MD }) {
        Text('无障碍不是"额外加个属性"，而是决定读屏用户能不能用。下面每一组都是「关掉标注」与「正确标注」的对照，可用顶部开关切换。')
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_secondary'))
          .width('100%')

        Row() {
          Text(this.annotate ? '标注：开（正确做法）' : '标注：关（对照用，读屏会念错）')
            .fontSize(AppFontSize.BODY_SM)
            .fontColor(this.annotate ? $r('app.color.qj_brand') : $r('app.color.app_text_tertiary'))
          Blank()
          Row() {
            CommonTag({
              text: this.annotate ? '切换对照' : '恢复标注',
              tone: TagTone.NEUTRAL
            })
          }
          .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XXS, bottom: AppSpacing.XXS })
          .borderRadius(AppRadius.FULL)
          .onClick((): void => {
            this.annotate = !this.annotate;
          })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding(AppSpacing.MD)
        .borderRadius(AppRadius.MD)
        .backgroundColor($r('app.color.app_bg_card'))

        this.sectionTitle('① 纯图标按钮：必须给 accessibilityText')

        this.label('只有图标的按钮若不给文案，读屏只会念"按钮"，用户不知道会触发什么。')

        Row({ space: AppSpacing.MD }) {
          // 未标注：读屏只会念「按钮」
          if (!this.annotate) {
            Button({ type: ButtonType.Circle }) {
              SymbolGlyph($r('sys.symbol.trash'))
                .fontSize(20)
                .fontColor([$r('app.color.app_text_primary')])
            }
            .width(48)
            .height(48)
            .backgroundColor($r('app.color.app_bg_card'))
          } else {
            Button({ type: ButtonType.Circle }) {
              SymbolGlyph($r('sys.symbol.trash'))
                .fontSize(20)
                .fontColor([$r('app.color.app_text_primary')])
            }
            .width(48)
            .height(48)
            .backgroundColor($r('app.color.app_bg_card'))
            .accessibilityText('删除这条记录')
            .accessibilityDescription('删除后不可恢复')
            .accessibilityLevel('yes')
          }

          Text(this.annotate ? '读屏：删除这条记录，删除后不可恢复' : '读屏：按钮（不知道要删什么）')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_secondary'))
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        this.sectionTitle('② 复合卡片：accessibilityGroup 合成一个焦点')

        this.label('图标 + 标题 + 描述是三段文字，不合并时读屏要念三次；accessibilityGroup(true) 会让它成为一个焦点。')

        if (!this.annotate) {
          ActionCard({
            title: '设置中心',
            subtitle: '账号 / 通知 / 关于，共 12 项',
            onAction: (): void => {
            }
          })
        } else {
          ActionCard({
            title: '设置中心',
            subtitle: '账号 / 通知 / 关于，共 12 项',
            onAction: (): void => {
            }
          })
            .accessibilityGroup(true)
            .accessibilityText('设置中心，进入后有 12 项设置')
            .accessibilityLevel('yes')
        }

        this.sectionTitle('③ 装饰元素：accessibilityLevel no 跳过')

        this.label('纯装饰的分隔线 / 背景图不该被读屏聚焦，否则用户要多按很多次才走到有用的元素。')

        Column({ space: AppSpacing.XS }) {
          Text('分组 A')
            .fontSize(AppFontSize.BODY_SM)
            .fontColor($r('app.color.app_text_primary'))
          Divider()
            .color($r('app.color.app_divider'))
            .accessibilityLevel('no')
          Text('分组 B')
            .fontSize(AppFontSize.BODY_SM)
            .fontColor($r('app.color.app_text_primary'))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(AppSpacing.MD)
        .borderRadius(AppRadius.MD)
        .backgroundColor($r('app.color.app_bg_card'))

        this.sectionTitle('④ 图片：不给文案时读屏念文件名')

        this.label('Image 没有 accessibilityText 时，读屏会念资源名（如 startIcon.png），这对用户毫无意义。')

        Row({ space: AppSpacing.SM }) {
          Image($r('app.media.startIcon'))
            .width(40)
            .height(40)
            .borderRadius(AppRadius.SM)
            .accessibilityText(this.annotate ? '应用图标：趣开发' : '')
          Text(this.annotate ? '读屏：应用图标，趣开发' : '读屏：startIcon（念文件名）')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_secondary'))
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        this.sectionTitle('照抄要点')

        Text('1. 组件自身有文字（Text/Button 带 label）时读屏会自动念，不必重复给 accessibilityText；\n2. 只有图标、只有图形、Image 才必须补文案；\n3. 卡片类复合结构用 accessibilityGroup(true) + accessibilityText 一句说完，别让用户按三次；\n4. 装饰元素一律 accessibilityLevel(\'no\')；\n5. 验收：真机开「屏幕朗读」，从页首划到尾，听是否能连续说出每项是什么、能不能操作。')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .constraintSize({ maxWidth: DesignToken.contentMaxWidth(this.bp()) })
      .padding({
        left: DesignToken.pagePadding(this.bp()),
        right: DesignToken.pagePadding(this.bp()),
        top: AppSpacing.LG,
        bottom: DesignToken.tabPageBottomPadding(this.bp(), this.windowAdapter.bottomAvoidVp)
      })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .backgroundColor($r('app.color.app_bg_page'))
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}
