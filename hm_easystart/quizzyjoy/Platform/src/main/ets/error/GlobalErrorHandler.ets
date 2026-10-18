import { errorManager } from '@kit.AbilityKit';
import { AppError, ErrorLevel, Logger } from '@quizzyjoy/foundation';
import { ErrorMapper } from './ErrorMapper';

const DOMAIN: string = 'global';
const TAG: string = 'GlobalErrorHandler';

/**
 * 未捕获异常观察者。
 *
 * 实现说明（实测踩坑）：ErrorObserver 类型未通过 @kit.AbilityKit 导出，
 * 直接 import '@ohos.app.ability.ErrorObserver' 会报模块无法解析。
 * 因此这里用结构化匹配的普通类：只要具备 onUnhandledException / onException
 * 两个签名一致的方法，即可被 errorManager.on('error', ...) 接受。
 */
class BlueprintErrorObserver {
  onUnhandledException(errMsg: string): void {
    Logger.fatal(DOMAIN, TAG, `unhandledException: ${errMsg}`);
    GlobalErrorHandler.notify(AppError.fatal(0, errMsg, DOMAIN));
  }

  onException(errObject: Error): void {
    Logger.error(DOMAIN, TAG, `exception: ${errObject.message}`);
    GlobalErrorHandler.notify(ErrorMapper.from(errObject, DOMAIN));
  }
}

/** 外部（如崩溃上报 SDK）可注册的处理者 */
export type ErrorReporter = (error: AppError) => void;

/**
 * 全局异常兜底。
 *
 * 职责：接住"没人处理"的异常，保证：
 * 1. 一定落日志（否则线上问题无从查起）
 * 2. 一定有机会上报（EXPECTED 级别的业务分支不上报）
 * 3. 尽量不崩溃（致命错误交给页面做安全降级）
 *
 * 安装位置：每个入口 Ability 的 onCreate 中调用一次。
 */
export class GlobalErrorHandler {
  private static installed: boolean = false;
  private static reporters: ErrorReporter[] = [];
  private static observerId: number = -1;
  private static observer: BlueprintErrorObserver = new BlueprintErrorObserver();

  /** 安装全局监听（幂等） */
  static install(): void {
    if (GlobalErrorHandler.installed) {
      return;
    }
    try {
      GlobalErrorHandler.observerId = errorManager.on('error', GlobalErrorHandler.observer);
      GlobalErrorHandler.installed = true;
      Logger.info(DOMAIN, TAG, `global error observer installed, id=${GlobalErrorHandler.observerId}`);
    } catch (err) {
      Logger.error(DOMAIN, TAG, `install failed: ${JSON.stringify(err)}`);
    }
  }

  /** 卸载（测试用） */
  static uninstall(): void {
    if (!GlobalErrorHandler.installed) {
      return;
    }
    try {
      errorManager.off('error', GlobalErrorHandler.observerId);
    } catch (err) {
      Logger.error(DOMAIN, TAG, `uninstall failed: ${JSON.stringify(err)}`);
    }
    GlobalErrorHandler.installed = false;
  }

  /** 注册上报者（埋点 / APM 接入点） */
  static addReporter(reporter: ErrorReporter): void {
    GlobalErrorHandler.reporters.push(reporter);
  }

  /** 统一出口：日志 + 上报。所有边界捕获到的异常都应走这里 */
  static notify(error: AppError): void {
    if (error.level === ErrorLevel.FATAL) {
      Logger.fatal(error.domain, TAG, error.toLog());
    } else if (error.level === ErrorLevel.RECOVERABLE) {
      Logger.error(error.domain, TAG, error.toLog());
    } else {
      Logger.info(error.domain, TAG, error.toLog());
    }
    if (!error.needReport()) {
      return;
    }
    for (const reporter of GlobalErrorHandler.reporters) {
      try {
        reporter(error);
      } catch (err) {
        // 上报失败不得影响主流程
      }
    }
  }
}