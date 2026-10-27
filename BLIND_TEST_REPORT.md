# Blind Test Report (Week 8)

Team Prestige: Campus Lost and Found / Prestige Lost & Found API

> **Before submitting:** Part 1 is complete. Parts 2 to 5 must describe what really happened in the blind test. Replace every `[bracket]` and delete this note. If the other team never got a working response, say so plainly: the handout says "it didn't work" is a real and useful result.

---

## Part 1: What we published

### Docs site (Part A)

- Rendered from `openapi.yaml` with **Swagger UI**, in `docs/index.html`.
- Opens at **http://10.53.50.111:3000/docs** while our server runs, so a reader needs nothing installed. [If you also published it on GitHub Pages: add the URL here.]
- All 10 operations in the contract appear on the page, each with its request shape and response shape: `GET /health`, `GET` and `POST /claims`, `PATCH` and `DELETE /claims/{claimId}`, `GET /students/{studentId}/claims`, `GET /schools/{schoolId}/item-statistics`, `GET /claims/{claimId}/fees`, `GET` and `POST /claims/{claimId}/refunds`.

### README quickstart (Part B)

| What the handout requires | Where it is in `README.md` |
|---|---|
| Overview: what the API is and who it's for | Opening paragraphs |
| Auth instructions | "Authentication": the `X-API-Key` header, the two 401 messages, and how to get a key |
| One working example per major endpoint, with the real response | "Endpoints": a `curl` command and its real response for each of the 9 endpoints |
| Error format reference | "Errors": the `{"error": "..."}` shape and a table of status codes |
| How to run it locally from a clean clone | "Running it locally": exact commands, plus `./run.sh` |
| One copy-paste quickstart command | "Quickstart for partner teams" |

Every example response in the README was checked against the running server before the swap.

### Our own clean-terminal check

The handout says to run the quickstart yourself, exactly as written, from a clean terminal.

- [ ] Ran the Quickstart `curl` exactly as written, on [date], from [laptop that is not the server]. Result: [200 and the claim list / what went wrong]
- [ ] Followed "Running it locally" from a fresh clone. Result: [worked / what was missing]

---

## Part 2: The swap

| | |
|---|---|
| Team that tested our README | [team name] |
| Are they our ring partner? | [No] [If you had to pair with another available team, say so here and why] |
| Had they used our API before? | [No] |
| What we gave them | `README.md`, our base URL, and one API key. No verbal explanation. |
| How they reached our API | [same Wi-Fi / hotspot / deployed URL] |
| Date and time | [date, start time] |

## Part 3: What happened when our README was tested

- **Did they get a working response?** [Yes / No]
- **Time to first working response:** [n minutes / never]
- **First request they tried:** [e.g. the Quickstart `curl`]

### Where they got stuck

Write down exactly where, and why: which line of the README they misread, skipped, or couldn't follow.

| # | What they were trying to do | Where they got stuck | Why | Docs gap or something else? |
|---|---|---|---|---|
| 1 | [e.g. first call] | [e.g. the Quickstart command] | [e.g. ran `curl` in PowerShell, which isn't real curl] | [Docs gap] |
| 2 | | | | |

[If they never got stuck: "They followed the Quickstart and got a 200 on the first try, in about n minutes."]

## Part 4: What we changed in our docs

| Problem they hit | Change we made to `README.md` |
|---|---|
| [e.g. didn't know where to get a key] | [e.g. added who to ask, and how] |

Gaps we didn't have time to close: [list them, or "none"]

## Part 5: Our turn, testing their README

- **Team:** [name]
- **Did we get a working response?** [Yes / No], after [n minutes]
- **Where we got stuck:** [exact line of their README, and why]
- **What we told them afterwards:** [the gaps we reported]

---

## Honest summary

[One paragraph. Did a stranger get a working response from our README alone? How long did it take? What does that say about our documentation, and what's the single most important thing we fixed or still need to fix?]
