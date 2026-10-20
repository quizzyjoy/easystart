/**
 * 学习 Tab 的教学章节内容（v3.38）。
 *
 * 定位：模板自带的教学文档——每章对应本工程里**真实存在**的代码，fork 后可整章替换。
 * 内容即代码（不用 rawfile + JSON 解析）：类型完整、编译期可查、无运行时 IO 失败面；
 * 后续加图只需给 LearnBlock 增加图片分支。
 */

/** 文档块（渲染层按 kind 分发：p 段落 / code 代码 / list 要点 / note 提示）。 */
export class LearnBlock {
  readonly kind: string;
  readonly text: string;
  readonly items: string[];

  constructor(kind: string, text: string, items: string[]) {
    this.kind = kind;
    this.text = text;
    this.items = items;
  }

  static paragraph(text: string): LearnBlock {
    return new LearnBlock('p', text, []);
  }

  static code(text: string): LearnBlock {
    return new LearnBlock('code', text, []);
  }

  static bullets(items: string[]): LearnBlock {
    return new LearnBlock('list', '', items);
  }

  static note(text: string): LearnBlock {
    return new LearnBlock('note', text, []);
  }
}

/** 一章教学文档。 */
export class LearnChapter {
  readonly id: string;
  readonly title: string;
  readonly summary: string;
  readonly minutes: number;
  readonly blocks: LearnBlock[];

  constructor(id: string, title: string, summary: string, minutes: number, blocks: LearnBlock[]) {
    this.id = id;
    this.title = title;
    this.summary = summary;
    this.minutes = minutes;
    this.blocks = blocks;
  }
}

/** 章节目录（顺序即列表顺序；新增章节在此追加一条）。 */
export const LEARN_CHAPTERS: LearnChapter[] = [
  new LearnChapter(
    'state-v1-v2',
    'ArkTS 状态管理：V1 → V2',
    '装饰器逐一对照 · 本工程真实写法 · 五个高频坑',
    8,
    [
      LearnBlock.paragraph(
        '本工程全量使用状态管理 V2。V1 的 @State/@Prop/@Link 加 @Observed/@ObjectLink 组合已被 V2 取代：' +
          'V2 观测粒度更细（属性级）、跨组件代理更强、派生值有专门装饰器。两者不能混用——同一个组件里' +
          '出现 V1 与 V2 装饰器会直接编译报错，所以迁移必须按组件逐个完成。'),
      LearnBlock.bullets([
        '@State → @Local：组件内部可变状态，只能在组件内初始化',
        '@Prop → @Param：父传子的只读入参，子组件不得赋值',
        '@Link 双向绑定 → @Param + @Event：子组件上抛事件，由父组件改状态',
        '@Observed + @ObjectLink → @ObservedV2 + @Trace：属性级观测，自动逐层代理',
        '@Watch → @Monitor：监听指定表达式的变化',
        '新增 @Computed：派生值，随依赖变化自动重算'
      ]),
      LearnBlock.paragraph('V1 写法（本工程已无此形态，仅作对照）：'),
      LearnBlock.code('@Observed\nclass Profile {\n  name: string = \'游客\';\n}\n\n' +
        '@Component\nstruct HeaderView {\n  @Prop title: string = \'\';\n' +
        '  @Link count: number = 0;      // 双向绑定\n  @State expanded: boolean = false;\n}'),
      LearnBlock.paragraph('V2 写法（本工程 commons/AppSettings/view/DeveloperView.ets 的真实片段）：'),
      LearnBlock.code('@ComponentV2\nexport struct DeveloperView {\n' +
        '  @Local profile: DeveloperProfile = new DeveloperProfile(...);\n' +
        '  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();\n' +
        '  @Local qrVisible: boolean = false;\n}'),
      LearnBlock.paragraph(
        '父子通信改成了单向数据流：@Param 只读入参 + @Event 回调上抛。本工程所有子页都按这个接法——' +
          '子组件不碰路由、不碰父状态，只把「用户点了什么」告诉父组件。'),
      LearnBlock.code('// 子组件：只读入参 + 事件上抛\n' +
        '@Param onOpenDetail: (item: HomeItem) => void = (item: HomeItem): void => {};\n\n' +
        '// 用户点击 → 只上报，不改自己也不改父\nthis.onOpenDetail(item);'),
      LearnBlock.paragraph(
        '嵌套对象靠 @ObservedV2 + @Trace 做到属性级观测。本工程 SettingsViewModel 是典型：' +
          '一个全局单例被多个设置子页共享，任一属性变化，所有绑定的页面一起刷新。'),
      LearnBlock.code('@ObservedV2\nexport class SettingsViewModel {\n' +
        '  @Trace colorMode: number = 0;   // 属性级观测，跨子页共享\n}'),
      LearnBlock.paragraph('五个高频坑（都在本工程踩过）：'),
      LearnBlock.bullets([
        'V1/V2 混用：@ComponentV2 里写 @State 直接编译失败，迁移按组件整块换，不要逐个装饰器试',
        '@Param 只读：子组件赋值会报 read-only property，改状态一律回父组件',
        '@Local 只代理第一层：嵌套对象内部变化不触发刷新，用 @ObservedV2/@Trace 或整体换引用',
        'ForEach 必须给稳定业务 key（用 id 不用索引），否则增删时复用错位、动画乱跳',
        '普通方法不在依赖追踪链上：派生值放 @Computed，否则状态变了文本不刷新（示例见组件示例的 ColorMath 区块）'
      ]),
      LearnBlock.note(
        '迁移顺序建议：先把装饰器整体换到 V2 → 再把双向绑定拆成 @Param + @Event → 最后处理嵌套对象的观测。' +
          '编译器报错带精确的 文件:行:列，按报错逐个改比通读代码快得多。')
    ]),
  new LearnChapter(
    'theme-skinning',
    '主题换肤：四层颜色模型',
    '静态令牌 / AttributeModifier / 运行时单例 / 系统默认色 · 以本工程现行实现为例',
    10,
    [
      LearnBlock.paragraph(
        '换肤看起来是"改一个颜色变量"，实际要动四处。屏幕上一处颜色的来源有四类，它们并列存在、不是优先级关系：' +
          '哪一层没接入，对应位置的像素就不会变。这也是"改了主题却只变一半"的唯一成因。'),
      LearnBlock.bullets([
        'L1 资源令牌 $r(app.color.qj_*)：编译期固化，只随深浅色变',
        'L2 AttributeModifier：普通类，不参与观察，切主题后要等页面重建',
        'L3 运行时主题单例：@ObservedV2 + @Trace，读它的组件当帧重渲染',
        'L4 ThemeControl.setDefaultTheme：接管系统组件与未显式着色位置的默认色'
      ]),
      LearnBlock.paragraph('本工程四层的落点如下（路径都真实存在，可直接打开对照）：'),
      LearnBlock.code(
        'L1  AppScope/resources/base/element/color.json                 // qj_brand 等令牌\n' +
        'L2  commons/AppComponent/src/main/ets/modifier/                 // AppButtonModifier 族\n' +
        'L3  quizzyjoy/VitalUI/src/main/ets/theme/UiThemeManager.ets     // 运行时单例\n' +
        'L4  quizzyjoy/Platform/src/main/ets/theme/AppThemeController.ets// hex → CustomTheme\n' +
        '编排 commons/AppComponent/src/main/ets/theme/AppThemeApplier.ets\n' +
        '启动 commons/AppCommon/src/main/ets/bootstrap/AppBootstrap.ets'
      ),
      LearnBlock.paragraph('L3 是整套方案的核心：一个 @ObservedV2 单例存两个字段，组件 @Local 引一下就能当帧响应。'),
      LearnBlock.code(
        '@ObservedV2\n' +
        'export class UiThemeManager {\n' +
        '  private static instance: UiThemeManager | undefined = undefined;\n' +
        '  @Trace presetId: string = DEFAULT_THEME_PRESET;   // 当前主题包\n' +
        '  @Trace accentColor: string = \'\';                 // 强调色覆盖\n' +
        '  private constructor() {}\n' +
        '  static getInstance(): UiThemeManager { /* 懒建单例 */ }\n' +
        '}'
      ),
      LearnBlock.paragraph(
        '强调色与主题包是叠加关系，不是二选一：强调色优先 → 主题包基准色 → 静态令牌。' +
          '注意默认主题包这一支回退到 $r(qj_brand 而不是硬编码同值 hex，深浅色才能继续由 resources/dark 负责。'),
      LearnBlock.code(
        'brandColor(): ResourceColor {\n' +
        '  if (this.accentColor.length > 0) { return this.accentColor; }\n' +
        '  if (this.presetId === DEFAULT_THEME_PRESET) { return $r(\'app.color.qj_brand\'); }\n' +
        '  return resolveThemePreset(this.presetId).baseHex;\n' +
        '}'
      ),
      LearnBlock.paragraph(
        'L2 的特殊之处：AttributeModifier 是普通类，不在组件的观察依赖图里，读 @Trace 字段不会触发重渲染。' +
          '工程用静态中转解决——铺层时把当前色写进静态字段，modifier 每次重建时再读一次。'),
      LearnBlock.code(
        'static brandColor(): ResourceColor {                 // AppThemeApplier\n' +
        '  return AppThemeApplier.currentAccent.length > 0\n' +
        '    ? AppThemeApplier.currentAccent : $r(\'app.color.qj_brand\');\n' +
        '}'
      ),
      LearnBlock.paragraph(
        'L4 把"一个色"翻译成一套令牌。工程覆盖七个：brand、fontEmphasize、iconEmphasize、' +
          'backgroundEmphasize、compEmphasizeSecondary、compEmphasizeTertiary、interactiveSelect。' +
          'colors 与 darkColors 必须成对，否则深色模式下会出现亮底亮字。'),
      LearnBlock.code(
        'ThemeControl.setDefaultTheme({\n' +
        '  colors: AppThemeController.lightColors(hex),      // 7 个令牌\n' +
        '  darkColors: AppThemeController.darkColors(hex)    // 深色派生，API 20 起\n' +
        '} as CustomTheme);'
      ),
      LearnBlock.paragraph(
        '铺层顺序有契约：先写单例，再算 effectiveAccent()，最后铺 L4。顺序反过来会取到上一次的颜色，' +
          'L4 就被铺成旧主题。'),
      LearnBlock.code(
        'static apply(presetId: string, accentHex: string): void {\n' +
        '  const theme: UiThemeManager = UiThemeManager.getInstance();\n' +
        '  theme.setPresetId(presetId);                              // 1. 先 L3\n' +
        '  theme.setAccentColor(accentHex);\n' +
        '  AppThemeApplier.currentAccent = theme.effectiveAccent();  // 2. 静态中转\n' +
        '  AppThemeController.applyPreset(theme.presetId, theme.accentColor);  // 3. 再 L4\n' +
        '}'
      ),
      LearnBlock.paragraph(
        '冷启动把读取与注入拆开：AppBootstrap.restoreTheme() 只读偏好、返回纯数据，' +
          '由各入口 Ability 自己调 apply 注入。这样启动封装不依赖表现层，手表端可以直接不接主题。'),
      LearnBlock.code(
        'AppBootstrap.restoreTheme().then((state: AppThemeState): void => {\n' +
        '  AppThemeApplier.apply(state.presetId, state.accentHex);\n' +
        '});'
      ),
      LearnBlock.paragraph(
        '外观页（commons/AppSettings/src/main/ets/component/AccentColorSetting.ets）由三部分组成：' +
          '主题包 chips、取色器、实时预览。取色器采用 draft 确认制——拖动只改内部草稿，点确认才回调，' +
          '避免连续拖动产生大量重算与落库。'),
      LearnBlock.bullets([
        '切主题包时必须清掉强调色覆盖（传空串），否则优先级更高的旧强调色会盖住新主题包',
        '组件要自己持有单例，同时开一个 @Param accentColor 口子：只靠传参必漏，只靠单例不能特调',
        '@Param 默认值与顶层 @Builder 都不在渲染路径上，读单例不响应——改为调用侧读取后传进去',
        '只给 colors 不给 darkColors，深色模式会沿用浅色值，表现为亮底亮字'
      ]),
      LearnBlock.note(
        '排查换色问题只用两句判断：页面重建后才对 → 求值时机问题；重建后仍不对 → 依赖没接上。' +
          '完整版文档见仓库 教程/主题/主题.md。')
    ])
];

/** 按 id 取章节（未知 id 返回 undefined，由入口层回退到章节列表）。 */
export function findLearnChapter(chapterId: string): LearnChapter | undefined {
  return LEARN_CHAPTERS.find((chapter: LearnChapter): boolean => chapter.id === chapterId);
}

/** 章节不存在时的占位（旧链接 / 已删章节不白屏，提示返回目录）。 */
export const LEARN_MISSING_CHAPTER: LearnChapter = new LearnChapter(
  '__missing__', '章节不存在', '该章节可能已被删除，请返回学习 Tab 重新选择。', 0, []);

/** 按 id 取章节，未命中给占位章节（详情页唯一的取值入口，免去空判断）。 */
export function learnChapterOrDefault(chapterId: string): LearnChapter {
  const hit: LearnChapter | undefined = findLearnChapter(chapterId);
  return hit === undefined ? LEARN_MISSING_CHAPTER : hit;
}
