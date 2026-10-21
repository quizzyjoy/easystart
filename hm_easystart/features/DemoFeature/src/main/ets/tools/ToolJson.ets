/**
 * JSON 工具台的纯逻辑（v3.46）：格式化 / 压缩 / 键排序 / 路径查询 / 错误行定位。
 *
 * 解析用内置 `JSON.parse`（`@ohos.util.json` 的 parse 同源），但**它不给错误位置**，
 * 所以错误行用「二分前缀解析」定位：找到「第一次解析失败的最小行前缀」= 出错行。
 * 精度到行，够定位问题，成本只有 O(log n) 次解析。
 */
export class JsonOutcome {
  ok: boolean = false;
  output: string = '';
  error: string = '';
  /** 出错行号（1 基）；0 表示没有错误或未定位到。 */
  line: number = 0;

  static fail(error: string, line: number): JsonOutcome {
    const o = new JsonOutcome();
    o.ok = false;
    o.error = error;
    o.line = line;
    return o;
  }
}

export const JSON_TEXT_LIMIT: number = 524288;

export class ToolJson {
  static format(text: string, indent: number): JsonOutcome {
    return ToolJson.build(text, indent, false);
  }

  static minify(text: string): JsonOutcome {
    return ToolJson.build(text, 0, false);
  }

  static sortKeys(text: string, indent: number): JsonOutcome {
    return ToolJson.build(text, indent, true);
  }

  /** 路径查询：支持 `$.a.b[0]` / `a.b[0]` / `$` 三种写法。 */
  static query(text: string, path: string): JsonOutcome {
    let root: Object | null = null;
    try {
      root = JSON.parse(text) as Object | null;
    } catch (err) {
      return JsonOutcome.fail(`JSON 语法错误：${(err as Error).message ?? ''}`, ToolJson.errorLine(text));
    }
    const tokens: string[] = ToolJson.tokenize(path);
    let current: Object | null = root;
    for (let i = 0; i < tokens.length; i++) {
      const t: string = tokens[i];
      if (current === null) {
        return JsonOutcome.fail('路径不存在：中途遇到 null', 0);
      }
      if (t.startsWith('[')) {
        const idx: number = parseInt(t.substring(1, t.length - 1), 10);
        const arr: Object[] = current as Object[];
        if (Number.isNaN(idx) || idx < 0 || idx >= arr.length) {
          return JsonOutcome.fail(`路径不存在：下标 ${idx} 越界（长度 ${arr.length}）`, 0);
        }
        current = arr[idx];
      } else {
        const rec: Record<string, Object | null> = current as Record<string, Object | null>;
        // ArkTS 不支持 `in` 运算符：JSON 里不会出现 undefined，用取值判空等价于判存在
        const next: Object | null | undefined = rec[t];
        if (next === undefined) {
          return JsonOutcome.fail(`路径不存在：没有键 "${t}"`, 0);
        }
        current = next;
      }
    }
    const out = new JsonOutcome();
    out.ok = true;
    out.output = JSON.stringify(current, null, 2);
    return out;
  }

  /** 二分前缀解析，返回第一次失败的行号（1 基）。 */
  static errorLine(text: string): number {
    if (text.trim().length === 0) {
      return 0;
    }
    if (ToolJson.tryParse(text)) {
      return 0;
    }
    const lines: string[] = text.split('\n');
    let lo: number = 1;
    let hi: number = lines.length;
    while (lo < hi) {
      const mid: number = Math.floor((lo + hi) / 2);
      const prefix: string = lines.slice(0, mid).join('\n');
      if (ToolJson.tryParse(prefix)) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  private static build(text: string, indent: number, sortKeys: boolean): JsonOutcome {
    if (text.trim().length === 0) {
      return JsonOutcome.fail('请输入 JSON', 0);
    }
    if (text.length > JSON_TEXT_LIMIT) {
      return JsonOutcome.fail('内容超过 512 KB，建议在电脑上处理', 0);
    }
    let parsed: Object | null = null;
    try {
      parsed = JSON.parse(text) as Object | null;
    } catch (err) {
      const line: number = ToolJson.errorLine(text);
      return JsonOutcome.fail(`JSON 语法错误${line > 0 ? `（约第 ${line} 行）` : ''}：${(err as Error).message ?? ''}`,
        line);
    }
    let value: Object | null = parsed;
    if (sortKeys) {
      value = ToolJson.sortValue(parsed);
    }
    const out = new JsonOutcome();
    out.ok = true;
    out.output = indent > 0 ? JSON.stringify(value, null, indent) : JSON.stringify(value);
    return out;
  }

  private static tryParse(text: string): boolean {
    try {
      JSON.parse(text);
      return true;
    } catch (err) {
      return false;
    }
  }

  /** 递归按键名排序（数组保序），返回新值，不改原对象。 */
  private static sortValue(value: Object | null): Object | null {
    if (value === null) {
      return null;
    }
    if (Array.isArray(value)) {
      const src: Object[] = value as Object[];
      const dst: Object[] = [];
      for (let i = 0; i < src.length; i++) {
        const sorted: Object | null = ToolJson.sortValue(src[i]);
        dst.push(sorted === null ? '' : sorted);
      }
      return dst;
    }
    const rec: Record<string, Object | null> = value as Record<string, Object | null>;
    const keys: string[] = Object.keys(rec).sort();
    const built: Record<string, Object | null> = {};
    for (let i = 0; i < keys.length; i++) {
      const k: string = keys[i];
      built[k] = ToolJson.sortValue(rec[k]);
    }
    return built;
  }

  /** `$.a.b[0]` → ['a', 'b', '[0]'] */
  private static tokenize(path: string): string[] {
    let p: string = path.trim();
    if (p.startsWith('$')) {
      p = p.substring(1);
    }
    if (p.startsWith('.')) {
      p = p.substring(1);
    }
    const tokens: string[] = [];
    if (p.length === 0) {
      return tokens;
    }
    const re = new RegExp('([^.\\[\\]]+)|\\[(\\d+)\\]', 'g');
    let m: RegExpExecArray | null = re.exec(p);
    while (m !== null) {
      if (m[1] !== undefined) {
        tokens.push(m[1]);
      } else {
        tokens.push(`[${m[2]}]`);
      }
      m = re.exec(p);
    }
    return tokens;
  }
}
