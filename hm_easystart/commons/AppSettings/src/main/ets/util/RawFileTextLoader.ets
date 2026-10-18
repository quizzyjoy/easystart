import { util } from '@kit.ArkTS';
import { common } from '@quizzyjoy/platform';

/**
 * rawfile 文本加载器（v3.28，TODO-019）：
 * 数据驱动子页（公告 / 版本日志 / 帮助反馈 / 开发者）共用，
 * 读取 + utf-8 解码收口一处（RawFileTextView 长文本组件同款范式）。
 * 文件缺失 / 读取失败抛异常，由调用方兜底为空态。
 */
export class RawFileTextLoader {
  /** 读取 rawfile 根下指定文本文件并解码为字符串。 */
  static async load(context: common.UIAbilityContext, fileName: string): Promise<string> {
    const buffer: Uint8Array = await context.resourceManager.getRawFileContent(fileName);
    const decoder: util.TextDecoder = util.TextDecoder.create('utf-8');
    return decoder.decodeToString(buffer);
  }
}
