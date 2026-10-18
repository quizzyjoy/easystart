import { pasteboard } from '@kit.BasicServicesKit';

/**
 * 剪贴板读写机制封装（v3.29，TODO-020）：画廊「剪贴板与安全组件」演示用。
 *
 * 与 AppSettings 域内同名工具（v3.28 帮助页复制）并存：各自域内使用、互不引用
 * （v3.29 用户裁定 kit 导入权限放开后，域内 util 是正统落位，不强制收敛 Platform）。
 * 写入免权限；**读取需临时授权**——仅 PasteButton 点击授权窗口内调用方有效，
 * 无授权时返回空串（安全组件「点击即许可」机制的对照教学点）。
 * 依据官方文档（标识为准）：ts-security-components-pastebutton。
 */
export class ClipboardUtil {
  /** 复制纯文本到系统剪贴板；返回 true 成功 / false 失败。 */
  static copyText(text: string): Promise<boolean> {
    const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    return pasteboard.getSystemPasteboard().setData(data)
      .then((): boolean => true)
      .catch((): boolean => false);
  }

  /** 读取系统剪贴板首条纯文本；剪贴板为空 / 非文本 / 无授权时返回空串。 */
  static async readText(): Promise<string> {
    try {
      const data: pasteboard.PasteData = await pasteboard.getSystemPasteboard().getData();
      const record: pasteboard.PasteDataRecord = data.getRecordAt(0);
      return record.plainText ?? '';
    } catch (error) {
      return '';
    }
  }
}
