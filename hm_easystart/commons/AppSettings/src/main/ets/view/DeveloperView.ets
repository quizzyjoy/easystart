import { AppFontSize, AppFontWeight, AppLineHeight, AppRadius, AppSize, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { AppEnvManager, AppEnvSnapshot, BreakpointManager, MarketHelper, common } from '@quizzyjoy/platform';
import { AppDialog, AppEmptyState, CommonToast, DialogSemantic } from '@easystart/app-component';
import { image } from '@kit.ImageKit';
import { CompanyInfo, DevGroup, DevLink, DeveloperProfile, PersonInfo } from '../model/SettingsContentModels';
import { ClipboardUtil } from '../util/ClipboardUtil';
import { QrCodeUtil } from '../util/QrCodeUtil';
import { RawFileTextLoader } from '../util/RawFileTextLoader';

const RAWFILE_NAME: string = 'developer.json';

/**
 * 开发者子页（v3.28 数据驱动；v3.34 两段式重构）：
 *
 * - **上半段公司**：品牌 + 公司全称 + 统一社会信用代码 / ICP / 客服邮箱 + 开源主页
 *   （GitHub / Gitee / AtomGit 三平台按钮）；
 * - **下半段个人**：头像字 + 姓名 / 职务 / 简介 + 三组链接（开源社区 / 技术贴 / 社媒）
 *   + 联系方式（邮箱 / 微信一键复制）；
 * - **多设备**：按钮网格按断点 1/2/3 列（xs 单列、sm 两列、md+ 三列），内容限宽
 *   `contentMaxWidth`；**手表（wearable）只渲染公司段**，个人段整体跳过。
 *
 * 数据源 rawfile/developer.json（fork 替换点）；解析收口 DeveloperProfile.parse，
 * 结构不符或读取失败兜底空档案 → 空态。链接统一经 MarketHelper.openUri 打开。
 */
@ComponentV2
export struct DeveloperView {
  @Local profile: DeveloperProfile = new DeveloperProfile(
    new CompanyInfo('', '', '', '', '', '', []),
    new PersonInfo('', '', [], [], '', '', '')
  );
  @Local emptyText: string = '';
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local env: AppEnvSnapshot = AppEnvManager.get();
  /** 手表二维码覆盖层（v3.34）：显示态 / 位图 / 标题 / 原链接（生成失败时展示）。 */
  @Local qrVisible: boolean = false;
  @Local qrImage: image.PixelMap | undefined = undefined;
  @Local qrTitle: string = '';
  @Local qrUrl: string = '';

  aboutToAppear(): void {
    const ctx: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    try {
      this.emptyText = ctx.resourceManager.getStringSync($r('app.string.settings_developer_empty').id);
    } catch (err) {
      this.emptyText = '';
    }
    this.load();
  }

  private async load(): Promise<void> {
    try {
      const ctx: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const text: string = await RawFileTextLoader.load(ctx, RAWFILE_NAME);
      this.profile = DeveloperProfile.parse(text);
    } catch (err) {
      this.profile = new DeveloperProfile(
        new CompanyInfo('', '', '', '', '', '', []),
        new PersonInfo('', '', [], [], '', '', '')
      );
    }
  }

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  private isWearable(): boolean {
    return this.env.deviceType === 'wearable';
  }

  /** 按钮网格列数：xs 单列 / sm 两列 / md 及以上三列。 */
  private columnsTemplate(): string {
    const bp: string = this.bp();
    if (this.isWearable() || bp === 'xs' || bp === 'sm') {
      return '1fr';
    }
    if (bp === 'md') {
      return '1fr 1fr';
    }
    return '1fr 1fr 1fr';
  }

  /**
   * 品牌图标（v3.34，SVG 资源版）。
   *
   * 早前用 Shape + viewPort 缩放 24 单位 path，真机实测只显示一个小点
   * （viewPort 未按预期缩放），故改为 SVG 资源 + Image.fillColor 着色。
   */
  @Builder
  brandIcon(name: string) {
    if (name.startsWith('GitHub')) {
      Image($r('app.media.brand_github'))
        .width(20).height(20)
    } else if (name === 'Gitee') {
      Image($r('app.media.brand_gitee'))
        .width(20).height(20)
    } else if (name === '稀土掘金') {
      Image($r('app.media.brand_juejin'))
        .width(20).height(20)
    } else if (name === 'CSDN') {
      Image($r('app.media.brand_csdn'))
        .width(20).height(20)
    } else if (name === '华为开发者联盟') {
      Image($r('app.media.brand_huawei'))
        .width(20).height(20)
    } else if (name === '抖音') {
      Image($r('app.media.brand_douyin'))
        .width(20).height(20)
    } else if (name === '小红书') {
      Image($r('app.media.brand_xiaohongshu'))
        .width(20).height(20)
    } else if (name === '哔哩哔哩') {
      Image($r('app.media.brand_bilibili'))
        .width(20).height(20)
    } else {
      // AtomGit / 公司官网 / 个人主页：通用链接图标
      SymbolGlyph($r('sys.symbol.link'))
        .fontSize(20)
        .fontColor([$r('app.color.app_text_secondary')])
    }
  }

  /** 打开外部链接；无处理方时 Toast 降级。 */
  private openLink(url: string): void {
    MarketHelper.getInstance().openUri(url).then((ok: boolean): void => {
      if (!ok) {
        CommonToast.info($r('app.string.about_open_repo_failed'));
      }
    });
  }

  /** 链接点击分流：手表（无 Web 组件）→ 二维码覆盖层；其它 → 外部浏览器。 */
  private handleLink(title: string, url: string): void {
    if (this.isWearable()) {
      this.showQr(title, url);
    } else {
      this.openLink(url);
    }
  }

  /** 生成并展示二维码（手表端）；能力缺失时覆盖层仍展示链接文本兜底。 */
  private async showQr(title: string, url: string): Promise<void> {
    this.qrTitle = title;
    this.qrUrl = url;
    this.qrImage = await QrCodeUtil.create(url);
    this.qrVisible = true;
  }

  /** 复制到剪贴板并提示（联系方式用）。 */
  private copyText(text: string): void {
    ClipboardUtil.copyText(text).then((ok: boolean): void => {
      CommonToast.info(ok ? $r('app.string.settings_developer_copied') : $r('app.string.about_open_repo_failed'));
    });
  }

  /**
   * fork 提示对话框：说明替换真实开发者信息的位置。
   *
   * 原计划挂在 HdsNavDestination 的 titleBar menu，但当前 SDK 的
   * HdsNavigationMenuContentOptions.value 元素类型 HdsNavigationMenuItemOptions 未声明
   * （编译器解析为 HdsNavigationBadgeIconOptions，无 action 字段），故改为页内信息行入口。
   */
  private showForkTip(): void {
    const uiCtx: UIContext = this.getUIContext();
    const host = uiCtx.getHostContext();
    let title: string = '开发者信息说明';
    let body: string = '';
    if (host !== undefined) {
      try {
        title = host.resourceManager.getStringSync($r('app.string.settings_developer_fork_tip_title'));
        body = host.resourceManager.getStringSync($r('app.string.settings_developer_fork_tip_body'));
      } catch (err) {
        body = '';
      }
    }
    AppDialog.open(uiCtx, DialogSemantic.CONFIRM, title, body, (): void => {
    });
  }

  /** fork 提示行（页内入口，点击弹说明）。 */
  @Builder
  forkTipRow() {
    Row({ space: AppSpacing.SM }) {
      SymbolGlyph($r('sys.symbol.info_circle'))
        .fontSize(AppSize.ICON_LG)
        .fontColor([$r('app.color.app_link')])
      Text($r('app.string.settings_developer_fork_tip_title'))
        .fontSize(AppFontSize.BODY_SM)
        .fontColor($r('app.color.app_link'))
        .layoutWeight(1)
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(AppFontSize.TITLE_SM)
        .fontColor([$r('app.color.app_text_tertiary')])
    }
    .width('100%')
    .padding(AppSpacing.MD)
    .borderRadius(AppRadius.LG)
    .backgroundColor($r('app.color.app_bg_card'))
    .onClick((): void => {
      this.showForkTip();
    })
  }

  @Builder
  infoRow(label: ResourceStr, value: string) {
    Row({ space: AppSpacing.SM }) {
      Text(label)
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_tertiary'))
        .flexShrink(0)
      Text(value)
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_secondary'))
        .layoutWeight(1)
        .textAlign(TextAlign.End)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  /** 链接卡片（网格单元）：官方品牌矢量图标 + 名称 + 描述。 */
  @Builder
  linkCard(link: DevLink) {
    Row({ space: AppSpacing.SM }) {
      // 官方品牌图标（SVG 资源，v3.34）
      this.brandIcon(link.name)
      Column({ space: AppSpacing.XXS }) {
        Text(link.name)
          .fontSize(AppFontSize.BODY)
          .fontWeight(AppFontWeight.MEDIUM)
          .fontColor($r('app.color.app_text_primary'))
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(link.desc)
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding(AppSpacing.MD)
    .borderRadius(AppRadius.LG)
    .backgroundColor($r('app.color.app_bg_card'))
    .onClick((): void => {
      this.handleLink(link.name, link.url);
    })
  }

  /** 一组链接（标题 + 网格）。 */
  @Builder
  linkGroup(group: DevGroup) {
    Column({ space: AppSpacing.SM }) {
      Text(group.title)
        .fontSize(AppFontSize.BODY_SM)
        .fontWeight(AppFontWeight.MEDIUM)
        .fontColor($r('app.color.app_text_secondary'))
        .width('100%')
      Grid() {
        ForEach(group.links, (link: DevLink) => {
          GridItem() {
            this.linkCard(link)
          }
        }, (link: DevLink): string => link.url)
      }
      .columnsTemplate(this.columnsTemplate())
      .columnsGap(AppSpacing.SM)
      .rowsGap(AppSpacing.SM)
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 公司段（上半）。 */
  @Builder
  companySection() {
    Column({ space: AppSpacing.MD }) {
      Row({ space: AppSpacing.SM }) {
        Column() {
          Text(this.profile.company.brand.length > 0
            ? this.profile.company.brand.substring(0, 1)
            : $r('app.string.settings_developer'))
            .fontSize(AppFontSize.TITLE_SM)
            .fontWeight(AppFontWeight.BOLD)
            .fontColor($r('app.color.app_text_on_brand'))
        }
        .width(48)
        .height(48)
        .borderRadius(AppRadius.LG)
        .backgroundColor($r('app.color.qj_brand'))
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column({ space: AppSpacing.XXS }) {
          Text(this.profile.company.name)
            .fontSize(AppFontSize.BODY)
            .fontWeight(AppFontWeight.BOLD)
            .fontColor($r('app.color.app_text_primary'))
          Text(this.profile.company.brand)
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Column({ space: AppSpacing.XS }) {
        if (this.profile.company.creditCode.length > 0) {
          this.infoRow($r('app.string.settings_developer_credit_code'), this.profile.company.creditCode)
        }
        if (this.profile.company.icp.length > 0) {
          this.infoRow($r('app.string.settings_developer_icp'), this.profile.company.icp)
        }
        if (this.profile.company.email.length > 0) {
          this.infoRow($r('app.string.settings_developer_email'), this.profile.company.email)
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 公司官网（v3.34）：手机/平板/PC 打开官网，手表生成二维码
      if (this.profile.company.website.length > 0) {
        Row({ space: AppSpacing.SM }) {
          SymbolGlyph($r('sys.symbol.link'))
            .fontSize(AppSize.ICON_LG)
            .fontColor([$r('app.color.app_link')])
          Text($r('app.string.settings_developer_website'))
            .fontSize(AppFontSize.BODY_SM)
            .fontColor($r('app.color.app_link'))
            .layoutWeight(1)
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(AppFontSize.TITLE_SM)
            .fontColor([$r('app.color.app_text_tertiary')])
        }
        .width('100%')
        .padding(AppSpacing.MD)
        .borderRadius(AppRadius.LG)
        .backgroundColor($r('app.color.app_bg_card'))
        .onClick((): void => {
          this.handleLink('公司官网', this.profile.company.website);
        })
      }

      if (this.profile.company.repos.length > 0) {
        Column({ space: AppSpacing.SM }) {
          Text($r('app.string.settings_developer_open_source'))
            .fontSize(AppFontSize.BODY_SM)
            .fontWeight(AppFontWeight.MEDIUM)
            .fontColor($r('app.color.app_text_secondary'))
            .width('100%')
          Grid() {
            ForEach(this.profile.company.repos, (link: DevLink) => {
              GridItem() {
                this.linkCard(link)
              }
            }, (link: DevLink): string => link.url)
          }
          .columnsTemplate(this.columnsTemplate())
          .columnsGap(AppSpacing.SM)
          .rowsGap(AppSpacing.SM)
          .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(AppSpacing.LG)
    .borderRadius(AppRadius.XL)
    .backgroundColor($r('app.color.app_bg_card'))
  }

  /** 个人段（下半；手表不渲染）。 */
  @Builder
  personSection() {
    Column({ space: AppSpacing.MD }) {
      Row({ space: AppSpacing.SM }) {
        Column() {
          Text(this.profile.person.name.length > 0
            ? this.profile.person.name.substring(0, 1)
            : '•')
            .fontSize(AppFontSize.TITLE_SM)
            .fontWeight(AppFontWeight.BOLD)
            .fontColor($r('app.color.app_text_on_brand'))
        }
        .width(48)
        .height(48)
        .borderRadius(AppRadius.FULL)
        .backgroundColor($r('app.color.qj_brand'))
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column({ space: AppSpacing.XXS }) {
          Text(this.profile.person.name)
            .fontSize(AppFontSize.BODY)
            .fontWeight(AppFontWeight.BOLD)
            .fontColor($r('app.color.app_text_primary'))
          Text(this.profile.person.title)
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.profile.person.intro.length > 0) {
        Column({ space: AppSpacing.XS }) {
          ForEach(this.profile.person.intro, (line: string, index: number) => {
            Text(line)
              .fontSize(AppFontSize.BODY_SM)
              .fontColor($r('app.color.app_text_secondary'))
              .lineHeight(AppLineHeight.for(AppFontSize.BODY_SM, AppLineHeight.RELAXED))
              .width('100%')
          }, (line: string, index: number): string => `intro_${index}`)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }

      ForEach(this.profile.person.groups, (group: DevGroup) => {
        this.linkGroup(group)
      }, (group: DevGroup): string => group.title)

      // 个人主页（v3.34）：手机/平板/PC 打开官网个人页，手表生成二维码
      if (this.profile.person.homepage.length > 0) {
        Row({ space: AppSpacing.SM }) {
          SymbolGlyph($r('sys.symbol.link'))
            .fontSize(AppSize.ICON_LG)
            .fontColor([$r('app.color.app_link')])
          Text($r('app.string.settings_developer_homepage'))
            .fontSize(AppFontSize.BODY_SM)
            .fontColor($r('app.color.app_link'))
            .layoutWeight(1)
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(AppFontSize.TITLE_SM)
            .fontColor([$r('app.color.app_text_tertiary')])
        }
        .width('100%')
        .padding(AppSpacing.MD)
        .borderRadius(AppRadius.LG)
        .backgroundColor($r('app.color.app_bg_card'))
        .onClick((): void => {
          this.handleLink('个人主页', this.profile.person.homepage);
        })
      }

      if (this.profile.person.email.length > 0 || this.profile.person.wechat.length > 0) {
        Column({ space: AppSpacing.SM }) {
          Text($r('app.string.settings_developer_contact'))
            .fontSize(AppFontSize.BODY_SM)
            .fontWeight(AppFontWeight.MEDIUM)
            .fontColor($r('app.color.app_text_secondary'))
            .width('100%')
          if (this.profile.person.email.length > 0) {
            Row({ space: AppSpacing.SM }) {
              Text(this.profile.person.email)
                .fontSize(AppFontSize.BODY_SM)
                .fontColor($r('app.color.app_text_primary'))
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text($r('app.string.settings_developer_copy'))
                .fontSize(AppFontSize.CAPTION)
                .fontColor($r('app.color.app_link'))
            }
            .width('100%')
            .padding(AppSpacing.MD)
            .borderRadius(AppRadius.LG)
            .backgroundColor($r('app.color.app_bg_card'))
            .onClick((): void => {
              this.copyText(this.profile.person.email);
            })
          }
          if (this.profile.person.wechat.length > 0) {
            Row({ space: AppSpacing.SM }) {
              Text(`微信：${this.profile.person.wechat}`)
                .fontSize(AppFontSize.BODY_SM)
                .fontColor($r('app.color.app_text_primary'))
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text($r('app.string.settings_developer_copy'))
                .fontSize(AppFontSize.CAPTION)
                .fontColor($r('app.color.app_link'))
            }
            .width('100%')
            .padding(AppSpacing.MD)
            .borderRadius(AppRadius.LG)
            .backgroundColor($r('app.color.app_bg_card'))
            .onClick((): void => {
              this.copyText(this.profile.person.wechat);
            })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(AppSpacing.LG)
    .borderRadius(AppRadius.XL)
    .backgroundColor($r('app.color.app_bg_card'))
  }

  /** 手表二维码覆盖层：半透明底 + 白卡片（二维码 / 生成失败时展示链接）。 */
  @Builder
  qrOverlay() {
    Column() {
      Column({ space: AppSpacing.MD }) {
        Text(this.qrTitle)
          .fontSize(AppFontSize.BODY)
          .fontWeight(AppFontWeight.BOLD)
          .fontColor($r('app.color.app_text_primary'))
        if (this.qrImage !== undefined) {
          Image(this.qrImage)
            .width(200)
            .height(200)
            .borderRadius(AppRadius.LG)
        } else {
          Text(this.qrUrl)
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_secondary'))
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        Text($r('app.string.settings_developer_qr_hint'))
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
      }
      .padding(AppSpacing.LG)
      .borderRadius(AppRadius.XL)
      .backgroundColor($r('app.color.app_bg_card'))
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#80000000')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick((): void => {
      this.qrVisible = false;
    })
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Scroll() {
        Column({ space: DesignToken.sectionSpacing() }) {
        if (this.profile.isEmpty()) {
          AppEmptyState({
            icon: $r('sys.symbol.person_2'),
            title: this.emptyText
          })
        } else {
          // v3.34 fork 提示：页内信息行（titleBar menu 类型链在当前 SDK 缺失，改用页内入口）
          this.forkTipRow()
          if (!this.profile.company.isEmpty()) {
            this.companySection()
          }
          // 手表只保留公司段（个人段整体跳过）
          if (!this.isWearable() && !this.profile.person.isEmpty()) {
            this.personSection()
          }
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .constraintSize({ maxWidth: DesignToken.contentMaxWidth(this.bp()) })
      .padding({
        // v3.32 宽度统一：左右额外内缩，对齐 HdsListItemCard 自带的约 17vp 横向内缩，
        // 使自绘卡片与设置行的背景宽度一致（否则子页卡片会比主页行宽一圈）。
        left: DesignToken.pagePadding(this.bp()),
        right: DesignToken.pagePadding(this.bp()),
        top: AppSpacing.LG,
        bottom: AppSpacing.XXXL
      })
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.app_bg_page'))
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      // 手表二维码覆盖层（全屏点击关闭）
      if (this.qrVisible) {
        this.qrOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }
}
