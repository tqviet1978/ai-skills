# Output Format — Cách trình bày kết quả review

## Cấu trúc tổng thể

```
## Code Review: [tên file/module/function]

### TL;DR
[2-3 câu tóm tắt: code đang làm gì, vấn đề chính là gì, mức độ cần attention]

### Findings

[Danh sách findings, nhóm theo severity]

### Summary Table

[Bảng tổng hợp]

### Đề xuất ưu tiên

[Top 3 việc nên làm ngay]
```

---

## Severity Levels

| Level | Icon | Khi nào dùng |
|-------|------|-------------|
| Critical | 🔴 | Bug hiện tại, security hole, data loss risk |
| Major | 🟠 | Design flaw, technical debt cao, sẽ gây vấn đề khi scale/change |
| Minor | 🟡 | Code smell, readability, style inconsistency |
| Suggestion | 💡 | Alternative approach tốt hơn, không bắt buộc |

---

## Format cho mỗi Finding

```markdown
#### [Icon] [Severity]: [Tên vấn đề ngắn gọn]

**File/Location:** `path/to/file.php` → `functionName()` (line X-Y)

**Code hiện tại:**
```lang
// đoạn code có vấn đề
```

**Vấn đề:**
[Giải thích RÕ RÀNG vấn đề là gì. Không chỉ "code xấu" — phải nói được: điều gì sẽ xảy ra, khi nào nó gãy, tại sao đây là vấn đề]

**Câu hỏi cần đặt ra:**
- Tại sao lại là [tên/cách làm hiện tại]?
- Điều gì xảy ra nếu [trigger condition]?

**Consequence nếu không fix:**
[Cụ thể: sẽ gãy khi nào, tốn bao nhiêu effort để fix sau, risk là gì]

**Đề xuất:**
```lang
// code sau khi fix
```

**Tại sao approach này tốt hơn:**
[Giải thích ngắn gọn trade-offs]

**Tag:** `[DEBT:FRAGILE]` ← nếu là technical debt
```

---

## Summary Table

```markdown
| # | Severity | Location | Vấn đề | Tag |
|---|----------|----------|--------|-----|
| 1 | 🔴 Critical | `auth.php:94` | Redirect URL hardcode | `[DEBT:FRAGILE]` |
| 2 | 🟠 Major | `accounts.php:localPost` | Hostname coupling | `[DEBT:COUPLING]` |
| 3 | 🟡 Minor | `accounts.php:tctLogin` | Function làm 3 việc | — |
```

---

## Ví dụ TL;DR tốt

> **Tốt:** "File `accounts.php` implement TCT login flow. Logic chạy đúng với happy path, nhưng có 2 vấn đề cần attention: (1) `localPost` hardcode `localhost:8080` sẽ gãy khi service được move, và (2) hàm `tctLogin` đang làm 3 việc khác nhau khiến khó test và maintain."

> **Không tốt:** "Code có một số vấn đề về naming và architecture cần được xem xét."

---

## Tone và cách đặt câu hỏi

Review phải **constructive**, không phán xét. Thay vì:
- ❌ "Code này sai" → ✅ "Approach này sẽ gây vấn đề khi X, cân nhắc Y vì..."
- ❌ "Naming xấu" → ✅ "Tên `localPost` gợi lên câu hỏi: nếu service này được deploy lên server khác thì sao? Có thể đổi thành `callCaptchaService` để tách khỏi deployment assumption"
- ❌ "Tại sao lại làm vậy?" (rhetorical, tiêu cực) → ✅ "Mình tò mò về quyết định dùng localhost:8080 thay vì domain name — có context gì đặc biệt không? Nếu không, việc inject URL từ config sẽ linh hoạt hơn"

Khi không chắc intent của tác giả → **hỏi trước khi kết luận**:
> "Mình thấy `token_fresh` được tính là `< 8 tiếng` — đây có phải business requirement từ phía TCT không, hay là con số estimate? Nếu là business rule thì nên extract thành constant có tên để dễ tìm sau này."
