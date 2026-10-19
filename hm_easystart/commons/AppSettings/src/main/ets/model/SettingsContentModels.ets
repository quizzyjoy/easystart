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
  readonly personalEmail: string;
  readonly qqGroup: string;

  constructor(email: string, personalEmail: string, qqGroup: string) {
    this.email = email;
    this.personalEmail = personalEmail;
    this.qqGroup = qqGroup;
  }

  /** 两渠道均未配置（空态判定）。 */
  isEmpty(): boolean {
    return this.email.length === 0 && this.personalEmail.length === 0 && this.qqGroup.length === 0;
  }

  /** 解析 help_feedback.json；结构不符返回空渠道（子页渲染空态）。 */
  static parse(text: string): FeedbackChannels {
    const root: Record<string, Object> = JSON.parse(text) as Record<string, Object>;
    const email: Object = root['email'];
    const personalEmail: Object = root['personalEmail'];
    const qqGroup: Object = root['qqGroup'];
    return new FeedbackChannels(
      typeof email === 'string' ? email : '',
      typeof personalEmail === 'string' ? personalEmail : '',
      typeof qqGroup === 'string' ? qqGroup : ''
    );
  }
}

/** 开发者对外链接（开源平台 / 技术社区 / 社媒）。 */
export class DevLink {
  readonly name: string;
  readonly desc: string;
  readonly url: string;

  constructor(name: string, desc: string, url: string) {
    this.name = name;
    this.desc = desc;
    this.url = url;
  }
}

/** 开发者链接分组（开源社区 / 技术贴 / 社媒）。 */
export class DevGroup {
  readonly title: string;
  readonly links: DevLink[];

  constructor(title: string, links: DevLink[]) {
    this.title = title;
    this.links = links;
  }
}

/** 公司信息（开发者页上半段）。 */
export class CompanyInfo {
  readonly name: string;
  readonly brand: string;
  readonly creditCode: string;
  readonly icp: string;
  readonly email: string;
  /** 公司官网（ArkWeb 内嵌或二维码）。 */
  readonly website: string;
  readonly repos: DevLink[];

  constructor(name: string, brand: string, creditCode: string, icp: string, email: string,
    website: string, repos: DevLink[]) {
    this.name = name;
    this.brand = brand;
    this.creditCode = creditCode;
    this.icp = icp;
    this.email = email;
    this.website = website;
    this.repos = repos;
  }

  isEmpty(): boolean {
    return this.name.length === 0 && this.brand.length === 0;
  }
}

/** 个人信息（开发者页下半段）。 */
export class PersonInfo {
  readonly name: string;
  readonly title: string;
  readonly intro: string[];
  readonly groups: DevGroup[];
  readonly email: string;
  readonly wechat: string;
  /** 个人主页（ArkWeb 内嵌或二维码）。 */
  readonly homepage: string;

  constructor(name: string, title: string, intro: string[], groups: DevGroup[],
    email: string, wechat: string, homepage: string) {
    this.name = name;
    this.title = title;
    this.intro = intro;
    this.groups = groups;
    this.email = email;
    this.wechat = wechat;
    this.homepage = homepage;
  }

  isEmpty(): boolean {
    return this.name.length === 0 && this.groups.length === 0;
  }
}

/**
 * 开发者页数据（developer.json，v3.34 两段式）：
 * company = 公司段（名称 / 信用代码 / ICP / 邮箱 / 开源主页）；
 * person = 个人段（姓名 / 职务 / 简介 / 三组链接：开源社区、技术贴、社媒）。
 */
export class DeveloperProfile {
  readonly company: CompanyInfo;
  readonly person: PersonInfo;

  constructor(company: CompanyInfo, person: PersonInfo) {
    this.company = company;
    this.person = person;
  }

  /** 两段皆空（空态判定）。 */
  isEmpty(): boolean {
    return this.company.isEmpty() && this.person.isEmpty();
  }

  /** 解析 developer.json；结构不符返回空档案（子页渲染空态）。 */
  static parse(text: string): DeveloperProfile {
    const root: Record<string, Object> = JSON.parse(text) as Record<string, Object>;
    return new DeveloperProfile(
      DeveloperProfile.parseCompany(root['company']),
      DeveloperProfile.parsePerson(root['person'])
    );
  }

  private static parseCompany(raw: Object | undefined): CompanyInfo {
    if (raw === undefined || raw === null) {
      return new CompanyInfo('', '', '', '', '', '', []);
    }
    const record: Record<string, Object> = raw as Record<string, Object>;
    return new CompanyInfo(
      DeveloperProfile.str(record['name']),
      DeveloperProfile.str(record['brand']),
      DeveloperProfile.str(record['creditCode']),
      DeveloperProfile.str(record['icp']),
      DeveloperProfile.str(record['email']),
      DeveloperProfile.str(record['website']),
      DeveloperProfile.parseLinks(record['repos'])
    );
  }

  private static parsePerson(raw: Object | undefined): PersonInfo {
    if (raw === undefined || raw === null) {
      return new PersonInfo('', '', [], [], '', '', '');
    }
    const record: Record<string, Object> = raw as Record<string, Object>;
    const intro: string[] = [];
    const rawIntro: Object = record['intro'];
    if (Array.isArray(rawIntro)) {
      for (const line of rawIntro as Object[]) {
        if (typeof line === 'string' && line.length > 0) {
          intro.push(line);
        }
      }
    }
    const groups: DevGroup[] = [];
    const rawGroups: Object = record['groups'];
    if (Array.isArray(rawGroups)) {
      for (const g of rawGroups as Object[]) {
        const gr: Record<string, Object> = g as Record<string, Object>;
        const title: string = DeveloperProfile.str(gr['title']);
        const links: DevLink[] = DeveloperProfile.parseLinks(gr['links']);
        if (title.length > 0 && links.length > 0) {
          groups.push(new DevGroup(title, links));
        }
      }
    }
    return new PersonInfo(
      DeveloperProfile.str(record['name']),
      DeveloperProfile.str(record['title']),
      intro,
      groups,
      DeveloperProfile.str(record['email']),
      DeveloperProfile.str(record['wechat']),
      DeveloperProfile.str(record['homepage'])
    );
  }

  private static parseLinks(raw: Object | undefined): DevLink[] {
    const links: DevLink[] = [];
    if (raw === undefined || raw === null || !Array.isArray(raw)) {
      return links;
    }
    for (const item of raw as Object[]) {
      const record: Record<string, Object> = item as Record<string, Object>;
      const name: string = DeveloperProfile.str(record['name']);
      const url: string = DeveloperProfile.str(record['url']);
      if (name.length > 0 && url.length > 0) {
        links.push(new DevLink(name, DeveloperProfile.str(record['desc']), url));
      }
    }
    return links;
  }

  private static str(value: Object | undefined): string {
    return typeof value === 'string' ? value : '';
  }
}
