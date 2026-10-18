import { ResponsiveRule } from './ResponsiveRule';

/**
 * 响应式值（v2.4）：规则数组（AND 语义）+ 命中值。
 *
 * 用法：声明 ResponsiveCase<T> 列表，经 ResponsiveValueResolver.resolve 按
 * 快照（如 BreakpointManager.snapshot()）求值——first-match-wins，
 * 无命中返回 fallback。规则即数据：可集中声明、可随配置下发。
 */
export class ResponsiveCase<T> {
  /** 命中条件：数组内全部规则成立（AND）。空数组 = 恒命中（兜底位）。 */
  readonly rules: ResponsiveRule[];
  /** 命中时取的值。 */
  readonly value: T;

  constructor(rules: ResponsiveRule[], value: T) {
    this.rules = rules;
    this.value = value;
  }
}

/**
 * 求值器（纯静态，纯函数）。
 * 首个全部规则命中的 case 胜出；无命中返回 fallback。
 */
export class ResponsiveValueResolver {
  static resolve<T>(cases: ResponsiveCase<T>[], snapshot: Record<string, string | number | boolean>,
    fallback: T): T {
    for (let i = 0; i < cases.length; i++) {
      const item: ResponsiveCase<T> = cases[i];
      let hit: boolean = true;
      for (let j = 0; j < item.rules.length; j++) {
        if (!item.rules[j].matches(snapshot)) {
          hit = false;
          break;
        }
      }
      if (hit) {
        return item.value;
      }
    }
    return fallback;
  }
}
