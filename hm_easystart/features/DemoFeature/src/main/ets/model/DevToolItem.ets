/**
 * 开发工具目录数据（v3.41）。
 *
 * 一项一卡：已实现的工具 status = READY（点击进对应面板），规划中的工具
 * status = PLANNED（卡片灰显 + 「待实现」角标，点击给出提示）。
 *
 * 规划项的 sourceUrl 指向参考实现，统一登记在 docs/权威参考与开源项目盘点.md §6
 * （开源备忘录）：实现新工具时先查备忘录再动代码，避免重复调研。
 */
export enum DevToolStatus {
  /** 已实现，可点击进入 */
  READY,
  /** 待实现（卡片灰显 + 角标） */
  PLANNED
}

/** 卡片图标：不直接存 Resource（不能动态拼 $r），由视图按 key 映射为 sys.symbol。 */
export enum DevToolSymbol {
  DISPLAY,
  PALETTE,
  GRID
}

export class DevToolItem {
  id: string = '';
  title: string = '';
  desc: string = '';
  symbol: DevToolSymbol = DevToolSymbol.DISPLAY;
  status: DevToolStatus = DevToolStatus.READY;
  /** 参考实现地址（调研出处；同时登记在开源备忘录 §6） */
  sourceUrl: string = '';

  constructor(id: string, title: string, desc: string, symbol: DevToolSymbol, status: DevToolStatus,
    sourceUrl: string = '') {
    this.id = id;
    this.title = title;
    this.desc = desc;
    this.symbol = symbol;
    this.status = status;
    this.sourceUrl = sourceUrl;
  }
}

/**
 * 开发工具清单。
 *
 * 排序约定：已实现的排前面，待实现的按调研优先级排后面。
 */
export function devTools(): DevToolItem[] {
  const ready: DevToolItem[] = [
    new DevToolItem('device', '设备能力检测', '断点 / 设备形态 / 窗口适配 / 网络 / 国际化',
      DevToolSymbol.DISPLAY, DevToolStatus.READY)
  ];
  const planned: DevToolItem[] = [
    new DevToolItem('iconkit', '图标处理 Kit',
      'hdsDrawable 分层图标合成：size 控尺寸、hasBorder 加描边',
      DevToolSymbol.PALETTE, DevToolStatus.READY,
      'https://gitcode.com/HarmonyOS_Samples/uidesign-kit_-sample-code_-arkts'),
    new DevToolItem('transitions', '转场动效合集',
      '元素进出 / 曲线对比 / 共享元素 / 形变位移 四种演示',
      DevToolSymbol.GRID, DevToolStatus.READY,
      'https://gitcode.com/HarmonyOS_Samples/transitions-collection')
  ];
  return ready.concat(planned);
}
