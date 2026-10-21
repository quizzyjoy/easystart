/**
 * 正则测试器的纯逻辑（v3.46）。
 *
 * 三处防护（ArkTS 没有简易 Worker 通道，只能靠上限硬拦）：
 * 1. 输入文本上限 8000 字符，超出截断并置 truncated；
 * 2. 匹配循环上限 5000 次；
 * 3. 零宽匹配（如 `\b`、`a*`）手动 lastIndex+1，避免死循环。
 */
export class RegexMatch {
  text: string = '';
  index: number = 0;
  groups: string[] = [];

  constructor(text: string, index: number, groups: string[]) {
    this.text = text;
    this.index = index;
    this.groups = groups;
  }
}

export class RegexOutcome {
  ok: boolean = false;
  error: string = '';
  matches: RegexMatch[] = [];
  replaced: string = '';
  truncated: boolean = false;

  static fail(error: string): RegexOutcome {
    const o = new RegexOutcome();
    o.ok = false;
    o.error = error;
    return o;
  }
}

export const REGEX_TEXT_LIMIT: number = 8000;
const MATCH_LIMIT: number = 5000;

export class ToolRegex {
  static run(pattern: string, flags: string, text: string): RegexOutcome {
    if (pattern.length === 0) {
      return RegexOutcome.fail('请输入正则表达式');
    }
    let re: RegExp;
    try {
      re = new RegExp(pattern, flags);
    } catch (err) {
      return RegexOutcome.fail(`正则语法错误：${(err as Error).message ?? '无法解析'}`);
    }
    const out = new RegexOutcome();
    out.ok = true;
    out.truncated = text.length > REGEX_TEXT_LIMIT;
    const body: string = out.truncated ? text.substring(0, REGEX_TEXT_LIMIT) : text;
    const global: boolean = flags.indexOf('g') >= 0;
    let guard: number = 0;
    if (!global) {
      const m: RegExpExecArray | null = re.exec(body);
      if (m !== null) {
        out.matches.push(ToolRegex.toMatch(m));
      }
      try {
        out.replaced = body.replace(re, '[命中]');
      } catch (e) {
        out.replaced = '';
      }
      return out;
    }
    let m: RegExpExecArray | null = re.exec(body);
    while (m !== null && guard < MATCH_LIMIT) {
      out.matches.push(ToolRegex.toMatch(m));
      if (m[0].length === 0) {
        re.lastIndex += 1;
      }
      guard += 1;
      m = re.exec(body);
    }
    try {
      out.replaced = body.replace(re, '[命中]');
    } catch (e) {
      out.replaced = '';
    }
    return out;
  }

  /** flags 勾选状态 → 字符串（g 由调用方保证，替换预览才有意义）。 */
  static flagsOf(ignoreCase: boolean, multiline: boolean, dotAll: boolean): string {
    let f: string = 'g';
    if (ignoreCase) {
      f += 'i';
    }
    if (multiline) {
      f += 'm';
    }
    if (dotAll) {
      f += 's';
    }
    return f;
  }

  private static toMatch(m: RegExpExecArray): RegexMatch {
    const groups: string[] = [];
    for (let i = 1; i < m.length; i++) {
      const g: string | undefined = m[i];
      groups.push(g === undefined ? '∅' : g);
    }
    return new RegexMatch(m[0], m.index, groups);
  }
}
