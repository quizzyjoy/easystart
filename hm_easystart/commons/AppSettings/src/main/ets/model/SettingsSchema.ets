/**
 * 设置页 schema 引擎（v3.30，TODO-021）：全页数据驱动的多 app 可复用设置页。
 *
 * 口径：「结构进模板、内容 fork 填」的延伸——设置页的组 / 行 / 控件 / 偏好键 /
 * 深链目标全部由 rawfile/settings_schema.json 定义，fork 改 JSON 即得定制设置页；
 * 新符号图标经 registerSymbol 一行注册（$r 为编译期引用，无法按名动态取）。
 *
 * 解析纪律（沿 SettingsContentModels v3.28）：JSON 边界单次 `as Record<string, Object>`
 * + 逐字段 typeof 校验；缺失 / 破坏时整包回落 fallbackGroups() 最小骨架，不崩溃。
 * 文案约定：`"$r:key"` 前缀 = 资源键（渲染层经 resourceManager.getStringByNameSync
 * 解析，失败回落原字面量）；其余字符串 = 字面量直写（fork 普通写法）。
 * 色板约定：icon.tint 取 `c01`~`c20`（AppScope chart_cXX 双份深浅色令牌，静态映射）。
 */
export class SchemaIconDef {
  /** 符号注册表键名（sys.symbol 短名，如 'paintbrush_fill'）。 */
  symbol: string = '';
  /** 彩底色板键（'c01'~'c20'；空 = 不着色）。 */
  tint: string = '';
  /** 图标风格：'chip'（默认，圆形彩底贴片）| 'tint'（仅图标着色）。 */
  style: string = 'chip';
}

/** select 行选项。label 支持字面量或 "$r:key"；value 预留（当前 select 存索引档位）。 */
export class SchemaOptionDef {
  label: string = '';
  value: string = '';
}

export class SchemaRowDef {
  id: string = '';
  /** 行型：nav | switch | select | slider | action | info | builtin。 */
  type: string = '';
  /** builtin 行为键：displayMode | language | fontSize | haptic | keepScreenOn |
   *  orientation | clearCache | systemJump | accentColor（映射 SettingsViewModel，行为零改）。 */
  builtin: string = '';
  /** nav/info 目标路由值（SettingsRoute 域内同值）。 */
  route: string = '';
  /** 路由参数（POLICY 三 kind 等）。 */
  param: string = '';
  /** action 行动作键（内建 shareApp，fork 经 SettingsSchemaActions 注册扩展）。 */
  actionId: string = '';
  /** switch/select/slider 通用偏好键（SchemaRowStore 泛型读写 + 钩子）。 */
  prefKey: string = '';
  /** 通用行默认值（字符串形式：'true' / '2' / '0.85'）。 */
  defaultValue: string = '';
  icon: SchemaIconDef | undefined = undefined;
  title: string = '';
  subtitle: string = '';
  /** 动态值源：displayMode | cacheSize | versionName（nav/info 行后缀实时值）。 */
  valueSource: string = '';
  options: SchemaOptionDef[] = [];
  /** 设备形态过滤（AppEnvManager.deviceType；空 = 全形态）。 */
  deviceTypes: string[] = [];
  /** slider 参数。 */
  min: number = 0;
  max: number = 100;
  step: number = 1;

  defaultBool(): boolean {
    return this.defaultValue === 'true';
  }

  defaultNumber(): number {
    const parsed: number = Number(this.defaultValue);
    return Number.isNaN(parsed) ? 0 : parsed;
  }
}

export class SchemaGroupDef {
  id: string = '';
  /** 组型：list（默认卡片行组）| grid（操作宫格区块）。 */
  type: string = 'list';
  title: string = '';
  rows: SchemaRowDef[] = [];
}

export class SchemaPageDef {
  groups: SchemaGroupDef[] = [];
}

export class SettingsSchema {
  /** 页表：home（设置主页组区）/ general / appearance（fork 可自扩页键）。 */
  pages: Record<string, SchemaPageDef> = {};

  /** 解析 schema 文本；任何缺失 / 破坏均静默回落空 schema（渲染层取 fallbackGroups）。 */
  static parse(raw: string): SettingsSchema {
    const schema: SettingsSchema = new SettingsSchema();
    try {
      const root: Record<string, Object> = JSON.parse(raw) as Record<string, Object>;
      const pagesRaw: Object | undefined = root['pages'];
      if (pagesRaw === undefined) {
        return schema;
      }
      const pagesRec: Record<string, Object> = pagesRaw as Record<string, Object>;
      const pageIds: string[] = ['home', 'general', 'appearance'];
      for (const pageId of pageIds) {
        const pageRaw: Object | undefined = pagesRec[pageId];
        if (pageRaw !== undefined) {
          schema.pages[pageId] = SettingsSchema.parsePage(pageRaw as Record<string, Object>);
        }
      }
    } catch (error) {
      return new SettingsSchema();
    }
    return schema;
  }

  /** 兜底最小骨架：schema 缺失 / 破坏时的降级面（外观与通用 + 关于入口）。 */
  static fallbackGroups(): SchemaGroupDef[] {
    const appearanceRow: SchemaRowDef = new SchemaRowDef();
    appearanceRow.id = 'fallback_appearance';
    appearanceRow.type = 'nav';
    appearanceRow.route = 'appearance';
    appearanceRow.title = '$r:settings_appearance';
    const generalRow: SchemaRowDef = new SchemaRowDef();
    generalRow.id = 'fallback_general';
    generalRow.type = 'nav';
    generalRow.route = 'general';
    generalRow.title = '$r:settings_general_title';
    const aboutRow: SchemaRowDef = new SchemaRowDef();
    aboutRow.id = 'fallback_about';
    aboutRow.type = 'nav';
    aboutRow.route = 'about';
    aboutRow.title = '$r:settings_about';
    const groupMain: SchemaGroupDef = new SchemaGroupDef();
    groupMain.id = 'fallback_main';
    groupMain.title = '$r:settings_group_general';
    groupMain.rows = [appearanceRow, generalRow];
    const groupAbout: SchemaGroupDef = new SchemaGroupDef();
    groupAbout.id = 'fallback_about_group';
    groupAbout.title = '$r:settings_group_about';
    groupAbout.rows = [aboutRow];
    return [groupMain, groupAbout];
  }

  private static parsePage(rec: Record<string, Object>): SchemaPageDef {
    const page: SchemaPageDef = new SchemaPageDef();
    const groupsRaw: Object | undefined = rec['groups'];
    if (groupsRaw === undefined || !Array.isArray(groupsRaw)) {
      return page;
    }
    const groupsArr: Object[] = groupsRaw as Object[];
    for (const groupItem of groupsArr) {
      const groupRec: Record<string, Object> = groupItem as Record<string, Object>;
      const group: SchemaGroupDef = new SchemaGroupDef();
      group.id = SettingsSchema.str(groupRec, 'id');
      group.type = SettingsSchema.str(groupRec, 'type');
      group.type = group.type.length > 0 ? group.type : 'list';
      group.title = SettingsSchema.str(groupRec, 'title');
      group.rows = SettingsSchema.parseRows(groupRec);
      page.groups.push(group);
    }
    return page;
  }

  private static parseRows(groupRec: Record<string, Object>): SchemaRowDef[] {
    const rows: SchemaRowDef[] = [];
    const rowsRaw: Object | undefined = groupRec['rows'];
    if (rowsRaw === undefined || !Array.isArray(rowsRaw)) {
      return rows;
    }
    const rowsArr: Object[] = rowsRaw as Object[];
    for (const rowItem of rowsArr) {
      const rowRec: Record<string, Object> = rowItem as Record<string, Object>;
      const row: SchemaRowDef = new SchemaRowDef();
      row.id = SettingsSchema.str(rowRec, 'id');
      row.type = SettingsSchema.str(rowRec, 'type');
      row.builtin = SettingsSchema.str(rowRec, 'builtin');
      row.route = SettingsSchema.str(rowRec, 'route');
      row.param = SettingsSchema.str(rowRec, 'param');
      row.actionId = SettingsSchema.str(rowRec, 'actionId');
      row.prefKey = SettingsSchema.str(rowRec, 'prefKey');
      row.defaultValue = SettingsSchema.str(rowRec, 'defaultValue');
      row.title = SettingsSchema.str(rowRec, 'title');
      row.subtitle = SettingsSchema.str(rowRec, 'subtitle');
      row.valueSource = SettingsSchema.str(rowRec, 'valueSource');
      row.min = SettingsSchema.num(rowRec, 'min', 0);
      row.max = SettingsSchema.num(rowRec, 'max', 100);
      row.step = SettingsSchema.num(rowRec, 'step', 1);
      row.deviceTypes = SettingsSchema.strArray(rowRec, 'deviceTypes');
      row.icon = SettingsSchema.parseIcon(rowRec);
      row.options = SettingsSchema.parseOptions(rowRec);
      // 清洗：缺 id/标题/type 直接丢弃；select 无选项丢弃；builtin 缺行为键按 nav 降级面丢弃
      if (row.id.length === 0 || row.title.length === 0 || row.type.length === 0) {
        continue;
      }
      if (row.type === 'select' && row.options.length === 0) {
        continue;
      }
      if (row.type === 'builtin' && row.builtin.length === 0) {
        continue;
      }
      rows.push(row);
    }
    return rows;
  }

  private static parseIcon(rowRec: Record<string, Object>): SchemaIconDef | undefined {
    const iconRaw: Object | undefined = rowRec['icon'];
    if (iconRaw === undefined) {
      return undefined;
    }
    const iconRec: Record<string, Object> = iconRaw as Record<string, Object>;
    const icon: SchemaIconDef = new SchemaIconDef();
    icon.symbol = SettingsSchema.str(iconRec, 'symbol');
    icon.tint = SettingsSchema.str(iconRec, 'tint');
    const style: string = SettingsSchema.str(iconRec, 'style');
    icon.style = style.length > 0 ? style : 'chip';
    return icon;
  }

  private static parseOptions(rowRec: Record<string, Object>): SchemaOptionDef[] {
    const options: SchemaOptionDef[] = [];
    const optionsRaw: Object | undefined = rowRec['options'];
    if (optionsRaw === undefined || !Array.isArray(optionsRaw)) {
      return options;
    }
    const optionsArr: Object[] = optionsRaw as Object[];
    for (const optionItem of optionsArr) {
      const optionRec: Record<string, Object> = optionItem as Record<string, Object>;
      const option: SchemaOptionDef = new SchemaOptionDef();
      option.label = SettingsSchema.str(optionRec, 'label');
      option.value = SettingsSchema.str(optionRec, 'value');
      if (option.label.length > 0) {
        options.push(option);
      }
    }
    return options;
  }

  private static str(rec: Record<string, Object>, key: string): string {
    const value: Object | undefined = rec[key];
    return typeof value === 'string' ? value : '';
  }

  private static num(rec: Record<string, Object>, key: string, fallback: number): number {
    const value: Object | undefined = rec[key];
    return typeof value === 'number' ? value : fallback;
  }

  private static strArray(rec: Record<string, Object>, key: string): string[] {
    const out: string[] = [];
    const value: Object | undefined = rec[key];
    if (value === undefined || !Array.isArray(value)) {
      return out;
    }
    const arr: Object[] = value as Object[];
    for (const item of arr) {
      if (typeof item === 'string') {
        out.push(item);
      }
    }
    return out;
  }

  // ———————— 资源注册表（$r 为编译期引用，schema 键名经静态映射解析） ————————

  /** 符号注册表：默认覆盖默认 schema 全部符号 + 家族实证备选；fork 经 registerSymbol 扩展。 */
  private static symbols: Record<string, Resource> = {
    'paintbrush_fill': $r('sys.symbol.paintbrush_fill'),
    'paintbrush': $r('sys.symbol.paintbrush'),
    'slider_horizontal_2': $r('sys.symbol.slider_horizontal_2'),
    'bell': $r('sys.symbol.bell'),
    'doc_text_badge_clock': $r('sys.symbol.doc_text_badge_clock'),
    'envelope_badge_adiowaves': $r('sys.symbol.envelope_badge_adiowaves'),
    'share': $r('sys.symbol.share'),
    'person_2': $r('sys.symbol.person_2'),
    'person_crop_circle_fill': $r('sys.symbol.person_crop_circle_fill'),
    'info_circle': $r('sys.symbol.info_circle'),
    'lock': $r('sys.symbol.lock'),
    'doc_text': $r('sys.symbol.doc_text'),
    'checkmark_circle': $r('sys.symbol.checkmark_circle'),
    'flag_fill': $r('sys.symbol.flag_fill'),
    'textformat': $r('sys.symbol.textformat'),
    'textformat_size_square': $r('sys.symbol.textformat_size_square'),
    'heart_fill': $r('sys.symbol.heart_fill'),
    'clock_fill': $r('sys.symbol.clock_fill'),
    'screen_rotation': $r('sys.symbol.screen_rotation'),
    'trash_fill': $r('sys.symbol.trash_fill'),
    'gearshape': $r('sys.symbol.gearshape'),
    'sun_max': $r('sys.symbol.sun_max'),
    'moon': $r('sys.symbol.moon'),
    'ellipsis_circle': $r('sys.symbol.ellipsis_circle'),
    'chevron_right': $r('sys.symbol.chevron_right'),
    // fill 变体族（v3.30 polish：默认 schema 行图标统一视觉重量；id_defined.json 逐名验证存在）
    'bell_fill': $r('sys.symbol.bell_fill'),
    'info_circle_fill': $r('sys.symbol.info_circle_fill'),
    'lock_fill': $r('sys.symbol.lock_fill'),
    'doc_text_fill': $r('sys.symbol.doc_text_fill'),
    'checkmark_circle_fill': $r('sys.symbol.checkmark_circle_fill'),
    'person_2_fill': $r('sys.symbol.person_2_fill'),
    'envelope_badge_adiowaves_fill': $r('sys.symbol.envelope_badge_adiowaves_fill'),
    'doc_text_badge_clock_fill': $r('sys.symbol.doc_text_badge_clock_fill'),
    'textformat_size_square_fill': $r('sys.symbol.textformat_size_square_fill'),
    'gearshape_fill': $r('sys.symbol.gearshape_fill'),
    'sun_max_fill': $r('sys.symbol.sun_max_fill'),
    'moon_fill': $r('sys.symbol.moon_fill'),
    'star_fill': $r('sys.symbol.star_fill'),
    'gift_fill': $r('sys.symbol.gift_fill'),
    'envelope_fill': $r('sys.symbol.envelope_fill'),
    'qrcode': $r('sys.symbol.qrcode')
  };

  /** fork 注册新符号（一行代码扩展点；未注册键渲染回落 gearshape）。 */
  static registerSymbol(name: string, resource: Resource): void {
    SettingsSchema.symbols[name] = resource;
  }

  static symbolResource(name: string): Resource | undefined {
    return SettingsSchema.symbols[name];
  }

  /** c01~c20 色板（chart_cXX 深浅双份令牌，静态映射）。 */
  private static tints: Record<string, Resource> = {
    'c01': $r('app.color.chart_c01'),
    'c02': $r('app.color.chart_c02'),
    'c03': $r('app.color.chart_c03'),
    'c04': $r('app.color.chart_c04'),
    'c05': $r('app.color.chart_c05'),
    'c06': $r('app.color.chart_c06'),
    'c07': $r('app.color.chart_c07'),
    'c08': $r('app.color.chart_c08'),
    'c09': $r('app.color.chart_c09'),
    'c10': $r('app.color.chart_c10'),
    'c11': $r('app.color.chart_c11'),
    'c12': $r('app.color.chart_c12'),
    'c13': $r('app.color.chart_c13'),
    'c14': $r('app.color.chart_c14'),
    'c15': $r('app.color.chart_c15'),
    'c16': $r('app.color.chart_c16'),
    'c17': $r('app.color.chart_c17'),
    'c18': $r('app.color.chart_c18'),
    'c19': $r('app.color.chart_c19'),
    'c20': $r('app.color.chart_c20')
  };

  static tintResource(name: string): Resource | undefined {
    return SettingsSchema.tints[name];
  }
}
