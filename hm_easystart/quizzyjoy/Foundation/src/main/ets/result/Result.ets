import { AppError } from '../error/AppError';

/**
 * 结果类型：用返回值表达"可预期的失败"，避免用异常控制流程。
 *
 * 选择标准：
 * - 失败是业务的一部分（校验不通过、无数据、未登录）→ 用 Result
 * - 失败是意外（网络断了、系统调用报错）→ throw AppError，由边界统一处理
 *
 * 这样能显著减少 try-catch 嵌套，也让"哪些失败必须处理"在类型上可见。
 */
export class Result<T> {
  readonly success: boolean;
  readonly data: T | undefined;
  readonly error: AppError | undefined;

  private constructor(success: boolean, data: T | undefined, error: AppError | undefined) {
    this.success = success;
    this.data = data;
    this.error = error;
  }

  static ok<T>(data: T): Result<T> {
    return new Result<T>(true, data, undefined);
  }

  static fail<T>(error: AppError): Result<T> {
    return new Result<T>(false, undefined, error);
  }

  /** 取数据，失败时用兜底值 */
  getOrDefault(fallback: T): T {
    if (this.success && this.data !== undefined) {
      return this.data;
    }
    return fallback;
  }

  /** 取数据，失败时抛出（仅在"确实拿不到就不能继续"的场景用） */
  getOrThrow(): T {
    if (this.success && this.data !== undefined) {
      return this.data;
    }
    const cause: AppError = this.error !== undefined ? this.error : AppError.unknown('result failed');
    throw cause;
  }

  onSuccess(action: (data: T) => void): void {
    if (this.success && this.data !== undefined) {
      action(this.data);
    }
  }

  onFailure(action: (error: AppError) => void): void {
    if (!this.success && this.error !== undefined) {
      action(this.error);
    }
  }

  map<R>(transform: (data: T) => R): Result<R> {
    if (this.success && this.data !== undefined) {
      return Result.ok<R>(transform(this.data));
    }
    const cause: AppError = this.error !== undefined ? this.error : AppError.unknown('result failed');
    return Result.fail<R>(cause);
  }
}