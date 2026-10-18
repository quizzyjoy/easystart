import { pasteboard } from '@kit.BasicServicesKit';

/**
 * 剪贴板封装（v3.28，TODO-019）：帮助反馈子页复制邮箱 / QQ 群号用。
 *
 * 「机制」收口本文件（pasteboard 单 kit 触点，不外泄）；
 * 「复制什么、复制后提示什么」是应用层策略，由调用方注入。
 * 返回 Promise<boolean>：true 成功 / false 失败（权限或系统异常）。
 */
export class ClipboardUtil {
  /** 复制纯文本到系统剪贴板。 */
  static copyText(text: string): Promise<boolean> {
    const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    return pasteboard.getSystemPasteboard().setData(data)
      .then((): boolean => true)
      .catch((): boolean => false);
  }
}
