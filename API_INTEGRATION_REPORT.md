# API Integration Report — Majid Flutter App

**তারিখ:** 25 June 2026

## সারসংক্ষেপ

| | সংখ্যা |
|---|---|
| মোট Endpoint সংজ্ঞায়িত | 89 |
| API কল করা হয়েছে (আগে থেকে + এখন ফিক্স করা) | 38 |
| API কল বাকি আছে | 51 |
| সম্পন্ন | ~43% |

---

## এই সেশনে যা ফিক্স করা হয়েছে

| # | Screen | কী ফিক্স হলো | Endpoint |
|---|---|---|---|
| 1 | repair_request_details_page | Status update button গুলোতে API কল যোগ হয়েছে | `repair-requests/update-status/{id}` |
| 2 | repair_request_details_page | Note যোগ করার ফর্ম ও API কল যোগ হয়েছে | `repair-requests/add-note/{id}` |
| 3 | repair_request_details_page | Timeline এখন real status অনুযায়ী দেখায় | — |
| 4 | repair_page | "Create Repair Request" বাটনে ফর্ম ও API কল যোগ হয়েছে | `repair-requests/add` |
| 5 | checkout_page | Hardcoded data সরিয়ে real repair data দেখাচ্ছে | — |
| 6 | checkout_page | "Send Invoice" বাটনে API কল যোগ হয়েছে | `invoices/create` |
| 7 | invoice_page | "Send Invoice" বাটনে API কল যোগ হয়েছে | `invoices/create` |
| 8 | device_report_page | Hardcoded field (iCloud Lock, SIM Lock, MDM, etc.) সব real data দেখাচ্ছে | — |
| 9 | device_report_page | AI Risk Score এখন real data থেকে calculate হচ্ছে | — |

---

## বিস্তারিত Screen-ভিত্তিক রিপোর্ট

### 1. Auth (Login/Signup/Password) — 7/7 COMPLETE

| Endpoint | Screen | Status |
|---|---|---|
| `auth/login` | login_screen_view | ✅ |
| `auth/refresh-token` | api_client (interceptor) | ✅ |
| `auth/forgot-password` | forgot_password_screen_view | ✅ |
| `auth/resend-forgot-otp` | otp_verification_screen_view | ✅ |
| `auth/verify-otp` | otp_verification_screen_view | ✅ |
| `auth/reset-password` | create_new_password_screen_view | ✅ |
| `auth/change-password` | profile_controller | ✅ |

---

### 2. User — 5/7

| Endpoint | Screen | Status | সমস্যা |
|---|---|---|---|
| `user/register` | signup_screen_view | ✅ | — |
| `user/verify-email` | otp_verification_screen_view | ✅ | — |
| `user/resend-otp` | otp_verification_screen_view | ✅ | — |
| `user/my-profile` | home_controller + profile_controller | ✅ | — |
| `user/update-profile` | edit_profile_page | ✅ | — |
| `user/all-users` | — | ❌ বাকি | Admin feature — নতুন screen দরকার |
| `user/balance-history` | — | ❌ বাকি | নতুন screen দরকার |

---

### 3. IMEI/Scan — 3/7

| Endpoint | Screen | Status | সমস্যা |
|---|---|---|---|
| `imei/services` | scan_device_page | ✅ | — |
| `imei/check-v2` | scan_device_page | ✅ | — |
| `imei/history` | scan_device_page | ✅ | — |
| `imei/services/sync` | — | ❌ বাকি | Admin/background sync — screen দরকার নাই |
| `imei/risk-analysis` | — | ❌ বাকি | নতুন screen দরকার |
| `imei/device-analysis` | — | ❌ বাকি | নতুন screen দরকার |
| `imei/check-batch` | — | ❌ বাকি | Bulk scan screen দরকার |

---

### 4. Inventory/Stock — 5/11

| Endpoint | Screen | Status | সমস্যা |
|---|---|---|---|
| `inventory/create` | add_new_device_page | ✅ | — |
| `inventory/my-inventory` | inventory_screen, home, invoice, profile | ✅ | — |
| `inventory/sold-items` | home_controller | ✅ | — |
| `inventory/create-from-barcode/bulk` | add_new_device_page | ✅ | — |
| `inventory/import-csv` | add_new_device_page | ✅ | — |
| `inventory` (all) | — | ❌ বাকি | my-inventory দিয়ে কাজ চলতেছে |
| `inventory/grouped` | — | ❌ বাকি | নতুন screen দরকার |
| `inventory/create-from-barcode` (single) | — | ❌ বাকি | bulk আছে, দরকার কম |
| `inventory/import-csv/template` | — | ❌ বাকি | Download button যোগ করতে হবে |
| `inventory/{id}` | — | ❌ বাকি | Detail screen দরকার |
| `inventory/user/{userId}` | — | ❌ বাকি | Admin feature |
| `inventory/status/{status}` | — | ❌ বাকি | Filter feature দরকার |

---

### 5. Category — 3/5

| Endpoint | Screen | Status | সমস্যা |
|---|---|---|---|
| `category` (create) | stock_controller | ✅ | — |
| `category/with-count` | stock_controller + home_controller | ✅ | — |
| `category/{id}` (update/delete) | stock_controller | ✅ | — |
| `category` (all) | — | ❌ বাকি | with-count দিয়ে কাজ হচ্ছে |
| `category/bulk-update-count` | — | ❌ বাকি | দরকার কম |

---

### 6. Repair Requests — 3/9 (আগে 1/9 ছিল — 2টা ফিক্স হয়েছে)

| Endpoint | Screen | Status | সমস্যা |
|---|---|---|---|
| `repair-requests/my-history` | repair_page, home, profile | ✅ | — |
| `repair-requests/add` | repair_page (bottom sheet) | ✅ ফিক্স হয়েছে | — |
| `repair-requests/update-status/{id}` | repair_request_details_page | ✅ ফিক্স হয়েছে | — |
| `repair-requests/add-note/{id}` | repair_request_details_page | ✅ ফিক্স হয়েছে | — |
| `repair-requests/completed` | — | ❌ বাকি | Completed tab/filter দরকার |
| `repair-requests/{id}` | — | ❌ বাকি | Single fetch — list data দিয়ে কাজ চলতেছে |
| `repair-requests/tech-note/{id}` | — | ❌ বাকি | নতুন UI দরকার |
| `repair-requests/technician-feedback/{id}` | — | ❌ বাকি | নতুন UI দরকার |
| `repair-requests/user/{userId}/descriptions` | — | ❌ বাকি | Admin feature |

---

### 7. Invoice — 1/4 (আগে 0/4 ছিল — 1টা ফিক্স হয়েছে)

| Endpoint | Screen | Status | সমস্যা |
|---|---|---|---|
| `invoices/create` | invoice_page + checkout_page | ✅ ফিক্স হয়েছে | — |
| `invoices/all` | — | ❌ বাকি | Invoice list screen দরকার |
| `invoices/shopkeeper/{id}` | — | ❌ বাকি | নতুন screen দরকার |
| `invoices/{id}` | — | ❌ বাকি | Invoice detail screen দরকার |

---

### 8. Customer — 1/5

| Endpoint | Screen | Status | সমস্যা |
|---|---|---|---|
| `customer/shopkeeper/{id}` | invoice_page | ✅ | — |
| `customer/create` | — | ❌ বাকি | নতুন screen দরকার |
| `customer/all` | — | ❌ বাকি | নতুন screen দরকার |
| `customer/update/{id}` | — | ❌ বাকি | নতুন screen দরকার |
| `customer/delete/{id}` | — | ❌ বাকি | নতুন screen দরকার |

---

### 9. Payment — 1/4

| Endpoint | Screen | Status | সমস্যা |
|---|---|---|---|
| `payment/my-payments` | profile_controller | ✅ | — |
| `payment/create-payment` | — | ❌ বাকি | Payment flow দরকার |
| `payment/all-payments` | — | ❌ বাকি | Admin feature |
| `payment/webhook` | — | ❌ বাকি | Server-side only |

---

### 10. Subscription — 1/3

| Endpoint | Screen | Status | সমস্যা |
|---|---|---|---|
| `subscription/all` | profile_controller | ✅ | — |
| `subscription/create` | — | ❌ বাকি | upgrade_plan_page-এ payment flow দরকার |
| `subscription/update/{id}` | — | ❌ বাকি | নতুন screen দরকার |

---

### 11. Dashboard — 0/1

| Endpoint | Screen | Status | সমস্যা |
|---|---|---|---|
| `dashboard/stats` | — | ❌ বাকি | home_controller-এ কানেক্ট করতে হবে |

---

### 12. Notification — 2/5

| Endpoint | Screen | Status | সমস্যা |
|---|---|---|---|
| `notification/shopkeeper` | notifications_page | ✅ | — |
| `notification/read/{id}` | notifications_page | ✅ | — |
| `notification` (all) | — | ❌ বাকি | দরকার কম |
| `notification/user` | — | ❌ বাকি | দরকার কম |
| `notification/{id}` | — | ❌ বাকি | দরকার কম |

---

### 13. Cart — 3/5

| Endpoint | Screen | Status | সমস্যা |
|---|---|---|---|
| `add-to-cart/create` | inventory_screen | ✅ | — |
| `add-to-cart/shopkeeper/{id}` | cart_items_page | ✅ | — |
| `add-to-cart/delete/{id}` | cart_items_page | ✅ | — |
| `add-to-cart/update/{id}` | — | ❌ বাকি | Quantity update দরকার |
| `add-to-cart/delete-all` | — | ❌ বাকি | "Clear Cart" button দরকার |

---

### 14-19. সম্পূর্ণ বাকি (কোনো Screen নাই)

| Feature | Endpoints | Status | সমস্যা |
|---|---|---|---|
| Review | 3 (create, byShopkeeper, delete) | ❌ সব বাকি | নতুন screen দরকার |
| Bank Details | 5 (create, byInvoice, byAddedBy, update, delete) | ❌ সব বাকি | নতুন screen দরকার |
| Low Stock Alert | 5 (create, myAlert, byId, update, delete) | ❌ সব বাকি | নতুন screen দরকার |
| OCR | 2 (extract-imei, extract-nid) | ❌ সব বাকি | Camera integration দরকার |
| Barcode | 1 (search) | ❌ বাকি | নতুন feature দরকার |
| Location | 1 (get) | ❌ বাকি | Location feature দরকার |

---

## পরবর্তী কাজের Priority

### এখনকার Screen-এ কানেক্ট করা যায় (নতুন screen ছাড়া)

| # | কাজ | কোথায় | Endpoint |
|---|---|---|---|
| 1 | Dashboard stats কানেক্ট | home_controller | `dashboard/stats` |
| 2 | Cart quantity update | cart_items_page | `add-to-cart/update/{id}` |
| 3 | Clear Cart button | cart_items_page | `add-to-cart/delete-all` |
| 4 | CSV template download | add_new_device_page | `inventory/import-csv/template` |

### নতুন Screen বানাতে হবে

| # | Feature | প্রয়োজনীয় Endpoints |
|---|---|---|
| 1 | Customer Management (CRUD) | customer/create, update, delete |
| 2 | Invoice List & Detail | invoices/all, invoices/{id} |
| 3 | Bank Details | bank-details/* (5 endpoints) |
| 4 | Low Stock Alert | low-stock-alert/* (5 endpoints) |
| 5 | Review/Rating | review/* (3 endpoints) |
| 6 | Inventory Detail | inventory/{id} |
| 7 | Balance History | user/balance-history |
| 8 | IMEI Risk/Device Analysis | imei/risk-analysis, device-analysis |
| 9 | OCR Scanner | ocr/extract-imei, extract-nid |
| 10 | Payment Flow | payment/create-payment |
