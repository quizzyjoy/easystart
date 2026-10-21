import { UiThemeManager } from '@quizzyjoy/vitalui';
import { AppFontSize, AppFontWeight, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager } from '@quizzyjoy/platform';

/** 关于模板的一节（标题 + 说明 + 要点）。 */
class TemplateAboutSection {
  readonly title: string;
  readonly desc: string;
  readonly bullets: string[];

  constructor(title: string, desc: string, bullets: string[]) {
    this.title = title;
    this.desc = desc;
    this.bullets = bullets;
  }
}

/**
 * 关于模板（L3，v3.38 三级架构）。
 *
 * 只回答三个问题：这是什么 / 怎么用 / 如何 fork。
 * 本页位于 features/DemoFeature（示例包内），由 product/entry 与 entry_pc 的 pageMap 挂载：
 * 而本页是入口侧的说明页，不参与示例域（fork 时随示例包一起删掉也可）。
 */
const ABOUT_SECTIONS: TemplateAboutSection[] = [
  new TemplateAboutSection('这是什么', '「一次开发、四端部署」的鸿蒙应用模板：手机/折叠屏、2in1、TV、手表四个入口共用同一套基础库与业务特性。',
    [
      '三库分层：Foundation（令牌与响应式）· Platform（脆弱系统能力收口）· VitalUI（通用视图组件）',
      '四层目录：quizzyjoy 三库 → commons 应用级域 → features 业务特性 → product 四端入口装配',
      'HDS 原生感：HdsNavigation / HdsTabs / HdsListItemCard 官方组件 + 官方沉浸光感与安全区姿势',
      '设计令牌单一来源：颜色、字阶、圆角、间距、动效一律走令牌与资源，禁止就地写字面量'
    ]),
  new TemplateAboutSection('怎么用', '示例 Tab 按「能力域 → 分组 → 单页」三级组织，学习 Tab 是配套教程——每章都对应仓库里真实存在的代码。',
    [
      '组件示例：单组件一页式对照，按内容拆成七组（操作与状态 / 输入与检索 / 反馈与容器 / 弹层与选择器 / 响应式与令牌 / 平台能力 / 应用组件与动效）',
        'VitalUI 组件：库内组件的独立专区（数据图表 / 加载与骨架 / 颜色选择器 / 状态与列表），与上一条分开成卡',
        '四端差异：手机 / 折叠屏 / 2in1 为示例 Tab 三级结构（入口卡 → 二级导航 → 单页）；TV 端无 Navigation 宿主，退化为一张全量长页',
      '场景示例：可整页复制的页面范式（反馈流 / 数据看板 / 表单 / 列表四态 / 搜索 / 折叠屏分屏）',
      '模板能力：设置中心、详情页范式、账号登录页范式三块已装好的基础设施（设备能力已移到底部「开发工具」Tab）',
      '设计令牌：全量令牌对照页；换肤只改 AppScope 的颜色资源（qj_ 前缀品牌色）',
      '学习：ArkTS 状态管理 V1 → V2 等章节，边读边对照源码'
    ]),
  new TemplateAboutSection('如何 fork', '复制本仓后按顺序改这几处，其余结构照用；改动越少，后续跟模板升级越省力。',
    [
      'AppScope/app.json5 改 bundleName 与版本号；AppScope/resources 换 app_name 与品牌色',
      '删除 @easystart/demo-feature（本演示包）与示例 / 学习 / 开发工具三个 Tab，替换成自己的 feature',
      '新业务照 features/HomeFeature 的 MVVM 结构新建：data（Repository）→ viewmodel → view',
      '签名配置不入库（本仓 build-profile.json5 走 skip-worktree），fork 后用 DevEco 自动签名',
      '提交格式与版本号纪律见仓库 plan/git_constraints.md'
    ])
];

@ComponentV2
export struct TemplateAboutView {
  @Local theme: UiThemeManager = UiThemeManager.getInstance();

  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  @Builder
  sectionBody(section: TemplateAboutSection) {
    Column({ space: AppSpacing.SM }) {
      Text(section.title)
        .fontSize(AppFontSize.TITLE_SM)
        .fontWeight(AppFontWeight.MEDIUM)
        .fontColor($r('app.color.app_text_primary'))
        .width('100%')
      Text(section.desc)
        .fontSize(AppFontSize.BODY_SM)
        .fontColor($r('app.color.app_text_secondary'))
        .lineHeight(22)
        .width('100%')
      Column({ space: AppSpacing.SM }) {
        ForEach(section.bullets, (item: string, index: number) => {
          Row({ space: AppSpacing.SM }) {
            Text('·')
              .fontSize(AppFontSize.BODY)
              .fontColor(this.theme.brandColor())
            Text(item)
              .fontSize(AppFontSize.BODY_SM)
              .fontColor($r('app.color.app_text_primary'))
              .lineHeight(22)
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
        }, (item: string, index: number): string => `${index}_${item}`)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(AppSpacing.MD)
    .borderRadius(AppRadius.XL)
    .backgroundColor($r('app.color.app_bg_card'))
  }

  build() {
    Scroll() {
      Column({ space: DesignToken.sectionSpacing() }) {
        ForEach(ABOUT_SECTIONS, (section: TemplateAboutSection) => {
          this.sectionBody(section)
        }, (section: TemplateAboutSection): string => section.title)

        Text('本页只给上手路径；上面每条结论都能在仓库里找到对应源码。')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .constraintSize({ maxWidth: DesignToken.contentMaxWidth(this.bp()) })
      .padding({
        left: DesignToken.pagePadding(this.bp()),
        right: DesignToken.pagePadding(this.bp()),
        top: AppSpacing.LG,
        bottom: AppSpacing.XXXL
      })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .backgroundColor($r('app.color.app_bg_page'))
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}
