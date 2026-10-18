/**
 * 设置域数据驱动内容模型（v3.28，TODO-019）：
 * 公告 / 版本日志 / 帮助反馈 / 开发者团队四类子页的 rawfile JSON 解析。
 *
 * 设计口径（「结构进模板、内容 fork 填」）：
 * - 数据文件放 AppSettings 域 resources/rawfile/（announcement.json /
 *   version_log.json / help_feedback.json / developer.json），fork 只改
 *   JSON 不改代码；文件内 _readme 字段为 fork 说明占位，解析时忽略；
 * - JSON 视为不可信输入：parse 只在 JSON 边界做一次 as 转换
 *   （Record<string, Object>，仓内既有范式），逐字段 typeof 校验后
 *   拷贝进严格模型，结构不符或 JSON 非法（抛异常由调用方兜底）时
 *   返回空数据 → 子页渲染空态，不崩溃；
 * - 模型字段只读（readonly），渲染层零二次加工。
 */

/** 公告条目（announcement.json items 数组元素）。 */
export class AnnouncementEntry {
  readonly title: string;
  readonly date: string;
  readonly body: string;

  constructor(title: string, date: string, body: string) {
    this.title = title;
    this.date = date;
    this.body = body;
  }

  /** 解析 announcement.json；结构不符返回空数组（子页渲染空态）。 */
  static parseList(text: string): AnnouncementEntry[] {
    const entries: AnnouncementEntry[] = [];
    const root: Record<string, Object> = JSON.parse(text) as Record<string, Object>;
    const rawItems: Object = root['items'];
    if (!Array.isArray(rawItems)) {
      return entries;
    }
    const items: Object[] = rawItems as Object[];
    for (const item of items) {
      const record: Record<string, Object> = item as Record<string, Object>;
      const title: Object = record['title'];
      const date: Object = record['date'];
      const body: Object = record['body'];
      if (typeof title === 'string' && typeof date === 'string' && typeof body === 'string') {
        entries.push(new AnnouncementEntry(title, date, body));
      }
    }
    return entries;
  }
}

/** 版本日志条目（version_log.json versions 数组元素）。 */
export class VersionLogEntry {
  readonly version: string;
  readonly date: string;
  readonly notes: string[];

  constructor(version: string, date: string, notes: string[]) {
    this.version = version;
    this.date = date;
    this.notes = notes;
  }

  /** 解析 version_log.json；结构不符返回空数组（子页渲染空态）。 */
  static parseList(text: string): VersionLogEntry[] {
    const entries: VersionLogEntry[] = [];
    const root: Record<string, Object> = JSON.parse(text) as Record<string, Object>;
    const rawItems: Object = root['versions'];
    if (!Array.isArray(rawItems)) {
      return entries;
    }
    const items: Object[] = rawItems as Object[];
    for (const item of items) {
      const record: Record<string, Object> = item as Record<string, Object>;
      const version: Object = record['version'];
      const date: Object = record['date'];
      if (typeof version !== 'string' || typeof date !== 'string') {
        continue;
      }
      const notes: string[] = [];
      const rawNotes: Object = record['notes'];
      if (Array.isArray(rawNotes)) {
        const noteItems: Object[] = rawNotes as Object[];
        for (const noteItem of noteItems) {
          if (typeof noteItem === 'string') {
            notes.push(noteItem);
          }
        }
      }
      entries.push(new VersionLogEntry(version, date, notes));
    }
    return entries;
  }
}

/** 帮助反馈渠道（help_feedback.json）；字段空串 = 渠道未配置（对应行隐藏）。 */
export class FeedbackChannels {
  readonly email: string;
  readonly qqGroup: string;

  constructor(email: string, qqGroup: string) {
    this.email = email;
    this.qqGroup = qqGroup;
  }

  /** 两渠道均未配置（空态判定）。 */
  isEmpty(): boolean {
    return this.email.length === 0 && this.qqGroup.length === 0;
  }

  /** 解析 help_feedback.json；结构不符返回空渠道（子页渲染空态）。 */
  static parse(text: string): FeedbackChannels {
    const root: Record<string, Object> = JSON.parse(text) as Record<string, Object>;
    const email: Object = root['email'];
    const qqGroup: Object = root['qqGroup'];
    return new FeedbackChannels(
      typeof email === 'string' ? email : '',
      typeof qqGroup === 'string' ? qqGroup : ''
    );
  }
}

/** 开发者团队成员（developer.json members 数组元素）。 */
export class DeveloperMember {
  readonly name: string;
  readonly role: string;
  readonly bio: string;

  constructor(name: string, role: string, bio: string) {
    this.name = name;
    this.role = role;
    this.bio = bio;
  }
}

/** 开发者团队（developer.json）：intro 简介 + members 成员列表。 */
export class DeveloperProfile {
  readonly intro: string;
  readonly members: DeveloperMember[];

  constructor(intro: string, members: DeveloperMember[]) {
    this.intro = intro;
    this.members = members;
  }

  /** 简介与成员均空（空态判定）。 */
  isEmpty(): boolean {
    return this.intro.length === 0 && this.members.length === 0;
  }

  /** 解析 developer.json；结构不符返回空档案（子页渲染空态）。 */
  static parse(text: string): DeveloperProfile {
    const root: Record<string, Object> = JSON.parse(text) as Record<string, Object>;
    const rawIntro: Object = root['intro'];
    const intro: string = typeof rawIntro === 'string' ? rawIntro : '';
    const members: DeveloperMember[] = [];
    const rawItems: Object = root['members'];
    if (Array.isArray(rawItems)) {
      const items: Object[] = rawItems as Object[];
      for (const item of items) {
        const record: Record<string, Object> = item as Record<string, Object>;
        const name: Object = record['name'];
        const role: Object = record['role'];
        const bio: Object = record['bio'];
        if (typeof name === 'string' && typeof role === 'string' && typeof bio === 'string') {
          members.push(new DeveloperMember(name, role, bio));
        }
      }
    }
    return new DeveloperProfile(intro, members);
  }
}
