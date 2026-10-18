import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { fileUri } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { Logger } from '@quizzyjoy/foundation';
import { ErrorMapper } from '../error/ErrorMapper';

const DOMAIN: string = 'platform';
const TAG: string = 'ShareHelper';

/** 分享选项（可选字段，未提供走默认；回调可选订阅）。 */
export interface ShareOptions {
  /** 面板预览标题 */
  title?: string;
  /** 面板预览描述 */
  description?: string;
  /** 预览模式，默认 DEFAULT */
  previewMode?: systemShare.SharePreviewMode;
  /** 选择模式，默认 SINGLE（BATCH 需配合多记录，暂不暴露） */
  selectionMode?: systemShare.SelectionMode;
  /** 分享面板关闭回调 */
  onPanelDismiss?: () => void;
  /** 分享到目标应用完成回调（回传目标应用名） */
  onShareCompleted?: (targetName: string) => void;
}

/**
 * 系统分享机制封装（v3.2，依据官方 Share Kit 样例 + 复核报告 #55 施工单）。
 *
 * 三分法落位：本类只做「机制」——utd 类型推断、fileUri 转换、面板容错与回调订阅，
 * 全部收敛在本文件（utd/fileUri/ShareKit 三 kit 依赖不外泄，F14 唯一出口）；
 * 「分享什么内容、给谁看」是应用层策略，经方法入参注入。
 *
 * 生命周期：attach 与 detach 成对（AppBootstrap.prepare / destroy 编排）；
 * 未 attach 时调用仅 WARN 忽略（与 RouterManager 同款防御）。
 * 【降基线】@kit.ShareKit 属 HMS 侧（指南 §18.1 预登记裁剪点④）：
 * OpenHarmony lite 分支整文件裁剪即可，本类是 Platform 内唯一 ShareKit 触点。
 */
export class ShareHelper {
  private static instance: ShareHelper | undefined = undefined;

  private context: common.UIAbilityContext | undefined = undefined;

  private constructor() {
  }

  static getInstance(): ShareHelper {
    if (ShareHelper.instance === undefined) {
      ShareHelper.instance = new ShareHelper();
    }
    return ShareHelper.instance;
  }

  /** 注入上下文（UIAbility.onCreate 中调用，与 detach 成对）。 */
  attach(context: common.UIAbilityContext): void {
    this.context = context;
    Logger.info(DOMAIN, TAG, 'attached');
  }

  /** 解绑（onDestroy 中调用，与 attach 成对）。 */
  detach(): void {
    this.context = undefined;
    Logger.info(DOMAIN, TAG, 'detached');
  }

  /** 分享纯文本。 */
  shareText(content: string, options?: ShareOptions): void {
    const record: systemShare.SharedRecord = {
      utd: utd.UniformDataType.PLAIN_TEXT,
      content: content,
      title: options?.title,
      description: options?.description
    };
    this.show(record, options);
  }

  /** 分享链接（https 等 URL，面板按超链接渲染预览）。 */
  shareLink(url: string, options?: ShareOptions): void {
    const record: systemShare.SharedRecord = {
      utd: utd.UniformDataType.HYPERLINK,
      content: url,
      title: options?.title,
      description: options?.description
    };
    this.show(record, options);
  }

  /**
   * 分享本地文件（utd 类型按扩展名自动推断；无扩展名回退纯文本基准）。
   * path 为应用沙箱内绝对路径，内部经 fileUri.getUriFromPath 转 uri。
   */
  shareFile(path: string, options?: ShareOptions): void {
    const dot: number = path.lastIndexOf('.');
    const utdId: string = dot >= 0
      ? utd.getUniformDataTypeByFilenameExtension(path.substring(dot), utd.UniformDataType.PLAIN_TEXT)
      : utd.UniformDataType.PLAIN_TEXT;
    const record: systemShare.SharedRecord = {
      utd: utdId,
      uri: fileUri.getUriFromPath(path),
      title: options?.title,
      description: options?.description
    };
    this.show(record, options);
  }

  /** 统一面板拉起：构造 SharedData → 订阅回调 → show 容错（失败仅 WARN 不中断业务）。 */
  private show(record: systemShare.SharedRecord, options?: ShareOptions): void {
    const context: common.UIAbilityContext | undefined = this.context;
    if (context === undefined) {
      Logger.warn(DOMAIN, TAG, 'not attached: call attach in AppBootstrap.prepare first');
      return;
    }
    let data: systemShare.SharedData;
    try {
      data = new systemShare.SharedData(record);
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `SharedData build failed: ${ErrorMapper.from(err, DOMAIN, 'show').toLog()}`);
      return;
    }
    let controller: systemShare.ShareController;
    try {
      controller = new systemShare.ShareController(data);
    } catch (err) {
      Logger.warn(DOMAIN, TAG,
        `ShareController build failed (ShareKit unavailable?): ${ErrorMapper.from(err, DOMAIN, 'show').toLog()}`);
      return;
    }
    const onDismiss: (() => void) | undefined = options?.onPanelDismiss;
    if (onDismiss !== undefined) {
      controller.on('dismiss', onDismiss);
    }
    const onCompleted: ((targetName: string) => void) | undefined = options?.onShareCompleted;
    if (onCompleted !== undefined) {
      controller.on('shareCompleted', (result: systemShare.ShareOperationResult) => {
        onCompleted(result.targetAbilityInfo.name);
      });
    }
    const showOptions: systemShare.ShareControllerOptions = {
      previewMode: options?.previewMode ?? systemShare.SharePreviewMode.DEFAULT,
      selectionMode: options?.selectionMode ?? systemShare.SelectionMode.SINGLE
    };
    controller.show(context, showOptions).then(() => {
      Logger.info(DOMAIN, TAG, 'share panel shown');
    }).catch((err: BusinessError) => {
      Logger.warn(DOMAIN, TAG, `show failed: ${ErrorMapper.fromBusiness(err, DOMAIN, 'show').toLog()}`);
    });
  }
}
