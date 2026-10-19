# 课程作业 v2 要求覆盖矩阵 (Course Compliance Matrix)

Final Delivery Phase 1 — 逐项审计作业要求 vs 代码 / 测试 / Reference 证据。

- 作业文本：`assignment/`（英文 `assignment-en` 与中文 `assignment-cn`，内容一致；本节同时引用）。
- 审计基线：分支 `week4/structured-recognition`，HEAD `f5533b3c4486a644a9c2c427dc617efbe8dd8570`，审计开始时 tracked tree clean。
- 行为验收：T01–T20 = 20/20 PASS；Unit **466/466**；**62/62 full UI regression, including 2 real Contacts integration tests (System01/System02)**（Phase 1.1 校准新增 Unit 反例 + B-01/B-02 行为验证 UI；真实 Contacts 测试会修改模拟器通讯录，属已知副作用）；hook 隔离 **16/16 ABSENT**（Release）/ **16/16 PRESENT**（Debug dylib）。
- Reference 审计：[final-reference-audit.md](../final-reference-audit.md) P01–P11。
- 真实 Vision 评估（本轮新增）：[real-vision-34/summary.md](../evaluation/real-vision-34/summary.md)。
- 本矩阵日期：2026-10-12。本文件不含任何未经验证的 PASS。

> **Phase 2A-1 更新（2026-10-19）**：以上审计基线（HEAD `f5533b3`、日期 2026-10-12）为**历史事实，保留不改**。此后 Phase 1.1 修复已获 Human Decision **Accepted — 2026-10-18**，并以 `de58eee81326e6728080a2816ac718520c268366` **提交并推送**到 `origin/week4/structured-recognition`。当前交付状态：B-01 / B-02 / G-01 均 FIXED 且完成行为级验证；门禁基线为 Unit **466/466**、**62/62 full UI regression（含 2 项真实 Contacts 集成）**、Debug/Release 构建 PASS、hook 隔离 **16/16**。本节仅补充状态，不覆盖下方任何历史判定。

## 状态定义

| 状态 | 含义 |
|---|---|
| **PASS** | 有代码实现 + 有自动化或人工证据支持该条要求 |
| **PARTIAL** | 行为/证据部分满足，缺口已分类（见 [final-gap-list.md](./final-gap-list.md)） |
| **MISSING-EVIDENCE** | 实现存在或可能存在，但缺少作业要求形态的证明 |
| **NOT-IMPLEMENTED** | 作业明确要求的可观察行为在代码中不存在 |
| **NOT OBSERVED** | CamCard 侧从未实际观察到，不得填写任何结果 |
| **N/A-EXCLUDED** | 作业 §15 明确排除项，或可选字段 |

确定性功能（§5.1：UI/导航/状态/持久化/编辑/删除/搜索/标签/导出）标准 = 100% Reference Test 通过；
概率性功能（§5.2：OCR 与字段识别）标准 = 保留原文与结构化结果、GT 字段准确率、错误归因、人工修正，**不**要求 34/34。

---

## A. 确定性功能要求（作业 §7.1–§13 / T01–T20）

### A1. §7.1 Feature 1 — 名片夹首页 (T01/T12/T17)

作业原文："At minimum: Business card list; Empty-card state; Scan-business-card entry; Summary information for each business card; Tap to enter the business card details page; Search entry; Immediate list update after adding/deleting."

| 要求 | 对应代码 | 测试证据 | Reference 证据 | 实际完成 | 仍缺少的证明 | 状态 / 影响交付 |
|---|---|---|---|---|---|---|
| 名片列表 + 空态 | [CardHolderView.swift](../../SimCamCard/View/CardHolder/CardHolderView.swift)（`card-holder-empty`） | UI `CardHolderEmptyUITests`；Unit Holder 套件 | `REF-card-holder-01-empty.png`、`REF-card-holder-02-after-save.png` | 空/满两种状态均实现 | — | **PASS**；不影响 |
| 扫描入口 / 搜索入口 | `ScanEntryView`（scan-entry）；`CardSearchView` pushed 页 | UI `ScanEntryUITests`、搜索 UI | `REF-scanner-01-initial.png`、`REF-search-01/02` | 均实现；搜索为独立页而非内嵌条（fidelity 差异） | — | **PASS**（行为）；不影响 |
| 每行摘要信息 | [BusinessCardRow.swift](../../SimCamCard/View/CardHolder/BusinessCardRow.swift)（name/company + processed 缩略图） | UI holder 行断言 | `REF-card-holder-02-after-save.png` | 名称/公司/缩略图摘要 | — | **PASS**；不影响 |
| 点击进入详情 | CardHolder NavigationLink `card-row-*` | UI detail 进入测试；T13 | 同上 | 实现 | — | **PASS**；不影响 |
| 新增/删除后即时刷新 | `onAppear` + T17 `onDeleted` 闭包 | UI direct-save/delete | `REF-card-holder-02`、`REF-delete-01` | 实现 | — | **PASS**；不影响 |
| 首次启动工作流（Empty→Scan→Save→出现） | 全链路 | T01/T12 UI | `REF-card-holder-01/02` | 端到端证明 | — | **PASS**；不影响 |

### A2. §7.2 Feature 2 — 拍摄与图片导入 (T02–T05, T20)

作业原文（必做）："Camera preview; Camera permission request; Capture button; Back navigation; Cancel; Retake; Import from photo library; Captured-image preview; Confirm and enter recognition."
作业原文（必测）："Normal capture; Confirm after capture; Retake after capture; Cancel after capture; Import from photo library; **Camera permission denied; Photo library permission denied**; Exit midway."

| 要求 | 对应代码 | 测试证据 | Reference 证据 | 实际完成 | 仍缺少的证明 | 状态 / 影响交付 |
|---|---|---|---|---|---|---|
| 相机预览 / 权限请求 / 拍摄 / 返回 | [ScanEntryView.swift](../../SimCamCard/View/Scan/ScanEntryView.swift) 真实 AVCapture 会话 | UI T02/T04；权限 Unit | `REF-scanner-01/02`、`REF-permission-01-camera.png` | 真机 AVCapture（模拟器跑通） | 物理 iPhone 拍摄（环境无设备） | **PASS**（模拟器）；物理设备 = platform 限制 |
| Camera permission denied | `ScanViewModel` denied/restricted → 稳定 fallback 页（无拍摄/导入动作） | UI `testDeniedShowsStableFallbackWithoutSessionUI` 等 3 个 | `REF-permission-01-camera.png`（仅系统对话框） | 自定义 fallback 超出 Reference 观察 | — | **PASS**（行为）；不影响 |
| **Photo library permission denied（必测项）** | 系统 `PhotosPicker`（PhotosUI），进程外选择器，**iOS 上不产生相册授权弹窗，因此不存在 denied 状态**；仅有 load failure fixture | E04 load-failure fixture 测试（不等价于授权拒绝） | `REF-permission-02-photo-library.png`（仅系统设置/对话框截图） | 平台组件使该必测场景无法以同名状态出现 | 作业点名要求的"相册权限拒绝"测试**无对应证据**；需要人类决定如何向老师说明（旧 API 语义 vs 现代 picker） | **PARTIAL（platform-specific limitation + MISSING-EVIDENCE）**；可能影响"必测项"勾选，见 G-02 |
| Cancel（流程中取消）/ Exit midway | `handleImportCancel`、crop retake/cancel、recognition cancel(E06) | UI import-cancel / crop-cancel / E06 | — | 各阶段取消均有 fixture 证明 | 系统 picker 内真人取消手势未在模拟器独立验证（T05 已自认） | **PARTIAL**（MISSING-EVIDENCE G-03）；不阻断功能 |
| Retake / captured preview / confirm→recognition | Crop/Recognition 自动链 | UI T04/T06 | `2026-10-01-increment2-captured-photo-fixture.png` | 实现 | — | **PASS**（模拟器） |

### A3. §7.3 Feature 3 — 区域检测与图像校正 (T06)

作业原文："Automatic boundary detection; Visualization; Automatic cropping; Perspective correction; Orientation correction; Manual adjustment; Confirmation; Retake." 且 "must satisfy the behavior and result requirements specified by the instructor's test dataset"，测试数据需含透视/旋转/暗光/复杂桌面背景等。

| 要求 | 对应代码 | 测试证据 | Reference 证据 | 实际完成 | 仍缺少的证明 | 状态 / 影响交付 |
|---|---|---|---|---|---|---|
| 自动边界检测 + 可视化 + 手动调整 + 透视/方向校正 + 确认/重拍 | [CardCropProcessor](../../SimCamCard/Crop/CardCropProcessor.swift)、[CardRegionDetector](../../SimCamCard/Detection/CardRegionDetector.swift)、[CardCropView.swift](../../SimCamCard/View/Scan/CardCropView.swift) | UI T06（auto/manual/confirm/retake）；Unit crop 套件；真实 Vision smoke 001–004 | `REF-crop-01-manual-adjust.png` | 功能齐全 | 物理设备检测精度未声称（platform） | **PASS（功能/模拟器）** |
| **教师数据集上的检测结果要求（复杂背景）** | 同上（auto-accept + fallback 路径） | **本轮真实评估**：`CardRegionGeometry.minimumDetectedArea` (0.05) 闸门上线；14 张 tiny-quad 误锁全部回退到 inset fallback，零 OCR 行卡片从 14→0 张，pipeline error 从 2→0 次；present 字段准确率从 46.8% → 70.4%（summary §9 逐卡 before/after） | 无 CamCard 同类数据 | 闸门已覆盖 14/14 历史误锁样本；card-022 为真实 no-detection fallback（不受影响） | summary §9 完整记录修复效果 | **PASS**（§7.3 数据集要求已大幅提升；残余误差属 OCR/提取层，非检测缺失） |

### A4. §7.4 Feature 4 — OCR 文本识别 (T07)

作业原文："Students must not display only the final OCR result. The complete intermediate process must be preserved: Original → OCR Raw Text → Structured Fields → Manual Correction → Final Contact. These intermediate results must be available for subsequent analysis."

| 要求 | 对应代码 | 测试证据 | Reference 证据 | 实际完成 | 仍缺少的证明 | 状态 / 影响交付 |
|---|---|---|---|---|---|---|
| 真实 OCR | `CardOCRProcessor`（Vision RecognizeTextRequest .accurate, zh-Hans+en-US，自动语言检测，correction OFF） | Unit OCR 套件（含真实 Vision 无文字/渲染文字测试）；本轮 34 张真实评估 | T07 Raw Text = frozen **Partial**（CamCard 未外露 raw 屏） | 实现 | — | **PASS（保留契约）** |
| Raw text 逐字保留并持久化 | `OCRLine.top1 verbatim` → `StructuredRecognitionResult.ocrResult` → `BusinessCard.rawOCRText`（JSON 持久化） | T12 byte-exact 资产 + raw 保留测试 | CamCard raw 屏 **NOT OBSERVED** | 数据链完整可追溯：本轮 `raw-ocr.jsonl` 逐行含 confidence | App 内无 raw text 查看 UI（frozen T07 Partial；CamCard 从未暴露） | **PASS（保留/可追溯要求）**；UI 查看 = fidelity gap，不影响交付 |
| 中间过程"可用于后续分析" | rawOCRText + structured 全部落盘 | 本轮评估 harness 即消费这些中间产物 | — | 满足 | — | **PASS** |

### A5. §7.5 Feature 5 — 结构化字段提取 (T08/T09/T10)

作业原文 8 个必需字段："Name, Company, Job Title, Mobile Phone, Office Phone, Email, Website, Address"；可选：Department, Fax, Postal Code, Notes。

| 要求 | 对应代码 | 测试证据 | Reference 证据 | 实际完成 | 仍缺少的证明 | 状态 / 影响交付 |
|---|---|---|---|---|---|---|
| 8 字段结构化 | [CardFieldExtractor.swift](../../SimCamCard/Recognition/CardFieldExtractor.swift)（Phase A 类型 token + Phase B 语义） | Unit T08；GT 级回归 typed 34/34 | `REF-recognition-01..06`（card A/B/C） | 8 字段 + fax 均有 | Department/Postal Code = 作业可选，Domain 无 | **PASS**（可选缺失合法，N/A-EXCLUDED） |
| 缺失网站不得虚构 (T09) | website 仅识别 `www.`/`http(s)://` token；email-domain masking | Unit card-002；GT 回归 0 website 假阳性；真实评估 25 个 website-present/9 absent | `REF-recognition-03/04`（card B） | 满足 | — | **PASS** |
| 多电话 mobile/office/fax 分类 (T10) | 标签族 手机/Mobile、电话/Tel、传真/Fax；裸号 `1[3-9]` 归 mobile，其余诚实 `.other` | GT 回归多电话 23/23；真实评估：12 个 kind_misclassification（数字找到但落 `.other`：mobile 6 / office 5 / fax 1） | `REF-recognition-05/06`（card C） | 标签齐全时正确；无标签号码不强行归类 | 12 个 kind 错误的实际样例已在 summary §4/§8 列明 | **PASS（确定性 T10）**；概率性分类弱点已如实报告 |

### A6. §8 — AI 能力边界显式测试

作业原文点名五类情形：Field Ambiguity（Apple = company/product/address?）、Name–Company Confusion（Jordan Lee / Lee Consulting）、Multiple Phones（mobile/office/fax）、Mixed Chinese/English（朱宏明 / Professor / Tongji University）、Missing Fields（不得补全网站）。

| 情形 | 代码/测试位置 | 实际覆盖 | 仍缺少的证明 | 状态 |
|---|---|---|---|---|
| Field ambiguity | Extractor Unit 中的歧义行用例 + 不虚构契约 | 以"无标签不猜测"策略覆盖；未用字面 "Apple" 用例 | 可在交付说明中引用具体测试名；无独立边界分析报告 | **PARTIAL**（MISSING-EVIDENCE G-07：证据分散在 Unit/changes.md，无独立分析文档） |
| Name–Company confusion | GT 双语卡（card-019 等）+ parser Unit | 双语/多实体卡覆盖 | 同上 | **PARTIAL** |
| Multi phones | T10 + 23/23 GT 回归 | 充分 | — | **PASS** |
| Mixed CJK | 34 张含 zh/ja/ko/fr/de/es 卡；GT 回归 | 充分 | — | **PASS** |
| Missing fields（不补全） | T09；真实评估 73 个 GT-absent 单元按四桶重算（前后同定义）：strict canonical absence **64**、alt exact **7**、alt partial **2**、genuine fabrication **0** | **0** genuine fabrication；**9** alternate-language 行（GT `company=null` + `companyLatin` 有值时 parser 提升拉丁行，其中 **7 exact / 2 partial**，partial 不计入 exact） | summary §3/§4.1/§9 同定义 before/after | **PASS**（四桶互斥；strict canonical absence 与 genuine fabrication **均可跨运行比较**——前者衡量缺席字段保持缺席，后者衡量缺席字段未被捏造填充，性质不同；partial 不计入 exact） |

### A7. §9 Feature 6 — 识别确认与人工修正 (T11, T20)

作业原文："AI recognition results must not be saved directly without verification… User modifications; Cancellation of modifications."

| 要求 | 对应代码 | 测试证据 | Reference 证据 | 状态 |
|---|---|---|---|---|
| 识别结果进入可编辑确认页（不直接保存） | [RecognitionView.swift](../../SimCamCard/View/Scan/RecognitionView.swift) | T08/T11 UI | `REF-recognition-01..06` | **PASS** |
| 人工修正（scalar/多电话/多 email 行）替换最终值 | `manualEditing` draft；CardEditView ForEach emails/phones | Unit T11 套件；UI before/after | `REF-edit-01/02` | **PASS** |
| 修正取消 / 重拍放弃 | retake-discard；E06 failure Cancel | UI | — | **PASS** |
| 非名片空结果：进表单、无失败弹窗、无虚构、Save 禁用；minimal 卡可保存；OCR 失败有 Retake+Cancel | W4I12 E06/E07/E08 | UI `ExceptionHandlingUITests` + Unit E07；真实 t20-negative PNG 真实管线 0 字段 | `REF-exception-01-minimal-card-empty-fields.png`、`REF-exception-02-non-card-empty-result.png` | **PASS**（禁用 Save 超出 CamCard 已观察证据，fidelity 已注明） |

### A8. §10 Feature 7 — 保存与名片详情页 (T13/T14)（原阻断项 B-01/B-02 已修复）

作业原文（中英一致）："The business card detail page must support: View original business card; View recognized fields; Edit; Save; Delete; Back navigation; **Tap phone number; Tap email address; Tap website.** Functions that invoke external system applications may use native system components."

| 要求 | 对应代码 | 测试证据 | Reference 证据 | 实际完成 | 状态 / 影响交付 |
|---|---|---|---|---|---|
| 查看识别字段 | [CardDetailView.swift](../../SimCamCard/View/CardDetail/CardDetailView.swift) + [CardDetailFieldRow.swift](../../SimCamCard/View/CardDetail/CardDetailFieldRow.swift) 全 scalar + 多值行 | UI detail 001 full/004 minimal | `REF-detail-01/03` | 全部字段展示 | **PASS** |
| Edit / Save（编辑后保存） | CardEditView + `CardDetailViewModel` | T14 Unit/UI | `REF-edit-01/02` | 实现 | **PASS** |
| Delete（确认后删除） | `card-detail-delete` + 原生确认 alert | T17 | `REF-delete-01` | 实现 | **PASS** |
| Back navigation | NavigationStack 返回 | UI | — | 实现 | **PASS** |
| **Tap phone number（点击电话号码）** | [CardDetailURLMapping.swift](../../SimCamCard/View/CardDetail/CardDetailURLMapping.swift) `phoneURL(_:)` → `tel:`（**最小结构校验** minimal guards：不含可拨数字 → nil；**非完整电话格式验证**，典型非法值反例 PASS ≠ 任意非法输入必然被拒）；[CardDetailFieldRow.swift](../../SimCamCard/View/CardDetail/CardDetailFieldRow.swift) `Button` + `openURL` seam；无效/空号不触发调用 | Unit `CardDetailURLMappingTests`（percent-encoding + 非法输入反例）；**UI 行为验证**：DEBUG-only `-SimCamCardCaptureOpenURL 1` hook 捕获实际 URL——`testCardDetailRowTapInitiatesCorrectURL` tap mobile/office 行断言捕获 `tel:+86%20138%200013%208000` / `tel:+86%2021%205555%201234` | `REF-detail-02-phone-picker.png`（CamCard 系统操作面板） | 实现 | **PASS**（B-01 behavioral verification: PASS；系统 App 最终接管未实测） |
| **Tap email address（点击 Email）** | 同上，`emailURL(_:)` → `mailto:`（**最小结构校验** minimal guards：单 `@`/非空 local/domain/域名含点/无空白 → 失败即 nil；**非完整 Email 格式验证**，典型非法值反例 PASS ≠ 任意非法输入必然被拒） | 同上 Unit；**UI 行为验证**：tap email 行断言捕获 `mailto:wei.zhang@zhiyuntech.com` | email 行在 REF-detail-03 可见；点击结果 NOT OBSERVED | 实现 | **PASS**（B-01 behavioral verification: PASS；系统 App 最终接管未实测） |
| **Tap website（点击 Website）** | 同上，`websiteURL(_:)` → safe `https://`（显式非 web scheme 如 `ftp://`/`file://`/`javascript:` 拒绝；裸域名升级 https） | 同上 Unit；**UI 行为验证**：tap website 行断言捕获 `https://www.zhiyuntech.com` | website「首页」行可见；点击结果 NOT OBSERVED | 实现 | **PASS**（B-01 behavioral verification: PASS；系统 App 最终接管未实测） |
| **View original business card（查看原始名片）** | [CardDetailView.swift](../../SimCamCard/View/CardDetail/CardDetailView.swift) `card-detail-original-image` 图条 + `fullScreenCover` 全屏查看器；`CardDetailViewModel.loadOriginalImage()` 复用 `ImageAssetStore` | Unit：VM 字节级断言 `originalImageReference` ≠ `processedImageReference`；UI `CardDetailUITests` missing-image 降级；**正向 E2E**：T18 首次保存后及 terminate/relaunch 后各完成 缩略图 → 全屏 → 关闭 闭环 | REF-detail-01/03 未见原图查看器（NOT OBSERVED） | 实现 | **PASS**（B-02 behavioral verification: PASS） |

> 说明：final-reference-audit.md P07 将 tel/mailto/URL 归类为 "excluded from the slice (no Reference acceptance row)"。该分类对 Reference fidelity 成立，**但对课程作业不成立**——作业 §10 明文列为 must-support。本矩阵以作业文本为准。

### A9. §11 Feature 8 — 搜索与基本管理 (T15/T16)

作业原文：搜索 "Name; Company; Job title; Phone; Email"；标签 "Create Tag → Assign → View by Tag → Delete Tag"。

| 要求 | 代码 | 测试证据 | Reference | 状态 |
|---|---|---|---|---|
| 五范围搜索 + 空结果/清除/返回清除/组合搜索 | [CardSearchView.swift](../../SimCamCard/View/Search/CardSearchView.swift) | Unit 五范围；UI E14/E19 | `REF-search-01/02`（仅 name/company 已观察） | **PASS**；综合/企业分段搜索 = §15 排除 |
| 标签创建/指派/过滤/删除保留名片 | GroupManagementView + 独立 catalog | T16 Unit + UI；E12 双取消 | `REF-group-01..07` | **PASS** |

### A10. §12 Feature 9 — 本地持久化 (T18)

作业原文关键路径："Save → Kill App → Relaunch → Find → Open"；必须保证 original image、corrected fields、tags、notes 均在。

| 要求 | 代码 | 测试证据 | Reference | 状态 |
|---|---|---|---|---|
| JSON 文件仓储（schemaVersion 1）+ 文件图片存储 | `Persistence/`、ImageAssetStore | UI terminate(.notRunning)/relaunch 套件；Unit | `REF-persistence-01-after-relaunch.png` | **PASS（模拟器）** |
| 原图/改后字段/标签/备注存活 | 同上 | T18 全要素 | 同上 | **PASS** |
| 已知技术债：孤儿图片 GC、非 throwing 仓储、损坏 JSON 恢复 | — | final-acceptance §"Known non-blocking limitations" 已记录 | — | Non-blocking debt（G-06） |

### A11. §13 Feature 10 — 联系人导出 (T19)

作业原文："at least one of: Save to system Contacts **or** Export as VCF/vCard"；必须验证 Name/Company/Job title/Phone/Email/Address 映射。

| 要求 | 代码 | 测试证据 | Reference | 状态 |
|---|---|---|---|---|
| 系统联系人导出（满足二选一） | `SystemContactExporter`（CNContactStore+CNSaveRequest） | 真实 System01/02 + Contacts.app 六字段核对；5 个 denial/failure UI + T19 Unit | `REF-export-01..05` | **PASS**（真实 CNContactStore 成功） |
| VCF 导出 | 无 | — | CamCard VCF 路径 NOT OBSERVED | **N/A-EXCLUDED**（二选一已满足） |
| website 不导出 | 作业六字段映射不含 URL | Contacts.app 证据独立可见 | diff-4 frozen-domain | **PASS**（不缺项） |
| CRM/云同步 | 未做 | — | — | **N/A-EXCLUDED**（§15） |

---

## B. 概率性功能要求（作业 §5.2 / §7.4 / W6）

作业原文（§5.2 学生必须）："Preserve the original AI/OCR output; Preserve structured field extraction results; Compare with Ground Truth; Calculate field-level accuracy; Compare with the reference application; Analyze causes of recognition errors; Allow manual correction."

| # | 要求 | 交付物 | 状态 |
|---|---|---|---|
| B1 | 保留原始 OCR 输出 | `rawOCRText` 持久化；[raw-ocr.jsonl](../evaluation/real-vision-34/raw-ocr.jsonl)（316 行逐行 confidence + pipelineError + 检测区域坐标/面积 + 全图诊断 OCR） | **PASS** |
| B2 | 保留结构化结果 | [structured-results.jsonl](../evaluation/real-vision-34/structured-results.jsonl) | **PASS** |
| B3 | 与 GT 逐字段对比 | [comparison.csv](../evaluation/real-vision-34/comparison.csv) 306 行（34×9） | **PASS** |
| B4 | 字段级准确率 | present 字段 **164/233 = 70.4%**（gate 前 109/233 = 46.8%，summary §9 逐卡 before/after）；73 个 GT-absent 单元四桶（前后**同定义**）：canonical absence **68→64**、alt exact **3→7**、alt partial **2→2**、genuine fab **0→0**；分字段表、分母/归一化规则齐全（summary §3/§4.1/§9.1 + environment） | **PASS（如实报告，未追求 34/34，未改 GT）** |
| B5 | 与 Reference App 对比 | **仅 card A/B/C（=card-001/002/003）+ card-004 + 1 张非名片有真实 CamCard 观察**；card-005–034 = **NOT OBSERVED**（详见 §D） | **PARTIAL / NOT OBSERVED（G-04，需人类补拍或在报告中限定对比范围）** |
| B6 | 识别错误归因 | 三层分离：检测/裁剪 **4**、OCR **10**、解析器 **55**（69 个 present 未匹配）；错误类型 8 类统计；**30** kind 误分类；GT-absent 四桶（同定义 before/after）：canonical absence **68→64**、alt exact **3→7**、alt partial **2→2**、genuine fab **0→0**；逐卡明细 + before/after 对比（summary §2/§4/§4.1/§5/§7/§8/§9） | **PASS** |
| B7 | 允许人工修正 | T11/A7 | — | **PASS** |
| B8 | GT 级解析器回归（独立层，保留） | `StructuredGroundTruthRegressionTests`：typed 34/34、full-exact 32/34、0 fabrication、多电话 23/23 | **PASS**（与真实 Vision 层显式分离，不互相引用） |
| B9 | 真实评估不污染确定性基线 | harness env-gated（`TEST_RUNNER_REAL_VISION_EVAL=1`），默认 skip；456 基线不受影响 | — | **PASS** |

数据集规模（§14 建议 30–50，含 GT）：**34 张 PNG + 34 个 GT JSON**，类型覆盖中/英/双语/竖版/多电话/缺字段/复杂背景；另 1 个非名片异常样本（单独计数）。**PASS**。GT schema 与不可变性：[dataset-integrity-audit.md](../dataset-integrity-audit.md)。

---

## C. Week 5 / Week 6 交付物要求

| 作业条目 | 现有交付 | 缺口 | 状态 |
|---|---|---|---|
| Week 5 "UI Golden Tests" | 60 个确定性 XCUITest（行为断言）+ `ai/validation/*.png` 人工截图（每周 increment 留档）+ REF 截图 | **无自动化像素级 Golden 套件**；现有"golden"实质是人工目视对照 + 行为自动化 | **MISSING-EVIDENCE（G-05）**：是否需要补一个截图断言套件由人类按老师口径决定 |
| Week 6 "UI screenshot comparison" | P01–P11 逐页人工对照报告（final-reference-audit，含每处差异分类）+ REF/实现截图双方 | 无自动化 screenshot-diff；对照仅覆盖 card A/B/C 场景 | **PARTIAL**（人工对照证据存在，自动化不存） |
| Week 6 "Standardized testing using 30–50 cards" | 34 卡 GT 回归 + **本轮 34 卡真实 Vision 评估** | — | **PASS** |
| Week 6 "OCR error analysis / Field-extraction error analysis" | summary.md §2/§4/§5/§7/§8（分离 OCR 层与提取层） | — | **PASS** |
| Week 6 "AI collaboration records" | [changes.md](../changes.md) 6200+ 行逐 increment 日志（AI 改动/人类 Accepted 标记 40+ 处，含 W4I12 Human Accepted 2026-10-09）；[ai/README.md](../README.md) AI 使用流程 | `ai/prompts/_local/` 目录**为空**——无独立 prompt 归档；过程记录以 changes.md 为准 | **PARTIAL（G-08）** |
| Week 6 "AI capability-boundary analysis" | §8 五情形散见于 extractor Unit、GT 回归、changes.md、reference-environment.md | 无独立边界分析报告文档 | **PARTIAL（G-07）** |
| Week 6 "SDD documentation finalization" | `spec/` 7 篇 + `spec.md` + ai/ 系列 | README.md 仍停留在 "Week 1 Frozen / Next: Week 2" 状态，与最终实现不符 | **Non-blocking debt（G-09，打包前必须刷新）** |
| Week 6 "Final demonstration" | 无演示脚本/录屏 | 若老师要求演示需另行准备 | **MISSING-EVIDENCE（G-10，取决于 Canvas 要求）** |
| §16 "No One-Prompt Generation" | 增量式开发全程记录（changes.md） | — | **PASS** |

---

## D. CamCard 已观察对照范围（§5 B5 明细）

Reference 版本 CamCard 8.63.1，观察源 = `evidence/screenshots/REF-*.png`（40 张，见 [image-manifest.md](../../evidence/image-manifest.md)）。

| Dataset 卡 | CamCard 真实识别结果 |
|---|---|
| card A = card-001（standard bilingual，张伟） | **OBSERVED**：`REF-recognition-01/02`（top/bottom）+ 详情/编辑/导出全流程截图 |
| card B = card-002（missing website） | **OBSERVED**：`REF-recognition-03/04`（缺网站观察） |
| card C = card-003（multiple phones/fax） | **OBSERVED**：`REF-recognition-05/06` |
| card-004（minimal name+mobile） | **OBSERVED（仅最小卡异常行为）**：`REF-exception-01-minimal-card-empty-fields.png`；字段级识别结果未单独截全 |
| 非名片 t20-negative-001 | **OBSERVED（空结果行为）**：`REF-exception-02-non-card-empty-result.png` |
| **card-005 ～ card-034（30 张）** | **NOT OBSERVED**——无任何 CamCard 识别截图/记录；summary.md 与所有交付文本不得出现这 30 张的 CamCard 准确率数字 |

流程/页面级观察（与具体卡片识别率无关）：scanner、crop、import picker、save、holder、search(name/company)、group 全流程、notes、export Contacts 五张、camera/photo 权限对话框、detail phone-picker、delete 确认。

仍需人类在 CamCard 中补做的事项（若要扩大对比范围）：
1. 对 card-005–034（或老师指定子集）逐张导入 CamCard，截图识别结果页（top/bottom）与保存后详情页；
2. 详情页点击 email / website 的实际系统行为截图（当前仅 phone picker 被观察）；
3. 相册权限拒绝在 CamCard 中的表现（若老师设备/旧 API 可复现）；
4. CamCard 是否提供"查看原始名片图"入口的确认截图。

---

## E. 专项核查结论（任务书点名五项）

1. **详情页电话/Email/Website 点击**：已实现（`CardDetailURLMapping` + `CardDetailFieldRow` 原生 `openURL` seam；无效/缺失值不触发；Unit + UI 覆盖）→ **B-01 FIXED**（证据见 A8）。详情页**查看原始名片**亦已实现（复用 `ImageAssetStore`，图条 + 全屏查看器）→ **B-02 FIXED**。
2. **Photo Import / Photo Library 权限与取消**：权限拒绝 = 现代 PhotosPicker 平台不适用 + 缺作业同名测试证据（G-02）；真人取消手势未独立验证（G-03）。
3. **原始 OCR 保留与可追溯**：PASS——持久化字段、逐行 JSONL、confidence、区域坐标、管线错误串全部可追溯；App 内无 raw 查看 UI（frozen T07 Partial，CamCard 同样未观察到）。
4. **34 张真实图片识别评估**：PASS（真实生产组件，env-gated，可重复）；字段准确率 **70.4%**（gate 前 46.8%）；73 个 GT-absent 单元四桶**同定义** before/after（canonical absence **68→64**、alt exact **3→7**、alt partial **2→2**、genuine fab **0→0**；strict canonical absence 与 genuine fabrication 均可跨运行比较，衡量不同性质问题），检测器误锁已通过 `minimumDetectedArea` 闸门关闭（零 OCR 行卡 14→0、pipeline error 2→0；summary §9 逐卡 before/after），已如实分离报告。
5. **UI Golden 对照**：无自动化 golden；人工目视对照 + 62 项完整 UI 回归（含 2 项真实 Contacts 集成）+ 双方截图 = PARTIAL（G-05）。
6. **AI 协作/人类审核记录**：changes.md + ai/README.md + W4I12 Human Accepted；prompt 归档目录为空（G-08）；无独立能力边界分析文档（G-07）。

## F. 审计结论

- 确定性 T01–T20 行为层：**20/20 PASS 成立**；作业 §10 原验收盲区（三个点击行为 + 原图查看，记为 B-01/B-02）**已在 Phase 1.1 实现并通过 Unit/UI 测试**。
- 概率层：检测器面积闸门（`minimumDetectedArea` = 0.05）已实施；34 张真实评估 present 字段准确率 **46.8% → 70.4%**；73 个 GT-absent 单元按四桶**同定义** before/after 报告（canonical absence **68→64**、alt exact **3→7**、alt partial **2→2**、genuine fabrication **0→0**）——strict canonical absence 与 genuine fabrication **均可跨运行比较**，只是衡量不同性质的问题（前者 = 缺席字段保持缺席的正确性，后者 = 缺席字段未被捏造值填充），不把 strict-before 与 relaxed-after 混为同一 safety 指标（`BioSystems`/`Secure Systems` 等部分重叠已标 **PARTIAL**，不计 exact）；before/after 逐卡对比完整记录于 summary §9；未修改 GT/数据集。
- 交付建议：B-01/B-02/G-01 均已修复并验证（详见 [final-gap-list.md](./final-gap-list.md)）；**Human Decision：Accepted — 2026-10-18 (human review)**。
- **归档状态（Phase 2A-1 更新，2026-10-19）**：修复范围已以 `de58eee` **commit + push** 至 `origin/week4/structured-recognition`（原“不自行 commit / push / merge / tag / 打包”的 Phase 1.1 语态为提交前历史记录，保留不改）。本轮文档刷新未改动 production / test / frozen 文件。
