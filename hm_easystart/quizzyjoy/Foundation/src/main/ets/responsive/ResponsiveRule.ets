/**
 * 响应式规则原语（v2.4 起，v2.4.1 扩充至 14 运算符）。
 *
 * 借鉴官方 MultiDeviceLibrary responsiverule 的严格 ArkTS 重写：
 * 1. 官方用字符串运算符 + 运行时谓词拼接，本实现改为 enum + 分支谓词——
 *    拼写错误在编译期暴露，且避免字符串解析开销；
 * 2. 纯计算、零 @kit——数据源快照由调用方注入（Platform 的 BreakpointManager.snapshot() 等）。
 */

/** 规则运算符（编译期封闭集合，禁止字符串拼接）。 */
export enum ResponsiveOperator {
  /** 等于 */
  EQ = 'eq',
  /** 不等于 */
  NEQ = 'neq',
  /** 大于（仅 number） */
  GT = 'gt',
  /** 大于等于（仅 number） */
  GTE = 'gte',
  /** 小于（仅 number） */
  LT = 'lt',
  /** 小于等于（仅 number） */
  LTE = 'lte',
  /** 属于字符串集合（value 为 string[]） */
  IN = 'in',
  /** 不属于字符串集合（value 为 string[]；v2.4.1） */
  NOT_IN = 'notIn',
  /** 包含子串（仅 string；v2.4.1） */
  CONTAINS = 'contains',
  /** 不包含子串（仅 string；v2.4.1） */
  NOT_CONTAINS = 'notContains',
  /** 前缀匹配（仅 string；v2.4.1） */
  STARTS_WITH = 'startsWith',
  /** 后缀匹配（仅 string；v2.4.1） */
  ENDS_WITH = 'endsWith',
  /** 闭区间 [lower, upper]（number + number[2]；v2.4.1） */
  BETWEEN_CLOSED = 'betweenClosed',
  /** 正则匹配（value 为正则模式串；v2.4.1。求值路径每次构造 RegExp，高频场景可加缓存） */
  MATCHES = 'matches'
}

/** 条件值联合：基本量或数组（IN/NOT_IN 用 string[]，BETWEEN_CLOSED 用 number[]）。 */
export type RuleValue = string | number | boolean | string[] | number[];

/**
 * 单条规则：field + operator + value，对快照中同名字段求值。
 * 类型不匹配（如对 string 用 GT、对非 string 用 IN）视为「不匹配」，不抛异常——
 * 规则求值属可预期失败，按 §15 用返回值表达。
 */
export class ResponsiveRule {
  readonly field: string;
  readonly operator: ResponsiveOperator;
  readonly value: RuleValue;

  constructor(field: string, operator: ResponsiveOperator, value: RuleValue) {
    this.field = field;
    this.operator = operator;
    this.value = value;
  }

  /** 对快照求值：字段缺失 / 类型不匹配 / 比较不成立均返回 false。 */
  matches(snapshot: Record<string, string | number | boolean>): boolean {
    const actual: string | number | boolean | undefined = snapshot[this.field];
    if (actual === undefined) {
      return false;
    }
    const expected: RuleValue = this.value;
    // ── 数组型运算符 ──────────────────────────────────────────────
    if (this.operator === ResponsiveOperator.IN
      || this.operator === ResponsiveOperator.NOT_IN) {
      if (typeof actual !== 'string' || !Array.isArray(expected)) {
        return false;
      }
      let hit: boolean = false;
      for (let i = 0; i < expected.length; i++) {
        const item: string | number = expected[i];
        if (typeof item === 'string' && item === actual) {
          hit = true;
          break;
        }
      }
      return this.operator === ResponsiveOperator.IN ? hit : !hit;
    }
    if (this.operator === ResponsiveOperator.BETWEEN_CLOSED) {
      if (typeof actual !== 'number' || !Array.isArray(expected) || expected.length !== 2) {
        return false;
      }
      const lower: string | number = expected[0];
      const upper: string | number = expected[1];
      if (typeof lower !== 'number' || typeof upper !== 'number') {
        return false;
      }
      return actual >= lower && actual <= upper;
    }
    // 数组 expected 只被数组型运算符消费，其余运算符遇到即不匹配
    if (Array.isArray(expected)) {
      return false;
    }
    // ── 字符串标量型运算符 ────────────────────────────────────────
    if (this.operator === ResponsiveOperator.CONTAINS
      || this.operator === ResponsiveOperator.NOT_CONTAINS
      || this.operator === ResponsiveOperator.STARTS_WITH
      || this.operator === ResponsiveOperator.ENDS_WITH
      || this.operator === ResponsiveOperator.MATCHES) {
      if (typeof actual !== 'string' || typeof expected !== 'string') {
        return false;
      }
      switch (this.operator) {
        case ResponsiveOperator.CONTAINS:
          return actual.includes(expected);
        case ResponsiveOperator.NOT_CONTAINS:
          return !actual.includes(expected);
        case ResponsiveOperator.STARTS_WITH:
          return actual.startsWith(expected);
        case ResponsiveOperator.ENDS_WITH:
          return actual.endsWith(expected);
        case ResponsiveOperator.MATCHES:
          return new RegExp(expected).test(actual);
        default:
          return false;
      }
    }
    // ── 通用标量运算符（v2.4 原有语义保持） ────────────────────────
    if (typeof actual !== typeof expected) {
      return false;
    }
    switch (this.operator) {
      case ResponsiveOperator.EQ:
        return actual === expected;
      case ResponsiveOperator.NEQ:
        return actual !== expected;
      case ResponsiveOperator.GT:
        return typeof actual === 'number' && typeof expected === 'number' && actual > expected;
      case ResponsiveOperator.GTE:
        return typeof actual === 'number' && typeof expected === 'number' && actual >= expected;
      case ResponsiveOperator.LT:
        return typeof actual === 'number' && typeof expected === 'number' && actual < expected;
      case ResponsiveOperator.LTE:
        return typeof actual === 'number' && typeof expected === 'number' && actual <= expected;
      default:
        return false;
    }
  }
}
