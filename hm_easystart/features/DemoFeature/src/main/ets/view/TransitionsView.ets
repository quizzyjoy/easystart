import { curves } from '@kit.ArkUI';
import { AppFontSize, AppFontWeight, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, WindowAdapter } from '@quizzyjoy/platform';

/** 共享元素转场演示用的条目（id 同时是 sharedTransition 的 key）。 */
export class TransitionCard {
  id: string = '';
  title: string = '';
  desc: string = '';

  constructor(id: string, title: string, desc: string) {
    this.id = id;
    this.title = title;
    this.desc = desc;
  }
}

/** 演示条目数据（列表页与详情页共用，保证 sharedTransition key 一致）。 */
export function transitionCards(): TransitionCard[] {
  return [
    new TransitionCard('c1', '页面级共享元素', '列表卡与详情大图共用同一个 sharedTransition key'),
    new TransitionCard('c2', '跨页容器形变', '同一张卡从列表位置放大到详情位置，内容不做二次布局')
  ];
}

export function transitionCardOrDefault(id: string): TransitionCard {
  const list: TransitionCard[] = transitionCards();
  for (let i = 0; i < list.length; i++) {
    if (list[i].id === id) {
      return list[i];
    }
  }
  return list[0];
}

/**
 * 转场动效合集（v3.42，开发工具第三项从「待实现」转真实现）。
 *
 * 四个可直接对照的演示，全部用 ArkUI 现成能力，不依赖额外三方库：
 * 1. **元素进出**：`TransitionEffect.OPACITY.combine(scale).combine(rotate)` + `.animation()`
 * 2. **曲线对比**：同一个位移，`Curve.Linear / EaseInOut / springMotion` 三曲线并行播放
 * 3. **共享元素**：`.sharedTransition()` 从列表卡转到详情页（`TRANSITION_DETAIL`）
 * 4. **形变与位移**：`animateTo` 改 width/offset 组合（含回弹）
 */
@ComponentV2
export struct TransitionsView {
  @Param onOpenTransitionDetail: (id: string) => void = (_id: string): void => {
  };
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  @Local shown: boolean = true;
  @Local linearX: number = 0;
  @Local easeX: number = 0;
  @Local springX: number = 0;
  @Local morphWide: boolean = false;
  @Local cards: TransitionCard[] = transitionCards();

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  /** 元素进出：出现 / 消失各一套效果（消失走 rotate + 缩小，避免和出现完全同形）。 */
  private enterEffect(): TransitionEffect {
    return TransitionEffect.OPACITY
      .combine(TransitionEffect.scale({ x: 0.6, y: 0.6 }))
      .combine(TransitionEffect.rotate({ angle: 0, z: 90 }))
      .animation({ duration: 320, curve: Curve.Friction });
  }

  private exitEffect(): TransitionEffect {
    return TransitionEffect.asymmetric(
      TransitionEffect.OPACITY.combine(TransitionEffect.scale({ x: 0.6, y: 0.6 })),
      TransitionEffect.OPACITY.combine(TransitionEffect.rotate({ angle: 0, z: -90 }))
    ).animation({ duration: 260, curve: Curve.EaseIn });
  }

  /** 三曲线同场对比：同时启动三段落位动画，位移相同、缓动不同。 */
  private playCurves(): void {
    const uiContext: UIContext = this.getUIContext();
    const target: number = this.linearX === 0 ? 96 : 0;
    uiContext.animateTo({ duration: 700, curve: Curve.Linear }, (): void => {
      this.linearX = target;
    });
    uiContext.animateTo({ duration: 700, curve: Curve.EaseInOut }, (): void => {
      this.easeX = target;
    });
    uiContext.animateTo({ duration: 700, curve: curves.interpolatingSpring(0, 1, 228, 30) }, (): void => {
      this.springX = target;
    });
  }

  build() {
    Scroll() {
      Column({ space: DesignToken.sectionSpacing() }) {
        Text('转场与动效：四种最常用形态，点击卡片内按钮即可对照')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')

        // —— 1. 元素进出 ——
        Column({ space: AppSpacing.MD }) {
          this.cardTitle('① 元素进出', 'TransitionEffect.OPACITY + scale + rotate，进出场用 asymmetric 区分')
          Button(this.shown ? '隐藏方块' : '显示方块')
            .fontSize(AppFontSize.BODY_SM)
            .onClick((): void => {
              // transition 由 if 分支驱动，切换前后包一层 animateTo 只是为了同步其余同帧属性
              this.shown = !this.shown;
            })
          if (this.shown) {
            Column() {
              Text('进出场')
                .fontSize(AppFontSize.CAPTION)
                .fontColor($r('app.color.app_text_on_brand'))
            }
            .width(96)
            .height(64)
            .borderRadius(AppRadius.MD)
            .backgroundColor($r('app.color.qj_brand'))
            .justifyContent(FlexAlign.Center)
            .transition(this.enterEffect())
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(AppSpacing.LG)
        .borderRadius(AppRadius.XL)
        .backgroundColor($r('app.color.app_bg_card'))

        // —— 2. 曲线对比 ——
        Column({ space: AppSpacing.MD }) {
          this.cardTitle('② 缓动曲线对比', '同样 96vp 位移：Linear / EaseInOut / interpolatingSpring 同场播放')
          Button(this.linearX === 0 ? '播放' : '复位')
            .fontSize(AppFontSize.BODY_SM)
            .onClick((): void => {
              this.playCurves();
            })
          // 三行直接内联：@Builder 多参数按值传递不会随状态刷新（ArkUI 已知约束），
          // 这类「跟随动画变化的行」必须写在 build 里直接用 @Local 值。
          Row({ space: AppSpacing.SM }) {
            Text('Linear')
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_tertiary'))
              .width(72)
            Row() {
              Column()
                .width(20)
                .height(20)
                .borderRadius(AppRadius.SM)
                .backgroundColor($r('app.color.app_text_secondary'))
                .offset({ x: this.linearX })
            }
            .layoutWeight(1)
            .height(28)
            .padding({ left: AppSpacing.XXS })
            .borderRadius(AppRadius.SM)
            .backgroundColor($r('app.color.app_bg_page'))
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')

          Row({ space: AppSpacing.SM }) {
            Text('EaseInOut')
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_tertiary'))
              .width(72)
            Row() {
              Column()
                .width(20)
                .height(20)
                .borderRadius(AppRadius.SM)
                .backgroundColor($r('app.color.app_text_secondary'))
                .offset({ x: this.easeX })
            }
            .layoutWeight(1)
            .height(28)
            .padding({ left: AppSpacing.XXS })
            .borderRadius(AppRadius.SM)
            .backgroundColor($r('app.color.app_bg_page'))
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')

          Row({ space: AppSpacing.SM }) {
            Text('Spring')
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_tertiary'))
              .width(72)
            Row() {
              Column()
                .width(20)
                .height(20)
                .borderRadius(AppRadius.SM)
                .backgroundColor($r('app.color.app_text_secondary'))
                .offset({ x: this.springX })
            }
            .layoutWeight(1)
            .height(28)
            .padding({ left: AppSpacing.XXS })
            .borderRadius(AppRadius.SM)
            .backgroundColor($r('app.color.app_bg_page'))
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(AppSpacing.LG)
        .borderRadius(AppRadius.XL)
        .backgroundColor($r('app.color.app_bg_card'))

        // —— 3. 共享元素 ——
        Column({ space: AppSpacing.MD }) {
          this.cardTitle('③ 共享元素转场', 'sharedTransition：点击卡片进入详情，卡片与详情大图共用同一 key')
          ForEach(this.cards, (item: TransitionCard) => {
            Row({ space: AppSpacing.MD }) {
              Column() {
                Text(item.id.toUpperCase())
                  .fontSize(AppFontSize.CAPTION)
                  .fontColor($r('app.color.app_text_on_brand'))
              }
              .width(44)
              .height(44)
              .borderRadius(AppRadius.SM)
              .backgroundColor($r('app.color.qj_brand'))
              .justifyContent(FlexAlign.Center)
              // 关键：列表侧与详情侧的 key 拼法必须一致
              .sharedTransition(`tcard-${item.id}`, { duration: 350, curve: Curve.Friction })

              Column({ space: AppSpacing.XXS }) {
                Text(item.title)
                  .fontSize(AppFontSize.BODY_SM)
                  .fontColor($r('app.color.app_text_primary'))
                  .width('100%')
                Text(item.desc)
                  .fontSize(AppFontSize.CAPTION)
                  .fontColor($r('app.color.app_text_tertiary'))
                  .width('100%')
                  .maxLines(2)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding(AppSpacing.SM)
            .borderRadius(AppRadius.MD)
            .backgroundColor($r('app.color.app_bg_page'))
            .onClick((): void => {
              this.onOpenTransitionDetail(item.id);
            })
          }, (item: TransitionCard): string => item.id)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(AppSpacing.LG)
        .borderRadius(AppRadius.XL)
        .backgroundColor($r('app.color.app_bg_card'))

        // —— 4. 形变 ——
        Column({ space: AppSpacing.MD }) {
          this.cardTitle('④ 形变与位移', 'animateTo 同时改 width 与 offset，看容器与内容如何各自响应')
          Button(this.morphWide ? '收窄' : '展开')
            .fontSize(AppFontSize.BODY_SM)
            .onClick((): void => {
              this.getUIContext().animateTo({ duration: 420, curve: Curve.FastOutSlowIn }, (): void => {
                this.morphWide = !this.morphWide;
              });
            })
          Column() {
            Text(this.morphWide ? '宽态 100%' : '窄态 60%')
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_on_brand'))
          }
          .width(this.morphWide ? '100%' : '60%')
          .height(52)
          .borderRadius(AppRadius.MD)
          .backgroundColor($r('app.color.app_accent_teal'))
          .justifyContent(FlexAlign.Center)
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
  cardTitle(title: string, hint: string) {
    Column({ space: AppSpacing.XXS }) {
      Text(title)
        .fontSize(AppFontSize.BODY)
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

}
