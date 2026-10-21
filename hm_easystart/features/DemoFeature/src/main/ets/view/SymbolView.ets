import { AppFontSize, AppFontWeight, AppRadius, AppSpacing, DesignToken, Logger } from '@quizzyjoy/foundation';
import { BreakpointManager, WindowAdapter } from '@quizzyjoy/platform';
import { UiThemeManager } from '@quizzyjoy/vitalui';

/**
 * Symbol 能力一览（v3.47，开发工具「环境与能力」组第四项）。
 *
 * 系统 SymbolGlyph 的可调能力逐块放真控件对照（不写死截图）：
 * 1. **渲染策略** `renderingStrategy`：SINGLE / MULTIPLE_COLOR / MULTIPLE_OPACITY
 * 2. **多色分层** `fontColor(Array<ResourceColor>)`：颜色按符号层级依次生效
 * 3. **动效策略** `effectStrategy`：NONE / SCALE / HIERARCHICAL
 * 4. **symbolEffect 六类**：Scale / Bounce / Pulse / Hierarchical / Appear·Disappear / Replace
 * 5. **字重与尺寸**、6. **阴影** `symbolShadow`（API 20 起）
 *
 * 依据：本机 `ets/component/symbolglyph.d.ts` + 官方文档 ts-basic-components-symbolglyph（MCP 检索）。
 */
@ComponentV2
export struct SymbolView {
  @Local theme: UiThemeManager = UiThemeManager.getInstance();
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();

  /** Pulse / Hierarchical / Appear 共用：isActive 重载，true 播放、false 停止。 */
  @Local playing: boolean = false;
  /** Scale / Bounce：triggerValue 重载，每次 +1 播一次。 */
  @Local scaleTrigger: number = 0;
  @Local bounceTrigger: number = 0;
  /** Replace：图标在两者之间切换，三个替换方式各有独立 trigger。 */
  @Local replaceFlag: boolean = false;
  @Local replaceTriggerA: number = 0;
  @Local replaceTriggerB: number = 0;
  @Local replaceTriggerC: number = 0;

  /** 阴影参数（ShadowOptions 需显式类型；build() 内不能声明局部变量）。 */
  private shadowOpts: ShadowOptions = { radius: 6, color: '#4D000000', offsetX: 2, offsetY: 3 };

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  /** 三层调色板：第一个颜色被单色策略使用，二三色用于多色/分层。 */
  private layerColors(): ResourceColor[] {
    return [this.theme.brandColor(), $r('app.color.app_accent_teal'), $r('app.color.app_accent_pink')];
  }

  private togglePlaying(): void {
    this.playing = !this.playing;
    Logger.info('0xD001', 'SymbolView', `symbol effect playing=${this.playing}`);
  }

  build() {
    Scroll() {
      Column({ space: DesignToken.sectionSpacing() }) {
        // —— 说明 ——
        Column({ space: AppSpacing.XS }) {
          Text('Symbol 能力一览')
            .fontSize(AppFontSize.BODY)
            .fontWeight(AppFontWeight.MEDIUM)
            .fontColor($r('app.color.app_text_primary'))
            .width('100%')
          Text('系统符号不止是矢量图标：支持多色分层、三档动效策略、六类可编程动效、字重尺寸与阴影。' +
            '下面每一项都是可点的真控件。')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(AppSpacing.LG)
        .borderRadius(AppRadius.XL)
        .backgroundColor($r('app.color.app_bg_card'))

        // —— ① 渲染策略 × ② 多色分层 ——
        Column({ space: AppSpacing.MD }) {
          this.sectionTitle('① 渲染策略 × ② 多色分层',
            'renderingStrategy(SINGLE / MULTIPLE_COLOR / MULTIPLE_OPACITY) + fontColor([主色, 副色, 强调色])')
          Row() {
            this.renderCell('单色', 'SINGLE', SymbolRenderingStrategy.SINGLE)
            this.renderCell('多色', 'MULTIPLE_COLOR', SymbolRenderingStrategy.MULTIPLE_COLOR)
            this.renderCell('分层', 'MULTIPLE_OPACITY', SymbolRenderingStrategy.MULTIPLE_OPACITY)
          }
          .width('100%')

          Text('同一颗 folder_badge_plus：SINGLE 只吃第一个颜色；MULTIPLE_COLOR 按层取三色；' +
            'MULTIPLE_OPACITY 用第一色的不同透明度区分层级。')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(AppSpacing.LG)
        .borderRadius(AppRadius.XL)
        .backgroundColor($r('app.color.app_bg_card'))

        // —— ③ effectStrategy ——
        Column({ space: AppSpacing.MD }) {
          this.sectionTitle('③ 动效策略 effectStrategy', 'NONE / SCALE（整体缩放）/ HIERARCHICAL（按层依次）')
          Row() {
            this.strategyCell('NONE', SymbolEffectStrategy.NONE)
            this.strategyCell('SCALE', SymbolEffectStrategy.SCALE)
            this.strategyCell('HIERARCHICAL', SymbolEffectStrategy.HIERARCHICAL)
          }
          .width('100%')

          Text('这是「强调动效」的默认策略（点击系统按钮时常见）；要精确控制播放时机请用下面的 symbolEffect。')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(AppSpacing.LG)
        .borderRadius(AppRadius.XL)
        .backgroundColor($r('app.color.app_bg_card'))

        // —— ④ symbolEffect 六类 ——
        Column({ space: AppSpacing.MD }) {
          this.sectionTitle('④ symbolEffect 六类动效', '两个重载：isActive 控制播放态 / triggerValue 触发一次；点击标签试')

          Flex({ wrap: FlexWrap.Wrap }) {
            this.triggerCell('Scale', $r('sys.symbol.heart_fill'),
              new ScaleSymbolEffect(EffectScope.WHOLE, EffectDirection.UP), this.scaleTrigger, (): void => {
                this.scaleTrigger = this.scaleTrigger + 1;
              })
            this.triggerCell('Bounce', $r('sys.symbol.arrow_clockwise'),
              new BounceSymbolEffect(EffectScope.WHOLE, EffectDirection.UP), this.bounceTrigger, (): void => {
                this.bounceTrigger = this.bounceTrigger + 1;
              })
            this.activeCell('Pulse', $r('sys.symbol.bolt_fill'), new PulseSymbolEffect())
            this.activeCell('Hierarchical', $r('sys.symbol.gearshape_fill'),
              new HierarchicalSymbolEffect(EffectFillStyle.ITERATIVE))
            this.activeCell('Appear', $r('sys.symbol.star_fill'), new AppearSymbolEffect(EffectScope.WHOLE))
            this.activeCell('Disappear', $r('sys.symbol.bookmark_fill'), new DisappearSymbolEffect(EffectScope.WHOLE))
          }
          .width('100%')

          this.replaceBlock()
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(AppSpacing.LG)
        .borderRadius(AppRadius.XL)
        .backgroundColor($r('app.color.app_bg_card'))

        // —— ⑤ 字重与尺寸 ——
        Column({ space: AppSpacing.MD }) {
          this.sectionTitle('⑤ 字重与尺寸', 'fontWeight 与 fontSize 对同一符号的视觉差异（符号字体的实心/描边由字重决定）')
          Row() {
            this.weightCell('Lighter', FontWeight.Lighter)
            this.weightCell('Normal', FontWeight.Normal)
            this.weightCell('Bold', FontWeight.Bold)
          }
          .width('100%')

          Row() {
            this.sizeCell(32)
            this.sizeCell(48)
            this.sizeCell(72)
          }
          .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(AppSpacing.LG)
        .borderRadius(AppRadius.XL)
        .backgroundColor($r('app.color.app_bg_card'))

        // —— ⑥ 阴影 ——
        Column({ space: AppSpacing.MD }) {
          this.sectionTitle('⑥ 阴影 symbolShadow', 'API 20 起支持；带阴影的符号适合做空态插画的主体')
          SymbolGlyph($r('sys.symbol.star_fill'))
            .fontSize(72)
            .fontColor([this.theme.brandColor()])
            .symbolShadow(this.shadowOpts)
          Text('symbolShadow({ radius: 6, color: #4D000000, offsetX: 2, offsetY: 3 })')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(AppSpacing.LG)
        .borderRadius(AppRadius.XL)
        .backgroundColor($r('app.color.app_bg_card'))

        // —— ⑦ 常用符号速查 ——
        Column({ space: AppSpacing.MD }) {
          this.sectionTitle('⑦ 常用符号速查', '图下标注 sys.symbol 名；名称都在本机 SDK 编译期校验过，可直接复制使用')
          Flex({ wrap: FlexWrap.Wrap }) {
            this.sampleCell('gearshape_fill', $r('sys.symbol.gearshape_fill'))
            this.sampleCell('heart_fill', $r('sys.symbol.heart_fill'))
            this.sampleCell('star_fill', $r('sys.symbol.star_fill'))
            this.sampleCell('person_crop_circle_fill', $r('sys.symbol.person_crop_circle_fill'))
            this.sampleCell('magnifyingglass', $r('sys.symbol.magnifyingglass'))
            this.sampleCell('calendar', $r('sys.symbol.calendar'))
            this.sampleCell('camera_fill', $r('sys.symbol.camera_fill'))
            this.sampleCell('envelope_fill', $r('sys.symbol.envelope_fill'))
            this.sampleCell('bookmark_fill', $r('sys.symbol.bookmark_fill'))
            this.sampleCell('bolt_fill', $r('sys.symbol.bolt_fill'))
            this.sampleCell('arrow_clockwise', $r('sys.symbol.arrow_clockwise'))
            this.sampleCell('share', $r('sys.symbol.share'))
          }
          .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(AppSpacing.LG)
        .borderRadius(AppRadius.XL)
        .backgroundColor($r('app.color.app_bg_card'))
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

  @Builder
  sectionTitle(title: string, hint: string) {
    Column({ space: AppSpacing.XXS }) {
      Text(title)
        .fontSize(AppFontSize.BODY_SM)
        .fontWeight(AppFontWeight.MEDIUM)
        .fontColor($r('app.color.app_text_primary'))
        .width('100%')
      Text(hint)
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_tertiary'))
        .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  renderCell(short: string, code: string, strategy: SymbolRenderingStrategy) {
    Column({ space: AppSpacing.XXS }) {
      SymbolGlyph($r('sys.symbol.folder_badge_plus'))
        .fontSize(56)
        .renderingStrategy(strategy)
        .fontColor(this.layerColors())
      Text(short)
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_secondary'))
        .maxLines(1)
      Text(code)
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_tertiary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  strategyCell(label: string, strategy: SymbolEffectStrategy) {
    Column({ space: AppSpacing.XXS }) {
      SymbolGlyph($r('sys.symbol.wifi'))
        .fontSize(56)
        .effectStrategy(strategy)
        .fontColor([this.theme.brandColor()])
      Text(label)
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_tertiary'))
        .maxLines(1)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  /** triggerValue 重载：点标签自增，播一次动效。 */
  @Builder
  triggerCell(label: string, icon: Resource, effect: SymbolEffect, trigger: number, onTap: () => void) {
    Column({ space: AppSpacing.XXS }) {
      SymbolGlyph(icon)
        .fontSize(40)
        .fontColor([this.theme.brandColor()])
        .symbolEffect(effect, trigger)
      Text(label)
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_secondary'))
        .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: 2, bottom: 2 })
        .borderRadius(AppRadius.SM)
        .backgroundColor($r('app.color.app_bg_page'))
        .onClick((): void => {
          onTap();
        })
    }
    .width('30%')
    .alignItems(HorizontalAlign.Center)
    .margin({ bottom: AppSpacing.MD })
  }

  /** isActive 重载：点一次开、再点一次停。 */
  @Builder
  activeCell(label: string, icon: Resource, effect: SymbolEffect) {
    Column({ space: AppSpacing.XXS }) {
      SymbolGlyph(icon)
        .fontSize(40)
        .fontColor([this.theme.brandColor()])
        .symbolEffect(effect, this.playing)
      Text(this.playing ? `${label} ▶` : label)
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_secondary'))
        .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: 2, bottom: 2 })
        .borderRadius(AppRadius.SM)
        .backgroundColor(($r('app.color.app_bg_page')))
        .onClick((): void => {
          this.togglePlaying();
        })
    }
    .width('30%')
    .alignItems(HorizontalAlign.Center)
    .margin({ bottom: AppSpacing.MD })
  }

  @Builder
  replaceBlock() {
    Column({ space: AppSpacing.XS }) {
      Text('Replace（三种替换方式）')
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_tertiary'))
        .width('100%')

      Row() {
        Column({ space: AppSpacing.XXS }) {
          SymbolGlyph(this.replaceFlag ? $r('sys.symbol.checkmark_circle') : $r('sys.symbol.repeat_1'))
            .fontSize(40)
            .fontColor([this.theme.brandColor()])
            .symbolEffect(new ReplaceSymbolEffect(EffectScope.WHOLE, ReplaceEffectType.SEQUENTIAL), this.replaceTriggerA)
          Text('SEQUENTIAL')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_secondary'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column({ space: AppSpacing.XXS }) {
          SymbolGlyph(this.replaceFlag ? $r('sys.symbol.checkmark_circle') : $r('sys.symbol.repeat_1'))
            .fontSize(40)
            .fontColor([this.theme.brandColor()])
            .symbolEffect(new ReplaceSymbolEffect(EffectScope.WHOLE, ReplaceEffectType.CROSS_FADE), this.replaceTriggerB)
          Text('CROSS_FADE')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_secondary'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column({ space: AppSpacing.XXS }) {
          SymbolGlyph(this.replaceFlag ? $r('sys.symbol.checkmark_circle') : $r('sys.symbol.repeat_1'))
            .fontSize(40)
            .fontColor([this.theme.brandColor()])
            .symbolEffect(new ReplaceSymbolEffect(EffectScope.LAYER, ReplaceEffectType.SLASH_OVERLAY),
              this.replaceTriggerC)
          Text('SLASH_OVERLAY')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_secondary'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')

      Text('切换图标并播放替换动效')
        .fontSize(AppFontSize.CAPTION)
        .fontColor(this.theme.onBrandColor())
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding({ top: AppSpacing.SM, bottom: AppSpacing.SM })
        .borderRadius(AppRadius.MD)
        .backgroundColor(this.theme.brandColor())
        .onClick((): void => {
          this.replaceFlag = !this.replaceFlag;
          this.replaceTriggerA = this.replaceTriggerA + 1;
          this.replaceTriggerB = this.replaceTriggerB + 1;
          this.replaceTriggerC = this.replaceTriggerC + 1;
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  weightCell(label: string, weight: FontWeight) {
    Column({ space: AppSpacing.XXS }) {
      SymbolGlyph($r('sys.symbol.info_circle'))
        .fontSize(48)
        .fontWeight(weight)
        .fontColor([this.theme.brandColor()])
      Text(label)
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_tertiary'))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  sizeCell(size: number) {
    Column({ space: AppSpacing.XXS }) {
      SymbolGlyph($r('sys.symbol.star_fill'))
        .fontSize(size)
        .fontColor([this.theme.brandColor()])
      Text(`${size}vp`)
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_tertiary'))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  sampleCell(name: string, icon: Resource) {
    Column({ space: AppSpacing.XXS }) {
      SymbolGlyph(icon)
        .fontSize(28)
        .fontColor([$r('app.color.app_text_secondary')])
      Text(name)
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_tertiary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('25%')
    .alignItems(HorizontalAlign.Center)
    .margin({ bottom: AppSpacing.MD })
  }
}
