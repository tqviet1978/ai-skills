---
name: code-review
description: >
  Thực hiện code review chuyên sâu trên bất kỳ code/codebase nào được cung cấp — qua file upload, paste trực tiếp, hay local agent API. Skill này KHÔNG chỉ kiểm tra syntax hay style: nó đặt câu hỏi về naming, design decisions, problem-solution fit, và phát hiện các code smells tiềm ẩn. Kích hoạt khi user yêu cầu "review code", "xem code này có ổn không", "check code", "refactor suggestions", "có technical debt gì không", "tại sao code này lại làm vậy", hay bất cứ lúc nào có code cần được đánh giá chất lượng — kể cả khi user chỉ paste một function ngắn hay đặt câu hỏi "cái này có sao không?".
---

# Code Review Skill

Skill này thực hiện code review theo tư duy của một senior engineer có kinh nghiệm: không chỉ đọc code mà còn **đặt câu hỏi về mọi quyết định thiết kế**, đặc biệt là những thứ "có vẻ ổn" nhưng thực ra đang che giấu vấn đề.

---

## Triết lý review

> **"Code tốt không chỉ chạy đúng — nó phải nói lên đúng intent, đứng vững trước thay đổi, và không để lại bẫy cho người đến sau."**

Nguyên tắc cốt lõi:
- **Đặt câu hỏi trước khi đánh giá.** Tên hàm lạ → hỏi tại sao, không chỉ flag "đặt tên xấu"
- **Trace ngược về problem statement.** Code có giải đúng problem không, hay chỉ giải đúng symptom?
- **Luôn xét alternatives.** Có cách nào đơn giản hơn, robust hơn, hoặc idiomatic hơn không?
- **Nghĩ đến tương lai.** Code này sẽ gãy ở đâu khi requirements thay đổi?

---

## Quy trình review

### Bước 1 — Tiếp nhận & Scope

Xác định rõ input trước khi bắt đầu:
- Code được cung cấp qua đâu? (paste, file upload, local agent API)
- Scope review: một function, một file, một module, hay toàn bộ flow?
- Ngôn ngữ / framework / context (nếu chưa rõ, detect từ code)
- User muốn focus vào dimension nào? (nếu không nêu → review toàn diện)

Nếu code được cung cấp qua **local agent API**, dùng lệnh `cat` hoặc `find` để đọc các file liên quan trước khi review. Nếu review một function, hãy đọc thêm các file nó gọi đến để có đủ context.

### Bước 2 — First Pass: Code Smell Detection

Đây là bước quan trọng nhất. Đọc code với con mắt **hoài nghi**. Với mỗi đoạn code, tự hỏi:

**Về naming:**
- Tên này có thực sự mô tả đúng việc nó làm không?
- Tên có chứa thông tin implementation thay vì intent? (`localPost`, `tmpData`, `doStuff`)
- Tên có gợi lên câu hỏi "tại sao lại thế này"? → đó là code smell

**Về structure:**
- Function này đang làm bao nhiêu việc?
- Có magic number, hardcoded value, hay hardcoded URL không?
- Có assumption nào về environment được bake cứng vào code không?

**Về coupling:**
- Code này có biết quá nhiều về internal của module khác không?
- Có direct dependency vào infrastructure cụ thể (localhost, port cứng, file path tuyệt đối)?
- Thay đổi một thứ sẽ gây ripple effect đến bao nhiêu chỗ?

**Về flow:**
- Error path có được xử lý đầy đủ không, hay chỉ happy path?
- Có silent failure nào không? (catch rồi bỏ qua)
- Timeout, retry, fallback có được nghĩ đến chưa?

### Bước 3 — Deep Analysis theo Dimension

Sau first pass, đi sâu vào từng dimension. Xem `references/dimensions.md` để biết checklist chi tiết cho từng loại.

**5 Dimensions:**
1. **Correctness** — Logic có đúng không? Edge cases?
2. **Design** — Architecture có clean không? Coupling? Abstraction đúng level?
3. **Resilience** — Code có chịu được failure, change, và scale không?
4. **Security** — Có vulnerability tiềm ẩn không?
5. **Maintainability** — 6 tháng sau đọc lại có hiểu không?

### Bước 4 — Tổng hợp & Output

Xem `references/output-format.md` để biết cách trình bày kết quả.

---

## Code Smell Catalog

Dưới đây là các patterns phổ biến cần phát hiện ngay khi đọc code. Mỗi smell đều đi kèm **câu hỏi cần đặt ra** và **hướng investigate**.

### 🔴 Smell: Naming tiết lộ implementation

**Dấu hiệu:** Tên chứa từ như `local`, `tmp`, `internal`, `helper`, tên kỹ thuật thay vì tên domain.

**Ví dụ điển hình:**
```php
function localPost(string $path, array $payload): array
```

**Câu hỏi cần đặt ra:**
- Tại sao lại là `local`? Nó có thể không-local không?
- `Post` là HTTP POST hay một khái niệm domain?
- Problem statement ban đầu là gì — tại sao function này tồn tại?

**Vấn đề tiềm ẩn:**
- Tên `local` bake cứng assumption về deployment topology
- Nếu service bị move ra external server → tên sai, và quan trọng hơn, URL hardcode bên trong cũng sẽ sai
- Technical debt: mọi caller đều bị bind vào assumption "service phải chạy local"

**Alternative approach:**
```php
// Thay vì localPost → đặt tên theo intent
function callCaptchaSolver(array $payload): array
// Hoặc inject URL thay vì hardcode
function callInternalService(string $endpoint, array $payload): array
```

---

### 🔴 Smell: Hardcoded infrastructure

**Dấu hiệu:** URL, hostname, port, file path tuyệt đối nằm thẳng trong code.

**Ví dụ:**
```php
$ch = curl_init('http://localhost:8080/' . ltrim($path, '/'));
```

**Câu hỏi:**
- Điều gì xảy ra nếu service này chạy trên port khác?
- Điều gì xảy ra nếu service được containerize, scale ra nhiều instance?
- Dev environment và production environment có cùng topology không?

**Technical debt:** Code này không thể được deploy linh hoạt. Config phải nằm ở config layer, không nằm trong business logic.

---

### 🟠 Smell: Primitive Obsession

**Dấu hiệu:** Dùng string/int/array thay vì object/type để đại diện cho domain concepts.

**Ví dụ:**
```php
function tctLogin(string $username, string $password): array
// Trả về array thô thay vì typed object
```

**Câu hỏi:**
- `array` trả về có structure nhất quán không? Ai enforce điều đó?
- Caller phải biết key nào tồn tại trong array — đây là hidden coupling

---

### 🟠 Smell: Silent Failure / Swallowed Error

**Dấu hiệu:** `catch` block trống, trả về default value thay vì propagate error, log rồi tiếp tục như không có gì.

**Ví dụ:**
```javascript
try {
    jwt = JSON.parse(localStorage.getItem('auth') ?? '{}')?.jwt ?? null;
} catch { /**/ }
```

**Câu hỏi:**
- Nếu parse fail, caller có biết không?
- Behavior khi fail có intentional không, hay chỉ là "để đó cho an toàn"?

---

### 🟠 Smell: Implicit Assumption / Magic Condition

**Dấu hiệu:** Condition check không rõ ý nghĩa, số ma thuật, string literal lặp lại nhiều nơi.

**Ví dụ:**
```php
if (strtotime($row['token_at']) > time() - 8 * 3600)
```

**Câu hỏi:**
- `8 * 3600` là gì? Token validity window? Tại sao 8 tiếng?
- Con số này có xuất hiện ở chỗ khác không? Nếu thay đổi phải sửa mấy chỗ?

---

### 🟡 Smell: Function làm quá nhiều việc

**Dấu hiệu:** Function dài hơn ~30 lines, tên dùng "and" (ngầm hay tường minh), nhiều levels of abstraction trong cùng một function.

**Ví dụ:**
```php
function tctLogin(string $username, string $password): array {
    // 1. Fetch captcha từ TCT
    // 2. Solve captcha
    // 3. Authenticate với TCT
    // → 3 việc khác nhau trong 1 function
}
```

**Câu hỏi:**
- Nếu chỉ muốn solve captcha mà không login, có được không?
- Nếu TCT thay đổi captcha mechanism, phải sửa bao nhiêu logic khác?

---

### 🟡 Smell: Abstraction Level mismatch

**Dấu hiệu:** Trong cùng một function, có cả high-level business logic lẫn low-level implementation detail.

**Ví dụ:**
```php
// High level
$user = upsertUser($googleUser);
$jwt = jwtEncode(['user_id' => $user['id']]);
// Rồi đột ngột xuống low level
header("Location: {$frontendUrl}/auth/callback?token=" . urlencode($jwt));
exit;
```

**Câu hỏi:**
- Tại sao redirect logic nằm trong auth business logic?
- Nếu sau này muốn trả JSON thay vì redirect, phải sửa ở đâu?

---

### 💡 Smell: Tight Coupling với External Service

**Dấu hiệu:** Gọi thẳng đến external service URL trong business logic, không có abstraction layer.

**Câu hỏi:**
- Nếu service này đổi domain/protocol, phải sửa bao nhiêu file?
- Code có thể test được không khi không có external service?
- Có retry/timeout/circuit breaker không?

---

## Khi review, luôn hỏi "So What?"

Với mỗi issue phát hiện, phải trả lời được:
1. **Problem statement**: Đây thực sự là vấn đề gì?
2. **Consequence**: Điều gì sẽ xảy ra nếu không fix?
3. **When will it break**: Trigger condition nào sẽ làm nó gãy?
4. **Alternative**: Cách tốt hơn là gì, và tại sao tốt hơn?
5. **Effort vs Risk**: Có đáng fix ngay không, hay có thể defer?

---

## Technical Debt Tagging

Khi phát hiện technical debt, tag theo loại để prioritize:

| Tag | Ý nghĩa |
|-----|---------|
| `[DEBT:FRAGILE]` | Sẽ gãy khi environment/config thay đổi |
| `[DEBT:COUPLING]` | Quá tight-coupled, khó thay thế component |
| `[DEBT:HIDDEN]` | Assumption không được document, dễ bị vi phạm |
| `[DEBT:TESTABILITY]` | Khó/không thể viết test |
| `[DEBT:SCALE]` | Sẽ có vấn đề khi load tăng |
| `[DEBT:SECURITY]` | Potential security concern, cần investigate |

---

## Tham khảo thêm

- `references/dimensions.md` — Checklist chi tiết cho 5 dimensions
- `references/output-format.md` — Cách format kết quả review
- `references/language-specifics.md` — Code smells đặc thù theo ngôn ngữ (PHP, JS/Vue, Python)
