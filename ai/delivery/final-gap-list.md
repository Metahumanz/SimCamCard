# Final Gap List — 交付前差异清单（P01–P11 复审 + 本轮新发现）

Final Delivery Phase 1。配套：[course-compliance-matrix.md](./course-compliance-matrix.md)、
[final-reference-audit.md](../final-reference-audit.md)、
[real-vision-34/summary.md](../evaluation/real-vision-34/summary.md)。

- 基线：`week4/structured-recognition` @ `f5533b3c4486a644a9c2c427dc617efbe8dd8570`
- 日期：2026-10-12
- 复审方法：P01–P11 每个 PARTIAL 重新判定"是不是课程要求内的可观察行为缺失"，而非视觉装饰。
- 分类（任务书 §6 指定六类）：
  1. **Required behavior blocker** — 作业明文要求的可观察行为缺失；
  2. **Missing validation evidence** — 行为可能存在但缺少作业要求形态的证明；
  3. **Reference fidelity gap** — 行为 PASS 但与 CamCard 表面不同；
  4. **Platform-specific limitation** — iOS 27/SwiftUI/系统组件/无物理设备所致；
  5. **Excluded functionality** — 作业 §15 或 spec 排除清单内；
  6. **Non-blocking technical debt** — 记录在案、不阻断交付。

---

# ✅ Phase 1.1 更新（2026-10-18）— 原 blocker 已修复并完成行为级校准验证

Phase 1（2026-10-12）曾发现 **1 个确定 blocker（B-01）+ 1 个 blocker 候选（B-02）** 及概率性管线缺陷 **G-01**，
并 STOP 交由人类裁决。Phase 1.1 经人类批准后实施修复并全部通过验证；校准轮补齐了行为级证据与非法输入加固：

- **B-01 FIXED — behavioral verification: PASS**：详情页电话/Email/Website 点击已实现；DEBUG-only
  `-SimCamCardCaptureOpenURL 1` hook 实际 tap mobile/office/email/website 四行并断言捕获 `tel:`/`mailto:`/`https:` URL。
  非法输入加固（**minimal structural guards**）：phone 无数字 / email 结构非法 / website 显式非 web scheme（`ftp://` 等）一律返回 nil 不触发调用。
  **本轮仅实现最小结构校验，非完整电话/Email 格式验证；典型非法值反例测试 PASS 不等于任意非法输入都必然被拒绝。**
  **诚实边界**：系统 App（Phone/Mail/Safari）最终接管行为未在模拟器实测。
- **B-02 FIXED — behavioral verification: PASS**：详情页"查看原始名片"已实现；正向 E2E 完成
  首次保存及 terminate/relaunch 后 缩略图 → 全屏 → 关闭 双阶段闭环；Unit 字节级断言区分 `originalImageReference`
  与 `processedImageReference`。
- **G-01 FIXED**：`CardRegionGeometry.minimumDetectedArea`（0.05）面积闸门将 14 张 tiny-quad 误锁卡全部路由到
  inset fallback——零 OCR 行卡 14→0、`invalidRegion` 管线错误 2→0、present 字段准确率 **46.8% → 70.4%**
  （同一 harness/GT/归一化规则下的 before/after，见 summary.md §9 逐卡对比）。**保持 FIXED，未扩大算法修改。**

**校准轮门禁**：Unit **466/466**、**62/62 full UI regression, including 2 real Contacts integration tests (System01/System02)**、Debug/Release 构建均 PASS、
hook 隔离 **16/16 ABSENT**（Release）/ **16/16 PRESENT**（Debug dylib）。已知副作用：2 项真实 Contacts 集成测试会修改模拟器通讯录。

当前无未决 Required behavior blocker。

**Human Decision：Accepted — 2026-10-18 (human review)**（Phase 1.1 功能实现验收归档；历史 W4I12 / Phase 1 记录保持原样，未改写）。

---

# 历史记录：Phase 1 STOP 声明（2026-10-12）

本轮复审发现 **1 个确定 blocker（B-01）+ 1 个 blocker 候选（B-02）**，均在作业 §10 明文要求内、
且不在原 T01–T20 验收覆盖范围内。按任务书 §6 规则：**已停止，不自行扩大修改范围，不修复、不提交、不打包**，
交由人类裁决。修复均为小范围（系统原生组件，作业允许："may use native system components"），
但"修不修 / 何时修 / 是否补测"必须由人类决定。

另有一个概率性管线缺陷 G-01（检测器误检，14/34 auto-accept 零文本），在 §5.2 框架内不构成
确定性 blocker，但对"教师数据集结果要求"（§7.3）影响面大，一并提交人类决策。

---

## 1. Required behavior blockers

> **Phase 1.1 状态：B-01 / B-02 均已 FIXED。** 以下保留 Phase 1 原始判定作为历史记录，修复证据见各节末尾「Phase 1.1 解决」。

### B-01 ｜详情页点击 电话 / Email / Website 全部未实现（确定 blocker）→ **FIXED（Phase 1.1）**

- **作业原文（§10，中英一致）**："The business card detail page must support: … **Tap phone number;
  Tap email address; Tap website.**" / "点击电话号码；点击Email；点击Website。"
  下一句明确允许："Functions that invoke external system applications may use native system components."
- **现状**：
  - [CardDetailView.swift L74-79](file:///Users/metahumanz/codework/SimCamCard/SimCamCard/View/CardDetail/CardDetailView.swift#L74-L79) 注释："Deliberately NOT implemented: phone/email/web invocation (no tel:/URL wiring)"；
  - [CardDetailFieldRow.swift](file:///Users/metahumanz/codework/SimCamCard/SimCamCard/View/CardDetail/CardDetailFieldRow.swift) 是纯 `HStack`，无 `Button`/`Link`/`onTapGesture`/`openURL`；
  - 全文件唯一 `UIApplication.shared.open` 调用是导出权限页的 `openSystemSettings()`。
- **Reference**：`REF-detail-02-phone-picker.png` 证明 CamCard 点电话弹出系统操作面板；
  `REF-detail-01` 顶部有"电话"动作按钮。email/website 行可见但**点击结果未截图（NOT OBSERVED）**——
  不影响"作业要求该行为存在"的判定。
- **为何原审计漏掉**：final-reference-audit P07 以"no Reference acceptance row"将其归类 excluded；
  T13 验收文本只写"saved fields displayed"。Reference 维度成立，**作业维度不成立**。
- **修复边界（供人类决策，不在本轮执行）**：`CardDetailFieldRow` 按字段类型包 `Link`/`Button`
  （tel:、mailto:、https://；phone 多值可走系统 actionSheet 或直接 tel:）；
  需补确定性 UI 测试（断言行可点/调用 openURL seam）；模拟器无电话/邮件 App，测试需用 seam mock。
- **影响交付：是。** 这是作业 §10 must-support 列表中的 3 个可观察行为。
- **Phase 1.1 解决**：新增 [CardDetailURLMapping.swift](file:///Users/metahumanz/codework/SimCamCard/SimCamCard/View/CardDetail/CardDetailURLMapping.swift)
  （`phoneURL` → `tel:`、`emailURL` → `mailto:`、`websiteURL` → safe `https://`；无效/缺失值返回 nil 不触发调用）；
  [CardDetailFieldRow.swift](file:///Users/metahumanz/codework/SimCamCard/SimCamCard/View/CardDetail/CardDetailFieldRow.swift)
  按行包 `Button` + `openURL` seam。测试：Unit `CardDetailURLMappingTests`（合法/分隔符/无效值/percent-encoding）+
  UI `CardDetailUITests`（openURL seam 断言，模拟器不依赖真实电话/邮件 App）。
- **Phase 1.1 校准加固（behavioral verification）**：新增 DEBUG-only `-SimCamCardCaptureOpenURL 1` hook
  （[DebugOpenURLCapture.swift](file:///Users/metahumanz/codework/SimCamCard/SimCamCard/View/Debug/DebugOpenURLCapture.swift)），
  在 App 组合根替换 SwiftUI `openURL` 为记录器——捕获实际发起的 `absoluteString`、**不转发给系统 App**，
  并经 accessibility 元素暴露给 UI 测试。UI `testCardDetailRowTapInitiatesCorrectURL` 实际 tap mobile/office/email/website
  四行并断言捕获到 `tel:+86%20138%200013%208000` / `tel:+86%2021%205555%201234` / `mailto:wei.zhang@zhiyuntech.com` /
  `https://www.zhiyuntech.com`；`testCardDetailAddressRowDoesNotInitiateURL` 反例断言地址行不发起任何 URL。
  **诚实边界**：该 hook 证明的是 App 发起的 URL；系统 App（Phone/Mail/Safari）的最终接管行为在模拟器中未实测。
- **非法输入加固（校准发现并修复，minimal structural guards）**：`phoneURL` 曾仅查空值，`"not-a-phone"` 也会发起 `tel:`——违反冻结要求
  「无效或缺失值不得触发调用」。现 phone 增加"至少含一个可拨数字"校验，email 增加结构校验（单 `@`、非空
  local/domain、域名含点、无空白），并修复 website 显式非 web scheme（`ftp://`/`file://`）被静默升级为 `https://` 的缺陷。
  对应 Unit 反例：`"not-a-phone"`/`"()-"`/`"not-an-email"`/`"a@@b.com"`/`"a@b"` 等 12+ 条断言全部返回 nil。
  **边界说明：本轮仅实现最小结构校验（minimal structural guards），不是完整电话/Email 格式验证；典型非法值反例
  测试 PASS 不等于任意非法输入都必然被拒绝。**

### B-02 ｜详情页"查看原始名片"无 UI（blocker 候选，需人类解释裁决）→ **FIXED（Phase 1.1）**

- **作业原文（§10）**：detail page must support "**View original business card** / 查看原始名片"。
- **现状**：
  - 原始图片字节确实持久化（[ScanViewModel.swift L1016](file:///Users/metahumanz/codework/SimCamCard/SimCamCard/ViewModel/ScanViewModel.swift#L1016) `imageStore.save(reference: originalRef, data: crop.original.data)`），满足 §12 持久化保证；
  - 但详情页不渲染任何名片图像，全工程无图片查看器（无 fullScreenCover/ImageViewer；`originalImageReference` 不被任何 View 消费）；名片夹列表只显示 processed 缩略图。
- **Reference**：`REF-detail-01/03` 顶部为深色头像 header，**未观察到**原图查看入口/界面（NOT OBSERVED）。
- **解释空间**：T13（§17）验收文本仅要求"all saved fields displayed correctly"，不含图像。
  若老师把 §10 的 "View original business card" 解释为"保存的原图可追溯/在流程中可见"，
  现状可辩护；若解释为"详情页可点开查看原图"，则缺失。
- **影响交付：待人类裁决。** 若需修复，边界小：详情页加图条/点击全屏查看 `originalImageReference`（数据已在）。
- **Phase 1.1 解决**：[CardDetailView.swift](file:///Users/metahumanz/codework/SimCamCard/SimCamCard/View/CardDetail/CardDetailView.swift)
  新增 `card-detail-original-image` 图条（maxHeight 200）与 `fullScreenCover` 全屏查看器；
  `CardDetailViewModel.loadOriginalImage()` 经既有 `ImageAssetStore` 惰性加载，无第二图片数据所有者；
  缺图时优雅降级（不渲染图条，其余行不受影响）。测试：UI `CardDetailUITests.testCardDetailMissingOriginalImageGracefulDegradation`
  + T18 persistence relaunch 后原图仍可见（[CardPersistenceUITests.swift](file:///Users/metahumanz/codework/SimCamCard/SimCamCardUITests/CardPersistenceUITests.swift)）。
- **Phase 1.1 校准正向 E2E（behavioral verification）**：
  `CardPersistenceUITests` 扩展 T18 全链路闭环：首次保存后打开 Detail → 断言缩略图 → tap → 断言全屏查看器 → 关闭 →
  terminate/relaunch → 重新打开同一 card → 断言缩略图 → tap → 断言全屏查看器 → 关闭。两阶段均通过。
  Unit：`CardDetailViewModelTests.loadOriginalImageUsesOriginalReferenceNotProcessed` 用可区分的两个 payload
  （original=PNG signature, processed=JPEG signature）注入 `InMemoryImageAssetStore`，断言 VM 读取的是 `originalImageReference`
  而非 `processedImageReference`——在持久化/VM 层精确证明数据来源。

---

## 2. Missing validation evidence（缺作业要求形态的证明）

| ID | 事项 | 现状证据 | 缺什么 | 建议动作 |
|---|---|---|---|---|
| G-02 | **作业 §7.2 点名必测 "Photo library permission denied"** | 现代 PhotosUI `PhotosPicker` 进程外运行、不申请相册授权，**denied 状态在 iOS 27 不存在**；仅有 `REF-permission-02` 截图 + load-failure fixture | 作业清单项的直接证据 | 人类决定：(a) 在报告中引用 Apple 平台语义说明不可测；或 (b) 用受限相册/旧 API 复现；或 (c) 问老师口径 |
| G-03 | 系统 PhotosPicker 内真人取消手势 | E04 fixture 驱动的取消结果有 UI/Unit 证明；真人手势 final-acceptance T05 自认 NOT INDEPENDENTLY VERIFIED | 真机/模拟器手动取消一次的截图或录屏 | 交付前手动验证一次并存档（2 分钟） |
| G-05 | **Week 5 "UI Golden Tests"** | 55 个确定性行为 XCUITest + `ai/validation/*.png` 人工截图 + REF 截图 | 没有任何自动化像素/snapshot golden 断言（全仓库无 "golden" 字样） | 人类按老师口径裁决：人工对照报告是否算作 Golden 证据；若老师要自动化，需新增 snapshot 测试（工作量中等） |
| G-07 | Week 6 "AI capability-boundary analysis" | §8 五情形（歧义/名企混淆/多电话/中英混排/缺字段）散落在 extractor Unit、GT 回归、changes.md、`spec/reference-environment.md` | 无独立的边界分析文档 | 可在打包前从现有证据汇编一篇短报告（不需改代码） |
| G-08 | Week 6 "AI collaboration records" | changes.md 6200+ 行、40+ Accepted 标记、W4I12 Human Accepted；ai/README.md 流程规约 | `ai/prompts/_local/` 目录为空，无 prompt 原文归档 | 在报告中说明记录以 changes.md 为准；如老师要求 prompt 级证据则无法追溯补造（诚实声明） |
| G-10 | Week 6 "Final demonstration" | 无演示脚本/录屏 | 演示制品 | 查 Canvas 是否要求，再决定录屏 |

---

## 3. Reference fidelity gaps（行为 PASS，表面差异；P01–P11 复审结论）

P01–P11 行为仍为 20/20 PASS；所有 PARTIAL 复审后**维持原分类**——均非课程要求内的可观察行为缺失。
明细不变，摘要：

| 页 | PARTIAL 内容 | 分类 | 本轮复审结论 |
|---|---|---|---|
| P01 Holder | 头像/行样式、内嵌搜索条 | deferred cosmetic | 行为齐，维持 |
| P02 Scanner | 自定义 denied fallback（REF 仅系统对话框）；物理设备帧 | cosmetic + platform | 维持 |
| P03 Picker | 系统表面差异；真人取消未验证 | platform（→ G-03） | 维持 |
| P04 Crop | 手柄绘制非像素复刻；物理设备精度 | cosmetic + platform | 维持 |
| P05 Recognition | 空结果 Save 可见但禁用超出 REF 已观察证据（REF 未观察禁用态）；raw 过渡屏 CamCard 未外露；card-004 号码保留 OCR 空格 | cosmetic + 证据边界 | 维持 |
| P06 Save | 成功插图样式 | cosmetic | 维持 |
| P07 Detail | 头像/深色 header/收藏星/展开收起/英文公司昵称/action bar 样式 | cosmetic + frozen-domain + excluded | **但 tel/mailto/web 与原图查看从本类移出 → B-01/B-02** |
| P08 Search | 综合/个人/企业分段、企业数据源 | excluded（§15） | 维持 |
| P09 Group | 列表样式、alert cancel 相位 | cosmetic | 维持 |
| P10 Notes | 页面 chrome 简化；REF 内联"拍名片保存"摘要行（Domain 无法表示） | cosmetic + frozen-domain | 维持 |
| P11 Export | diff-1 denied 页 vs alert；diff-2/5 macOS 账户选择器；diff-3 email/address 无 work label → CNLabelOther；diff-4 website 不导出（作业 §13 六字段不含 URL） | platform / frozen-domain | 维持 |

CamCard 识别率对照范围：仅 card A/B/C（card-001/002/003）+ card-004 最小卡异常 + 1 张非名片
有真实观察；**card-005–034 全部 NOT OBSERVED**（矩阵 §D 已列补拍清单）。任何交付文本不得给这 30 张编造 CamCard 数字。

---

## 4. Platform-specific limitations

| ID | 事项 | 说明 |
|---|---|---|
| G-02p | 相册授权拒绝场景不存在 | 见 G-02。PhotosUI 现代 picker 无授权模型；作业写于旧 API 语境 |
| G-11 | 无物理 iPhone | 相机拍摄/真实光线检测/电话/邮件/浏览器跳转全部仅模拟器证明；final-acceptance 已全程声明 |
| G-12 | Contacts 导出表面 | CamCard 证据来自 macOS/Mac Catalyst，iOS 无账户选择器（diff-2/5） |

---

## 5. Excluded functionality（确认不做，合规）

注册/会员/订阅支付/广告/云同步/多设备/团队名片夹/Salesforce/CRM/企业权限与组织/数字名片设计与模板/
二维码交换/邮件签名/虚拟背景/AI 商业智能与分析/推荐/会议录制与总结/销售管线（§15 全量排除，代码中均无）。
搜索 综合/企业 分段、企业数据源（P08）；名片收藏星、递名片/分享名片、邀请、提醒（P07 action chrome）；
Department/Postal Code（§7.5 明确可选）；VCF（§13 二选一，Contacts 已满足）。

---

## 6. Non-blocking technical debt

| ID | 事项 | 记录位置 |
|---|---|---|
| G-06a | 孤儿名片图片无 GC（删卡后图片文件残留） | final-acceptance T18 |
| G-06b | Repository 协议 non-throwing，磁盘写失败无恢复路径 | 同上 |
| G-06c | 损坏 JSON 恢复路径未建（absent-file 稳定，corrupt 未处理） | 同上 |
| G-09 | **README.md 内容陈旧**：仍写 "Week 1 Frozen / Next: Week 2"，与最终实现严重不符 | 打包前必须刷新（构建说明仍可用，需重写项目状态段） |
| G-13 | `evidence/image-manifest.md` 抬头仍写 "Week 1 SDD baseline"（清单内容本身完整准确） | 打包前顺手修订抬头 |
| G-14 | `ai/changes.md` 末尾保留 W4I12 提交前"未 commit/push"历史语态 | 文档整理时加历史语境说明，不删改原始日志 |

---

## 7. 概率性管线缺陷（非 blocker，按 §5.2 如实报告，但需人类知晓）

### G-01 ｜ Vision 矩形检测器在 14/34 张教师数据集上误锁装饰小矩形（auto-accept 路径）→ **FIXED（Phase 1.1）**

- 现象与证据：[summary.md §2](../evaluation/real-vision-34/summary.md)。
  14 张检测区域面积 0.007–0.024（正常裁剪 0.47–0.93），裁剪输出 50–93 px 无文字 → 0 OCR 行；
  card-012/029 低于几何下限 0.01 → `invalidRegion` 管线报错。
- 根因证据：同 14 张全图诊断 OCR **全部**恢复 5–11 行；124 个 present 字段未匹配中
  **93 个属检测/裁剪根因**（12 OCR 根因、19 解析器根因）。card-025–034 为共享模板，
  误检坐标几乎相同（左上角装饰元素）。
- 缓解因素：App 提供 P04 手动拖角调整，用户可在确认前纠正；本评估测的是 auto-accept 路径。
- §5.2 框架：概率功能要求是"保留+准确率+归因+人工修正"，不保证全对——因此**不列为确定性 blocker**；
  但 §7.3 另有 "must satisfy behavior and result requirements specified by the instructor's test dataset"，
  41% 的卡 auto-accept 零文本是实质性能缺陷，是否在提交前修（例如：检测区域面积/置信度闸门、
  亚阈值 quad 回退到 inset/full 而非 throw、首候选不达标时尝试后续候选）由人类决策。
  任何修复都属新 Increment，需配确定性单测 + 重跑 34 卡评估对比。
- 伴随概率性弱点（已报告、不需单独决策）：12 个 phone kind 误分类（落 `.other`，不猜）；
  9 个 alternate-language 行（GT `company=null` + `companyLatin` 非空；**7 exact / 2 partial**，属真实 GT 字段的语言变体，**不算 fabrication**）；
  card-005/019/022 等 OCR 错读样例。
- **Phase 1.1 解决**：采用修复选项"检测区域面积闸门 + 亚阈值 quad 回退"。
  [CardRegionGeometry.swift](file:///Users/metahumanz/codework/SimCamCard/SimCamCard/Crop/CardRegionGeometry.swift)
  新增 `minimumDetectedArea = 0.05` 与 `isAcceptableAutoDetection(_:)`（阈值依据：34 张中正确裁剪面积 0.47–0.93，
  误锁 quad 0.007–0.024，间距 >10×，非单样本硬编码）；
  [CardCropProcessor.swift](file:///Users/metahumanz/codework/SimCamCard/SimCamCard/Crop/CardCropProcessor.swift)
  仅在 `prepare()` 的 auto-accept 分支应用闸门，Core Image 主链与实时预览路径未改；
  新增 `CardRegionDetecting` 协议 seam 支持 stub 注入。
  验证（同 harness/GT/归一化规则，baseline 为临时回退闸门后的实测）：detection accepted 33→19、fallback 1→15、
  pipeline error 2→0、零 OCR 行卡 14→0、present 字段匹配 109/233 (46.8%) → 164/233 (70.4%)、
  GT-absent 四桶（前后同定义）canonical absence **68→64** / alt exact **3→7** / alt partial **2→2** / genuine fabrication **0→0**；
  §9 逐卡 before/after 表完整列出每张卡变化。
  单测：`CardRegionGeometryTests` +3（面积闸门边界）、`CardCropProcessorTests` +3（stub 注入拒绝/接受/无检测回退）。

---

## 8. 处置优先级建议（Phase 1.1 更新后）

1. ~~决策 B-01~~ **已修复 + behavioral verification: PASS（Phase 1.1 校准）**——DEBUG-only openURL capture 四行实际 tap 断言 + 非法输入 minimal structural guards + 16/16 hook 隔离。
2. ~~解释裁决 B-02~~ **已修复 + behavioral verification: PASS（Phase 1.1 校准）**——正向 E2E 双阶段闭环（保存后 + relaunch 后各一次缩略图→全屏→关闭）+ VM 字节级 `originalImageReference` 断言。
3. ~~决策 G-01~~ **已修复（Phase 1.1）**——面积闸门 + 回退，34 卡重跑评估 before/after 见 summary §9。**保持 FIXED，未扩大算法修改。**
4. G-02/G-03 取得平台说明或手动证据；G-05/G-07/G-08/G-10 按 Canvas 与老师口径补证据（维持原建议）。
5. G-09/G-13/G-14 文档刷新（打包前必做，维持原建议）。

本轮：归档校准完成（Human Decision：**Accepted — 2026-10-18 (human review)**）。不自行 commit、不 push、不 merge、不 tag、不建 ZIP——提交由人类执行。
