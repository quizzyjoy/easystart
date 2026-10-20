import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { Logger } from '@quizzyjoy/foundation';
import { DocIndex, DocMeta } from './DocTypes';

const DOMAIN: string = '0x1001';
const TAG: string = 'DocRepository';
const ROOT: string = 'docs';

/**
 * 教程仓库（rawfile 读取 + 内存缓存）。
 *
 * 内容由 `scripts/sync-docs.mjs` 在构建前从仓根 `教程/` 同步进 `resources/rawfile/docs/`，
 * 应用侧只做两件事：读 `index.json` 作目录、把 `path` 交给 Markdown 组件按 rawfile 模式渲染。
 */
export class DocRepository {
  private static index: DocIndex | undefined = undefined;

  /** 读取目录（失败返回空数组，页面显示空态而不是白屏）。 */
  static async loadIndex(context: common.UIAbilityContext): Promise<DocMeta[]> {
    if (DocRepository.index !== undefined) {
      return DocRepository.index.docs;
    }
    try {
      const bytes: Uint8Array = await context.resourceManager.getRawFileContent(`${ROOT}/index.json`);
      const text: string = util.TextDecoder.create('utf-8').decodeToString(bytes);
      const parsed: DocIndex = JSON.parse(text) as DocIndex;
      DocRepository.index = parsed;
      return parsed.docs;
    } catch (err) {
      Logger.error(DOMAIN, TAG, `loadIndex failed: ${JSON.stringify(err)}`);
      return [];
    }
  }

  /** 按 id 取文档元数据（未知 id 返回 undefined）。 */
  static find(docs: DocMeta[], id: string): DocMeta | undefined {
    return docs.find((item: DocMeta): boolean => item.id === id);
  }
}
