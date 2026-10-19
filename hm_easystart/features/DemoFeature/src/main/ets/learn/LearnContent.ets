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
