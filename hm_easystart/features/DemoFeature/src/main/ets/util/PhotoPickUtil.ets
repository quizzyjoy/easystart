import { photoAccessHelper } from '@kit.MediaLibraryKit';

/**
 * 照片选择机制封装（v3.29，TODO-020）：PhotoViewPicker 免权限选图。
 *
 * 依据官方文档（标识为准）：harmonyos-guides/photoaccesshelper-photoviewpicker
 * 与 best-practices/bpta-permission-application（读写媒体库优先 Picker + 安全控件路线）。
 * 「机制」收口本文件（MediaLibraryKit 单 kit 触点）；「选几张、选完展示什么」由调用方决定。
 * kit 导入权限：v3.29 用户裁定——任何包有权直接 import kit（指南 F14 修订），
 * 故按判据 7 落 DemoFeature 域内 util，出现第二个使用方再考虑上移。
 */
export class PhotoPickUtil {
  /** 拉起系统图库选择图片（picker 模式免权限）；取消或失败返回空数组。 */
  static async selectPhoto(maxCount: number): Promise<string[]> {
    const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = maxCount;
    const picker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
    try {
      const result: photoAccessHelper.PhotoSelectResult = await picker.select(options);
      return result.photoUris;
    } catch (error) {
      // 用户取消（13900042）或面板拉起失败：演示场景按「未选择」处理
      return [];
    }
  }
}
