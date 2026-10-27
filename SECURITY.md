# Security

How the Prestige Lost & Found API and the Campus Lost and Found website are protected.

Week 9 was presentations, so there was no separate security lab. The Week 10 handout expects our API to already be "locked behind a key", with a rate limit and no secrets in the code. This file records how we do that and how it's tested.

---

## 1. Partner API

| Threat | Protection | Where |
|---|---|---|
| Anyone who reads our public docs can call the API | Every route except `/health` needs an `X-API-Key` header. Missing key: `401 {"error":"missing X-API-Key header"}`. Wrong key: `401 {"error":"invalid API key"}` | `requireApiKey()` in `src/middleware/security.js` |
| Guessing a key by timing responses | Keys are compared in constant time | `keyMatches()` |
| A partner calling too often, by accident or not | 60 requests per minute per key. Over that: `429` with a `Retry-After` header. Each key has its own allowance, so one partner can't use up another's | `createRateLimiter()` |
| Keys leaking through the code or git | Keys are read from `.env` only. `.gitignore` excludes `.env`; `.env.example` holds placeholders | `src/config.js`, `.gitignore` |
| Keys leaking through logs | The request log records time, method, path, status and duration, never headers or bodies | `requestLogger()` |
| A browser's preflight being blocked by the key check | CORS runs before the key check, and only for origins listed in `CORS_ORIGINS` | `cors()` |
| Bad input reaching the database | Every write checks required fields, types and values before writing anything; failures return `400` | `src/routes/partnerApi.js` |
| SQL injection | Every query uses `?` placeholders; user input is never pasted into SQL | All files in `src/` |
| Internal details leaking in errors | Unexpected errors return `500 {"error":"internal server error"}`; details go to the server log only. The `X-Powered-By` header is off | `src/errors.js`, `app.js` |

### Managing keys

- Each partner team gets **its own key**, so one can be replaced without affecting the others.
- Generate a key: `node -e "console.log(require('crypto').randomBytes(24).toString('hex'))"`
- Add it to `API_KEYS` in `.env` (comma-separated for several teams), restart the server, and send it to that team **privately**. Never in a group chat, screenshot, or commit.
- To replace a leaked key: generate a new one, swap it into `API_KEYS`, restart, send the new one privately. The old key stops working straight away.

---

## 2. Website

| Threat | Protection | Where |
|---|---|---|
| Stolen passwords | Hashed with scrypt and a random salt per student; never stored in plain text or returned by the API | `hashPassword()` in `src/util.js` |
| Discovering which emails have accounts | A wrong email and a wrong password give the same `401` message | `/web/auth/login` in `src/routes/web.js` |
| Stolen session cookies | The cookie is `HttpOnly` (page scripts can't read it) and `SameSite=Lax`. The database stores only a SHA-256 hash of the token. Sessions expire after 7 days and are deleted on logout | `src/middleware/session.js` |
| Seeing another school's items | Every website query is limited to the logged-in student's school | `src/routes/web.js` |
| Acting on someone else's items or claims | Only the finder can decide claims or remove an item; only the claimant can withdraw a claim. Anyone else gets `403` | `src/routes/web.js` |
| Claim evidence being public | Evidence files are served only to the claimant and the finder, never from the public `uploads` path. A finder's phone number is shown to a claimant only after approval | `/web/claims/{id}/evidence` |
| Malicious uploads | Max 5 MB; the real file type is checked from the file's first bytes (JPG, PNG, GIF, WEBP, plus PDF for evidence); files get random names | `src/uploads.js` |
| Script injection in pages | All user text is HTML-escaped before it's shown. Responses send `X-Content-Type-Options: nosniff` and `X-Frame-Options: DENY` | `esc()` in `public/js/app.js`, `app.js` |
| Our upstream partner's key exposed in the browser | Our server calls the partner; the browser only ever talks to our own server | `src/routes/upstream.js` |

---

## 3. How it's tested

Run `npm test`. The security behaviour is checked by real tests, not just described here.

| Check | Test |
|---|---|
| No key gives 401 | `security.test.js`: "rejects a request with no key with 401" |
| Wrong key gives 401 | "rejects a wrong key with 401" |
| A key missing its last character is rejected | "rejects a key that is only a prefix of a real key" |
| Write routes are protected too, and nothing is deleted | "checks the key on write routes too" |
| `/health` stays open | "leaves /health open so partners can check the server is up" |
| 429 with `Retry-After`; each key counted separately | "returns 429 with Retry-After once a key goes over its limit, per key" |
| Preflight works for allowed origins only | the two CORS tests |
| Errors are JSON, and the framework isn't revealed | the two "Errors" tests |
| Same login error for unknown email and wrong password | `website.test.js`: "gives the same 401 for a wrong password and an unknown email" |
| Evidence hidden from other students and from `/uploads` | "runs the full flow: claim with evidence…" |
| Non-image uploads rejected | "rejects a file that is not an image with 400" |

---

## 4. Incidents

Record any security problem here: what happened, and what you did about it.

| Date | What happened | What we did |
|---|---|---|
| [date] | `.env` (with our API key and MySQL password) and `node_modules` were committed to GitHub, because they were added before `.gitignore` existed | [Removed them with `git rm -r --cached .env node_modules`; generated a new API key and sent it to our partner privately; changed the MySQL password] |

Removing a file in a new commit doesn't erase it from git history, so anything that was in it must be treated as leaked and replaced.

---

## 5. Known limits

- The server runs over plain HTTP on the lab network, so the API key and session cookie travel unencrypted. A real deployment needs HTTPS.
- Rate-limit counters are kept in memory, so they reset when the server restarts.
- There's no lockout after repeated failed logins.
