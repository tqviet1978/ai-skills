# WORKLOG — v1.2.0

> **Project:** auth-service
> **Date:** 2025-03-15
> **Author:** @trung.dev
> **Status:** ✅ Done

---

## 1. Problem Statement

### Vấn đề hiện tại
JWT token hiện tại không có cơ chế refresh — khi token hết hạn (sau 1 giờ), user bị đăng xuất đột ngột và phải login lại từ đầu. Điều này gây trải nghiệm kém, đặc biệt với user đang thao tác dở form dài.

### Context & Background
`auth-service` là microservice xử lý xác thực cho toàn bộ hệ thống. Hiện dùng `jsonwebtoken` v9, access token TTL = 1h. Chưa có refresh token logic. User base: ~15,000 DAU.

### Mục tiêu cần đạt
- [x] Thêm refresh token endpoint `POST /auth/refresh`
- [x] Access token TTL giữ nguyên 1h, refresh token TTL = 7 ngày
- [x] Refresh token được lưu vào Redis (blacklist khi logout)
- [ ] Viết unit test coverage ≥ 80% cho auth module

---

## 2. Phân tích Giải pháp

### Giải pháp đã cân nhắc

#### Phương án A: Sliding session (server-side)
- **Mô tả:** Lưu toàn bộ session trên server, gia hạn mỗi lần có request
- **Ưu điểm:** Đơn giản, dễ revoke
- **Nhược điểm / Rủi ro:** Không stateless, khó scale ngang, thêm DB query mỗi request
- **Độ phức tạp:** Trung bình
- **Effort ước tính:** 2 ngày

#### Phương án B: Refresh Token + Redis Blacklist
- **Mô tả:** Access token ngắn hạn, refresh token dài hạn lưu Redis. Logout thì blacklist refresh token.
- **Ưu điểm:** Stateless với access token, revocable, chuẩn OAuth2
- **Nhược điểm / Rủi ro:** Cần Redis, phức tạp hơn phương án A một chút
- **Độ phức tạp:** Trung bình
- **Effort ước tính:** 1.5 ngày

#### Phương án C: Long-lived JWT (tăng TTL)
- **Mô tả:** Tăng TTL access token lên 7 ngày
- **Ưu điểm:** Nhanh, không cần thay đổi nhiều
- **Nhược điểm / Rủi ro:** Không thể revoke nếu token bị lộ, security risk cao
- **Độ phức tạp:** Thấp
- **Effort ước tính:** 30 phút

### ✅ Giải pháp được chọn: Phương án B

**Lý do chọn:**
Phương án B cân bằng tốt giữa security và UX. Redis đã có sẵn trong infra (dùng cho cache). Phương án C bị loại ngay vì rủi ro bảo mật. Phương án A không phù hợp với kiến trúc stateless hiện tại.

**Các giả định / điều kiện tiên quyết:**
- Redis instance đã chạy và accessible từ auth-service
- Client (web/mobile) phải xử lý logic tự động gọi `/auth/refresh` khi nhận 401

---

## 3. Việc Đã Làm (Done)

- [x] Thiết kế schema refresh token: `{ userId, tokenHash, expiresAt, deviceId }`
- [x] Implement `POST /auth/refresh` endpoint với validation đầy đủ
- [x] Lưu refresh token vào Redis với TTL 7 ngày
- [x] Implement logout: xóa refresh token khỏi Redis
- [x] Cập nhật middleware để handle 401 → trigger refresh flow
- [x] Update Swagger docs cho 2 endpoint mới

### Các thay đổi đáng chú ý
| File / Module | Thay đổi | Ghi chú |
|---|---|---|
| `src/auth/auth.service.ts` | Thêm `generateRefreshToken()`, `validateRefreshToken()` | Hash token trước khi lưu Redis |
| `src/auth/auth.controller.ts` | Thêm `POST /refresh`, update `POST /logout` | |
| `src/common/redis.service.ts` | Thêm `setWithTTL()`, `deleteKey()` | Wrapper nhỏ cho ioredis |
| `src/auth/dto/refresh-token.dto.ts` | File mới | DTO validate request body |

---

## 4. Việc Còn Lại & Future Work

### 🔧 Việc cần làm tiếp (Next session)
- [ ] Viết unit tests — hiện coverage mới đạt ~45%, cần lên 80%
- [ ] Test E2E flow: login → dùng access token → refresh → dùng token mới

### 💡 Future Work (Không urgent, nhưng nên làm)
- [ ] Device management: cho user xem và revoke các thiết bị đang đăng nhập
- [ ] Rotate refresh token mỗi lần dùng (one-time use) để tăng security
- [ ] Thêm rate limiting cho `/auth/refresh` tránh abuse

### ⚠️ Known Issues / Risks
- Nếu Redis down, toàn bộ refresh flow sẽ fail → cần fallback strategy (hiện chưa có)

---

## 5. Roadmap & Next Steps

```
Phase 1 (hiện tại): Core Auth — Xác thực cơ bản an toàn
  └─ ✅ JWT access token
  └─ ✅ Refresh token + Redis blacklist
  └─ 🟡 Unit test coverage ≥ 80%

Phase 2: Enhanced Security — Tăng cường bảo mật
  └─ ⬜ One-time refresh token rotation
  └─ ⬜ Device management UI
  └─ ⬜ Anomaly detection (đăng nhập từ IP lạ)

Phase 3 (Long-term): OAuth2 & SSO
  └─ ⬜ Google / GitHub OAuth2 login
  └─ ⬜ SAML SSO cho enterprise clients
```

---

## 6. Ghi Chú Kỹ Thuật

```bash
# Chạy auth service local với Redis
docker compose up redis -d
npm run start:dev -- auth-service

# Test refresh endpoint
curl -X POST http://localhost:3000/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken": "your-refresh-token-here"}'

# Xem Redis keys
redis-cli KEYS "refresh:*"
```

---

## 7. References

- [RFC 6749 — OAuth 2.0 Refresh Token](https://datatracker.ietf.org/doc/html/rfc6749#section-6)
- [PR #247 — feat: refresh token implementation](https://github.com/company/auth-service/pull/247)
- [JIRA: AUTH-89 — Implement refresh token flow](https://jira.company.com/AUTH-89)
