Mobile Home Screen API
======================

This document explains the planned `/api/home` endpoint and how the Toonga mobile clients should consume it to render the dashboard shown in the reference screenshot (greeting, search, horizontal chips, and featured cards).

Overview
--------
- Endpoint aggregates the data the home screen needs in a single payload to minimize round-trips.
- Requires an authenticated user (Bearer Sanctum token).
- Categories come straight from the `categories` table via `Category::enabled()->ordered()`, so the payload always reflects what has been configured in the CMS/DB.

Endpoint
--------
- **Method/Route:** `GET /api/home`
- **Headers:** `Accept: application/json`, `Authorization: Bearer <token>`
- **Query params (optional):**
  - `lat`, `lng` (floats) — allow backend to tailor suggestions per city.
  - `limit` (int, default 10) — how many featured experiences to include.

Response Contract
-----------------
```json
{
  "timestamp": "2025-11-21T10:12:00Z",
  "user": {
    "id": 17,
    "name": "Joshua",
    "greeting": "Good evening"
  },
  "search": {
    "placeholder": "Search for beverages, nightlife...",
    "recent_terms": ["nsm"],
    "suggestions_url": "/api/store/search/suggestions"
  },
  "categories": [
    {
      "id": 4,
      "name": "Beverages",
      "slug": "beverages",
      "is_active": true,
      "icon_url": "https://toonga.app/storage/icons/beverages.png",
      "sort_order": 1
    },
    {
      "id": 7,
      "name": "Nightlife",
      "slug": "nightlife",
      "is_active": true,
      "icon_url": null,
      "sort_order": 2
    }
  ],
  "featured": [
    {
      "id": 1201,
      "title": "Nightlife",
      "subtitle": "Late-night vibes",
      "available_text": "Available tonight",
      "miles_award": 120,
      "image_url": "https://toonga.app/images/cards/nightlife.png",
      "category_id": 7,
      "vendor_id": 93,
      "cta": {
        "text": "Explore",
        "target_type": "category",
        "target_id": 7
      }
    }
  ],
  "notifications": {
    "unread_count": 1
  }
}
```

Data Sources
------------
- `user`: derived from the authenticated user (`Auth::user()`), plus a computed greeting string based on local time (`Good morning / afternoon / evening`). Name is fetched from `users.name`.
- `categories`: query `Category::enabled()->ordered()->get()` so that the array matches exactly what has been enabled in the dashboard. Each record is projected as `{ id, name, slug, is_active, icon_url, sort_order }`.
- `featured`: depends on product/campaign logic (e.g., curated cards or `CategoryFeaturedProduct` records). The API simply surfaces the data; the client just renders the cards horizontally.
- `notifications.unread_count`: optional convenience to show badge on the bell.

UI Behaviour Rules
------------------
1. **Greeting row**
   - Use `response.user.greeting` and `response.user.name`.
   - If `greeting` is empty, compute client-side using the device clock.
2. **Search bar**
   - Pre-fill the hint with `response.search.placeholder`.
   - When user types, hit `/api/store/search/suggestions?q=` (URL provided in `suggestions_url`).
   - Optionally show chips of `recent_terms`.
3. **Category chips**
   - Render categories in `sort_order` ascending—the order mirrors the DB `sort_order`.
   - Chips are only returned when `is_active` is `true`, so every chip is interactive. When tapped, open `/api/store/products?category_id=<id>` or route accordingly.
   - The currently selected category persists in local state; highlight the chip (e.g., yellow fill) similar to the screenshot.
4. **Featured cards (carousel)**
   - Iterate through `response.featured`.
   - Use `title`, `subtitle`, `available_text`, and `miles_award` to fill the text nodes in each card (see screenshot: “Nightlife”, “Available tonight”, “+120 miles on booking”).
   - Card tap behaviour depends on `cta.target_type`:
     - `category`: navigate to the category listing screen.
     - `vendor`: go to vendor storefront.
     - `product`: open product detail.
5. **Notifications icon**
   - Show a badge if `notifications.unread_count > 0`.

Fallback Strategy
-----------------
- If `/api/home` fails, fall back to previously cached payload (e.g., persisted JSON in local storage) to keep the home screen usable offline.
- When categories array is empty, hide the chip row and show a friendly empty state message.
- When featured carousel is empty, hide the component gracefully.

Client Sequence Diagram
-----------------------
1. App boots ➜ call `GET /api/home`.
2. While loading, show skeleton UI.
3. When response arrives:
   - Update greeting and search placeholder.
   - Render chips using the categories list.
   - Preload featured card images referenced via `image_url`.
4. User taps a chip ➜ call `GET /api/store/products?category_id=<id>` (existing endpoint) to populate the card carousel and downstream pages.

Future Enhancements
-------------------
- Add `banners[]` for hero promos.
- Add `recommendations[]` keyed by the selected category to avoid extra round trips on chip change.
- Expose `categories_version` to detect when to refresh cached chip data.

Testing
-------
Use a personal token and run:

```bash
curl -H "Authorization: Bearer $TOKEN" \
     -H "Accept: application/json" \
     https://toonga.app/api/home
```

Verify that:
- Active categories have `is_active: true`.
- Disabled ones still appear but with `is_active: false`.
- Featured cards reference only active categories to avoid dead ends on the UI.
