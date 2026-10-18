import { AppError } from '../error/AppError';
import { ErrorCode } from '../error/ErrorCode';

/**
 * 前置条件断言。
 *
 * 用法：在方法入口校验入参，快速失败（fail fast）。
 * 目的是让非法状态在"离问题最近的地方"暴露，而不是传播到几层之后才崩。
 */
export class Assert {
  static notNull<T>(value: T | undefined | null, name: string): T {
    if (value === undefined || value === null) {
      throw AppError.expected(ErrorCode.PARAM_INVALID, `${name} must not be null`);
    }
    return value;
  }

  static notEmpty(value: string, name: string): string {
    if (value.length === 0) {
      throw AppError.expected(ErrorCode.PARAM_INVALID, `${name} must not be empty`);
    }
    return value;
  }

  static isTrue(condition: boolean, message: string): void {
    if (!condition) {
      throw AppError.expected(ErrorCode.PARAM_INVALID, message);
    }
  }

  static inRange(value: number, min: number, max: number, name: string): number {
    if (value < min || value > max) {
      throw AppError.expected(ErrorCode.PARAM_INVALID, `${name} out of range [${min}, ${max}]: ${value}`);
    }
    return value;
  }
}