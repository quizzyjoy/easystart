import { common } from '@quizzyjoy/platform';
import { AppLauncher, MarketHelper, StoreProductView } from '@quizzyjoy/platform';
import { AppTabSegment, CommonTag, CommonToast, TagTone } from '@easystart/app-component';
import { AppFontSize, AppFontWeight, AppRadius, AppSpacing } from '@quizzyjoy/foundation';
import { SegmentButtonV2Items } from '@ohos.arkui.advanced.SegmentButtonV2';
import { AppMatrix, AppMatrixEntry, AppEntryStatus } from '../../model/AppMatrix';
import { ClipboardUtil } from '../../util/ClipboardUtil';

/**
 * 应用矩阵子页（v3.61）：趣开发系列四个应用的聚合展示。
 *
 * 点击行为回退链（真机验证过的顺序，见 `handleOpen`）：
 * 1. 本应用（SELF）→ 打开产品官网；
 * 2. 未上架 → 弹「应用介绍」半模态；
 * 3. 已上架且已安装 → 直接拉起；
 * 4. 已上架未安装 → 应用内详情页 → 市场详情 → 介绍弹窗。
 *
 * 介绍弹窗排版对齐数易项目里临境声场那套 sheet：顶部 `AppTabSegment` 分段 +
 * 滚动内容区。段数由数据决定（`AppMatrix.qqGroupNumber` 是否为空）：
 * - 有交流群（数易 / 临境声场）：简介与官网 · 交流群 · 详情与特性；
 * - 无交流群（趣开发 / 随易工具箱）：简介与官网 · 详情与特性。
 *
 * 段内容来源见 `AppMatrix`：`introLines`（简介）、QQ 群三字段（交流群）、
 * `featureLines`（详情，取自各产品官网介绍卡片）。
 */
@ComponentV2
export struct AppsView {
  /** 本应用被点击时的额外上抛（保留给宿主做埋点等，默认空实现）。 */
  @Event onOpenSelf: () => void = (): void => {
  };

  /** 介绍半模态是否可见。 */
  @Local showIntroSheet: boolean = false;
  /** 当前分段下标（0 简介 / 1 交流群或详情 / 2 详情）。 */
  @Local segIndex: number = 0;
  /** 分段项：打开时按有无交流群重建（2 段或 3 段）。 */
  @Local segItems: SegmentButtonV2Items = new SegmentButtonV2Items([
    { text: $r('app.string.apps_intro_seg_intro') },
    { text: $r('app.string.apps_intro_seg_detail') }
  ]);

  /** 弹窗数据（拆成扁平字段，避免嵌套对象观察不到变化）。 */
  @Local introId: string = '';
  @Local introName: ResourceStr = '';
  @Local introStatus: ResourceStr = '';
  @Local introLines: string[] = [];
  @Local introFeatureLines: string[] = [];
  @Local introSite: string = '';
  @Local introQqNumber: string = '';
  @Local introQqUrl: string = '';
  @Local introQqHasQr: boolean = false;
  /** 内测邀请链接（空串 = 该应用无内测入口）。 */
  @Local introInviteUrl: string = '';
  /** 详情卡是否双列（按容器实际宽度断点，v3.63）。 */
  @Local detailWide: boolean = false;

  /** 包名等宽展示用等宽字体族（不引外部字体，靠 CSS 等宽回退）。 */
  private static readonly MONO_FONT: string = 'HarmonyOS Sans Mono, monospace';

  /**
   * 打开矩阵里的一条。
   *
   * 顺序：本应用开官网 → 未上架弹介绍 → 已上架先试打开 → 详情页 → 市场 → 介绍。
   * 状态只决定"打不开时去哪"，不阻止"能打开就打开"。
   */
  private async handleOpen(entry: AppMatrixEntry): Promise<void> {
    // ① 本应用 → 打开产品官网
    if (entry.status === AppEntryStatus.SELF) {
      const opened: boolean = await MarketHelper.getInstance().openUri(AppMatrix.SELF_SITE);
      if (!opened) {
        CommonToast.info($r('app.string.apps_site_open_failed'));
      }
      return;
    }
    const context: common.UIAbilityContext =
      this.getUIContext().getHostContext() as common.UIAbilityContext;
    // ② 未上架 → 直接弹介绍（分段展示简介 / 交流群 / 详情）
    if (entry.status === AppEntryStatus.UNPUBLISHED) {
      this.showIntro(entry);
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

  /** 打开介绍半模态：写入内容并按有无交流群重建分段。 */
  private showIntro(entry: AppMatrixEntry): void {
    this.introId = entry.id;
    this.introName = entry.name;
    this.introStatus = entry.statusLabel;
    this.introLines = entry.introLines;
    this.introFeatureLines = entry.featureLines;
    this.introSite = entry.siteUrl;
    this.introQqNumber = entry.qqGroupNumber;
    this.introQqUrl = entry.qqJoinUrl;
    this.introQqHasQr = entry.qqHasQr;
    this.introInviteUrl = entry.inviteTestUrl;
    this.segIndex = 0;
    this.segItems = entry.qqGroupNumber.length > 0
      ? new SegmentButtonV2Items([
        { text: $r('app.string.apps_intro_seg_intro') },
        { text: $r('app.string.apps_intro_seg_group') },
        { text: $r('app.string.apps_intro_seg_detail') }
      ])
      : new SegmentButtonV2Items([
        { text: $r('app.string.apps_intro_seg_intro') },
        { text: $r('app.string.apps_intro_seg_detail') }
      ]);
    this.showIntroSheet = true;
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

  /**
   * 参加内测：优先用浏览器打开 AppGallery 邀测页。
   *
   * 邀测页必须登录华为账号后点「参加」，应用内无法代劳，所以这里只负责把用户送到浏览器；
   * 打不开浏览器时降级为复制链接，避免按钮变成"死键"。
   */
  private async joinInviteTest(): Promise<void> {
    if (this.introInviteUrl.length === 0) {
      return;
    }
    // 必须走浏览器：AppGallery 域名被应用市场接管，openUri 会落到市场首页
    const opened: boolean = await MarketHelper.getInstance().openInBrowser(this.introInviteUrl);
    if (opened) {
      return;
    }
    await this.copyInviteLink();
  }

  /** 复制内测链接（浏览器打不开时的确定性退路）。 */
  private async copyInviteLink(): Promise<void> {
    if (this.introInviteUrl.length === 0) {
      return;
    }
    const copied: boolean = await ClipboardUtil.copyText(this.introInviteUrl);
    CommonToast.info(copied
      ? $r('app.string.apps_intro_invite_test_copied')
      : $r('app.string.apps_intro_invite_test_failed'));
  }

  /** 加群：有短链走 QQ 加群页；没有短链则复制群号（数易只有群号）。 */
  private async joinGroup(): Promise<void> {
    if (this.introQqUrl.length > 0) {
      const opened: boolean = await MarketHelper.getInstance().openUri(this.introQqUrl);
      if (!opened) {
        CommonToast.info($r('app.string.apps_intro_qq_failed'));
      }
      return;
    }
    const copied: boolean = await ClipboardUtil.copyText(this.introQqNumber);
    CommonToast.info(copied
      ? $r('app.string.apps_intro_group_copied')
      : $r('app.string.apps_intro_qq_failed'));
  }

  /**
   * 段 1 的产品截图。
   *
   * 排版与数易项目一致：宽 100% + 显式高度 + `ImageFit.Contain`（定高必须配 Contain，
   * 否则竖版长图会被 Cover 裁掉）；Resource 必须编译期确定，故按 id 分支而不是传字段。
   */
  @Builder
  introShot() {
    Column() {
      if (this.introId === 'easymath') {
        Image($r('app.media.intro_easymath'))
          .width('100%')
          .height(260)
          .objectFit(ImageFit.Contain)
          .borderRadius(AppRadius.MD)
          .backgroundColor($r('app.color.app_bg_page_deep'))
      } else if (this.introId === 'vibestereo') {
        Image($r('app.media.intro_vibestereo'))
          .width('100%')
          .height(300)
          .objectFit(ImageFit.Contain)
          .borderRadius(AppRadius.MD)
          .backgroundColor($r('app.color.app_bg_page_deep'))
      } else if (this.introId === 'easytools') {
        Image($r('app.media.intro_easytools'))
          .width('100%')
          .height(300)
          .objectFit(ImageFit.Contain)
          .borderRadius(AppRadius.MD)
          .backgroundColor($r('app.color.app_bg_page_deep'))
      }
    }
    .width('100%')
  }

  /** 段 1：图文简介 + 产品官网按钮。 */
  @Builder
  segIntro() {
    Column({ space: AppSpacing.MD }) {
      Row({ space: AppSpacing.MD }) {
        Text(this.introName)
          .fontSize(AppFontSize.TITLE)
          .fontWeight(AppFontWeight.BOLD)
          .fontColor($r('app.color.app_text_primary'))
          .layoutWeight(1)
        CommonTag({ text: this.introStatus, tone: TagTone.NEUTRAL })
      }
      .width('100%')

      Column({ space: AppSpacing.SM }) {
        ForEach(this.introLines, (line: string, index: number) => {
          Text(line)
            .fontSize(AppFontSize.BODY_SM)
            .fontColor($r('app.color.app_text_secondary'))
            .lineHeight(AppFontSize.BODY_SM * 1.6)
            .width('100%')
        }, (line: string, index: number): string => `${index}`)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      this.introShot()

      Button($r('app.string.apps_intro_open_site'))
        .fontSize(AppFontSize.BODY_SM)
        .fontColor($r('app.color.app_text_on_brand'))
        .backgroundColor($r('app.color.qj_brand'))
        .borderRadius(AppRadius.FULL)
        .height(44)
        .width('100%')
        .margin({ top: AppSpacing.XS })
        .onClick((): void => {
          this.openSite();
        })

      // 内测入口：只有配了 inviteTestUrl 的应用才出现（数易已正式上架，没有这一块）
      if (this.introInviteUrl.length > 0) {
        Row({ space: AppSpacing.SM }) {
          Button($r('app.string.apps_intro_join_invite_test'))
            .fontSize(AppFontSize.BODY_SM)
            .fontColor($r('app.color.qj_brand'))
            .backgroundColor(Color.Transparent)
            .borderRadius(AppRadius.FULL)
            .border({ width: 1, color: $r('app.color.qj_brand') })
            .height(44)
            .layoutWeight(2)
            .onClick((): void => {
              this.joinInviteTest();
            })
          Button($r('app.string.apps_intro_invite_test_copy'))
            .fontSize(AppFontSize.BODY_SM)
            .fontColor($r('app.color.app_text_secondary'))
            .backgroundColor($r('app.color.app_bg_card'))
            .borderRadius(AppRadius.FULL)
            .height(44)
            .layoutWeight(1)
            .onClick((): void => {
              this.copyInviteLink();
            })
        }
        .width('100%')

        Text($r('app.string.apps_intro_invite_test_tip'))
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .lineHeight(AppFontSize.CAPTION * 1.5)
          .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 段 2：QQ 群二维码 + 加群按钮（仅数易 / 临境声场）。 */
  @Builder
  segGroup() {
    Column({ space: AppSpacing.MD }) {
      Text($r('app.string.apps_intro_group_tip'))
        .fontSize(AppFontSize.BODY_SM)
        .fontColor($r('app.color.app_text_secondary'))
        .lineHeight(AppFontSize.BODY_SM * 1.6)
        .width('100%')

      if (this.introQqHasQr) {
        Image($r('app.media.qq_group_vibestereo'))
          .width(200)
          .height(200)
          .objectFit(ImageFit.Contain)
          .borderRadius(AppRadius.MD)
          .backgroundColor($r('app.color.app_bg_card'))
      }

      Row({ space: AppSpacing.XS }) {
        Text($r('app.string.apps_intro_group_number_label'))
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_secondary'))
        Text(this.introQqNumber)
          .fontSize(AppFontSize.BODY)
          .fontWeight(AppFontWeight.MEDIUM)
          .fontColor($r('app.color.qj_brand'))
          .fontFamily(AppsView.MONO_FONT)
      }
      .width('100%')

      Button(this.introQqUrl.length > 0
        ? $r('app.string.apps_intro_qq_join')
        : $r('app.string.apps_intro_group_copy'))
        .fontSize(AppFontSize.BODY_SM)
        .fontColor($r('app.color.app_text_on_brand'))
        .backgroundColor($r('app.color.qj_brand'))
        .borderRadius(AppRadius.FULL)
        .height(44)
        .width('100%')
        .onClick((): void => {
          this.joinGroup();
        })

      Text(this.introQqUrl.length > 0
        ? $r('app.string.apps_intro_group_qr_tip')
        : $r('app.string.apps_intro_group_search_tip'))
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_tertiary'))
        .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 段 3：详情与特性（条目来自产品官网的介绍卡片）。
   *
   * 断点响应（v3.63）：用 `Flex` + wrap 而不是 `Grid`——`Grid` 直接放在 `Scroll` 里
   * 不给显式高度会塌成 0（仓内已知坑），Flex wrap 高度自适应且能换行成多列。
   * 列数按**容器实际宽度**判断（不是屏幕宽度）：超过 620vp 才升双列，
   * 保证卡片不会被压得过窄而难读；手机 / 窄窗仍是单列。
   */
  @Builder
  segDetail() {
    Column({ space: AppSpacing.SM }) {
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Start }) {
        ForEach(this.introFeatureLines, (line: string, index: number) => {
          Column() {
            Text(line)
              .fontSize(AppFontSize.BODY_SM)
              .fontColor($r('app.color.app_text_secondary'))
              .lineHeight(AppFontSize.BODY_SM * 1.65)
              .width('100%')
          }
          .width(this.detailWide ? '48.5%' : '100%')
          .padding(AppSpacing.MD)
          .margin({ bottom: AppSpacing.SM })
          .borderRadius(AppRadius.MD)
          .backgroundColor($r('app.color.app_bg_card'))
        }, (line: string, index: number): string => `${index}`)
      }
      .width('100%')
      .onAreaChange((oldArea: Area, newArea: Area): void => {
        const width: number = Number(newArea.width);
        this.detailWide = width >= 620;
      })

      Text($r('app.string.apps_intro_detail_source'))
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_tertiary'))
        .width('100%')
        .padding({ top: AppSpacing.XS })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 固定底栏主操作（v3.62）。
   *
   * 之前按钮放在 Scroll 内容末尾，长内容滚到底时会被 sheet 底部圆角 / 系统手势区盖住；
   * 现在固定在 Scroll 之外，三段共用一条底栏，按当前段切换动作：
   * 交流群段 → 一键加群（或复制群号），其余段 → 打开产品官网。
   */
  /** 半模态内容：分段条 + 可滚动段内容。 */
  @Builder
  introSheet() {
    Column() {
      AppTabSegment({
        items: this.segItems,
        selectedIndex: this.segIndex,
        onIndexChange: (index: number): void => {
          this.segIndex = index;
        }
      })
        .margin({ top: AppSpacing.XS, bottom: AppSpacing.MD })
        .padding({ left: AppSpacing.LG, right: AppSpacing.LG })

      Scroll() {
        Column() {
          if (this.segIndex === 0) {
            this.segIntro()
          } else if (this.introQqNumber.length > 0 && this.segIndex === 1) {
            this.segGroup()
          } else {
            this.segDetail()
          }
        }
        .width('100%')
        .padding({ left: AppSpacing.LG, right: AppSpacing.LG, bottom: AppSpacing.XXXL + 32 })
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
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
