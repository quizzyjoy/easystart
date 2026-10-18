import { AppError, Logger, Result } from '@quizzyjoy/foundation';
import { ErrorMapper } from '@quizzyjoy/platform';

const DOMAIN: string = 'demo';
const TAG: string = 'HomeRepository';

/**
 * 首页能力目录项的目标（导航语义载荷，v3.26）。
 *
 * feature 不感知路由名：本枚举由**入口装配层** switch 映射到 `AppRoute` 常量后再 push
 * （与 DemoFeature 的 `DemoSample` 同一范式），feature 侧零 RouterManager import；
 * 枚举到路由名的映射唯一出处在 product 入口层。
 */
export enum HomeTarget {
  /** 令牌总览子页 */
  TOKENS,
  /** 反馈流子页 */
  FEEDBACK,
  /** 数据看板子页 */
  CHARTS,
  /** 表单范式子页 */
  FORM,
  /** 列表四态子页 */
  LIST,
  /** 搜索场景子页 */
  SEARCH,
  /** 设置中心子页 */
  SETTINGS,
  /** 详情页范式（push 本项**对象**，示例「列表 → 详情」链路） */
  DETAIL,
  /** 设备能力（入口切换到底部 Tab，不 push） */
  DEVICE
}

/**
 * 首页目录项模型（模板能力目录：一行一卡，点击由入口按 target 分发）。
 *
 * v3.26 起首页由「One..Four 占位卡」改为**能力目录**：卡片即模板能力入口，
 * fork 后把本文件的数据换成真实接口（或真实业务条目）即可，视图与装配无需改动。
 */
export class HomeItem {
  id: string = '';
  title: string = '';
  description: string = '';
  /** 点击目标（入口 switch 分发；默认落在详情页范式）。 */
  target: HomeTarget = HomeTarget.DETAIL;
  /** 详情页元信息标签（仅 DETAIL 项使用；HomeDetailView 对空数组安全）。 */
  tags: string[] = [];
  /** 详情页正文段落（仅 DETAIL 项使用）。 */
  body: string[] = [];

  constructor(id: string, title: string, description: string, target: HomeTarget) {
    this.id = id;
    this.title = title;
    this.description = description;
    this.target = target;
  }

  /** 链式设置详情标签（目录数据声明更紧凑）。 */
  withTags(tags: string[]): HomeItem {
    this.tags = tags;
    return this;
  }

  /** 链式设置详情正文段落。 */
  withBody(body: string[]): HomeItem {
    this.body = body;
    return this;
  }
}

/**
 * 数据仓库（Repository）。
 *
 * 三条约定：
 * 1. feature 内的数据获取一律走 Repository，View / ViewModel 不得直接发请求。
 * 2. 返回值用 Result<T> 表达"可预期的失败"，只有意外才 throw。
 * 3. 边界处（网络 / 存储 / 系统 API）统一用 ErrorMapper 把系统异常转成 AppError。
 *
 * 当前为模板能力目录（占位实现），接入真实接口时只替换本文件。
 */
export class HomeRepository {
  async fetchItems(): Promise<Result<HomeItem[]>> {
    Logger.info(DOMAIN, TAG, 'fetchItems start (placeholder)');
    try {
      const items: HomeItem[] = [
        new HomeItem('1', '令牌总览',
          '字阶 / 圆角 / 间距 / 描边 / 阴影 / 触摸目标 / 色彩全量对照，页面即令牌真相',
          HomeTarget.TOKENS),
        new HomeItem('2', '反馈流',
          '提交失败重试 / 危险确认 / 筛选 Sheet 多选回写 / 轻提示降级对照',
          HomeTarget.FEEDBACK),
        new HomeItem('3', '数据看板',
          '四图表断点栅格 + 深浅色联动重绘 + 20 色色卡全量取色 + 选中详情联动',
          HomeTarget.CHARTS),
        new HomeItem('4', '表单范式',
          '受控表单域 + 逐域校验红线 + 取色实时联动 + 提交确认闭环',
          HomeTarget.FORM),
        new HomeItem('5', '列表四态',
          'StateContainer 加载/空/错误/内容四态 + RefreshList 刷新与分页状态机',
          HomeTarget.LIST),
        new HomeItem('6', '搜索场景',
          '防抖受控输入 + 热词提示 / 结果列表 / 无匹配空态三态流转',
          HomeTarget.SEARCH),
        new HomeItem('7', '设置中心',
          '显示模式 / 强调色 / 语言 / 字号 / 触感 / 屏幕方向 / 清缓存 / 关于与政策许可',
          HomeTarget.SETTINGS),
        new HomeItem('8', '详情页范式',
          '「列表 → 详情」标准骨架：徽标 + 元信息 + 正文 + 操作条（宽屏落 Split 右栏）',
          HomeTarget.DETAIL)
          .withTags(['详情范式', 'Split 适配', '分享接入'])
          .withBody([
            '本页是「列表 → 详情」标准范式：从首页目录进入，宽屏（lg 以上）由 HdsNavigation 的 Split 模式自动落到右栏，窄屏为整页 push。',
            '结构自上而下：品牌徽标 + 标题副标题 → 元信息标签行 → 正文段落 → 底部操作条（分享 / 收藏）。',
            '导航纪律：detail 视图不感知路由（不 import RouterManager），点击经 @Event 上抛给入口装配层；分享机制由 Platform 的 ShareHelper 承担，页面只决定「分享什么」。'
          ]),
        new HomeItem('9', '设备能力',
          '断点 / 能力探测 / 设备形态 / 窗口适配等平台能力面板（切换到底部「设备」Tab）',
          HomeTarget.DEVICE)
      ];
      if (items.length === 0) {
        // 可预期失败：属于正常业务分支，用 Result 返回而非抛异常
        return Result.fail<HomeItem[]>(AppError.expected(1, 'empty data set', DOMAIN));
      }
      Logger.info(DOMAIN, TAG, `fetchItems done, size=${items.length}`);
      return Result.ok<HomeItem[]>(items);
    } catch (err) {
      // 意外失败：映射成 AppError 后仍以 Result 交给上层，由上层决定 UI 表现
      const appError: AppError = ErrorMapper.from(err, DOMAIN, 'fetchItems');
      return Result.fail<HomeItem[]>(appError);
    }
  }
}
