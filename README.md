# Campus Lost and Found

Campus Lost and Found helps students get back things they lost at school. A student who finds something reports it with a photo; it appears as a tag in their school's portal. The owner searches the portal, claims the item with evidence, and the finder picks the rightful owner.

This repository contains two things:

1. **The website**, for students: register, log in, browse and search found items, report items, claim them with evidence, review claims and select the owner, notifications, profile, and dark mode.
2. **The Prestige Lost & Found API**, for partner teams: claims, fees, refunds and school statistics, protected by an API key. This is the API described in [`openapi.yaml`](./openapi.yaml).

**Team:** Prestige (Shannel Wanjiru, Raika Kanyiha, GuyTresor Gacheru, Tony Kibe)
**Integration contact:** Prestige team, via WhatsApp

---

## Quickstart for partner teams

You need the API key we sent you privately. Then:

```
curl -i -H "X-API-Key: YOUR_KEY" "http://10.53.50.111:3000/claims?status=claimed"
```

Expected: `200 OK` and

```json
[
  {
    "claimId": "c1",
    "studentId": "s1",
    "itemId": "i1",
    "status": "claimed",
    "rewardAmountCents": 1500,
    "submittedAt": "2026-07-01T09:15:00Z"
  }
]
```

Can't connect? First check the server is up (no key needed):

```
curl -i http://10.53.50.111:3000/health
```

`200 {"status":"ok"}` means you can reach us. If it hangs, you're not on the same network as our laptop, or a firewall is blocking it. Our laptop's address can change; message us if it stops working.

On Windows PowerShell, type `curl.exe` instead of `curl`.

---

## Base URL

```
http://10.53.50.111:3000
```

Browsable documentation for every endpoint is at **http://10.53.50.111:3000/docs** (rendered from `openapi.yaml` with Swagger UI).

## Authentication

Every endpoint except `/health` needs an API key in this header:

```
X-API-Key: <your-key>
```

- We issue one key per partner team, privately. Ask our integration contact if you don't have one.
- Keep the key in your `.env` and call us **from your server**, not from browser JavaScript, where anyone could read it.
- Missing header: `401 {"error":"missing X-API-Key header"}`
- Wrong key: `401 {"error":"invalid API key"}`

## Rate limit

**60 requests per minute per key.** Over the limit you get `429` with a `Retry-After` header giving the seconds to wait. If you hit this, you're probably calling us on every page load or refresh; keep the last result for a short while instead.

## Calling us from a browser (CORS)

We recommend calling us from your server. If you must call from a browser, send us your exact origin (for example `http://localhost:5173`, including the port). We add it to `CORS_ORIGINS`, and browser preflight requests are then answered before the key check.

## Conventions

- **IDs** are strings with a type prefix: `sch1` (school), `s1` (student), `i1` (item), `c1` (claim), `r1` (refund).
- **Money** is an integer number of cents: `1500` means 15.00.
- **Timestamps** are ISO 8601 in UTC: `2026-07-01T09:15:00Z`.
- **Claim status** is one of `pending` (waiting for the finder), `claimed` (approved; the item went back to this student), or `rejected`.

---

## Endpoints

| Method | Path | What it does | Success |
|---|---|---|---|
| GET | `/health` | Check the server is up (no key) | 200 |
| GET | `/claims?status={status}` | List claims with a status | 200 |
| POST | `/claims` | Submit a claim on an item | 201 |
| PATCH | `/claims/{claimId}` | Set a claim's status | 200 |
| DELETE | `/claims/{claimId}` | Withdraw a claim | 204 |
| GET | `/students/{studentId}/claims` | A student's claims | 200 |
| GET | `/schools/{schoolId}/item-statistics` | A school's lost-item totals | 200 |
| GET | `/claims/{claimId}/fees` | The fee on an approved claim | 200 |
| GET | `/claims/{claimId}/refunds` | Refunds on a claim | 200 |
| POST | `/claims/{claimId}/refunds` | Refund part of a claim's fee | 201 |

Every example below is a real response from the server running with its sample data.

### List claims by status

```
curl -i -H "X-API-Key: YOUR_KEY" "http://10.53.50.111:3000/claims?status=pending"
```

`200`:

```json
[
  { "claimId": "c2", "studentId": "s1", "itemId": "i2", "status": "pending", "rewardAmountCents": 0, "submittedAt": "2026-07-03T10:00:00Z" },
  { "claimId": "c3", "studentId": "s2", "itemId": "i2", "status": "pending", "rewardAmountCents": 0, "submittedAt": "2026-07-03T11:30:00Z" }
]
```

No claims with that status gives `200 []`. A missing or unknown status gives `400 {"error":"status must be one of: pending, claimed, rejected"}`.

### Submit a claim

```
curl -i -X POST http://10.53.50.111:3000/claims \
  -H "X-API-Key: YOUR_KEY" -H "Content-Type: application/json" \
  -d '{"studentId":"s1","itemId":"i3"}'
```

`201` (your `claimId` and `submittedAt` will differ; `submittedAt` is the time you sent it):

```json
{ "claimId": "c4", "studentId": "s1", "itemId": "i3", "status": "pending", "rewardAmountCents": 0, "submittedAt": "2026-10-21T08:30:00Z" }
```

| Body field | Type | Required |
|---|---|---|
| `studentId` | string | yes |
| `itemId` | string | yes |
| `description` | string | no: why the item is theirs |

Errors: `400` missing or wrong-type field; `404` student or item not found (or in a different school); `409` the item was already returned, the student found it themselves, or they already have an active claim on it.

### Set a claim's status

```
curl -i -X PATCH http://10.53.50.111:3000/claims/c2 \
  -H "X-API-Key: YOUR_KEY" -H "Content-Type: application/json" \
  -d '{"status":"claimed"}'
```

`200`:

```json
{ "claimId": "c2", "studentId": "s1", "itemId": "i2", "status": "claimed", "rewardAmountCents": 1500, "submittedAt": "2026-07-03T10:00:00Z" }
```

Setting `claimed` selects this student as the owner: the school's reward and handling fee are recorded and every other pending claim on the item becomes `rejected`. Sending the same status twice changes nothing. Errors: `400` invalid status, `404` no such claim, `409` another claim on the item is already approved.

### Withdraw a claim

```
curl -i -X DELETE -H "X-API-Key: YOUR_KEY" http://10.53.50.111:3000/claims/c2
```

`204` with no body. `404 {"error":"claim not found"}` if it doesn't exist.

### A student's claims

```
curl -i -H "X-API-Key: YOUR_KEY" http://10.53.50.111:3000/students/s1/claims
```

`200`:

```json
[
  { "claimId": "c1", "itemId": "i1", "status": "claimed", "submittedAt": "2026-07-01T09:15:00Z" },
  { "claimId": "c2", "itemId": "i2", "status": "pending", "submittedAt": "2026-07-03T10:00:00Z" }
]
```

A real student with no claims gives `200 []`. An unknown student gives `404 {"error":"student not found"}`.

### School statistics

```
curl -i -H "X-API-Key: YOUR_KEY" http://10.53.50.111:3000/schools/sch1/item-statistics
```

`200`:

```json
{ "schoolId": "sch1", "schoolName": "Lakeside High School", "totalItemsReported": 4, "totalItemsClaimed": 1, "totalRewardAmountPaidCents": 1500 }
```

`404 {"error":"school not found"}` for an unknown school.

### Fee on a claim

```
curl -i -H "X-API-Key: YOUR_KEY" http://10.53.50.111:3000/claims/c1/fees
```

`200`:

```json
{ "claimId": "c1", "studentId": "s1", "itemId": "i1", "amountPayableCents": 500 }
```

A fee exists only once a claim is approved. `GET /claims/c2/fees` gives `404 {"error":"no fee has been charged on this claim yet"}`; an unknown claim gives `404 {"error":"claim not found"}`.

### Refunds on a claim

```
curl -i -H "X-API-Key: YOUR_KEY" http://10.53.50.111:3000/claims/c1/refunds
```

`200`:

```json
[
  { "refundId": "r1", "claimId": "c1", "studentId": "s1", "amountCents": 250, "reason": "Item returned in damaged condition; partial refund issued.", "refundedAt": "2026-08-20T16:30:00Z" }
]
```

### Issue a refund

```
curl -i -X POST http://10.53.50.111:3000/claims/c1/refunds \
  -H "X-API-Key: YOUR_KEY" -H "Content-Type: application/json" \
  -d '{"studentId":"s1","amountCents":100,"reason":"Collected late because the office was closed."}'
```

`201` with the new refund (same shape as above). Errors: `400` missing or invalid field, or `studentId` is not the claim's student; `404` no such claim; `409` the claim has no fee, or the total refunded would exceed it (`{"error":"refund exceeds the remaining refundable fee of 150 cents"}`).

---

## Errors

Every error has the same shape:

```json
{ "error": "claim not found" }
```

| Status | Meaning |
|---|---|
| 400 | A field is missing, has the wrong type, or the body isn't valid JSON |
| 401 | Missing or wrong `X-API-Key` |
| 404 | No claim, student, item or school with that ID, or no such path |
| 409 | The request conflicts with the current state (see each endpoint) |
| 429 | Rate limit exceeded; wait `Retry-After` seconds |
| 500 | Our bug. Tell us the time and the request you sent |

## Sample data

The server starts with this data (reset it any time with `npm run db:setup`):

| | |
|---|---|
| Schools | `sch1` Lakeside High School, `sch2` Riverside Academy |
| Students | `s1`, `s2`, `s3` at sch1; `s4` at sch2 |
| Items | `i1` (returned), `i2`, `i3`, `i4` at sch1; `i5` at sch2 |
| Claims | `c1` claimed, `c2` and `c3` pending (both on `i2`) |
| Fee / refund | 500 on `c1`; refund `r1` of 250 on `c1` |

Website logins (password `password123` for all): `amani@lakeside.test`, `wanjiku@lakeside.test`, `brian@lakeside.test`, `faith@riverside.test`.

---

## Running it locally

You need **Node.js 18 or newer** and **MySQL** running.

```
git clone <this repo's URL>
cd <repo folder>
npm install
cp .env.example .env          # Windows: copy .env.example .env
```

Open `.env` and set at least:

- `DB_PASSWORD`: your MySQL password (leave empty if root has none)
- `API_KEYS`: the key(s) you give partners. Generate one with
  `node -e "console.log(require('crypto').randomBytes(24).toString('hex'))"`

Then:

```
npm run db:setup     # creates the database and tables, loads sample data (erases existing data)
npm start
```

The server prints the website address, the docs address, and the address partners on your network should use. Open **http://localhost:3000** for the website.

`./run.sh` does install, setup and start in one go (Mac/Linux/Git Bash).

### Tests

```
npm test
```

The tests use a separate database (`<DB_NAME>_test`), so they never touch your real data. They cover every endpoint: success, validation errors, not-found cases, edge cases, security, and the website flows.

### Using our upstream partner's API

Set `PARTNER_URL`, `PARTNER_API_KEY`, and the header, path and field names from their README in `.env`. The Browse page shows their data in a side panel. If their server isn't ready, run `npm run partner-stub` and point `PARTNER_URL` at `http://localhost:4000` with key `stub-key`.

### Project layout

```
app.js, server.js        the Express app, and the file that starts it
src/routes/partnerApi.js the partner API (openapi.yaml)
src/routes/web.js        the website's own JSON API
src/routes/upstream.js   calls our upstream partner (Week 10)
src/services/claims.js   claim rules shared by the website and the API
src/middleware/          API keys, rate limit, CORS, login sessions
src/mappers.js           database rows -> contract shapes
db/                      MySQL schema, sample data, setup script
public/                  the website (HTML, CSS, JS)
docs/                    Swagger UI docs page
__tests__/               Jest + Supertest tests
```

Weekly lab deliverables are in the `.md` files at the root; [`SUBMISSION_GUIDE.md`](./SUBMISSION_GUIDE.md) maps each week to its files.
