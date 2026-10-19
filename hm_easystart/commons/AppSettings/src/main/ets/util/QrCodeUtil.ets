import { image } from '@kit.ImageKit';
import { generateBarcode, scanCore } from '@kit.ScanKit';

/**
 * 二维码生成封装（v3.34）。
 *
 * 用途：手表端屏小、无法内嵌网页，把外链（公司官网 / 个人主页 / 开源仓）
 * 渲染成二维码，供手机扫码打开。
 *
 * 机制：HMS ScanKit 的 `generateBarcode.createBarcode`（`QR_CODE`）。
 * 能力缺失（`canIUse` 为 false，如不支持该 syscap 的模拟器）或生成异常时
 * 返回 `undefined`，由调用方降级为「复制链接」提示，不抛异常。
 */
export class QrCodeUtil {
  /** 生成尺寸（px）：320 在手表上可扫且不至于溢出。 */
  private static readonly SIZE: number = 320;

  /** 生成二维码位图；失败/不支持时返回 undefined。 */
  static async create(text: string): Promise<image.PixelMap | undefined> {
    if (text.length === 0) {
      return undefined;
    }
    if (!canIUse('SystemCapability.Multimedia.Scan.GenerateBarcode')) {
      return undefined;
    }
    try {
      const options: generateBarcode.CreateOptions = {
        scanType: scanCore.ScanType.QR_CODE,
        height: QrCodeUtil.SIZE,
        width: QrCodeUtil.SIZE
      };
      return await generateBarcode.createBarcode(text, options);
    } catch (err) {
      return undefined;
    }
  }
}
