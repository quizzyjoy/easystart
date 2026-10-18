/**
 * 敏感信息脱敏。
 *
 * 日志与上报前的最后一道闸门：任何可能含敏感信息的字段，必须先过本工具。
 */
export class MaskUtil {
  /** 手机号：138****8888 */
  static phone(value: string): string {
    if (value.length < 7) {
      return '***';
    }
    return `${value.substring(0, 3)}****${value.substring(value.length - 4)}`;
  }

  /** 邮箱：ab***@example.com */
  static email(value: string): string {
    const at: number = value.indexOf('@');
    if (at <= 1) {
      return '***';
    }
    return `${value.substring(0, 2)}***${value.substring(at)}`;
  }

  /** Token / 密钥：只留前 4 位 */
  static secret(value: string): string {
    if (value.length <= 4) {
      return '****';
    }
    return `${value.substring(0, 4)}****`;
  }

  /** 姓名：张*（注意：不能命名为 name，会与 Function.name 冲突） */
  static personName(value: string): string {
    if (value.length === 0) {
      return '';
    }
    return `${value.substring(0, 1)}${'*'.repeat(value.length - 1)}`;
  }
}