# 单文件交付包规划（ZIP）— 本轮仅规划，不打包

Final Delivery Phase 1 §7。所有大小/结构基于当前工作区实测（2026-10-12）。
**本文件不是打包命令执行记录；ZIP 待 Human Decision（B-01/B-02/G-01 处置后）再创建。**

## 0. Canvas 约束（必须先在作业页面核实，本文无法代查）

- 允许的提交文件类型（ZIP 是否允许、是否要求文件夹/其他格式）；
- 单文件大小上限；
- 是否要求额外的演示视频/PDF（影响 G-10 与是否需要导出报告 PDF）。

当前候选包未压缩 ≈ 53 MB（主要：`dataset/` 25 MB、`ai/validation/` 13 MB、`evidence/` 13 MB、
源码 ≈ 1.4 MB、文档 < 1 MB）；ZIP 压缩后预计仍接近原大小（PNG 为主），若超限按 §4 预案分级。

## 1. 建议包结构（单层根目录 `SimCamCard/`，解压即工程）

```text
SimCamCard/
├── README.md                     # 打包前刷新（G-09）：项目状态 + 构建/测试指引
├── SDD-README.md                 # SDD 工作入口
├── spec.md                       # SDD 规格主文档
├── SimCamCard.xcodeproj/         # Xcode 工程（排除 xcuserdata/，见 §3）
├── SimCamCard/                   # 完整生产源码（Swift 6，含 Crop/OCR/Extraction/…）
├── SimCamCardTests/              # 431 个确定性 Unit + GT 回归 + env-gated 真实评估 harness
├── SimCamCardUITests/            # 55 个确定性 XCUITest（另 2 个真实 Contacts gate）
├── tools/
│   └── assemble_real_vision34.py # 真实评估主机侧报告生成器（确定性、无副作用）
├── spec/                         # SDD 7 篇规格（页面/状态/参考测试/观察索引/环境/数据模型）
├── dataset/
│   ├── cards/                    # 34 张冻结 PNG（card-001..034，不可变）
│   ├── ground-truth/             # 34 个 GT JSON
│   ├── ground-truth-005-034.jsonl
│   ├── card-index-005-034.csv
│   └── exception-samples/        # t20-negative-001 非名片样本（单独计数）
├── evidence/
│   ├── screenshots/              # 40 张 REF-*.png CamCard 黑盒观察证据
│   └── image-manifest.md         # 清单（打包前修订 Week 1 抬头，G-13）
├── assignment/                   # 课程作业 v2 中英文原文（老师下发件，便于对照）
└── ai/
    ├── README.md                 # AI 协作流程规约
    ├── changes.md                # 全量 increment 日志 + 人类 Accepted 记录
    ├── dataset-integrity-audit.md
    ├── final-acceptance.md       # T01–T20 20/20 + 431/431 + 55/55 验收
    ├── final-reference-audit.md  # P01–P11 fidelity 审计
    ├── validation/               # 每周人工验证截图
    ├── evaluation/real-vision-34/
    │   ├── summary.md            # 真实 Vision 34 卡评估（字段准确率 + 根因分离）
    │   ├── environment.md        # 引擎/归一化/分母/可重复性
    │   ├── raw-ocr.jsonl
    │   ├── structured-results.jsonl
    │   ├── comparison.csv        # 306 行
    │   └── _eval-payload.json    # harness 原始载荷（provenance）
    └── delivery/
        ├── course-compliance-matrix.md   # 本轮：作业要求覆盖矩阵
        ├── final-gap-list.md             # 本轮：差异清单（含 B-01/B-02 STOP）
        └── delivery-package-plan.md      # 本文件
```

对照任务书 §7 候选内容：Xcode 工程与源码 ✓、README/构建说明 ✓（刷新后）、SDD 规格 ✓、
Reference evidence ✓、测试数据与 GT ✓、Reference Test/自动化测试 ✓、UI 对照与差异分析 ✓、
OCR 字段准确率报告 ✓、AI 协作与人工审核记录 ✓、最终验收报告 ✓。

## 2. 明确排除（不进包）

| 排除项 | 原因 |
|---|---|
| `.git/`（54 MB） | 任务书要求排除；本地 VCS 历史不随 Canvas 包提交 |
| `.trae/` | 本机工具目录 |
| `SimCamCard.xcodeproj/xcuserdata/`、`project.xcworkspace/xcuserdata/` | 本机用户态 Xcode 数据 |
| `~/Library/Developer/Xcode/DerivedData/`、工程外任何 DerivedData（本轮用 `/tmp/w4-delivery-derived`） | 构建缓存 |
| `/tmp/w4-*.xcresult` 及一切 xcresult | 大型临时测试产物；结论已固化进 `ai/final-acceptance.md` 与 `ai/evaluation/real-vision-34/` |
| 模拟器缓存 / CoreSimulator 数据 | 本机临时态 |
| 签名凭据、`.mobileprovision`、开发者证书、含 team 的 xcconfig | 工程当前 `CODE_SIGN_STYLE = Automatic` 且**无 DEVELOPMENT_TEAM 写入**，无凭据可泄 |
| `.DS_Store` | macOS 杂项 |
| `ai/prompts/_local/`（空目录） | 空目录无内容；如需保留可放 `.gitkeep`（可选） |

## 3. 干净环境构建与测试说明（写入刷新后的 README，供老师照做）

环境：Xcode 27.0 / Swift 6 / iOS 27 Simulator（验证机型 iPhone 18 Pro）；macOS（Apple Silicon 实测）。

```sh
# 1. 解压后打开
open SimCamCard.xcodeproj

# 2. 选模拟器构建（无需签名团队；如需真机可在 Signing & Capabilities 选自己的 Team）
xcodebuild -project SimCamCard.xcodeproj -scheme SimCamCard \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build

# 3. 确定性全量回归（串行；Unit 431 + UI 55 的口径见 final-acceptance.md）
xcodebuild test -project SimCamCard.xcodeproj -scheme SimCamCard \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -parallel-testing-enabled NO

# 4.（可选，概率性）34 张真实 Vision 评估：env-gated，默认 skip，不影响确定性基线
TEST_RUNNER_REAL_VISION_EVAL=1 xcodebuild test -project SimCamCard.xcodeproj -scheme SimCamCard \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -only-testing:SimCamCardTests/RealVision34EvaluationTests \
  -parallel-testing-enabled NO
python3 tools/assemble_real_vision34.py
# 产物：ai/evaluation/real-vision-34/{raw-ocr.jsonl,structured-results.jsonl,comparison.csv,summary.md}
```

注意事项（README 中写明）：
- Vision OCR 为概率性结果，逐卡数字跨机器/OS 可能小幅波动；raw text 全保留可追溯，GT/数据集从不为提分修改。
- 真实 Contacts 导出测试（System01/System02）会改动模拟器通讯录，需单独 `-only-testing:` 运行。
- 已知物理设备未验证（无 iPhone 环境）；相册 denied 场景的平台说明；B-01/B-02 状态以 `ai/delivery/` 为准。

## 4. 若超过 Canvas 大小上限的分级预案（按顺序）

1. 移除 `_eval-payload.json`（172 KB，可由 harness 重跑生成；保留其余 5 个产物）。
2. `ai/validation/`（13 MB）改为清单 + 仅保留每个 T 编号代表截图（其余仍在 git 历史可查——但提交包无 .git，故此步需先与人类确认）。
3. `evidence/screenshots/` 不建议删（这是唯一 Reference 黑盒证据）；如必须，优先保留
   recognition 6 张 + detail 4 张 + permission/export/exception 各关键张，其余在 image-manifest 中注明。
4. 数据集不可删（作业核心证据，30–50 张要求 + GT）。

## 5. 打包前 preflight 清单（人类放行后执行）

- [ ] B-01/B-02/G-01 有 Human Decision（修复则重新走 431+55 回归并重跑 34 卡评估）
- [ ] README.md 刷新（G-09）；image-manifest 抬头（G-13）；changes.md 历史语境注记（G-14）
- [ ] 确认 `git status`：评审新增文件是否先 commit（本 Phase 禁止提交，打包前由人类决定提交策略）
- [ ] Canvas 文件类型/大小已核实
- [ ] 用 `zip -r -X` 显式排除 §2 各项，解压到临时干净目录实测 §3 第 2、3 步
- [ ] 校验包内无 `.git`、xcuserdata、DerivedData、xcresult、`.DS_Store`、任何凭据
