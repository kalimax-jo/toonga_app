# Mobile Payments (MTN MoMo) – API Flow

## Overview
- Payments are tied to orders. Create the order first, then initiate payment.
- MTN MoMo “Request to Pay” is used.
- Auth required (Sanctum cookies or bearer token).
- Server handles callbacks and updates order/payment status; client polls status.

## Endpoints
- `POST /api/orders/{order}/pay` — initiate payment
- `GET /api/payments/{payment}/status` — check payment status
- (Callback) handled server-side by `/api/payments/{payment}/status` controller method; no client action needed.

## Initiate Payment
**Request**
```
POST /api/orders/{order}/pay
Content-Type: application/json
Authorization: Bearer <token>   // or Sanctum cookie

{
  "msisdn": "<payer_phone>"     // string, 8–20 chars
}
```

**Response (202 Accepted)**
```jsonc
{
  "message": "Payment initiated",
  "payment": {
    "id": 123,
    "payment_type": "order",
    "order_id": 456,
    "amount": 10000,
    "currency": "EUR",               // from config('services.momo.currency')
    "status": "processing",          // pending/processing until MTN confirms
    "payment_method": "mobile_money",
    "reference_number": "PMT-...",
    "external_reference": "MTN-REF",
    "transactions": [
      {
        "id": 789,
        "transaction_type": "credit",
        "amount": 10000,
        "status": "pending",
        "external_transaction_id": "MTN-REF",
        "transaction_data": { "payer_msisdn": "07****" }
      }
    ]
  }
}
```

## Check Payment Status
**Request**
```
GET /api/payments/{payment}/status
Authorization: Bearer <token>
```

**Response**
```jsonc
{
  "payment": {
    "id": 123,
    "status": "successful",          // pending | processing | successful | failed
    "order": { "id": 456, "order_number": "..." },
    "transactions": [ ... ],
    "vendor": { ... },
    "user": { ... }
  }
}
```

Polling guidance: poll until `status` is `successful` or `failed`, then stop. On `failed`, show the message and allow retry.

## Errors
- 422 on initiate: invalid `msisdn`.
- 400/409: order already paid or invalid state.
- Network/server errors: retry with backoff; do not duplicate orders.

## Notes
- Amount comes from the order total; description includes the order number.
- Miles/cashback/vendor share are processed server-side when payment completes.
- For MTN sandbox quirks: status `PENDING` may be simulated to `SUCCESSFUL` if enabled in config; the service handles this internally.
