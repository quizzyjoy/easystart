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
import { AppFontSize, AppFontWeight, AppRadius, AppSize, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { AppEnvManager, AppEnvSnapshot, BreakpointManager, ShareHelper, common } from '@quizzyjoy/platform';
import { CommonToast } from '@easystart/app-component';
import { AccentColorSetting } from '../component/AccentColorSetting';
import { SettingsSchema, SchemaGroupDef, SchemaIconDef, SchemaRowDef } from '../model/SettingsSchema';
import { SchemaRowStore, SettingsSchemaActions } from '../model/SchemaRowStore';
import { SettingsViewModel } from '../viewmodel/SettingsViewModel';
import { AppSettingsJump } from '../util/AppSettingsJump';
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
  private hostContext: common.Context | undefined = undefined;
  private appName: string = '';

  aboutToAppear(): void {
    this.hostContext = this.getUIContext().getHostContext();
    this.vm.load();
    this.loadSchema();
    this.loadAppName();
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
      })
      .catch((): void => {
        this.groups = SettingsSchema.fallbackGroups();
      });
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

  private loadAppName(): void {
    try {
      if (this.hostContext !== undefined) {
        this.appName = this.hostContext.resourceManager.getStringSync($r('app.string.app_name').id);
      }
    } catch (error) {
      this.appName = '';
    }
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
      ShareHelper.getInstance().shareText(`${this.appName} v${this.env.versionName}`, {
        title: this.appName
      });
      return;
    }
    SettingsSchemaActions.run(actionId);
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
      HdsListItemCard({
        prefixItem: this.prefixOf(row),
        textItem: {
          primaryText: { text: this.resolveText(row.title) },
          secondaryText: row.subtitle.length > 0 ? { text: this.resolveText(row.subtitle) } : undefined
        },
        suffixItem: new SuffixSwitch({
          isCheck: this.store.boolValues.get(row.prefKey) ?? row.defaultBool(),
          onChange: (on: boolean): void => {
            this.store.setBool(row.prefKey, on);
          }
        })
      })
        .width('100%')
    } else if (row.type === 'select') {
      HdsListItemCard({
        prefixItem: this.prefixOf(row),
        textItem: {
          primaryText: { text: this.resolveText(row.title) },
          secondaryText: row.subtitle.length > 0 ? { text: this.resolveText(row.subtitle) } : undefined
        },
        suffixItem: new SuffixSelect({
          value: this.selectValueLabel(row),
          optionValues: this.optionLabelList(row),
          optionSymbol: [],
          selected: this.store.numberValues.get(row.prefKey) ?? row.defaultNumber(),
          onSelect: (index: number): void => {
            this.store.setNumber(row.prefKey, index);
          }
        })
      })
        .width('100%')
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
