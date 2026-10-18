import { AppFontSize, AppFontWeight, AppRadius, AppSpacing } from '@quizzyjoy/foundation';

let cardStorage = new LocalStorage();

/**
 * 服务卡片 UI（2×2 / 2×4 双规格共用，v3.27 接业务）。
 *
 * 【数据契约】展示数据**全部**由 FormAbility 组装的 formBindingData 提供：
 * 卡片侧零计算、零 IO、零条件取数；键名须与 `@easystart/widget-common` 的
 * `CardPayloadKeys` 逐字一致（同值对齐纪律：改键名须同时改这里与契约包）。
 * 装饰器参数是字面量，不能引用常量，故此处以字面量书写并靠上述纪律约束。
 *
 * 【⚠️ 关键实现约束（v3.27 真机实测踩坑）】卡片页首帧渲染时 LocalStorage **尚未**载入
 * 载荷（先用 `@LocalStorageProp` 默认值渲染），随后载荷到达才更新状态。
 * 因此**凡是状态值都必须在该元素自身作用域内直接读取**——若经「带值参数的 `@Builder`」
 * （如 `infoRow(label, this.themeText)`）转手，值会被按值捕获、**永不随载荷更新**
 * （真机现象：标题/时间等直接读取的字段正常，而显示/语言/字号三项始终停在默认值）。
 * 故本页为每个状态行写**专用 @Builder**（无参数、内部直读状态）。
 *
 * 【规格切换】由载荷 `isWide` 决定（FormAbility 的 onAddForm / onSizeChanged 写入）。
 *
 * 【点击深链】整卡 postCardAction.router 拉起本入口 Ability，params.target='settings'
 * → 入口 Ability 寄存目标 → 页面 onPageShow 消费并跳转设置页。
 *
 * 【装饰器例外】卡片框架当前仅支持 V1（@Entry/@Component/@LocalStorageProp），
 * 登记为 P5 例外（指南 §15/§P5）。
 */
@Entry(cardStorage)
@Component
struct WidgetCard {
  @LocalStorageProp('title') title: string = '趣开发';
  @LocalStorageProp('subtitle') subtitle: string = '偏好摘要';
  @LocalStorageProp('themeText') themeText: string = '跟随系统';
  @LocalStorageProp('languageText') languageText: string = '跟随系统';
  @LocalStorageProp('fontSizeText') fontSizeText: string = '标准（1×）';
  @LocalStorageProp('hapticText') hapticText: string = '开';
  @LocalStorageProp('accentText') accentText: string = '#0a59f7';
  @LocalStorageProp('updatedText') updatedText: string = '';
  @LocalStorageProp('ctaText') ctaText: string = '打开设置 ›';
  @LocalStorageProp('isWide') isWide: string = '0';

  private isWideLayout(): boolean {
    return this.isWide === '1';
  }

  /** 静态标签（字面量常量，值参数安全——不随状态变化）。 */
  @Builder
  rowLabel(label: string) {
    Text(label)
      .fontSize(AppFontSize.CAPTION)
      .fontColor($r('app.color.app_text_tertiary'))
  }

  /**
   * 显示模式行。
   *
   * 【⚠️ 状态必须在本元素作用域内直读】卡片页首帧以 @LocalStorageProp 默认值渲染，
   * 载荷到达后才更新状态；若值经**带值参数的 @Builder**（`this.rowValue(this.themeText)`）
   * 或普通方法转手，会被按值捕获、**永不重渲染**（v3.27 真机实测：标题/时间等直读字段正常，
   * 显示/语言/字号恒为默认值）。故四行的值一律内联书写。
   */
  @Builder
  themeRow() {
    Row({ space: AppSpacing.XS }) {
      this.rowLabel('显示')
      Blank()
      Text(this.themeText)
        .fontSize(AppFontSize.CAPTION)
        .fontWeight(AppFontWeight.MEDIUM)
        .fontColor($r('app.color.app_text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  /** 语言行（值内联直读，同 themeRow 说明）。 */
  @Builder
  languageRow() {
    Row({ space: AppSpacing.XS }) {
      this.rowLabel('语言')
      Blank()
      Text(this.languageText)
        .fontSize(AppFontSize.CAPTION)
        .fontWeight(AppFontWeight.MEDIUM)
        .fontColor($r('app.color.app_text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  /** 字号行（值内联直读，同 themeRow 说明）。 */
  @Builder
  fontSizeRow() {
    Row({ space: AppSpacing.XS }) {
      this.rowLabel('字号')
      Blank()
      Text(this.fontSizeText)
        .fontSize(AppFontSize.CAPTION)
        .fontWeight(AppFontWeight.MEDIUM)
        .fontColor($r('app.color.app_text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  /** 触感行（仅宽卡展示；值内联直读，同 themeRow 说明）。 */
  @Builder
  hapticRow() {
    Row({ space: AppSpacing.XS }) {
      this.rowLabel('触感')
      Blank()
      Text(this.hapticText)
        .fontSize(AppFontSize.CAPTION)
        .fontWeight(AppFontWeight.MEDIUM)
        .fontColor($r('app.color.app_text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  /** 标题行：应用名 + 强调色圆点（强调色直接可视）。 */
  @Builder
  titleRow() {
    Row({ space: AppSpacing.XS }) {
      Text(this.title)
        .fontSize(AppFontSize.BODY_SM)
        .fontWeight(AppFontWeight.BOLD)
        .fontColor($r('app.color.app_text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
      Column()
        .width(AppSpacing.MD)
        .height(AppSpacing.MD)
        .borderRadius(AppRadius.FULL)
        .backgroundColor(this.accentText)
        .border({ width: 1, color: $r('app.color.app_divider') })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  /** 底栏：最近刷新 + CTA。 */
  @Builder
  footerRow() {
    Row({ space: AppSpacing.XS }) {
      Text(this.updatedText)
        .fontSize(AppFontSize.CAPTION_XS)
        .fontColor($r('app.color.app_text_quaternary'))
      Blank()
      Text(this.ctaText)
        .fontSize(AppFontSize.CAPTION_XS)
        .fontWeight(AppFontWeight.MEDIUM)
        .fontColor($r('app.color.qj_brand'))
        .maxLines(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  /** 2×2 紧凑：标题 + 三行偏好 + 底栏。 */
  @Builder
  compactLayout() {
    Column({ space: AppSpacing.XS }) {
      this.titleRow()
      this.themeRow()
      this.languageRow()
      this.fontSizeRow()
      this.footerRow()
    }
    .width('100%')
    .height('100%')
    .padding(AppSpacing.MD)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(HorizontalAlign.Start)
  }

  /** 2×4 宽卡：左栏偏好明细 / 右栏强调色与行动。 */
  @Builder
  wideLayout() {
    Row({ space: AppSpacing.MD }) {
      Column({ space: AppSpacing.XS }) {
        this.titleRow()
        this.themeRow()
        this.languageRow()
        this.fontSizeRow()
        this.hapticRow()
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Column({ space: AppSpacing.XS }) {
        Text(this.subtitle)
          .fontSize(AppFontSize.CAPTION_XS)
          .fontColor($r('app.color.app_text_tertiary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Column()
          .width('100%')
          .layoutWeight(1)
          .borderRadius(AppRadius.MD)
          .backgroundColor(this.accentText)
          .border({ width: 1, color: $r('app.color.app_divider') })
        this.footerRow()
      }
      .width(120)
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .height('100%')
    .padding(AppSpacing.MD)
    .alignItems(VerticalAlign.Center)
  }

  build() {
    Column() {
      if (this.isWideLayout()) {
        this.wideLayout()
      } else {
        this.compactLayout()
      }
    }
    .width('100%')
    .height('100%')
    .borderRadius(AppRadius.XL)
    .border({ width: 1, color: $r('app.color.app_divider') })
    .backgroundColor($r('app.color.app_bg_card'))
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'PcAbility',
        params: { 'target': 'settings' }
      });
    })
  }
}
