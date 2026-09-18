# Prompt: Functional impact of a Business Central upgrade

This file is the **format contract for the functional-consultant report**. It is the
counterpart of `Compare-instruction.md`, which is the contract for the technical report.
A functional consultant owns this file: change the wording, the order, the severity
labels or the output language here, and the workflow follows — no YAML edit needed.

**Output language: Vietnamese.** To switch, change this line and the wording table in
section 4; nothing else depends on it.

---

## 1. Who reads this

A functional consultant preparing an upgrade. They decide:

- which business processes must be re-tested before the upgrade is accepted (UAT scope),
- where numbers or behaviour may change silently,
- what to tell the client and the key users,
- whether a customization can be retired because the standard product now covers it.

They do **not** decide whether the code compiles. That is the technical report's job.

## 2. Input

`business-impact.json`, produced by `.github/scripts/diff_symbols.py rollup`. It is
already filtered and tiered — do not go looking for more findings in the raw symbol
diff, and do not re-derive severity from scratch.

Each finding carries:

| Field | Meaning |
|---|---|
| `severity` | `blocker` / `retest` / `opportunity` |
| `consequenceCode` | what kind of change it is — see the wording table in section 4 |
| `area` | business area, e.g. `Sales`, `Service`, `Finance` |
| `objectLabel` | **the name the user sees on screen** — use this, never `objectName` |
| `objectSurface` | `screen` / `report` / `data` / `choice-list` / `permissions` / `role-centre` |
| `facts` | the concrete before/after, including `memberLabel` for a field |
| `usedByCustomization` | true when our own AL code names it |
| `references` | AL file and line, when it is used by our code |

Also present: `areas` (scope), `customizationFootprint`, `outOfScopeByArea` (counts only),
`suppressedAsTechnical`, `coverageGaps`, `counts`.

The rollup already dropped renames, namespace moves, internal visibility changes and
attribute churn. Do not reintroduce them.

## 3. WRITING RULES

- Write for someone who knows Business Central as a product, not as a codebase.
- Name everything by `objectLabel` and `facts.memberLabel` — what appears on the screen.
- Every row must answer "what changes for the user or for the data", not "what changed
  in the symbols".
- State the business consequence before the cause.
- **Banned vocabulary.** The list below is the single source of truth: the workflow greps
  the finished report for these words and reports a leak as a defect. Edit the list here
  and the check follows. Where a technical fact genuinely matters, name the consequence
  and hand it to the developer — see `integration-point-changed` in the wording table.

<!-- banned-vocabulary: parsed by `diff_symbols.py checkreport`. One term per line. -->
```banned-vocabulary
signature
namespace
ordinal
var parameter
codeunit
object id
IntegrationEvent
EventSubscriber
ObsoleteState
SymbolReference
pure append
breaking change
```

<!-- required-sections: parsed by `diff_symbols.py checkreport`. One heading fragment per line. -->
```required-sections
Kết luận
Phải xử lý trước khi nâng cấp
Cần kiểm thử lại
Phạm vi đã xét
```
- Quantities: always give the count next to a heading, so the reader can judge size
  before reading.
- Never invent a finding. If `business-impact.json` does not contain it, it does not
  go in the report.
- Never present the report as complete coverage when `coverageGaps` is non-empty.

## 4. Wording table — `consequenceCode` to a sentence

Use these as the pattern; adapt the grammar, keep the meaning. `{label}` is
`objectLabel`, `{member}` is `facts.memberLabel`, `{area}` is the business area.

| `consequenceCode` | Câu tiếng Việt |
|---|---|
| `object-removed` | Microsoft đã bỏ {label}. Người dùng sẽ không còn tìm thấy nó ở chỗ cũ. |
| `object-obsoleted` | {label} đã bị Microsoft đánh dấu ngừng sử dụng và sẽ bị bỏ ở bản sau. |
| `field-removed` | Trường "{member}" trên {label} đã bị Microsoft bỏ. Dữ liệu và chức năng dựa vào trường này sẽ ngừng hoạt động. |
| `field-obsoleted` | Trường "{member}" trên {label} sắp bị bỏ. Cần chuyển sang cách làm mới trước khi nó biến mất. |
| `field-type-changed` | Kiểu dữ liệu của "{member}" trên {label} đã thay đổi. Dữ liệu cũ có thể không còn hợp lệ hoặc hiển thị sai. |
| `calcformula-changed` | Cách tính "{member}" trên {label} đã thay đổi. **Số liệu có thể khác trước dù không ai sửa gì.** |
| `tablerelation-changed` | Quan hệ dữ liệu của "{member}" trên {label} đã thay đổi. Danh sách chọn và kiểm tra hợp lệ có thể khác. |
| `permissions-changed` | Quyền truy cập dữ liệu khi dùng {label} đã thay đổi. Một số người dùng có thể mất hoặc được thêm quyền. |
| `dataclassification-changed` | Phân loại dữ liệu của {label} đã thay đổi. Có thể ảnh hưởng báo cáo tuân thủ và xử lý dữ liệu cá nhân. |
| `data-scope-changed` | Phạm vi dữ liệu của {label} đã thay đổi (theo công ty / đồng bộ). Cần kiểm tra lại với môi trường nhiều công ty. |
| `screen-behaviour-changed` | Cách hoạt động của {label} đã thay đổi (quyền sửa, thêm, xoá hoặc nguồn dữ liệu). |
| `caption-changed` | Nhãn trên màn hình đổi từ "{old}" thành "{new}". Cần cập nhật tài liệu và hướng dẫn người dùng. |
| `enum-value-removed` | Giá trị lựa chọn "{member}" của {label} đã bị bỏ. Bản ghi cũ đang dùng giá trị này sẽ không còn hợp lệ. |
| `enum-ordinal-changed` | Giá trị lựa chọn của {label} đã được đánh số lại. Dữ liệu cũ có thể hiển thị sai giá trị. |
| `enum-not-extensible` | {label} không còn cho phép mở rộng. Các giá trị tuỳ chỉnh đã thêm sẽ không còn dùng được. |
| `access-restricted` | {label} đã bị Microsoft giới hạn truy cập. Phần tuỳ chỉnh đang dùng nó cần được viết lại. |
| `integration-point-changed` | Điểm tích hợp mà phần tuỳ chỉnh đang dùng trên {label} đã thay đổi. **Lập trình viên phải sửa trước khi nâng cấp**, nếu không chức năng liên quan sẽ ngừng chạy. |
| `method-removed-used` | Một chức năng nội bộ mà phần tuỳ chỉnh đang gọi trên {label} đã bị bỏ. Lập trình viên phải thay thế trước khi nâng cấp. |
| `object-added` | Tính năng mới: {label}. |
| `enum-value-added` | {label} có thêm lựa chọn mới: "{member}". |

## 5. Output structure

Write exactly these sections, in this order. **Omit a section that has no data** — do
not write "không có gì ở đây".

```
# Đánh giá tác động nghiệp vụ — nâng cấp <environment>
<currentVersion> → <targetVersion> · <ngày> · độ phủ: <n>/<n> gói

## Kết luận
Ba đến năm câu. Bao nhiêu điểm phải xử lý trước, bao nhiêu quy trình cần kiểm thử,
mức rủi ro (THẤP / TRUNG BÌNH / CAO) và vì sao. Không liệt kê chi tiết ở đây.

## 🔴 Phải xử lý trước khi nâng cấp  (n)
| # | Ảnh hưởng nghiệp vụ | Vùng | Ai xử lý |
Một dòng cho mỗi finding severity=blocker. "Ai xử lý" là FC, Lập trình viên, hoặc cả hai —
suy ra từ usedByCustomization: có customization dùng thì cần Lập trình viên.
Sắp xếp: usedByCustomization=true lên trước, rồi theo vùng.

## 🟠 Cần kiểm thử lại — danh sách UAT  (n)
| # | Quy trình cần kiểm thử | Vì sao | Vùng | Ưu tiên |
Đây là bảng FC sẽ copy vào test plan, nên "Quy trình cần kiểm thử" phải là một hành động
nghiệp vụ cụ thể ("Tạo và post Sales Order", "In Posted Sales Invoice"), không phải tên
đối tượng. Gộp các finding cùng quy trình thành một dòng.
Ưu tiên: Cao nếu có customization dùng hoặc là thay đổi cách tính số liệu, còn lại Trung bình.

## 🟢 Cơ hội bỏ bớt tuỳ chỉnh  (n)
| Tính năng mới của Microsoft | Có thể thay thế | Ghi chú |
Chỉ đưa vào khi thực sự nhìn thấy phần tuỳ chỉnh tương ứng trong ALGo-App/. Nếu chỉ là
tính năng mới mà không rõ thay thế được gì, để ở "Đáng chú ý" bên dưới thay vì đoán.

## 🔍 Vùng KHÔNG kiểm tra được  (n)
| Gói | Vì sao | Rủi ro còn lại |
Lấy từ coverageGaps. Bắt buộc có nếu coverageGaps không rỗng.

## Phạm vi đã xét
Một đoạn ngắn: những vùng nghiệp vụ nào được xét (areas.effective), vùng nào suy ra từ
phần tuỳ chỉnh và vùng nào do team khai báo. Nêu rõ số thay đổi ở các vùng ngoài phạm vi
(outOfScopeByArea) như một con số tổng, và nói thẳng rằng chúng không được đánh giá.
```

## 6. SELF-CHECK before answering

1. Không có từ nào trong danh sách cấm ở section 3.
2. Mọi đối tượng được gọi bằng `objectLabel`, không phải `objectName`.
3. Số trong tiêu đề mỗi section khớp số dòng trong bảng của nó.
4. Mỗi dòng trong bảng UAT là một hành động nghiệp vụ, không phải tên đối tượng.
5. `coverageGaps` không rỗng thì section 🔍 phải có mặt.
6. Không có finding nào không tồn tại trong `business-impact.json`.
7. Kết luận nêu được mức rủi ro và lý do, không chỉ nhắc lại các con số.
