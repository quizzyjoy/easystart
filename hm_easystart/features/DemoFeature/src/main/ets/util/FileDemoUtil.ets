import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';

/** createImageAssetRequest 可接受的图片扩展名白名单（不在列的统一按 jpg 落盘）。 */
const IMAGE_EXTENSIONS: string[] = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heif'];

/**
 * SaveButton 免权限保存进系统图库的机制封装（v3.29，TODO-020）。
 *
 * 官方推荐链路（标识为准）：best-practices/bpta-permission-application +
 * harmonyos-guides/photoaccesshelper-savebutton ——
 * 沙箱中转 → MediaAssetChangeRequest.createImageAssetRequest → applyChanges。
 * 必须在 SaveButton 授权窗口内完成调用（API 20+ 窗口为点击后 1 分钟）。
 */
export class FileDemoUtil {
  /**
   * 把一张已获读授权的图片 URI（PhotoViewPicker 返回的 photoUris 具永久授权）保存进系统图库。
   * 返回 true 成功 / false 失败；沙箱中转文件无论成败均清理。
   */
  static async saveImageToGallery(context: common.Context, sourceUri: string): Promise<boolean> {
    let sandboxPath: string = '';
    try {
      const dot: number = sourceUri.lastIndexOf('.');
      const rawExt: string = dot >= 0 ? sourceUri.substring(dot + 1).toLowerCase() : '';
      const ext: string = IMAGE_EXTENSIONS.indexOf(rawExt) >= 0 ? rawExt : 'jpg';
      sandboxPath = `${context.filesDir}/easystart_save_${Date.now()}.${ext}`;
      const source: fileIo.File = await fileIo.open(sourceUri, fileIo.OpenMode.READ_ONLY);
      try {
        await fileIo.copyFile(source.fd, sandboxPath);
      } finally {
        fileIo.closeSync(source);
      }
      const request: photoAccessHelper.MediaAssetChangeRequest =
        photoAccessHelper.MediaAssetChangeRequest.createImageAssetRequest(context, fileUri.getUriFromPath(sandboxPath));
      await photoAccessHelper.getPhotoAccessHelper(context).applyChanges(request);
      return true;
    } catch (error) {
      return false;
    } finally {
      if (sandboxPath.length > 0) {
        try {
          fileIo.unlinkSync(sandboxPath);
        } catch (error) {
          // 中转文件清理失败不阻断演示流程
        }
      }
    }
  }
}
