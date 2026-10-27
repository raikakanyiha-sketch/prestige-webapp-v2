# Partner Test Results (Week 7)

Team Prestige: Campus Lost and Found / Prestige Lost & Found API

> **Before submitting:** Part 1 is complete. Parts 2 to 4 record the exchange with your ring partner and must contain what really happened. Replace every `[bracket]`, delete rows you don't need, and delete this note. "All of their tests passed" is a real and valid result; write it plainly if that's what happened.

---

## Part 1: Our own automated tests

**Tools:** Jest + Supertest. **Run with:** `npm test` (or `./run.sh test`).
The tests use their own database (`<DB_NAME>_test`), which is rebuilt with sample data before each run, so they never touch real data.

| Test file | What it covers | Tests |
|---|---|---|
| `__tests__/claims.test.js` | `GET /claims`, `POST /claims`, `PATCH /claims/{claimId}`, `DELETE /claims/{claimId}` | 28 |
| `__tests__/students-schools.test.js` | `GET /students/{studentId}/claims`, `GET /schools/{schoolId}/item-statistics` | 9 |
| `__tests__/fees-refunds.test.js` | `GET /claims/{claimId}/fees`, `GET` and `POST /claims/{claimId}/refunds` | 19 |
| `__tests__/security.test.js` | API key, rate limit, CORS, error format | 11 |
| `__tests__/website.test.js` | The website's own API: accounts, search, reporting, claims, choosing the owner, notifications, profile, upstream partner panel | 34 |
| **Total** | | **101** |

Result on [date], on [whose laptop]: [101 passed, 0 failed]

### Every endpoint is covered in all four ways

| Endpoint | Happy path | Validation (400) | Not found (404) | Edge case |
|---|---|---|---|---|
| `GET /claims` | Exact claim returned for `status=claimed` | Missing status; unknown status | n/a (filter, not an ID) | Status with no claims returns `200 []` |
| `POST /claims` | 201, pending, reward 0, then read back | Missing or wrong-type `studentId`/`itemId`; invalid JSON; nothing written on failure | Unknown student; unknown item; item in another school | 409 for own item, duplicate claim, already-returned item |
| `PATCH /claims/{claimId}` | Approve: reward set, rival claim rejected, fee created | Missing status; invalid status (checked before the ID) | Unknown claim; malformed ID | Same PATCH twice gives the same result (idempotent); 409 for a second approval |
| `DELETE /claims/{claimId}` | 204, empty body, claim gone | n/a (no body) | Deleting twice | Deleting the approved claim frees the item |
| `GET /students/{studentId}/claims` | Exact list, oldest first | n/a | Unknown student; malformed ID | Real student with no claims returns `200 []`; no extra fields leaked |
| `GET /schools/{schoolId}/item-statistics` | Exact live totals | n/a | Unknown school; malformed ID | School with nothing claimed returns zeros as numbers |
| `GET /claims/{claimId}/fees` | Exact fee | n/a | Unknown claim | Claim with no fee yet returns a specific 404 |
| `GET /claims/{claimId}/refunds` | Exact refund list | n/a | Unknown claim | Claim with no refunds returns `200 []` |
| `POST /claims/{claimId}/refunds` | 201, then read back | 7 cases: missing fields, string or decimal amount, zero, empty reason; nothing written on failure | Unknown claim | Refunding exactly the remaining fee is allowed; one cent more gives 409 |

### Our assertions would catch broken code

The tests check exact field names, types and values, and that responses contain **no extra fields** (`expectClaim`, `expectRefund` and `expectStudentClaim` in `__tests__/helpers.js` compare each response's keys with `openapi.yaml`). A test that only checked the status code could pass on broken code.

We checked this the way the handout suggests, by breaking the code on purpose:

| Deliberate break | Result |
|---|---|
| Renamed `rewardAmountCents` to `reward_amount_cents` in `src/mappers.js` | 5 tests failed |
| [Optional: another break you try, e.g. remove the "status is required" check in `src/routes/partnerApi.js`] | [n tests failed] |

Then we put the code back and all tests passed again.

---

## Part 2: The exchange

| | |
|---|---|
| Ring partner | [team name] |
| We sent them | `openapi.yaml` version [2.0.0], **not** our test files, on [date] via [channel] |
| They sent us | Their `openapi.yaml` version [x.y.z], on [date] |
| Their tests ran against | Our live server at [http://10.53.50.111:3000], on [date] at [time] |
| Our tests ran against | Their live server at [URL], on [date] at [time] |
| Our tests for their API | [file, e.g. `__tests__/partner/<their-api>.test.js`, or "in their repo"] |
| How we reached each other | [same Wi-Fi / phone hotspot / deployed URL] |

## Part 3: What their tests found in our API

[Total: x tests, y passed, z failed]

| # | Their test | Expected (by their reading of our contract) | What our API returned | Classification | What we did |
|---|---|---|---|---|---|
| 1 | [e.g. `GET /claims` with no status] | [e.g. 200 and every claim] | [400 status query parameter is required] | [Misunderstanding: our contract marks `status` as required] | [Explained to them; no change] |
| 2 | | | | | |

If every test passed: "All [x] of their tests passed against our running API. No changes were needed."

## Part 4: What our tests found in their API

[Total: x tests, y passed, z failed]

| # | Our test | Expected (from their contract) | What their API returned | Classification | What they did |
|---|---|---|---|---|---|
| 1 | | | | | |

### What we tested in their API

[Tick what you covered, matching what you did for your own API.]

- [ ] Happy path for every endpoint, checking field names and types against their contract
- [ ] Validation: missing and wrong-type fields on write endpoints
- [ ] Not found: an ID that doesn't exist
- [ ] At least one edge case per endpoint (empty list, boundary value)
- [ ] No key and wrong key (if their API needs one)

---

## How we classified failures

- **Real bug:** the API doesn't do what its own contract says. Fix the code.
- **Contract ambiguity:** the contract allows two reasonable readings and the test picked the other one. Clarify the contract (and add a row to `CONTRACT_DEVIATIONS.md`).
- **Misunderstanding:** the test expects something the contract never promised. Explain it to the other team; nobody's code changes.

## Changes made because of partner testing

| Change | File(s) | Commit |
|---|---|---|
| [e.g. clarified that `GET /students/{id}/claims` returns `[]` for a student with no claims] | [`openapi.yaml`, `CONTRACT_DEVIATIONS.md`] | [commit hash or message] |

[If nothing changed: "No changes were needed in our code or contract."]
