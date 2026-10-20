import { LayeredDrawableDescriptor } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { hdsDrawable } from '@kit.UIDesignKit';
import { AppFontSize, AppFontWeight, AppRadius, AppSpacing, DesignToken, Logger } from '@quizzyjoy/foundation';
import { BreakpointManager, WindowAdapter } from '@quizzyjoy/platform';

const DOMAIN: string = '0xD001';
const TAG: string = 'IconKitView';

/** 一次合成结果（size 与是否描边固定，像素结果由官方 API 产出）。 */
class IconRenderItem {
  id: string = '';
  size: number = 48;
  bordered: boolean = false;
  pixel: image.PixelMap;

  constructor(id: string, size: number, bordered: boolean, pixel: image.PixelMap) {
    this.id = id;
    this.size = size;
    this.bordered = bordered;
    this.pixel = pixel;
  }
}

/**
 * UI Design Kit 图标处理（v3.42，开发工具第二项从「待实现」转真实现）。
 *
 * 官方能力（`@kit.UIDesignKit` 的 `hdsDrawable`，syscap `SystemCapability.UIDesign.Core`）：
 * - `getHdsLayeredIcon(bundleName, layeredDrawableDescriptor, size, hasBorder)`：
 *   把**分层图标**（本工程 `AppScope/resources/base/media/layered_image.json` + background / foreground）
 *   合成为一张圆角图标位图，`size` 控制尺寸、`hasBorder` 加外描边；
 * - `getHdsIcon(bundleName, pixelMap, size, maskPixelMap, hasBorder)`：单层图 + 蒙版裁剪。
 *
 * 本页只演示分层合成（不需要额外蒙版素材），并保留**回退**：设备不支持该 syscap 或调用抛错时，
 * 退回 ArkUI 等效画法（前景图 + 底 + 圆角 + 描边），并显式告知原因，而不是给一张白图。
 */
@ComponentV2
export struct IconKitView {
  @Param onOpenTransitions: () => void = (): void => {
  };
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  @Local supported: boolean = canIUse('SystemCapability.UIDesign.Core');
  @Local plains: IconRenderItem[] = [];
  @Local bordereds: IconRenderItem[] = [];
  @Local failure: string = '';
  @Local bundleName: string = '';

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  aboutToAppear(): void {
    this.buildIcons();
  }

  /** 取分层图标描述符 → 按三种尺寸 × 描边开关各合成一张。 */
  private buildIcons(): void {
    if (!this.supported) {
      this.failure = '当前设备不支持 SystemCapability.UIDesign.Core，以下为 ArkUI 等效画法';
      return;
    }
    const host = this.getUIContext().getHostContext();
    if (host === undefined) {
      this.failure = '取不到宿主上下文，无法读取资源';
      return;
    }
    this.bundleName = host.applicationInfo?.name ?? '';
    const plains: IconRenderItem[] = [];
    const bordereds: IconRenderItem[] = [];
    try {
      // 分层图标：layered_image.json 描述（foreground + background），运行期拿到 LayeredDrawableDescriptor
      const descriptor = host.resourceManager.getDrawableDescriptor($r('app.media.layered_image').id);
      const layered = descriptor as LayeredDrawableDescriptor;
      const sizes: number[] = [48, 72, 96];
      for (let i = 0; i < sizes.length; i++) {
        const size: number = sizes[i];
        const plain: image.PixelMap = hdsDrawable.getHdsLayeredIcon(this.bundleName, layered, size, false);
        plains.push(new IconRenderItem(`p-${size}`, size, false, plain));
        const bordered: image.PixelMap = hdsDrawable.getHdsLayeredIcon(this.bundleName, layered, size, true);
        bordereds.push(new IconRenderItem(`b-${size}`, size, true, bordered));
      }
      this.plains = plains;
      this.bordereds = bordereds;
      this.failure = '';
      Logger.info(DOMAIN, TAG, `layered icon composed: ${plains.length + bordereds.length}`);
    } catch (err) {
      const e = err as BusinessError;
      this.failure = `官方接口调用失败（code=${e.code ?? -1}），以下为 ArkUI 等效画法`;
      Logger.warn(DOMAIN, TAG, `getHdsLayeredIcon failed: ${e.code} ${e.message}`);
      this.plains = [];
      this.bordereds = [];
    }
  }

  build() {
    Scroll() {
      Column({ space: DesignToken.sectionSpacing() }) {
        // —— 能力说明 ——
        Column({ space: AppSpacing.XS }) {
          Text('UI Design Kit · 图标处理')
            .fontSize(AppFontSize.BODY)
            .fontWeight(AppFontWeight.MEDIUM)
            .fontColor($r('app.color.app_text_primary'))
            .width('100%')
          Text('hdsDrawable.getHdsLayeredIcon：分层图标（前景 + 背景）合成为一张圆角位图，size 控尺寸、hasBorder 加外描边。')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        if (this.plains.length > 0) {
          // —— 官方 API 结果：两行（无描边 / 带描边），每行 48 / 72 / 96 ——
          Column({ space: AppSpacing.MD }) {
            Text('hasBorder = false（48 / 72 / 96vp）')
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_tertiary'))
              .width('100%')

            Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center }) {
              ForEach(this.plains, (item: IconRenderItem) => {
                Column({ space: AppSpacing.XS }) {
                  Image(item.pixel)
                    .width(item.size)
                    .height(item.size)
                  Text(`${item.size}`)
                    .fontSize(AppFontSize.CAPTION)
                    .fontColor($r('app.color.app_text_tertiary'))
                }
                .margin({ right: AppSpacing.LG, bottom: AppSpacing.SM })
              }, (item: IconRenderItem): string => item.id)
            }
            .width('100%')

            Text('hasBorder = true（同一批尺寸，多一圈外描边）')
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_tertiary'))
              .width('100%')
              .margin({ top: AppSpacing.SM })

            Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center }) {
              ForEach(this.bordereds, (item: IconRenderItem) => {
                Column({ space: AppSpacing.XS }) {
                  Image(item.pixel)
                    .width(item.size)
                    .height(item.size)
                  Text(`${item.size}`)
                    .fontSize(AppFontSize.CAPTION)
                    .fontColor($r('app.color.app_text_tertiary'))
                }
                .margin({ right: AppSpacing.LG, bottom: AppSpacing.SM })
              }, (item: IconRenderItem): string => item.id)
            }
            .width('100%')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding(AppSpacing.LG)
          .borderRadius(AppRadius.XL)
          .backgroundColor($r('app.color.app_bg_card'))
        } else {
          // —— 回退：ArkUI 等效画法 + 原因 ——
          Column({ space: AppSpacing.MD }) {
            Text(this.failure)
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_secondary'))
              .width('100%')

            Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center }) {
              this.fallbackIcon(48)
              this.fallbackIcon(72)
              this.fallbackIcon(96)
            }
            .width('100%')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding(AppSpacing.LG)
          .borderRadius(AppRadius.XL)
          .backgroundColor($r('app.color.app_bg_card'))
        }

        // —— 分层素材说明（为什么本页能合成）——
        Column({ space: AppSpacing.XS }) {
          Text('分层素材来源')
            .fontSize(AppFontSize.BODY_SM)
            .fontWeight(AppFontWeight.MEDIUM)
            .fontColor($r('app.color.app_text_secondary'))
            .width('100%')
          Text('AppScope/resources/base/media/layered_image.json（background.png + foreground.png）。' +
            'fork 时替换这三份素材即可，合成代码不用改。')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .constraintSize({ maxWidth: DesignToken.contentMaxWidth(this.bp()) })
      .padding({
        left: DesignToken.pagePadding(this.bp()),
        right: DesignToken.pagePadding(this.bp()),
        top: AppSpacing.LG,
        bottom: DesignToken.tabPageBottomPadding(this.bp(), this.windowAdapter.bottomAvoidVp)
      })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .backgroundColor($r('app.color.app_bg_page'))
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  /** 回退画法：前景图叠圆角底 + 描边，尺寸对齐官方 API 的同一组值。 */
  @Builder
  fallbackIcon(size: number) {
    Stack() {
      Image($r('app.media.foreground'))
        .width(size * 0.62)
        .height(size * 0.62)
        .objectFit(ImageFit.Contain)
    }
    .width(size)
    .height(size)
    .borderRadius(size * 0.22)
    .border({ width: 1, color: $r('app.color.app_divider') })
    .backgroundColor($r('app.color.qj_brand'))
    .margin({ right: AppSpacing.LG, bottom: AppSpacing.SM })
  }
}
