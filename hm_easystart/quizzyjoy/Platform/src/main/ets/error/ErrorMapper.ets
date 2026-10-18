import { BusinessError } from '@kit.BasicServicesKit';
import { AppError, ErrorCode } from '@quizzyjoy/foundation';

/**
 * 系统异常 → AppError 的映射器。
 *
 * 只在"边界"使用：调用系统 API / 网络 / 存储 / 跨模块 的地方。
 * 内部纯逻辑不要层层套 try-catch，让异常自然上抛到边界统一处理。
 */
export class ErrorMapper {
  /** 通用映射：任何 catch 到的对象都能安全转成 AppError */
  static from(err: Object, domain: string, detail: string = ''): AppError {
    if (err instanceof AppError) {
      return err as AppError;
    }
    if (err instanceof Error) {
      const e = err as Error;
      return AppError.recoverable(ErrorCode.UNKNOWN, e.message, domain, detail, e);
    }
    return AppError.recoverable(ErrorCode.UNKNOWN, `${err}`, domain, detail);
  }

  /** 系统 BusinessError 映射（带系统错误码，便于排查） */
  static fromBusiness(err: BusinessError, domain: string, detail: string = ''): AppError {
    const e = err as BusinessError;
    return AppError.recoverable(e.code, e.message, domain, detail);
  }

  /** 能力不可用 */
  static capabilityUnavailable(capability: string, domain: string = 'common'): AppError {
    return AppError.recoverable(ErrorCode.CAPABILITY_UNAVAILABLE, `capability unavailable: ${capability}`, domain);
  }

  /** 超时 */
  static timeout(what: string, ms: number, domain: string = 'common'): AppError {
    return AppError.recoverable(ErrorCode.TIMEOUT, `${what} timeout after ${ms}ms`, domain);
  }
}