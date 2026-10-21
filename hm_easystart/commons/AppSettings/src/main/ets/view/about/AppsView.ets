import { common } from '@quizzyjoy/platform';
import { AppLauncher, MarketHelper, StoreProductView } from '@quizzyjoy/platform';
import { AppDialog, CommonTag, CommonToast, DialogSemantic, TagTone } from '@easystart/app-component';
import { AppFontSize, AppRadius, AppSpacing, AppFontWeight } from '@quizzyjoy/foundation';
import { AppMatrix, AppMatrixEntry, AppEntryStatus } from '../../model/AppMatrix';

/**
 * 应用矩阵子页（v3.60）：趣开发系列四个应用的聚合展示。
 *
 * 点击行为是一条完整回退链（真机验证过的顺序，见 `handleOpen`）：
 * 1. 本应用（SELF）→ **打开产品官网**（不再跳「关于本应用」，官网信息更全）；
 * 2. 已安装 → 直接拉起目标应用（与上架状态无关）；
 * 3. 未上架 → 弹「应用介绍」半模态（真实介绍段落 + 产品截图 + 官网入口）；
 * 4. 已上架但未安装 → 应用内详情页（可当场下载）→ 市场详情 → 介绍弹窗。
 *
 * 介绍弹窗用 `bindSheet` 半模态而非对话框：截图需要滚动空间，参考数易项目里
 * 临境声场的介绍页做法（名称 + 分段内容 + 大图 + 官网按钮）。
 */
@ComponentV2
export struct AppsView {
  /** 本应用被点击时的额外上抛（保留给宿主做埋点等，默认空实现）。 */
  @Event onOpenSelf: () => void = (): void => {
  };

  /** 介绍半模态是否可见。 */
  @Local showIntroSheet: boolean = false;
  /** 当前介绍的是哪一条（拆成扁平字段，避免嵌套对象观察不到变化）。 */
  @Local introName: ResourceStr = '';
  @Local introDesc: ResourceStr = '';
  @Local introStatus: ResourceStr = '';
  @Local introLines: string[] = [];
  @Local introSite: string = '';
  @Local introBundle: string = '';
  /** 是否显示「打开应用」按钮（未上架应用：装了内测包就能打开）。 */
  @Local introLaunchable: boolean = false;

  /** 包名等宽展示用等宽字体族（不引外部字体，靠 CSS 等宽回退）。 */
  private static readonly MONO_FONT: string = 'HarmonyOS Sans Mono, monospace';

  /**
   * 打开矩阵里的一条。
   *
   * 顺序（v3.56 修正真机问题、v3.60 调整本应用行为与介绍内容）：
   * **先试着打开已安装应用，再按状态降级**。状态只决定"打不开时去哪"。
   */
  private async handleOpen(entry: AppMatrixEntry): Promise<void> {
    // ① 本应用 → 打开产品官网（不再跳「关于本应用」：官网信息更全，且本页已是设置子页）
    if (entry.status === AppEntryStatus.SELF) {
      const opened: boolean = await MarketHelper.getInstance().openUri(AppMatrix.SELF_SITE);
      if (!opened) {
        CommonToast.info($r('app.string.apps_site_open_failed'));
      }
      return;
    }
    const context: common.UIAbilityContext =
      this.getUIContext().getHostContext() as common.UIAbilityContext;
    // ② 未上架 → 直接弹介绍（真实介绍 + 截图 + 「打开应用」/「打开产品官网」双出口）。
    //    待上架应用本来就以"展示 + 内测"为主，不静默跳走更符合预期。
    if (entry.status === AppEntryStatus.UNPUBLISHED) {
      this.showIntro(entry, true);
      return;
    }
    // ③ 已上架 → 已安装就直接打开
    if (await AppLauncher.openApp(context, entry.bundleName)) {
      return;
    }
    // ④ 已上架但未安装 → 应用内详情页 → 市场详情 → 介绍弹窗
    if (StoreProductView.usable()) {
      const shown: boolean = await StoreProductView.loadProductDetail(context, entry.bundleName);
      if (shown) {
        return;
      }
    }
    if (await AppLauncher.openMarket(context, entry.bundleName)) {
      return;
    }
    this.showIntro(entry);
  }

  /**
   * 打开介绍半模态（内容取自 AppMatrix：真实介绍 + 截图 + 官网）。
   *
   * @param withLaunch true 时额外显示「打开应用」按钮（未上架但可能已安装/已装内测包）
   */
  private showIntro(entry: AppMatrixEntry, withLaunch: boolean = false): void {
    this.introLaunchable = withLaunch;
    this.introName = entry.name;
    this.introDesc = entry.desc;
    this.introStatus = entry.statusLabel;
    this.introLines = entry.introLines;
    this.introSite = entry.siteUrl;
    this.introBundle = entry.bundleName;
    this.showIntroSheet = true;
  }

  /** 尝试直接打开目标应用（未安装时提示，不弹市场）。 */
  private async launchTarget(): Promise<void> {
    const context: common.UIAbilityContext =
      this.getUIContext().getHostContext() as common.UIAbilityContext;
    const opened: boolean = await AppLauncher.openApp(context, this.introBundle);
    if (!opened) {
      CommonToast.info($r('app.string.apps_intro_app_missing'));
    }
  }

  /** 打开产品官网（失败给 toast，不让按钮变成"死键"）。 */
  private async openSite(): Promise<void> {
    if (this.introSite.length === 0) {
      return;
    }
    const opened: boolean = await MarketHelper.getInstance().openUri(this.introSite);
    if (!opened) {
      CommonToast.info($r('app.string.apps_site_open_failed'));
    }
  }

  /** 介绍半模态内容：标题行 + 分段介绍 + 截图 + 官网按钮 + 脚注。 */
  @Builder
  introSheet() {
    Column() {
      Scroll() {
        Column({ space: AppSpacing.MD }) {
          Row({ space: AppSpacing.SM }) {
            Text(this.introName)
              .fontSize(AppFontSize.TITLE)
              .fontWeight(AppFontWeight.BOLD)
              .fontColor($r('app.color.app_text_primary'))
              .layoutWeight(1)
            CommonTag({ text: this.introStatus, tone: TagTone.NEUTRAL })
          }
          .width('100%')

          Column({ space: AppSpacing.SM }) {
            ForEach(this.introLines, (line: string) => {
              Text(line)
                .fontSize(AppFontSize.BODY_SM)
                .fontColor($r('app.color.app_text_secondary'))
                .lineHeight(AppFontSize.BODY_SM * 1.6)
                .width('100%')
            }, (line: string, index: number): string => `${index}`)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          Text($r('app.string.apps_intro_shot_caption'))
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
            .width('100%')

          this.introShot()

          Column({ space: AppSpacing.XS }) {
            Row({ space: AppSpacing.XS }) {
              SymbolGlyph($r('sys.symbol.link'))
                .fontSize(AppFontSize.CAPTION)
                .fontColor([$r('app.color.app_text_tertiary')])
              Text(this.introBundle)
                .fontSize(AppFontSize.CAPTION)
                .fontColor($r('app.color.app_text_tertiary'))
                .fontFamily(AppsView.MONO_FONT)
                .layoutWeight(1)
            }
            .width('100%')

            Text(this.introSite)
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_tertiary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
          }
          .width('100%')
          .padding(AppSpacing.SM)
          .borderRadius(AppRadius.MD)
          .backgroundColor($r('app.color.app_bg_page_deep'))

          if (this.introLaunchable) {
            Button($r('app.string.apps_intro_open_app'))
              .fontSize(AppFontSize.BODY_SM)
              .fontColor($r('app.color.qj_brand'))
              .backgroundColor($r('app.color.app_bg_page_deep'))
              .borderRadius(AppRadius.FULL)
              .height(44)
              .width('100%')
              .onClick((): void => {
                this.launchTarget();
              })
          }

          Button($r('app.string.apps_intro_open_site'))
            .fontSize(AppFontSize.BODY_SM)
            .fontColor($r('app.color.app_text_on_brand'))
            .backgroundColor($r('app.color.qj_brand'))
            .borderRadius(AppRadius.FULL)
            .height(44)
            .width('100%')
            .onClick((): void => {
              this.openSite();
            })

          Text($r('app.string.apps_intro_site_tip'))
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
            .width('100%')
            .padding({ bottom: AppSpacing.XL })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ left: AppSpacing.LG, right: AppSpacing.LG, top: AppSpacing.SM })
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  appRow(entry: AppMatrixEntry) {
    Row({ space: AppSpacing.MD }) {
      Image(entry.icon)
        .width(56)
        .height(56)
        .borderRadius(AppRadius.MD)
        .objectFit(ImageFit.Cover)
      Column({ space: 4 }) {
        Row({ space: AppSpacing.XS }) {
          Text(entry.name)
            .fontSize(AppFontSize.BODY)
            .fontColor($r('app.color.app_text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          CommonTag({ text: entry.statusLabel, tone: TagTone.NEUTRAL })
        }
        .width('100%')

        Text(entry.desc)
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_secondary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(entry.bundleName)
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .fontFamily(AppsView.MONO_FONT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(AppFontSize.CAPTION)
        .fontColor([$r('app.color.app_text_tertiary')])
    }
    .width('100%')
    .padding(AppSpacing.MD)
    .borderRadius(AppRadius.LG)
    .backgroundColor($r('app.color.app_bg_card'))
    .onClick((): void => {
      this.handleOpen(entry);
    })
  }

  /**
   * 介绍弹窗里的产品截图。
   *
   * 单独做成 @Builder 并按 id 分支：`Image` 的入参必须是确定的 Resource，
   * 把 Resource 存进状态字段再传会丢失三语/密度解析，所以这里直接按 id 取。
   */
  @Builder
  introShot() {
    Column() {
      // 三个 Image 各占一个分支：Resource 必须在编译期确定，不能存进状态字段再传。
      // 高度显式给定，否则 width('100%') + Contain 在未约束的父容器里会塌成 0。
      if (this.introBundle === 'com.quizzyjoy.easymath') {
        Image($r('app.media.intro_easymath'))
          .width('100%')
          .height(230)
          .objectFit(ImageFit.Cover)
          .borderRadius(AppRadius.MD)
          .backgroundColor($r('app.color.app_bg_page_deep'))
      } else if (this.introBundle === 'com.quizzyjoy.vibestereo') {
        Image($r('app.media.intro_vibestereo'))
          .width('100%')
          .height(230)
          .objectFit(ImageFit.Cover)
          .borderRadius(AppRadius.MD)
          .backgroundColor($r('app.color.app_bg_page_deep'))
      } else if (this.introBundle === 'com.quizzyjoy.easytools') {
        Image($r('app.media.intro_easytools'))
          .width('100%')
          .height(230)
          .objectFit(ImageFit.Cover)
          .borderRadius(AppRadius.MD)
          .backgroundColor($r('app.color.app_bg_page_deep'))
      }
    }
    .width('100%')
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.MD }) {
        Text($r('app.string.apps_intro'))
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_secondary'))
          .lineHeight(AppFontSize.BODY_SM * 1.6)
          .width('100%')

        ForEach(AppMatrix.all(), (entry: AppMatrixEntry) => {
          this.appRow(entry)
        }, (entry: AppMatrixEntry): string => entry.id)

        Text($r('app.string.apps_fork_tip'))
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
          .padding({ top: AppSpacing.SM })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({
        left: AppSpacing.LG,
        right: AppSpacing.LG,
        top: AppSpacing.MD,
        bottom: AppSpacing.XXXL
      })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .backgroundColor($r('app.color.app_bg_page'))
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
    .bindSheet($$this.showIntroSheet, this.introSheet(), {
      detents: [SheetSize.LARGE, SheetSize.MEDIUM],
      showClose: true,
      dragBar: true,
      width: '86%',
      title: { title: $r('app.string.apps_intro_sheet_title') }
    })
  }
}
