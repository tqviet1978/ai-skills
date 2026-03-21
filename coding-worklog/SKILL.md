---
name: coding-worklog
description: >
  Tạo và cập nhật worklog khi coding — ghi lại toàn bộ quá trình phát triển phần mềm dưới dạng file Markdown có cấu trúc. Kích hoạt bất cứ khi nào user đề cập đến: "tạo worklog", "ghi lại tiến độ", "log công việc", "viết worklog", "update worklog", hoặc bất kỳ lúc nào kết thúc một phiên coding và cần ghi lại những gì đã làm. Cũng kích hoạt khi user bắt đầu một task kỹ thuật mới và cần lên kế hoạch rõ ràng trước khi code. Luôn dùng skill này khi cần tạo tài liệu kỹ thuật liên quan đến quá trình phát triển, debug, refactor, hoặc thiết kế hệ thống — kể cả khi user không nói rõ "worklog".
---

# Coding Worklog Skill

Skill này hướng dẫn agent tạo file worklog Markdown chuẩn, rõ ràng, có giá trị tham chiếu lâu dài khi phát triển phần mềm.

---

## Quy tắc đặt tên file

**Pattern:** `WORKLOG_V{semver}.md`

**Ví dụ:**
- `WORKLOG_V1.0.0.md` — khởi tạo tính năng / milestone đầu tiên
- `WORKLOG_V1.1.0.md` — thêm feature mới
- `WORKLOG_V1.0.1.md` — bugfix / patch nhỏ
- `WORKLOG_V2.0.0.md` — breaking change / refactor lớn

**Nguyên tắc chọn version:**
- Hỏi user version hiện tại nếu chưa rõ
- Nếu là worklog đầu tiên của project → dùng `V1.0.0`
- Nếu là bugfix/patch → tăng patch (z trong x.y.z)
- Nếu thêm feature → tăng minor (y trong x.y.z)
- Nếu breaking change → tăng major (x trong x.y.z)

---

## Cấu trúc file WORKLOG

Dưới đây là template đầy đủ. Dùng tất cả các section, không bỏ bớt. Nếu một section chưa có nội dung, ghi `_N/A_ hoặc _To be determined_` thay vì xóa section đó.

```markdown
# WORKLOG — v{VERSION}

> **Project:** {tên project}
> **Date:** {ngày tháng năm}
> **Author:** {tên / handle}
> **Status:** 🟡 In Progress | ✅ Done | 🔴 Blocked

---

## 1. Problem Statement

### Vấn đề hiện tại
{Mô tả rõ ràng vấn đề đang gặp phải. Trả lời: Cái gì đang bị sai? Ai bị ảnh hưởng? Ảnh hưởng như thế nào?}

### Context & Background
{Bối cảnh kỹ thuật liên quan. Ví dụ: đây là module nào, phụ thuộc vào gì, đã tồn tại bao lâu.}

### Mục tiêu cần đạt
- [ ] {Mục tiêu 1 — đo lường được}
- [ ] {Mục tiêu 2}
- [ ] {Mục tiêu 3}

---

## 2. Phân tích Giải pháp

### Giải pháp đã cân nhắc

#### Phương án A: {Tên phương án}
- **Mô tả:** {Giải thích ngắn gọn}
- **Ưu điểm:** {Liệt kê}
- **Nhược điểm / Rủi ro:** {Liệt kê}
- **Độ phức tạp:** Thấp / Trung bình / Cao
- **Effort ước tính:** {X giờ / ngày}

#### Phương án B: {Tên phương án}
- **Mô tả:** {Giải thích ngắn gọn}
- **Ưu điểm:** {Liệt kê}
- **Nhược điểm / Rủi ro:** {Liệt kê}
- **Độ phức tạp:** Thấp / Trung bình / Cao
- **Effort ước tính:** {X giờ / ngày}

#### Phương án C: {Tên phương án} _(nếu có)_
...

### ✅ Giải pháp được chọn: Phương án {X}

**Lý do chọn:**
{Giải thích tại sao phương án này được ưu tiên so với các phương án còn lại. Cân nhắc: trade-offs, context hiện tại, khả năng mở rộng, thời gian.}

**Các giả định / điều kiện tiên quyết:**
- {Điều kiện 1}
- {Điều kiện 2}

---

## 3. Việc Đã Làm (Done)

> Ghi theo thứ tự thời gian. Mỗi mục nên đủ cụ thể để người khác (hoặc bản thân sau này) hiểu được.

- [x] {Việc 1 — mô tả rõ, có thể kèm file/module liên quan}
- [x] {Việc 2}
- [x] {Việc 3}

### Các thay đổi đáng chú ý
| File / Module | Thay đổi | Ghi chú |
|---|---|---|
| `path/to/file.ts` | {Mô tả thay đổi} | {Ghi chú nếu cần} |

---

## 4. Việc Còn Lại & Future Work

### 🔧 Việc cần làm tiếp (Next session)
- [ ] {Task 1 — ưu tiên cao}
- [ ] {Task 2}

### 💡 Future Work (Không urgent, nhưng nên làm)
- [ ] {Cải tiến 1}
- [ ] {Refactor / tech debt}
- [ ] {Tính năng mở rộng}

### ⚠️ Known Issues / Risks
- {Vấn đề đã biết nhưng chưa xử lý — ghi rõ mức độ ảnh hưởng}

---

## 5. Roadmap & Next Steps

```
Phase 1 (hiện tại): {Tên phase} — {Mục tiêu}
  └─ ✅ {Milestone đã done}
  └─ 🟡 {Milestone đang làm}
  └─ ⬜ {Milestone chưa bắt đầu}

Phase 2: {Tên phase} — {Mục tiêu}
  └─ ⬜ {Feature / goal}
  └─ ⬜ {Feature / goal}

Phase 3 (Long-term): {Tên phase}
  └─ ⬜ {Vision / aspirational goal}
```

---

## 6. Ghi Chú Kỹ Thuật _(tuỳ chọn)_

> Dùng section này để ghi lại: lệnh đặc biệt, config quan trọng, snippet hữu ích, hoặc bất cứ thứ gì cần nhớ khi quay lại làm tiếp.

```bash
# Ví dụ: command để chạy test
npm run test:watch -- --testPathPattern=module-name
```

---

## 7. References _(tuỳ chọn)_

- [{Tên tài liệu}]({URL})
- {PR / Issue liên quan: #123}
- {Ticket: PROJ-456}
```

---

## Hướng dẫn Agent khi tạo Worklog

### Bước 1: Thu thập thông tin

Trước khi viết, hỏi user (hoặc suy luận từ context nếu đã có đủ thông tin):

1. **Version** — phiên bản hiện tại / version sẽ release?
2. **Project name** — tên project / repo?
3. **Problem** — đang giải quyết vấn đề gì?
4. **Done** — đã làm được gì trong phiên này?
5. **Remaining** — còn gì chưa làm?

Nếu user đang chat giữa chừng sau khi đã code, **đọc lại toàn bộ conversation** để tự điền thông tin trước khi hỏi.

### Bước 2: Điền template

- **Đừng bỏ section nào** — nếu chưa có nội dung, ghi `_N/A_` hoặc placeholder rõ ràng
- **Phần "Phân tích Giải pháp"** — nếu user chỉ nhắc 1 hướng, agent nên chủ động đề xuất thêm 1-2 phương án thay thế để so sánh, giúp worklog có giá trị hơn
- **Phần "Roadmap"** — dùng ASCII tree như template, không dùng Markdown list thông thường
- **Checklist "Done"** — dùng `- [x]` cho việc đã xong, `- [ ]` cho việc chưa xong
- **Bảng thay đổi file** — liệt kê các file/module quan trọng đã modified

### Bước 3: Lưu file

- Đặt tên đúng pattern: `WORKLOG_V{x.y.z}.md`
- Lưu vào thư mục gốc của project, hoặc `/docs/worklogs/` nếu project có cấu trúc docs riêng
- Nếu dùng `create_file` tool: lưu vào `/mnt/user-data/outputs/WORKLOG_V{x.y.z}.md`

---

## Ví dụ Worklog ngắn (Reference)

Xem file `templates/example_worklog.md` để có ví dụ thực tế đầy đủ.

---

## Lưu ý quan trọng

- **Worklog là tài liệu sống** — nên cập nhật liên tục, không phải chỉ viết một lần
- **Viết cho người khác đọc** — kể cả bản thân sau 3 tháng không nhớ gì
- **Phần "Giải pháp được chọn"** phải có lý do cụ thể, không chỉ "vì đơn giản hơn"
- **Roadmap** nên thực tế — đừng list quá nhiều nếu không có kế hoạch cụ thể
- Dùng **emoji status** nhất quán: ✅ Done, 🟡 In Progress, ⬜ Not Started, 🔴 Blocked
