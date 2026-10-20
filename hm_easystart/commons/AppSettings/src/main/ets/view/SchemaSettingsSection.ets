import {
  HdsListItemCard,
  IconSize,
  PrefixCustomBuilder,
  PrefixIcon,
  SuffixArrow,
  SuffixCustomBuilder,
  SuffixSelect,
  SuffixSwitch,
  SuffixTextAndArrow
} from '@kit.UIDesignKit';
import { SettingsRow } from './component/SettingsRow';
import { SettingsSelectRow, SettingsSliderRow, SettingsSwitchRow } from './component/SettingsControlRows';
import { AppFontSize, AppFontWeight, AppRadius, AppSize, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import {
  AppEnvManager,
  AppEnvSnapshot,
  AppGalleryHelper,
  BreakpointManager,
  MarketHelper,
  StoreCapabilityResult,
  StoreDynamicIcon,
  StorePrivacyKind,
  StoreSkill,
  common
} from '@quizzyjoy/platform';
import { AppDialog, CommonToast, DialogSemantic } from '@easystart/app-component';
import { AccentColorSetting } from '../component/AccentColorSetting';
import { SettingsSchema, SchemaGroupDef, SchemaIconDef, SchemaRowDef } from '../model/SettingsSchema';
import { SchemaRowStore, SettingsSchemaActions } from '../model/SchemaRowStore';
import { SettingsRoute } from '../model/SettingsRoute';
import { SettingsViewModel } from '../viewmodel/SettingsViewModel';
import { AppSettingsJump } from '../util/AppSettingsJump';
import { AppShare } from '../util/AppShare';
import { StoreFeedback } from '../util/StoreFeedback';
import { RawFileTextLoader } from '../util/RawFileTextLoader';

/**
 * schema 渲染器（v3.30，TODO-021）：设置页组区 / 行 / 控件的统一数据驱动渲染。
 *
 * - 页键：home（设置主页组区）/ general / appearance；fork 可自扩页键并自建视图装配；
 * - 行型七类：nav / action / info / switch / select / slider / builtin——
 *   builtin 行为行逐字复用 v3.28 视图接线（SettingsViewModel 即时生效链零改），
 *   通用三类行经 SchemaRowStore 泛型偏好 + 钩子注册表；
 * - 图标：chip 彩底贴片（PrefixCustomBuilder 官方槽 + chart_c01~c20 色板）为默认，
 *   tint 仅着色为降级；无 icon / 未注册符号 → 无前缀安全降级；
 * - 组型两类：list 卡片行组（默认）/ grid 操作宫格（断点分栏）；
 * - 值追踪铁律：行定义（schema 解析物）为静态配置可经 @Builder 值参数传递，
 *   状态值一律在元素参数内直读（this.store.* / this.vm.*，经 currentModeLabel 先例验证）。
 */
@ComponentV2
export struct SchemaSettingsSection {
  @Param page: string = 'home';
  /** 设置域内层导航栈（v3.32 双层栈：域内跳转压内层栈，不压外层应用栈）。 */
  @Param settingsStack: NavPathStack = new NavPathStack();
  @Local groups: SchemaGroupDef[] = [];
  // 单例（TODO-021 收口修复）：主页与各子页共享同一份设置状态，跨子页实时互通。
  @Local vm: SettingsViewModel = SettingsViewModel.getInstance();
  @Local store: SchemaRowStore = SchemaRowStore.getInstance();
  @Local env: AppEnvSnapshot = AppEnvManager.get();
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  /** 动态图标：选项标签（首项恒为「默认图标」，纯字符串——Select 不接受 Resource）、图标 id 列表、当前选中索引。 */
  @Local iconLabels: string[] = [];
  @Local iconIds: string[] = [];
  @Local iconSelected: number = 0;
  private hostContext: common.Context | undefined = undefined;

  aboutToAppear(): void {
    this.hostContext = this.getUIContext().getHostContext();
    this.vm.load();
    this.loadSchema();
  }

  private loadSchema(): void {
    const ctx: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    RawFileTextLoader.load(ctx, 'settings_schema.json')
      .then((raw: string): void => {
        const schema: SettingsSchema = SettingsSchema.parse(raw);
        const pageDef = schema.pages[this.page];
        if (pageDef !== undefined && pageDef.groups.length > 0) {
          this.groups = pageDef.groups;
        } else {
          this.groups = SettingsSchema.fallbackGroups();
        }
        this.store.loadRows(this.collectRows(this.groups));
        if (this.hasCacheRow(this.groups)) {
          this.vm.loadCacheSize(ctx);
        }
        if (this.hasIconRow(this.groups)) {
          this.loadDynamicIcons();
        }
      })
      .catch((): void => {
        this.groups = SettingsSchema.fallbackGroups();
      });
  }


  /** 本页是否有动态图标行（决定是否预取图标列表）。 */
  private hasIconRow(groups: SchemaGroupDef[]): boolean {
    for (const group of groups) {
      for (const row of group.rows) {
        if (row.builtin === 'dynamicIcon') {
          return true;
        }
      }
    }
    return false;
  }

  private collectRows(groups: SchemaGroupDef[]): SchemaRowDef[] {
    const rows: SchemaRowDef[] = [];
    for (const group of groups) {
      for (const row of group.rows) {
        rows.push(row);
      }
    }
    return rows;
  }

  private hasCacheRow(groups: SchemaGroupDef[]): boolean {
    for (const group of groups) {
      for (const row of group.rows) {
        if (row.valueSource === 'cacheSize' || row.builtin === 'clearCache') {
          return true;
        }
      }
    }
    return false;
  }

  // ———————— 文案 / 资源解析 ————————

  /** "$r:key" → resourceManager 按名解析（失败回落原字面量）；其余按字面量直写。 */
  private resolveText(spec: string): ResourceStr {
    if (spec.length === 0) {
      return '';
    }
    if (spec.indexOf('$r:') === 0) {
      const key: string = spec.substring(3);
      if (this.hostContext !== undefined) {
        try {
          return this.hostContext.resourceManager.getStringByNameSync(key);
        } catch (error) {
          return spec;
        }
      }
    }
    return spec;
  }

  private deviceAllowed(row: SchemaRowDef): boolean {
    if (row.deviceTypes.length === 0) {
      return true;
    }
    return row.deviceTypes.indexOf(AppEnvManager.get().deviceType) >= 0;
  }

  // ———————— 动态值源（v3.28 后缀实时值等价复刻） ————————

  private modeLabels(): ResourceStr[] {
    return [
      $r('app.string.opt_follow_system'),
      $r('app.string.opt_light'),
      $r('app.string.opt_dark')
    ];
  }

  private valueText(row: SchemaRowDef): ResourceStr {
    if (row.valueSource === 'displayMode') {
      return this.modeLabels()[this.vm.displayModeIndex()];
    }
    if (row.valueSource === 'cacheSize') {
      return this.cacheText();
    }
    if (row.valueSource === 'versionName') {
      return this.env.versionName.length > 0 ? this.env.versionName : '—';
    }
    return '';
  }


  private cacheText(): ResourceStr {
    if (this.vm.cacheSizeBytes < 0) {
      return $r('app.string.settings_cache_calculating');
    }
    return SettingsViewModel.formatSize(this.vm.cacheSizeBytes);
  }

  // ———————— 行为（内建动作 + 路由 + 清缓存确认，逐字复刻 v3.28 视图接线） ————————

  private pushRoute(route: string, param: string): void {
    // v3.32 双层栈：域内跳转压设置域内层栈（外层应用栈保持 Stack，设置域内按宽度自动分栏）
    if (param.length > 0) {
      this.settingsStack.pushPath({ name: route, param: param });
    } else {
      this.settingsStack.pushPath({ name: route });
    }
  }

  private runAction(actionId: string): void {
    if (actionId === 'shareApp') {
      // v3.39：分享入口已上移到设置根页 titleBar，设置行若配置 shareApp 仍复用同一实现
      AppShare.share(this.getUIContext());
      return;
    }
    if (actionId === 'checkUpdate') {
      this.runCheckUpdate();
      return;
    }
    if (actionId === 'rateApp') {
      this.runRateApp();
      return;
    }
    if (actionId === 'privacyStatement') {
      this.openPrivacyLink(StorePrivacyKind.STATEMENT);
      return;
    }
    if (actionId === 'userAgreement') {
      this.openPrivacyLink(StorePrivacyKind.USER_AGREEMENT);
      return;
    }
    if (actionId === 'revokePrivacy') {
      this.confirmRevokePrivacy();
      return;
    }
    SettingsSchemaActions.run(actionId);
  }

  // ———————— 上架后能力（v3.39：更新 / 评分 / 隐私 / 动态图标，全部带降级） ————————

  /**
   * 检查更新（保持 action 可用，供 fork 在 schema 里自行加回入口行）。
   * 默认入口是「关于本应用」子页的按钮（v3.40 起根页不再放这两行）。
   */
  private runCheckUpdate(): void {
    const helper: AppGalleryHelper = AppGalleryHelper.getInstance();
    helper.checkUpdate(true).then((result: StoreCapabilityResult): void => {
      if (result === StoreCapabilityResult.OK) {
        helper.showUpdateDialog().then((shown: StoreCapabilityResult): void => {
          if (shown !== StoreCapabilityResult.OK) {
            StoreFeedback.openMarket($r('app.string.settings_update_failed'));
          }
        });
        return;
      }
      if (result === StoreCapabilityResult.UP_TO_DATE) {
        CommonToast.info($r('app.string.settings_update_none'));
        return;
      }
      this.fallbackForUpdate(result);
    });
  }
  /** 更新失败分档降级：能解释的直接提示，其余统一跳市场详情页兜底。 */
  private fallbackForUpdate(result: StoreCapabilityResult): void {
    const message: ResourceStr = StoreFeedback.updateMessage(result);
    if (`${message}`.length > 0) {
      CommonToast.info(message);
      return;
    }
    StoreFeedback.openMarket($r('app.string.settings_update_failed'));
  }

  /** 应用内评分：官方弹窗优先，失败按码给不同提示，兜底跳市场。 */
  private runRateApp(): void {
    AppGalleryHelper.getInstance().showCommentDialog().then((result: StoreCapabilityResult): void => {
      if (result === StoreCapabilityResult.OK) {
        return;
      }
      const message: ResourceStr = StoreFeedback.rateMessage(result);
      if (`${message}`.length > 0) {
        CommonToast.info(message);
        return;
      }
      StoreFeedback.openMarket($r('app.string.settings_rate_failed'));
    });
  }

  /** 隐私声明 / 用户协议：官方链接优先，拿不到链接或拉起失败回退本地政策文本子页。 */
  private openPrivacyLink(kind: StorePrivacyKind): void {
    const url: string = AppGalleryHelper.getInstance().getPrivacyLink(kind);
    const fallbackParam: string = kind === StorePrivacyKind.STATEMENT ? 'privacy' : 'terms';
    if (url.length === 0) {
      CommonToast.info($r('app.string.settings_privacy_local'));
      this.pushRoute(SettingsRoute.POLICY, fallbackParam);
      return;
    }
    MarketHelper.getInstance().openUri(url).then((ok: boolean): void => {
      if (!ok) {
        this.pushRoute(SettingsRoute.POLICY, fallbackParam);
      }
    });
  }

  /** 撤回隐私授权：危险语义二次确认 + 后果说明（撤回后更新/评分会不可用）。 */
  private confirmRevokePrivacy(): void {
    if (!AppGalleryHelper.getInstance().usable(StoreSkill.PRIVACY)) {
      CommonToast.info($r('app.string.settings_privacy_unavailable'));
      return;
    }
    AppDialog.open(this.getUIContext(), DialogSemantic.DANGER,
      this.toPlainText($r('app.string.settings_privacy_revoke')),
      this.toPlainText($r('app.string.settings_privacy_revoke_msg')),
      (): void => {
        const result: StoreCapabilityResult = AppGalleryHelper.getInstance().revokePrivacyConsent();
        if (result === StoreCapabilityResult.OK) {
          CommonToast.info($r('app.string.settings_privacy_revoked'));
        } else {
          CommonToast.info($r('app.string.settings_privacy_unavailable'));
        }
      },
      // 危险语义复用，但动词是「撤回」不是「删除」（v3.39）
      this.toPlainText($r('app.string.settings_privacy_revoke_ok')));
  }

  /** 资源文案转纯字符串（Select 的选项只接受纯文本，Resource 会被渲染成空）。 */
  private toPlainText(value: ResourceStr): string {
    if (typeof value === 'string') {
      return value;
    }
    if (this.hostContext !== undefined) {
      try {
        return this.hostContext.resourceManager.getStringSync(value as Resource);
      } catch (err) {
        return '';
      }
    }
    return '';
  }

  /** 动态图标选项文案（带序号的格式串；资源缺失时回落英文兜底）。 */
  private iconItemLabel(seq: number): string {
    if (this.hostContext !== undefined) {
      try {
        return this.hostContext.resourceManager.getStringSync($r('app.string.settings_icon_item').id, seq);
      } catch (err) {
        return `Icon ${seq}`;
      }
    }
    return `Icon ${seq}`;
  }

  /** 拉取动态图标列表（首项恒「默认图标」，空列表表示未配置 → 整行隐藏）。 */
  private loadDynamicIcons(): void {
    AppGalleryHelper.getInstance().queryDynamicIcons().then((icons: StoreDynamicIcon[]): void => {
      if (icons.length === 0) {
        this.iconLabels = [];
        this.iconIds = [];
        this.iconSelected = 0;
        return;
      }
      const labels: string[] = [this.toPlainText($r('app.string.settings_icon_default'))];
      const ids: string[] = [''];
      let selected: number = 0;
      for (let index = 0; index < icons.length; index++) {
        labels.push(this.iconItemLabel(index + 1));
        ids.push(icons[index].iconId);
        if (icons[index].enabled) {
          selected = ids.length - 1;
        }
      }
      this.iconLabels = labels;
      this.iconIds = ids;
      this.iconSelected = selected;
    });
  }

  /** 切换动态图标（索引 0 = 恢复默认）；失败回滚显示并提示。 */
  private onSelectIcon(index: number): void {
    if (index < 0 || index >= this.iconIds.length) {
      return;
    }
    const helper: AppGalleryHelper = AppGalleryHelper.getInstance();
    const iconId: string = this.iconIds[index];
    this.iconSelected = index;
    const task: Promise<StoreCapabilityResult> = iconId.length === 0
      ? helper.disableDynamicIcon()
      : helper.selectDynamicIcon(iconId);
    task.then((result: StoreCapabilityResult): void => {
      if (result === StoreCapabilityResult.OK) {
        CommonToast.info($r('app.string.settings_icon_applied'));
        return;
      }
      CommonToast.info($r('app.string.settings_icon_failed'));
      this.loadDynamicIcons();
    });
  }

  private confirmClearCache(): void {
    const ctx: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.getUIContext().showAlertDialog({
      title: $r('app.string.settings_clear_cache'),
      message: $r('app.string.settings_clear_cache_confirm_msg'),
      primaryButton: {
        value: $r('app.string.settings_dialog_cancel'),
        action: (): void => {
        }
      },
      secondaryButton: {
        value: $r('app.string.settings_clear_cache_ok'),
        action: (): void => {
          this.vm.clearCache(ctx).then((): void => {
            CommonToast.info($r('app.string.settings_cache_cleared'));
          });
        }
      }
    });
  }

  // ———————— 图标前缀（chip 默认 / tint 降级 / 无前缀安全兜底） ————————

  private prefixOf(row: SchemaRowDef): PrefixCustomBuilder | PrefixIcon | undefined {
    const icon: SchemaIconDef | undefined = row.icon;
    if (icon === undefined || icon.symbol.length === 0) {
      return undefined;
    }
    const symbolRes: Resource | undefined = SettingsSchema.symbolResource(icon.symbol);
    if (symbolRes === undefined) {
      return undefined;
    }
    const tintRes: Resource | undefined = SettingsSchema.tintResource(icon.tint);
    // PrefixIconOptions 无着色字段（对表 kit barrel 实证）——'tint' 风格降级为纯图标，
    // 彩底贴片（chip，默认）为唯一着色路径（chart_c01~c20 色板）。
    if (icon.style === 'tint' || tintRes === undefined) {
      return new PrefixIcon({ iconSize: IconSize.SYSTEM_ICON, iconValue: { symbol: symbolRes } });
    }
    return new PrefixCustomBuilder((): void => {
      this.iconChip(symbolRes, tintRes);
    });
  }

  /** 行图标 symbol（无图标配置时为 undefined）。 */
  private symbolOf(row: SchemaRowDef): Resource | undefined {
    const icon: SchemaIconDef | undefined = row.icon;
    if (icon === undefined || icon.symbol.length === 0) {
      return undefined;
    }
    return SettingsSchema.symbolResource(icon.symbol);
  }

  /** 行图标 chip 底色（无 tint 配置时透明）。 */
  private tintOf(row: SchemaRowDef): ResourceColor {
    const icon: SchemaIconDef | undefined = row.icon;
    if (icon === undefined) {
      return Color.Transparent;
    }
    const tint: Resource | undefined = SettingsSchema.tintResource(icon.tint);
    return tint !== undefined ? tint : Color.Transparent;
  }


  @Builder
  iconChip(symbolRes: Resource, tintRes: Resource) {
    // 图标 fill 恒白（v3.30 polish：app_text_on_brand 恒 #FFFFFF，深浅色统一，用户裁定）
    Column() {
      SymbolGlyph(symbolRes)
        .fontSize(AppSize.ICON_LG)
        .fontColor([$r('app.color.app_text_on_brand')])
    }
    .width(AppSize.ICON_CHIP)
    .height(AppSize.ICON_CHIP)
    .borderRadius(AppRadius.FULL)
    .backgroundColor(tintRes)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // ———————— 组渲染 ————————

  @Builder
  groupHeader(title: ResourceStr) {
    // HDS 设置分组标题惯例（v3.30 polish）：小字次要色标签，层级让位于行内容
    // v3.32 宽度统一：左内边距对齐 HdsListItemCard 的横向内缩（实测 17.33vp），
    // 使标题与行背景左边缘同一条竖线（原 XS 会让标题比行多出一个缩进）。
    Text(title)
      .fontSize(AppFontSize.BODY_SM)
      .fontWeight(AppFontWeight.MEDIUM)
      .fontColor($r('app.color.app_text_secondary'))
      .width('100%')
      .padding({ left: AppSpacing.LG + AppSpacing.XXS })
  }

  @Builder
  groupBlock(group: SchemaGroupDef) {
    Column({ space: AppSpacing.MD }) {
      if (group.title.length > 0) {
        this.groupHeader(this.resolveText(group.title))
      }
      if (group.type === 'grid') {
        this.gridBlock(group)
      } else {
        Column({ space: AppSpacing.SM }) {
          ForEach(group.rows, (row: SchemaRowDef) => {
            if (this.deviceAllowed(row)) {
              this.schemaRow(row)
            }
          }, (row: SchemaRowDef): string => row.id)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // ———————— 操作宫格（EasyMath 更多操作 / EasyRandom 更多信息范式吸收） ————————

  private gridColumns(): string {
    const bp: string = `${this.breakpoint.breakpoint}`;
    if (bp === 'lg' || bp === 'xl') {
      return '1fr 1fr 1fr 1fr';
    }
    if (bp === 'md') {
      return '1fr 1fr 1fr';
    }
    return '1fr 1fr';
  }

  private gridSymbolRes(row: SchemaRowDef): Resource {
    if (row.icon !== undefined) {
      const res: Resource | undefined = SettingsSchema.symbolResource(row.icon.symbol);
      if (res !== undefined) {
        return res;
      }
    }
    return $r('sys.symbol.gearshape');
  }

  private gridTintRes(row: SchemaRowDef): Resource {
    if (row.icon !== undefined) {
      const res: Resource | undefined = SettingsSchema.tintResource(row.icon.tint);
      if (res !== undefined) {
        return res;
      }
    }
    return $r('app.color.chart_c01');
  }

  @Builder
  gridBlock(group: SchemaGroupDef) {
    Grid() {
      ForEach(group.rows, (row: SchemaRowDef) => {
        GridItem() {
          Column({ space: AppSpacing.XS }) {
            Column() {
              SymbolGlyph(this.gridSymbolRes(row))
                .fontSize(AppSize.ICON_LG)
                .fontColor([$r('app.color.app_text_on_brand')])
            }
            .width(AppSize.ICON_CHIP)
            .height(AppSize.ICON_CHIP)
            .borderRadius(AppRadius.FULL)
            .backgroundColor(this.gridTintRes(row))
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

            Text(this.resolveText(row.title))
              .fontSize(AppFontSize.BODY_SM)
              .fontColor($r('app.color.app_text_primary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .padding(AppSpacing.MD)
          .borderRadius(AppRadius.XL)
          .backgroundColor($r('app.color.app_bg_card'))
          .alignItems(HorizontalAlign.Center)
          .onClick((): void => {
            if (row.route.length > 0) {
              this.pushRoute(row.route, row.param);
            } else {
              this.runAction(row.actionId);
            }
          })
        }
      }, (row: SchemaRowDef): string => row.id)
    }
    .columnsTemplate(this.gridColumns())
    .columnsGap(AppSpacing.MD)
    .rowsGap(AppSpacing.MD)
    .width('100%')
  }

  // ———————— 行渲染（七行型分发） ————————

  private selectValueLabel(row: SchemaRowDef): ResourceStr {
    const idx: number = this.store.numberValues.get(row.prefKey) ?? row.defaultNumber();
    const clamped: number = idx >= 0 && idx < row.options.length ? idx : 0;
    if (row.options.length === 0) {
      return '';
    }
    return this.resolveText(row.options[clamped].label);
  }

  private optionLabelList(row: SchemaRowDef): ResourceStr[] {
    return row.options.map((option): ResourceStr => this.resolveText(option.label));
  }

  @Builder
  schemaRow(row: SchemaRowDef) {
    if (row.type === 'builtin') {
      this.builtinRow(row)
    } else if (row.type === 'nav') {
      SettingsRow({
        title: this.resolveText(row.title),
        subtitle: row.subtitle.length > 0 ? this.resolveText(row.subtitle) : '',
        icon: this.symbolOf(row),
        iconTint: this.tintOf(row),
        valueText: row.valueSource.length > 0 ? this.valueText(row) : '',
        onRowClick: (): void => {
          this.pushRoute(row.route, row.param);
        }
      })
    } else if (row.type === 'action') {
      SettingsRow({
        title: this.resolveText(row.title),
        subtitle: row.subtitle.length > 0 ? this.resolveText(row.subtitle) : '',
        icon: this.symbolOf(row),
        iconTint: this.tintOf(row),
        // v3.39：action 行也支持后缀动态值（检查更新行显示「检查中 / 已是最新 / 暂不可用」）
        valueText: row.valueSource.length > 0 ? this.valueText(row) : '',
        onRowClick: (): void => {
          this.runAction(row.actionId);
        }
      })
    } else if (row.type === 'info') {
      SettingsRow({
        title: this.resolveText(row.title),
        subtitle: row.subtitle.length > 0 ? this.resolveText(row.subtitle) : '',
        icon: this.symbolOf(row),
        iconTint: this.tintOf(row),
        valueText: this.valueText(row),
        showArrow: false
      })
    } else if (row.type === 'switch') {
      SettingsSwitchRow({
        title: this.resolveText(row.title),
        subtitle: row.subtitle.length > 0 ? this.resolveText(row.subtitle) : '',
        icon: this.symbolOf(row),
        iconTint: this.tintOf(row),
        isOn: this.store.boolValues.get(row.prefKey) ?? row.defaultBool(),
        onToggle: (on: boolean): void => {
          this.store.setBool(row.prefKey, on);
        }
      })
    } else if (row.type === 'select') {
      SettingsSelectRow({
        title: this.resolveText(row.title),
        subtitle: row.subtitle.length > 0 ? this.resolveText(row.subtitle) : '',
        icon: this.symbolOf(row),
        iconTint: this.tintOf(row),
        options: this.optionLabelList(row),
        selected: this.store.numberValues.get(row.prefKey) ?? row.defaultNumber(),
        onSelect: (index: number): void => {
          this.store.setNumber(row.prefKey, index);
        }
      })
    } else if (row.type === 'slider') {
      HdsListItemCard({
        prefixItem: this.prefixOf(row),
        textItem: {
          primaryText: { text: this.resolveText(row.title) },
          secondaryText: row.subtitle.length > 0 ? { text: this.resolveText(row.subtitle) } : undefined
        },
        suffixItem: new SuffixCustomBuilder((): void => {
          this.rowSlider(row)
        })
      })
        .width('100%')
    }
  }

  @Builder
  rowSlider(row: SchemaRowDef) {
    Slider({
      value: this.store.numberValues.get(row.prefKey) ?? row.defaultNumber(),
      min: row.min,
      max: row.max,
      step: row.step
    })
      .width('80%')
      .onChange((value: number, mode: SliderChangeMode): void => {
        if (mode === SliderChangeMode.End) {
          this.store.setNumber(row.prefKey, value);
        } else {
          this.store.setNumberLive(row.prefKey, value);
        }
      })
  }

  // ———————— builtin 行为行（逐字复刻 v3.28 视图接线，行为零改） ————————

  private languageLabels(): ResourceStr[] {
    // 语言名以各自母语原样呈现（跨语言环境不变，v3.13 口径）
    return [
      $r('app.string.opt_follow_system'),
      '简体中文',
      'English'
    ];
  }

  private orientationLabels(): ResourceStr[] {
    return [
      $r('app.string.opt_orientation_auto'),
      $r('app.string.opt_orientation_portrait'),
      $r('app.string.opt_orientation_landscape')
    ];
  }

  private fontSizeLabels(): ResourceStr[] {
    return [
      $r('app.string.opt_font_xs'),
      $r('app.string.opt_font_sm'),
      $r('app.string.opt_font_md'),
      $r('app.string.opt_font_lg'),
      $r('app.string.opt_font_xl')
    ];
  }

  @Builder
  builtinRow(row: SchemaRowDef) {
    if (row.builtin === 'accentColor') {
      Column() {
        AccentColorSetting()
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(AppSpacing.LG)
      .borderRadius(AppRadius.XL)
      .backgroundColor($r('app.color.app_bg_card'))
    } else if (row.builtin === 'dynamicIcon') {
      // 动态图标（v3.39）：官方列表为空 = 未配置 / 未上架 / 系统不支持 → 整行不渲染。
      // 用自绘 SettingsSelectRow（不用 HdsListItemCard：设置域宽度边际由 pagePadding 统一决定）。
      if (this.iconLabels.length > 0) {
        SettingsSelectRow({
          title: this.resolveText(row.title),
          subtitle: row.subtitle.length > 0 ? this.resolveText(row.subtitle) : '',
          icon: this.symbolOf(row),
          iconTint: this.tintOf(row),
          options: this.iconLabels,
          selected: this.iconSelected,
          onSelect: (index: number): void => {
            this.onSelectIcon(index);
          }
        })
      }
    } else if (row.builtin === 'displayMode') {
      HdsListItemCard({
        prefixItem: this.prefixOf(row),
        textItem: {
          primaryText: { text: this.resolveText(row.title) },
          secondaryText: row.subtitle.length > 0 ? { text: this.resolveText(row.subtitle) } : undefined
        },
        suffixItem: new SuffixSelect({
          value: this.modeLabels()[this.vm.displayModeIndex()],
          optionValues: this.modeLabels(),
          optionSymbol: [],
          selected: this.vm.displayModeIndex(),
          onSelect: (index: number): void => {
            this.vm.selectDisplayMode(index);
          }
        })
      })
        .width('100%')
    } else if (row.builtin === 'language') {
      HdsListItemCard({
        prefixItem: this.prefixOf(row),
        textItem: {
          primaryText: { text: this.resolveText(row.title) },
          secondaryText: row.subtitle.length > 0 ? { text: this.resolveText(row.subtitle) } : undefined
        },
        suffixItem: new SuffixSelect({
          value: this.languageLabels()[this.vm.languageIndex()],
          optionValues: this.languageLabels(),
          optionSymbol: [],
          selected: this.vm.languageIndex(),
          onSelect: (index: number): void => {
            const needRestart: boolean = this.vm.selectLanguage(index);
            if (needRestart) {
              CommonToast.info($r('app.string.settings_language_restart_hint'));
            }
          }
        })
      })
        .width('100%')
    } else if (row.builtin === 'fontSize') {
      HdsListItemCard({
        prefixItem: this.prefixOf(row),
        textItem: {
          primaryText: { text: this.resolveText(row.title) },
          secondaryText: row.subtitle.length > 0 ? { text: this.resolveText(row.subtitle) } : undefined
        },
        suffixItem: new SuffixSelect({
          value: this.fontSizeLabels()[this.vm.fontSizeIndex],
          optionValues: this.fontSizeLabels(),
          optionSymbol: [],
          selected: this.vm.fontSizeIndex,
          onSelect: (index: number): void => {
            this.vm.selectFontSize(index);
          }
        })
      })
        .width('100%')
    } else if (row.builtin === 'haptic') {
      HdsListItemCard({
        prefixItem: this.prefixOf(row),
        textItem: {
          primaryText: { text: this.resolveText(row.title) },
          secondaryText: row.subtitle.length > 0 ? { text: this.resolveText(row.subtitle) } : undefined
        },
        suffixItem: new SuffixSwitch({
          isCheck: this.vm.hapticEnabled,
          onChange: (on: boolean): void => {
            this.vm.toggleHaptic(on);
          }
        })
      })
        .width('100%')
    } else if (row.builtin === 'keepScreenOn') {
      HdsListItemCard({
        prefixItem: this.prefixOf(row),
        textItem: {
          primaryText: { text: this.resolveText(row.title) },
          secondaryText: row.subtitle.length > 0 ? { text: this.resolveText(row.subtitle) } : undefined
        },
        suffixItem: new SuffixSwitch({
          isCheck: this.vm.keepScreenOn,
          onChange: (on: boolean): void => {
            this.vm.toggleKeepScreenOn(on);
          }
        })
      })
        .width('100%')
    } else if (row.builtin === 'orientation') {
      HdsListItemCard({
        prefixItem: this.prefixOf(row),
        textItem: {
          primaryText: { text: this.resolveText(row.title) },
          secondaryText: row.subtitle.length > 0 ? { text: this.resolveText(row.subtitle) } : undefined
        },
        suffixItem: new SuffixSelect({
          value: this.orientationLabels()[this.vm.orientationIndex()],
          optionValues: this.orientationLabels(),
          optionSymbol: [],
          selected: this.vm.orientationIndex(),
          onSelect: (index: number): void => {
            this.vm.selectOrientation(index);
          }
        })
      })
        .width('100%')
    } else if (row.builtin === 'clearCache') {
      HdsListItemCard({
        prefixItem: this.prefixOf(row),
        textItem: {
          primaryText: { text: this.resolveText(row.title) },
          secondaryText: row.subtitle.length > 0 ? { text: this.resolveText(row.subtitle) } : undefined
        },
        suffixItem: new SuffixTextAndArrow({ text: this.cacheText() }),
        onClick: (): void => {
          this.confirmClearCache();
        }
      })
        .width('100%')
    } else if (row.builtin === 'systemJump') {
      HdsListItemCard({
        prefixItem: this.prefixOf(row),
        textItem: {
          primaryText: { text: this.resolveText(row.title) },
          secondaryText: row.subtitle.length > 0 ? { text: this.resolveText(row.subtitle) } : undefined
        },
        suffixItem: new SuffixArrow(),
        onClick: (): void => {
          const ctx: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
          AppSettingsJump.jumpToAppSystemSettings(ctx);
        }
      })
        .width('100%')
    }
  }

  build() {
    Column({ space: DesignToken.sectionSpacing() }) {
      ForEach(this.groups, (group: SchemaGroupDef) => {
        this.groupBlock(group)
      }, (group: SchemaGroupDef): string => group.id)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
