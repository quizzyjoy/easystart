/**
 * 文档条目（学习 Tab 目录的数据模型）。
 *
 * 数据来源：构建期由 `scripts/sync-docs.mjs` 从仓根 `教程/<专题>/<专题>.md` 生成，
 * 落在各端 `resources/rawfile/docs/index.json`。应用侧只读，不写。
 */
export class DocMeta {
  /** 稳定 id，同时是 md 的相对路径（不含扩展名），如 `主题/主题`。 */
  readonly id: string;
  /** 首个 H1。 */
  readonly title: string;
  /** 首段摘要（≤60 字）。 */
  readonly summary: string;
  /** 预计阅读时长（分钟），按正文字数估算。 */
  readonly minutes: number;
  /** 文中所有 H2 标题，用于大纲与检索。 */
  readonly sections: string[];
  /** rawfile 内的 md 路径，如 `docs/主题/主题.md`。 */
  readonly path: string;

  constructor(id: string, title: string, summary: string, minutes: number, sections: string[], path: string) {
    this.id = id;
    this.title = title;
    this.summary = summary;
    this.minutes = minutes;
    this.sections = sections;
    this.path = path;
  }
}

/** index.json 的顶层结构。 */
export class DocIndex {
  readonly generatedAt: string;
  readonly docs: DocMeta[];

  constructor(generatedAt: string, docs: DocMeta[]) {
    this.generatedAt = generatedAt;
    this.docs = docs;
  }
}
