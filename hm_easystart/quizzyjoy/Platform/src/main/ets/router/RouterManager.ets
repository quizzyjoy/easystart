import { Logger } from '@quizzyjoy/foundation';

const DOMAIN: string = 'platform';
const TAG: string = 'RouterManager';

/**
 * 统一路由管理（借鉴官方 sample_in_harmonyos 的 PageContext 模式，ArkTS 化）。
 *
 * 职责：NavPathStack 的唯一出口——
 * 1. push / replace / pop / popToIndex / clear 全部 try-catch 归一，
 *    跳转失败记 error 日志、不崩溃（路由失败不应中断业务流程）；
 * 2. 路由名常量由各应用的入口 / feature 自定义（模板示例见 entry Index.ets 的 ROUTE_DETAIL）；
 * 3. attach 与 Navigation 宿主页面生命周期成对（aboutToAppear / aboutToDisappear），
 *    防止持有已销毁的栈。
 *
 * 【零 @kit 纪律】NavPathStack 为 ArkUI 全局环境类型，无需 import；
 * 本类不触碰任何 @ohos/@kit 系统调用。
 * 参数类型用 Object（ArkTS 无 object 字面量类型），页面侧 instanceof / 模板字符串收窄。
 */
export class RouterManager {
  private static instance: RouterManager | undefined = undefined;
  private stack: NavPathStack | undefined = undefined;

  private constructor() {
  }

  static getInstance(): RouterManager {
    if (RouterManager.instance === undefined) {
      RouterManager.instance = new RouterManager();
    }
    return RouterManager.instance;
  }

  /** 注入导航栈（Navigation 宿主页面 aboutToAppear 调用，与 detach 成对）。 */
  attach(stack: NavPathStack): void {
    this.stack = stack;
    Logger.info(DOMAIN, TAG, 'attached');
  }

  /** 解绑（宿主页面 aboutToDisappear 调用，与 attach 成对）。 */
  detach(): void {
    this.stack = undefined;
    Logger.info(DOMAIN, TAG, 'detached');
  }

  /** 压入页面。param 为可选路由参数（建议传 class 实例或 string）。 */
  push(name: string, param?: Object): void {
    const stack: NavPathStack | undefined = this.stack;
    if (stack === undefined) {
      Logger.warn(DOMAIN, TAG, `push(${name}) ignored: not attached`);
      return;
    }
    try {
      stack.pushPath({ name: name, param: param });
    } catch (err) {
      Logger.error(DOMAIN, TAG, `push(${name}) failed: ${JSON.stringify(err)}`);
    }
  }

  /** 替换栈顶页面。 */
  replace(name: string, param?: Object): void {
    const stack: NavPathStack | undefined = this.stack;
    if (stack === undefined) {
      Logger.warn(DOMAIN, TAG, `replace(${name}) ignored: not attached`);
      return;
    }
    try {
      stack.replacePath({ name: name, param: param });
    } catch (err) {
      Logger.error(DOMAIN, TAG, `replace(${name}) failed: ${JSON.stringify(err)}`);
    }
  }

  /** 弹出栈顶页面。 */
  pop(animated: boolean = true): void {
    const stack: NavPathStack | undefined = this.stack;
    if (stack === undefined) {
      Logger.warn(DOMAIN, TAG, 'pop ignored: not attached');
      return;
    }
    try {
      stack.pop(animated);
    } catch (err) {
      Logger.error(DOMAIN, TAG, `pop failed: ${JSON.stringify(err)}`);
    }
  }

  /** 回退到指定索引（保留 0..index）。 */
  popToIndex(index: number): void {
    const stack: NavPathStack | undefined = this.stack;
    if (stack === undefined) {
      Logger.warn(DOMAIN, TAG, 'popToIndex ignored: not attached');
      return;
    }
    try {
      stack.popToIndex(index);
    } catch (err) {
      Logger.error(DOMAIN, TAG, `popToIndex(${index}) failed: ${JSON.stringify(err)}`);
    }
  }

  /** 清空路由栈。 */
  clear(): void {
    const stack: NavPathStack | undefined = this.stack;
    if (stack === undefined) {
      Logger.warn(DOMAIN, TAG, 'clear ignored: not attached');
      return;
    }
    try {
      stack.clear();
    } catch (err) {
      Logger.error(DOMAIN, TAG, `clear failed: ${JSON.stringify(err)}`);
    }
  }
}
