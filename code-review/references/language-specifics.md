# Language-Specific Code Smells

## PHP

**Type juggling:**
```php
// 🔴 Nguy hiểm — "0" == false == null == [] trong PHP
if ($result == false) { ... }
// ✅ Dùng strict comparison
if ($result === false) { ... }
```

**Error handling:**
```php
// 🟠 json_decode trả về null khi fail, không throw exception
$data = json_decode($body, true);
// Phải check:
if ($data === null && json_last_error() !== JSON_ERROR_NONE) { ... }
```

**Database:**
```php
// 🔴 SQL injection
$stmt = $db->query("SELECT * FROM users WHERE id = $id");
// ✅ Prepared statement
$stmt = $db->prepare("SELECT * FROM users WHERE id = ?");
$stmt->execute([$id]);
```

**exit/die trong business logic:**
```php
// 🟠 exit() trong function giữa business logic khiến khó test và trace
function authGoogleCallback(): never {
    // ...
    header("Location: ...");
    exit; // ← không thể mock, không thể test
}
// Cân nhắc: return response object, throw exception, hoặc ít nhất là tách redirect ra khỏi logic
```

**declare(strict_types=1):**
- Nếu file có `declare(strict_types=1)` → type errors sẽ throw exception thay vì coerce
- Nếu không có → PHP sẽ silently coerce `"123abc"` thành `123`

---

## JavaScript / Vue 3

**Async/await error handling:**
```javascript
// 🟠 Unhandled promise rejection
async function loadData() {
    const data = await fetchData(); // nếu fail → uncaught
}
// ✅
async function loadData() {
    try {
        const data = await fetchData();
    } catch (err) {
        // handle
    }
}
```

**Reactive state mutation:**
```javascript
// 🟠 Mutate array/object trực tiếp có thể không trigger reactivity
state.items[0] = newItem; // có thể không reactive
// ✅
state.items = [...state.items.slice(0, 0), newItem, ...state.items.slice(1)];
// hoặc dùng reactive methods: push, splice, etc.
```

**localStorage parsing:**
```javascript
// 🟠 Không validate schema sau khi parse
const data = JSON.parse(localStorage.getItem('auth'));
data.jwt // có thể undefined nếu format thay đổi
// ✅ Validate hoặc dùng optional chaining + default
const jwt = JSON.parse(localStorage.getItem('auth') ?? '{}')?.jwt ?? null;
```

**Vue: Watch vs Computed:**
- Dùng `computed` khi derive value từ state — không dùng `watch` để sync state
- `watch` với immediate + deep trên object lớn → performance issue

**Pinia persist timing:**
- `pinia-plugin-persistedstate` write to localStorage là **synchronous** trong setup, nhưng timing có thể unexpected khi set state rồi read ngay
- Nếu cần read lại ngay → đọc thẳng từ localStorage thay vì đợi store

---

## Python

**Mutable default arguments:**
```python
# 🔴 Classic Python trap
def append_to(element, to=[]):  # [] được tạo một lần duy nhất
    to.append(element)
    return to
# ✅
def append_to(element, to=None):
    if to is None:
        to = []
    to.append(element)
    return to
```

**Exception handling quá rộng:**
```python
# 🟠 Catch tất cả exceptions → ẩn bug
try:
    process()
except Exception:
    pass
# ✅ Catch specific exception
try:
    process()
except ValueError as e:
    logger.error(f"Invalid value: {e}")
```

**String formatting:**
```python
# 🟡 Concatenation với user input → potential injection
query = "SELECT * FROM users WHERE name = '" + name + "'"
# ✅ Parameterized
cursor.execute("SELECT * FROM users WHERE name = %s", (name,))
```

---

## General Patterns (mọi ngôn ngữ)

**Configuration trong code:**
```
# 🟠 Bất kỳ ngôn ngữ nào
BASE_URL = "http://localhost:8080"  # hardcode
API_KEY = "sk-abc123"              # secret trong code

# ✅
BASE_URL = os.getenv("API_BASE_URL")
API_KEY = os.getenv("API_KEY")
```

**Long parameter list (>4 params):**
- Dấu hiệu function đang làm quá nhiều việc, hoặc cần object/struct

**Boolean parameter:**
```php
processUser($user, true); // true nghĩa là gì???
// ✅ Dùng named constant hoặc tách function
processUser($user, sendEmail: true);
```

**Nested callbacks / callback hell:**
- Dùng async/await, Promise chain, hoặc coroutine tùy ngôn ngữ

**God object / God function:**
- Class/function biết và làm quá nhiều → SRP violation
