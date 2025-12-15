# Toonga API Surface

Base URL for production: `https://toonga.app/api`.  
Unless otherwise noted, requests expect/return JSON. Sanctum-protected routes require a bearer token (mobile apps) or Sanctum cookie (web portals). Role-restricted portals stack additional middleware as shown below.

## 1. Authentication & Profile (`routes/api.php:21-34`)
| Method | Path | Description | Middleware |
| --- | --- | --- | --- |
| POST | `/auth/send-code` | Send verification code to phone/email. | None |
| POST | `/auth/verify-code` | Verify code and issue auth token. | None |
| POST | `/auth/login` | Standard credential login. | None |
| GET | `/auth/google` | Redirect URI for Google OAuth. | None |
| GET | `/auth/google/callback` | OAuth callback handler. | None |
| GET | `/auth/me` | Fetch current profile. | `auth:sanctum` |
| POST | `/auth/update-profile` | Update profile fields. | `auth:sanctum` |
| POST | `/auth/logout` | Invalidate current token/session. | `auth:sanctum` |

## 2. Customer Orders & Payments (`routes/api.php:36-48`)
| Method | Path | Description | Middleware |
| --- | --- | --- | --- |
| POST | `/orders` | Create a new customer order. | `auth:sanctum` |
| GET | `/orders` | Paginated list of user orders. | `auth:sanctum` |
| GET | `/orders/{id}` | Order detail (numeric id). | `auth:sanctum` |
| PATCH | `/orders/{id}/cancel` | Cancel an order. | `auth:sanctum` |
| POST | `/orders/{order}/pay` | Start a payment (MoMo, etc.). | `auth:sanctum` |
| GET | `/payments/{payment}/status` | Poll payment status. | `auth:sanctum` |
| POST | `/admin/payments/{payment}/vendor-payout` | Trigger vendor payout for a payment. | `auth:sanctum`, `ensure.admin` |
| GET | `/account/overview` | Consolidated balances/miles summary. | `auth:sanctum` |
| POST | `/momo/callback` | MTN MoMo webhook receiver. | None |

## 3. Public Data & Storefront (`routes/api.php:53-63,271-274`)
| Method | Path | Description | Middleware |
| --- | --- | --- | --- |
| GET | `/categories` | Public category list. | None |
| GET | `/categories/{slug}/featured` | Featured products for category slug. | None |
| GET | `/vendors` | Public vendor list. | None |
| GET | `/public/vendors-simple` | Lightweight vendor id/name list. | None |
| GET | `/store/products` | Public storefront listing with filters. | None |
| GET | `/store/products/{id}` | Product detail (numeric id). | None |
| GET | `/store/search/suggestions` | Autocomplete suggestions. | None |

## 4. Public Reels (`routes/api.php:65-82`)
| Method | Path | Description | Middleware |
| --- | --- | --- | --- |
| GET | `/public/reels/status` | Health/status ping for reels API. | None |
| GET | `/public/reels` | Paginated public reels feed. | None |
| POST | `/public/reels/{id}/view` | Register a reel view. | None |
| GET | `/public/reels/{id}` | Reel detail. | None |
| GET | `/public/reels/{id}/comments` | Public comments list. | None |
| GET | `/public/vendors/{vendor}/follow` | Follow status for visitor session. | `web` |
| POST | `/public/reels/{id}/like` | Like a reel. | `web`, `auth:sanctum` |
| POST | `/public/reels/{id}/comments` | Add comment. | `web`, `auth:sanctum` |
| POST | `/public/vendors/{vendor}/follow` | Follow vendor. | `web`, `auth:sanctum` |
| DELETE | `/public/vendors/{vendor}/follow` | Unfollow vendor. | `web`, `auth:sanctum` |

## 5. Vendor Portal (`routes/api.php:92-118`)
Middleware: `web`, `ensure.vendor`.

| Method | Path | Description |
| --- | --- | --- |
| GET | `/vendor/me` | Current vendor profile summary. |
| GET | `/vendor/overview` | Dashboard metrics. |
| GET/POST | `/vendor/profile` | View / update vendor profile. |
| GET/POST/PUT/DELETE | `/vendor/products` & `/vendor/products/{id}` | Manage catalog items. |
| GET | `/vendor/subcategories` | Allowed subcategories. |
| GET | `/vendor/attributes` | Product attribute definitions. |
| GET | `/vendor/payments` | Payout history. |
| GET | `/vendor/top-products` | Best performing items. |
| GET | `/vendor/orders/recent` | Recent orders snapshot. |
| GET | `/vendor/orders` | Full vendor order list. |
| PATCH | `/vendor/orders/{order}/logistics` | Update logistics/delivery info. |
| GET | `/vendor/drivers` | Driver directory. |
| GET | `/vendor/analytics` | Sales metrics. |
| GET | `/vendor/reels/insights` | Reels performance. |
| GET | `/vendor/reports/download` | Download CSV/Excel report. |
| GET | `/vendor/rewards` | Vendor reward balances. |
| GET | `/vendor/reviews` | Product reviews. |
| GET/POST | `/vendor/support/tickets` | List/create support tickets. |
| POST | `/vendor/support/tickets/{ticket}/comments` | Add ticket comment. |

## 6. Driver Portal (`routes/api.php:120-128`)
Middleware: `web`, `EnsureDriver`.

| Method | Path | Description |
| --- | --- | --- |
| GET | `/driver/me` | Driver profile. |
| PUT | `/driver/profile` | Update profile. |
| GET | `/driver/orders` | Orders assigned to driver. |
| POST | `/driver/orders/confirm` | Confirm order via token. |
| GET/POST | `/driver/support/tickets` | Support tickets listing/creation. |
| POST | `/driver/support/tickets/{ticket}/comment` | Comment on ticket. |

## 7. Admin API (`routes/api.php:130-269`)
Middleware: `web`, `auth:sanctum`, `ensure.admin`. Highlights:

- Dashboard/profile: `GET /admin/dashboard`, `GET /admin/user`.
- Product management: CRUD and status toggles via `/admin/products`, `/admin/products/{id}`, `/admin/products/{id}/status`, `/admin/products/{id}/storefront-status`.
- Categories/Subcategories/Attributes maintenance.
- Vendors CRUD & verification (`/admin/vendors*`).
- Orders, logistics, fulfillment tools.
- Offers, payments, rewards, social media posts, reels moderation, reel-products REST, user administration, etc.
- Sales/admin support for partner approvals, analytics, exporting (see detailed routes in `routes/api.php` lines 137-269).

Refer to `routes/api.php` if you need the exhaustive per-endpoint list; every admin path starts with `/admin/...`.

## 8. Sales Portal (`routes/api.php:275-333`)
Middleware: `web`, `auth`, `ensure.sales`.

- Identity & profile: `GET /sales/me`, `/overview`, `/profile`, `POST /profile`, `/notifications`.
- Product onboarding: listing & CRUD via `/sales/products` plus category/subcategory/attribute helpers.
- Vendor & partner management: `/sales/vendors*`, `/sales/partners`, `/sales/vendors-simple`.
- Offers/orders/payments/contracts/tickets/reels management under `/sales/...`.
- Reel products REST resource: `/sales/reel-products` (+ `/sales/reel-products/by-reel/{reel}`).
- Analytics suite under `/sales/analytics/*` (summary/products/customers/traffic/reviews).
- Reports suite under `/sales/reports/*` (payments/commissions/orders/inventory/reels + `/export`).

## 9. Partner Portal (`routes/api.php:336-342`)
Middleware: `web`, `auth`, `ensure.partner`.

| Method | Path | Description |
| --- | --- | --- |
| GET | `/partner/overview` | Partner dashboard metrics. |
| GET | `/partner/offers` | Partner offers list. |
| POST | `/partner/offers` | Submit new offer. |
| PUT | `/partner/offers/{offer}` | Update offer (numeric id). |
| GET | `/partner/ads/reports` | Ad performance reports. |

## 10. Accountant Portal (`routes/api.php:344-349`)
Middleware: `web`, `auth`, `ensure.accountant`.

| Method | Path | Description |
| --- | --- | --- |
| GET | `/accountant/approval-status` | View payout approval queue. |
| POST | `/accountant/request-approval` | Request approval action. |
| GET | `/accountant/overview` | Accountant dashboard. |
| GET | `/accountant/payments` | Finance payment ledger. |

---

**How to use this file**
- Each path above is relative to `/api`.
- Combine with `php artisan route:list --path=api` to confirm middleware/names before integrating.
- For “REST resource” entries (e.g., `/admin/reel-products`), the following methods are implicit unless excluded: `GET /resource` (index), `POST /resource` (store), `GET /resource/{id}` (show), `PUT/PATCH /resource/{id}` (update), `DELETE /resource/{id}` (destroy).
