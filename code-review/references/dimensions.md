# Dimensions — Checklist chi tiết

## Dimension 1: Correctness

**Logic:**
- [ ] Happy path có đúng không?
- [ ] Các edge cases: null, empty, zero, negative, overflow
- [ ] Off-by-one errors trong vòng lặp, index, pagination
- [ ] Floating point comparison (dùng epsilon hay exact equal?)
- [ ] Concurrent access — race condition nếu nhiều request cùng lúc?

**Data integrity:**
- [ ] Input validation có đủ chặt không?
- [ ] Type coercion có gây unexpected behavior không? (PHP `==` vs `===`, JS `==`)
- [ ] Có assume input đã được sanitize ở layer trước không?

**State management:**
- [ ] State mutation có predictable không?
- [ ] Có side effect ẩn nào không?
- [ ] Rollback khi fail partial operation (đặc biệt với DB writes)?

---

## Dimension 2: Design

**Single Responsibility:**
- [ ] Mỗi function/class có đúng một lý do để thay đổi không?
- [ ] Function có làm nhiều hơn tên của nó gợi ý không?
- [ ] Có thể đặt tên function bằng một động từ đơn không?

**Abstraction:**
- [ ] Abstraction level có nhất quán trong function/class không?
- [ ] Interface có stable hay sẽ thay đổi theo implementation?
- [ ] Có leak implementation detail ra ngoài abstraction boundary không?

**Coupling & Cohesion:**
- [ ] Module này biết bao nhiêu về module khác?
- [ ] Thay đổi module A có bắt buộc thay đổi module B không?
- [ ] Các thứ liên quan có nằm gần nhau không?

**Naming:**
- [ ] Tên có mô tả đúng intent (không phải implementation)?
- [ ] Có từ nào gợi lên câu hỏi "tại sao" mà code không trả lời không?
- [ ] Abbreviation có phổ biến trong domain không, hay chỉ tác giả mới hiểu?

---

## Dimension 3: Resilience

**Failure handling:**
- [ ] Mọi external call có timeout không?
- [ ] Có retry logic cho transient failures không?
- [ ] Partial failure có được xử lý không?
- [ ] Error message có đủ context để debug không?
- [ ] Có distinguish được recoverable vs non-recoverable error không?

**Environment independence:**
- [ ] Code có chạy được trên dev/staging/prod không thay đổi không?
- [ ] Config (URL, credential, port) có tách khỏi logic không?
- [ ] Có hardcoded path, hostname, magic number nào không?

**Changeability:**
- [ ] Thêm một loại mới có cần sửa nhiều chỗ không?
- [ ] Có OCP violation không? (phải mở file cũ để extend behavior)
- [ ] External dependencies có dễ swap không?

**Observability:**
- [ ] Có đủ logging để trace request khi có incident không?
- [ ] Log có structured không, hay chỉ là free-form text?
- [ ] Có log sensitive data không?

---

## Dimension 4: Security

**Input handling:**
- [ ] User input có được validate/sanitize trước khi dùng không?
- [ ] SQL injection? (dùng prepared statement chưa?)
- [ ] XSS? (escape output chưa?)
- [ ] Path traversal? (validate file path chưa?)
- [ ] Mass assignment? (whitelist fields hay dùng thẳng request data?)

**Authentication & Authorization:**
- [ ] Auth check có bị bypass không?
- [ ] Token/secret có expire không?
- [ ] Có check ownership không? (user A có thể xem data của user B không?)

**Data exposure:**
- [ ] Response có trả về field không cần thiết không?
- [ ] Error message có leak internal detail không?
- [ ] Có log password/token/secret không?

**Crypto & Secret:**
- [ ] Secret có hardcode trong code không?
- [ ] Encryption algorithm có up-to-date không?
- [ ] IV/Salt có random hay reuse không?

---

## Dimension 5: Maintainability

**Readability:**
- [ ] Đọc code có hiểu ngay intent không?
- [ ] Comment có giải thích WHY không (không chỉ WHAT)?
- [ ] Nested condition có quá sâu không? (>3 levels → consider extract)

**Testability:**
- [ ] Function có thể test isolated không?
- [ ] Dependencies có injectable không, hay hardcode?
- [ ] Pure function hay có side effects?
- [ ] Có thể mock external calls không?

**Dead code & Complexity:**
- [ ] Có code unreachable không?
- [ ] Có feature flag/experiment code cũ chưa cleanup không?
- [ ] Cyclomatic complexity có cao không?
- [ ] Có duplicated logic ở nhiều chỗ không?
