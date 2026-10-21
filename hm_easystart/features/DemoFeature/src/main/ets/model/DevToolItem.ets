/**
 * 开发工具目录数据（v3.46：分两组 + 八项）。
 *
 * 一项一卡：READY = 点击进页面，PLANNED = 灰显 + 「待实现」角标（留给后续新增项）。
 * 图标 / 分组都用枚举，视图层再映射成 `sys.symbol` 与分组标题——`$r` 不能动态拼接。
 */
export enum DevToolStatus {
  /** 已实现，可点击进入 */
  READY,
  /** 待实现（卡片灰显 + 角标） */
  PLANNED
}

/** 分组：环境与能力（讲渲染/系统能力）· 数据处理（离线小工具）。 */
export enum DevToolGroup {
  ENV,
  DATA
}

/** 卡片图标：不直接存 Resource（不能动态拼 $r），由视图按 key 映射为 sys.symbol。 */
export enum DevToolSymbol {
  DISPLAY,
  PALETTE,
  GRID,
  HASH,
  CODEC,
  KEY,
  WRENCH,
  DOC
}

export class DevToolItem {
  id: string = '';
  title: string = '';
  desc: string = '';
  symbol: DevToolSymbol = DevToolSymbol.DISPLAY;
  status: DevToolStatus = DevToolStatus.READY;
  group: DevToolGroup = DevToolGroup.ENV;
  /** 参考实现地址（调研出处；同时登记在开源备忘录 §6） */
  sourceUrl: string = '';

  constructor(id: string, title: string, desc: string, symbol: DevToolSymbol, group: DevToolGroup,
    status: DevToolStatus = DevToolStatus.READY, sourceUrl: string = '') {
    this.id = id;
    this.title = title;
    this.desc = desc;
    this.symbol = symbol;
    this.group = group;
    this.status = status;
    this.sourceUrl = sourceUrl;
  }
}

export function devToolGroupTitle(group: DevToolGroup): string {
  return group === DevToolGroup.DATA ? '数据处理' : '环境与能力';
}

/**
 * 开发工具清单（顺序即展示顺序）。
 *
 * 数据处理组五项来自 devtoolkit.io 开发者分类调研（见
 * `plan/开发者工具-第三方工具调研-2026-10-20.md`），全部为纯本地实现、不依赖网络。
 */
export function devTools(): DevToolItem[] {
  const env: DevToolItem[] = [
    new DevToolItem('device', '设备能力检测', '断点 / 设备形态 / 窗口适配 / 网络 / 国际化',
      DevToolSymbol.DISPLAY, DevToolGroup.ENV),
    new DevToolItem('iconkit', '图标处理 Kit',
      'hdsDrawable 分层图标合成：size 控尺寸、hasBorder 加描边',
      DevToolSymbol.PALETTE, DevToolGroup.ENV, DevToolStatus.READY,
      'https://gitcode.com/HarmonyOS_Samples/uidesign-kit_-sample-code_-arkts'),
    new DevToolItem('transitions', '转场动效合集',
      '元素进出 / 曲线对比 / 共享元素 / 形变位移 四种演示',
      DevToolSymbol.GRID, DevToolGroup.ENV, DevToolStatus.READY,
      'https://gitcode.com/HarmonyOS_Samples/transitions-collection')
  ];
  const data: DevToolItem[] = [
    new DevToolItem('hash', '哈希校验', 'SHA-256 / SHA-512 / SHA-1 / MD5，可与期望值核对',
      DevToolSymbol.HASH, DevToolGroup.DATA,
      DevToolStatus.READY, 'https://devtoolkit.io/zh-cn/developer/hash-generator'),
    new DevToolItem('codec', '编码工作台', 'Base64 / URL / HTML 实体 / JSON 转义，四模式双向',
      DevToolSymbol.CODEC, DevToolGroup.DATA,
      DevToolStatus.READY, 'https://devtoolkit.io/zh-cn/developer/base64-encode-decode'),
    new DevToolItem('idtool', 'ID 生成', 'UUID v4 / ULID（时间序），附时间戳互看',
      DevToolSymbol.KEY, DevToolGroup.DATA,
      DevToolStatus.READY, 'https://devtoolkit.io/zh-cn/developer/ulid-generator'),
    new DevToolItem('regex', '正则测试器', '命中位置 / 捕获组 / 替换预览，带 ReDoS 上限',
      DevToolSymbol.WRENCH, DevToolGroup.DATA,
      DevToolStatus.READY, 'https://devtoolkit.io/zh-cn/developer/regex-tester'),
    new DevToolItem('jsontool', 'JSON 工具台', '格式化 / 压缩 / 键排序 / 路径查询 / 错误行',
      DevToolSymbol.DOC, DevToolGroup.DATA,
      DevToolStatus.READY, 'https://devtoolkit.io/zh-cn/developer/json-formatter')
  ];
  return env.concat(data);
}

/** 取某一组的条目（视图按组渲染两个网格）。 */
export function devToolsOf(group: DevToolGroup): DevToolItem[] {
  return devTools().filter((item: DevToolItem): boolean => item.group === group);
}
