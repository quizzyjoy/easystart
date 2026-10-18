import { AppFontSize, AppFontWeight, AppRadius, AppSpacing } from '@quizzyjoy/foundation';
import { BreakpointManager, CapabilityManager, DeviceManager, FormFactor, HapticManager, WindowAdapter } from '@quizzyjoy/platform';
import { ArcDotIndicator, ArcDirection, ArcSwiper, ArcSwiperController } from '@kit.ArkUI';
import { CardLaunchTarget } from '../model/CardLaunchTarget';
import { WearScreenUtil } from '../utils/WearScreenUtil';

/**
 * 手表独立入口首页（v3.27 升级为**手表范式页**）。
 *
 * 【依赖瘦身 · 必读】本模块只依赖 Foundation / Platform，**不依赖 VitalUI / AppComponent / feature**：
 * 手表放弃组件库复用，换取更小包体与更简单渲染路径（指南 §16 有体积实证）。
 * 页面一律用原生原语 + AppScope 令牌；圆/方屏与尺寸分级由本入口 `utils/WearScreenUtil` 提供。
 *
 * 【圆/方屏双适配（手表平台最佳实践）】
 * - 圆形屏：`ArcSwiper` + `ArcDotIndicator`（**弧屏**滑动容器），每页外包圆形容器裁切，
 *   避免方形内容在圆屏上被切角显得突兀；
 * - 方形屏：`Swiper` + `DotIndicator`，不做裁切；
 * - 两者都接表冠（`digitalCrownSensitivity`）；无 Tab（HDS 例外 E2，已登记）。
 *
 * 【四页范式】能力与 Token 面板（含屏幕形状/分级实测）→ 列表范式（原生 List + 触感 + 48vp 触摸目标）
 * → 圆环进度（原生 Progress + 手势/按钮改值）→ 边界说明（fork 指引）。
 *
 * 【卡片深链】手表卡片点击 → Ability 寄存 target='panel' → 本页 onPageShow 定位到面板页。
 */
const PAGE_PANEL: number = 0;
const PAGE_LIST: number = 1;
const PAGE_PROGRESS: number = 2;
const PAGE_BOUNDARY: number = 3;

/** 指示器颜色（圆/方屏共用一套）。 */
const INDICATOR_SELECTED: number = 0xFF0A59F7;
const INDICATOR_NORMAL: number = 0x66FFFFFF;

/** 列表范式示例条目。 */
const LIST_ITEMS: string[] = ['触感反馈示例', '触摸目标 48vp', '列表间距 Token', '原生原语范式'];

@Entry
@ComponentV2
struct WearableIndex {
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  @Local isRound: boolean = false;
  @Local currentIndex: number = PAGE_PANEL;
  @Local progressValue: number = 60;
  @Local listTapText: string = '';
  private arcController: ArcSwiperController = new ArcSwiperController();
  private swiperController: SwiperController = new SwiperController();
  private arcIndicator: ArcDotIndicator = new ArcDotIndicator()
    .arcDirection(ArcDirection.SIX_CLOCK_DIRECTION)
    .itemColor(INDICATOR_NORMAL)
    .selectedItemColor(INDICATOR_SELECTED);
  private squareIndicator: DotIndicator = new DotIndicator()
    .color(INDICATOR_NORMAL)
    .selectedColor(INDICATOR_SELECTED);

  aboutToAppear(): void {
    this.isRound = WearScreenUtil.isRound();
    // 卡片深链：注册消费者（应用已在前台时 onNewWant 不会重触发 onPageShow）
    CardLaunchTarget.setConsumer((): void => {
      this.handleCardLaunch();
    });
  }

  aboutToDisappear(): void {
    CardLaunchTarget.clearConsumer();
  }

  /** 页面可见时消费卡片深链（冷启动路径；取走即清空）。 */
  onPageShow(): void {
    this.handleCardLaunch();
  }

  /** 深链处理（冷启动 + 前台通知两条路径共用；无目标时 take 返回空串）。 */
  private handleCardLaunch(): void {
    const target: string = CardLaunchTarget.take();
    if (target === 'panel') {
      this.goTo(PAGE_PANEL);
    }
  }

  private goTo(index: number): void {
    if (this.isRound) {
      const diff: number = index - this.currentIndex;
      for (let i = 0; i < diff; i++) {
        this.arcController.showNext();
      }
      for (let i = 0; i < -diff; i++) {
        this.arcController.showPrevious();
      }
    } else {
      this.swiperController.changeIndex(index, true);
    }
    this.currentIndex = index;
  }

  private formFactor(): string {
    const factor: FormFactor = DeviceManager.getFormFactor(this.breakpoint.breakpoint, false);
    if (factor === FormFactor.COMPACT) {
      return 'COMPACT';
    }
    if (factor === FormFactor.EXPANDED) {
      return 'EXPANDED';
    }
    return 'MEDIUM';
  }

  @Builder
  statLine(label: string, value: string) {
    Row({ space: AppSpacing.XS }) {
      Text(label)
        .fontSize(AppFontSize.CAPTION_XS)
        .fontWeight(AppFontWeight.MEDIUM)
        .fontColor($r('app.color.app_text_secondary'))
      Blank()
      Text(value)
        .fontSize(AppFontSize.CAPTION_XS)
        .fontWeight(AppFontWeight.MEDIUM)
        .fontColor($r('app.color.app_text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  /** 页 1：能力与 Token 面板（含屏幕形状与尺寸分级实测值）。 */
  @Builder
  panelPage() {
    Scroll() {
      Column({ space: AppSpacing.XS }) {
        Text($r('app.string.app_name'))
          .fontSize(AppFontSize.BODY)
          .fontWeight(AppFontWeight.BOLD)
          .fontColor($r('app.color.app_text_primary'))
          .width('100%')
        Text(`device=${CapabilityManager.getDeviceType()} · bp=${this.breakpoint.breakpoint} · ${this.formFactor()}`)
          .fontSize(AppFontSize.CAPTION_XS)
          .fontColor($r('app.color.app_text_secondary'))
          .width('100%')

        Divider().color($r('app.color.app_divider')).margin({ top: AppSpacing.XXS, bottom: AppSpacing.XXS })

        // 屏幕适配实测（WearScreenUtil 的真相可视化）
        this.statLine('屏幕形状', this.isRound ? '圆形' : '方形')
        this.statLine('尺寸分级', WearScreenUtil.sizeBucket())
        this.statLine('屏幕尺寸', `${Math.round(WearScreenUtil.screenWidthVp())}×${Math.round(WearScreenUtil.screenHeightVp())}vp`)
        this.statLine('安全边距', `${WearScreenUtil.safePadding()}vp`)
        this.statLine('内容区宽', WearScreenUtil.contentWidthRatio())
        this.statLine('触摸目标', `${WearScreenUtil.minTouchSize()}vp`)
        this.statLine('列表间距', `${WearScreenUtil.listItemSpace()}vp`)

        Divider().color($r('app.color.app_divider')).margin({ top: AppSpacing.XXS, bottom: AppSpacing.XXS })

        this.statLine('窗口', `${Math.round(this.breakpoint.windowWidthVp)}×${Math.round(this.breakpoint.windowHeightVp)}`)
        this.statLine('栅格', `${this.breakpoint.gridColumns()} 列`)
        this.statLine('API', `${CapabilityManager.SDK_API_VERSION}`)
      }
      .width(WearScreenUtil.contentWidthRatio())
      .alignItems(HorizontalAlign.Start)
      .padding({ top: WearScreenUtil.safePadding(), bottom: WearScreenUtil.safePadding() })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
  }

  /** 页 2：列表范式（原生 List + 48vp 触摸目标 + 触感反馈 + Token 间距）。 */
  @Builder
  listPage() {
    Column({ space: AppSpacing.XS }) {
      Text('列表范式')
        .fontSize(AppFontSize.BODY)
        .fontWeight(AppFontWeight.BOLD)
        .fontColor($r('app.color.app_text_primary'))
        .width('100%')
      Text(`原生 List / ListItem · 触摸目标 ≥${WearScreenUtil.minTouchSize()}vp · 间距 ${WearScreenUtil.listItemSpace()}vp`)
        .fontSize(AppFontSize.CAPTION_XS)
        .fontColor($r('app.color.app_text_secondary'))
        .width('100%')

      List({ space: WearScreenUtil.listItemSpace() }) {
        ForEach(LIST_ITEMS, (item: string) => {
          ListItem() {
            Text(item)
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_primary'))
              .width('100%')
              .height(WearScreenUtil.minTouchSize())
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .borderRadius(AppRadius.MD)
          .backgroundColor($r('app.color.app_bg_card'))
          .onClick(() => {
            // 触感反馈：机制在 Platform（HapticManager），页面只表达意图
            HapticManager.getInstance().light();
            this.listTapText = `已点击：${item}`;
          })
        }, (item: string) => item)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      Text(this.listTapText.length > 0 ? this.listTapText : '点击条目触发轻触感反馈')
        .fontSize(AppFontSize.CAPTION_XS)
        .fontColor($r('app.color.app_text_tertiary'))
        .maxLines(1)
        .width('100%')
    }
    .width(WearScreenUtil.contentWidthRatio())
    .height('100%')
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .padding({ top: WearScreenUtil.safePadding(), bottom: WearScreenUtil.safePadding() })
  }

  /** 页 3：圆环进度（原生 Progress + 按钮改值）。 */
  @Builder
  progressPage() {
    Column({ space: AppSpacing.SM }) {
      Text('圆环进度')
        .fontSize(AppFontSize.BODY)
        .fontWeight(AppFontWeight.BOLD)
        .fontColor($r('app.color.app_text_primary'))
        .width('100%')

      Stack() {
        Progress({ value: this.progressValue, total: 100, type: ProgressType.Ring })
          .width(WearScreenUtil.scaledSize(140))
          .height(WearScreenUtil.scaledSize(140))
          .color($r('app.color.qj_brand'))
          .style({ strokeWidth: WearScreenUtil.scaledSize(12) })
        Text(`${this.progressValue}`)
          .fontSize(WearScreenUtil.resultFontSize() * 0.5)
          .fontWeight(AppFontWeight.LIGHT)
          .fontColor($r('app.color.app_text_primary'))
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Center)

      Row({ space: AppSpacing.SM }) {
        Button('-10')
          .fontSize(AppFontSize.CAPTION)
          .height(WearScreenUtil.minTouchSize())
          .layoutWeight(1)
          .backgroundColor($r('app.color.app_fill_medium'))
          .fontColor($r('app.color.app_text_primary'))
          .onClick(() => {
            this.progressValue = Math.max(0, this.progressValue - 10);
            HapticManager.getInstance().light();
          })
        Button('+10')
          .fontSize(AppFontSize.CAPTION)
          .height(WearScreenUtil.minTouchSize())
          .layoutWeight(1)
          .backgroundColor($r('app.color.qj_brand'))
          .fontColor($r('app.color.app_text_on_brand'))
          .onClick(() => {
            this.progressValue = Math.min(100, this.progressValue + 10);
            HapticManager.getInstance().medium();
          })
      }
      .width('100%')
    }
    .width(WearScreenUtil.contentWidthRatio())
    .height('100%')
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .padding({ top: WearScreenUtil.safePadding(), bottom: WearScreenUtil.safePadding() })
  }

  /** 页 4：边界说明（fork 指引）。 */
  @Builder
  boundaryPage() {
    Scroll() {
      Column({ space: AppSpacing.XS }) {
        Text('手表边界与 fork 指引')
          .fontSize(AppFontSize.BODY)
          .fontWeight(AppFontWeight.BOLD)
          .fontColor($r('app.color.app_text_primary'))
          .width('100%')
        Text('· 本入口**不引 VitalUI / AppComponent / feature**（体积瘦身，实测增量可控）；')
          .fontSize(AppFontSize.CAPTION_XS)
          .fontColor($r('app.color.app_text_secondary'))
          .width('100%')
        Text('· 圆/方屏与尺寸 Token 收口在本入口 utils/WearScreenUtil（形态专属适配的例外登记）；')
          .fontSize(AppFontSize.CAPTION_XS)
          .fontColor($r('app.color.app_text_secondary'))
          .width('100%')
        Text('· 设置域 / 强调色 / 主题化控件工厂**主动不接入**手表（指南 §5.2 既有主动设计）；')
          .fontSize(AppFontSize.CAPTION_XS)
          .fontColor($r('app.color.app_text_secondary'))
          .width('100%')
        Text('· 服务卡片：手表规格按官方文档收敛为 2×2（详见 form_config.json）；')
          .fontSize(AppFontSize.CAPTION_XS)
          .fontColor($r('app.color.app_text_secondary'))
          .width('100%')
        Text('· 设置能力可按「列表行进入单页」的范式扩展。')
          .fontSize(AppFontSize.CAPTION_XS)
          .fontColor($r('app.color.app_text_secondary'))
          .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ top: WearScreenUtil.safePadding(), bottom: WearScreenUtil.safePadding() })
    }
    .width(WearScreenUtil.contentWidthRatio())
    .height('100%')
    .scrollBar(BarState.Off)
  }

  /**
   * 四页（圆/方屏共用）。页框逐页显式书写——`@Builder` 不支持把 builder 作为参数传入
   * （编译期报 "does not meet UI component syntax"）；四段重复属入口样板判例（同样例子页标题栏）。
   * 圆形屏按屏宽裁圆（内接），方屏不裁。
   */
  @Builder
  pages() {
    Stack() {
      this.panelPage()
    }
    .width('100%')
    .height('100%')
    .borderRadius(this.isRound ? WearScreenUtil.screenWidthVp() / 2 : 0)
    .clip(this.isRound)
    .backgroundColor($r('app.color.app_bg_page'))

    Stack() {
      this.listPage()
    }
    .width('100%')
    .height('100%')
    .borderRadius(this.isRound ? WearScreenUtil.screenWidthVp() / 2 : 0)
    .clip(this.isRound)
    .backgroundColor($r('app.color.app_bg_page'))

    Stack() {
      this.progressPage()
    }
    .width('100%')
    .height('100%')
    .borderRadius(this.isRound ? WearScreenUtil.screenWidthVp() / 2 : 0)
    .clip(this.isRound)
    .backgroundColor($r('app.color.app_bg_page'))

    Stack() {
      this.boundaryPage()
    }
    .width('100%')
    .height('100%')
    .borderRadius(this.isRound ? WearScreenUtil.screenWidthVp() / 2 : 0)
    .clip(this.isRound)
    .backgroundColor($r('app.color.app_bg_page'))
  }

  build() {
    Column() {
      if (this.isRound) {
        // 圆形屏：弧屏滑动 + 环形指示器 + 表冠
        ArcSwiper(this.arcController) {
          this.pages()
        }
        .width('100%')
        .height('100%')
        .index(this.currentIndex)
        .vertical(false)
        .duration(300)
        .digitalCrownSensitivity(CrownSensitivity.MEDIUM)
        .indicator(this.arcIndicator)
        .onChange((index: number) => {
          this.currentIndex = index;
        })
      } else {
        // 方形屏：标准滑动 + 圆点指示器（Swiper 无 digitalCrownSensitivity，表冠特性仅弧屏容器提供）
        Swiper(this.swiperController) {
          this.pages()
        }
        .width('100%')
        .height('100%')
        .index(this.currentIndex)
        .vertical(false)
        .duration(300)
        .indicator(this.squareIndicator)
        .onChange((index: number) => {
          this.currentIndex = index;
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg_page'))
  }
}
