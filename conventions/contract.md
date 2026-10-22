# Cross-Stack API Contract

Single source of truth for the **API envelope** and **error-code registry**
shared across every stack in the deck. Any backend (Express, FastAPI, Go,
Rust, a Tauri command server, …) and any frontend (React, Next.js, Svelte,
a desktop app) that adopts this contract produces and consumes **exactly
this shape**, so a client never has to branch on which backend it is talking
to.

> Status: living document. When this changes, every adopting stack updates in
> lockstep. Adding a code = minor. Removing/renaming a code or changing the
> envelope = major.

## 1. The envelope

Every API response — success or failure, every endpoint, every stack — uses a
discriminated-union shape. The discriminant is `ok: boolean`.

### Success

```json
{
  "ok": true,
  "data": <T>,
  "meta": { "requestId": "<uuid>", "ms": <number>, "version": "v1" }
}
```

### Failure

```json
{
  "ok": false,
  "error": {
    "code": "<ErrorCode>",
    "message": "<human-readable>",
    "details": <Record<string, unknown> | undefined>
  },
  "meta": { "requestId": "<uuid>", "ms": <number>, "version": "v1" }
}
```

Rules:

- Discriminant is `ok`, not `success`/`status`.
- No top-level `data` on failure; no top-level `error` on success. Mutually
  exclusive.
- `data` is whatever the route promises: object, array, primitive, or `null`.
- `error.code` is required and comes from the registry below. Never invent
  codes.
- `error.message` is for humans — a toast or inline error. Under ~200 chars,
  never a stack trace.
- Clients branch on `error.code` and `error.details`, never on `message`
  text. Any value a client needs goes in `details`.
- `error.details` is optional and structured — the carrier slot for
  machine-readable extras. Multi-field validation uses
  `details.fieldErrors: Record<string, string>`.
- `meta` is required on every response (success and failure):
  - `requestId`: UUID v4 correlation id. Honor an incoming `X-Request-Id`
    only if it is a valid UUID; otherwise generate one. Never log an
    unvalidated client id.
  - `ms`: integer milliseconds elapsed server-side.
  - `version`: API version string, currently `"v1"`. Bumps only when the
    envelope shape itself changes.
- Response header `X-Request-Id` mirrors `meta.requestId`.
- No other top-level keys. Pagination/cursor belong inside `data`
  (`{ items, cursor }`), not at the envelope.
- A successful DELETE returns HTTP 200 with `{ ok: true, data: null, meta }`
  — never a bodyless 204 inside the v1 API surface.

## 2. Error-code registry

| Code | HTTP | When |
|---|:---:|---|
| `VALIDATION` | 400 | Input failed schema validation. Covers shape-wrong and semantically-invalid. Use `details.fieldErrors` for multi-field forms. |
| `UNAUTHENTICATED` | 401 | No valid session/token; anonymous or expired credentials. |
| `FORBIDDEN` | 403 | Authenticated, allowed to know the resource exists, but lacks permission for this action (e.g. editing something shared read-only). |
| `NOT_FOUND` | 404 | Resource does not exist, or the caller can't see it. Row-level denial on a row the caller can't see is always NOT_FOUND, never FORBIDDEN (don't leak existence). |
| `CONFLICT` | 409 | Unique-constraint violation, optimistic-lock failure, duplicate creation. |
| `RATE_LIMIT` | 429 | Too many requests. Send a `Retry-After` header when possible. |
| `UPSTREAM` | 502 | Downstream dependency failure (external API, third-party service, DB connectivity). Caller may retry. |
| `INTERNAL` | 500 | Unexpected server error. Generic message; full stack logged server-side with the requestId, never leaked. |

8 codes. Universal across every adopting stack.

Rules:

- The HTTP status MUST match the code. A `NOT_FOUND` is served as 404, never
  200 + `ok: false`.
- `VALIDATION` covers everything 400-related. Do not invent per-field codes;
  carry field-level info in `error.details.fieldErrors`.
- Adding a code is a contract change (minor). Removing/renaming is major.
- Clients may safely ignore unknown codes by falling back to `error.message`.
  New codes are non-breaking for consumers.
- Unique constraints that span users leak existence through `CONFLICT`. Scope
  them per user, or make the value unguessable.

Client-only synthesized codes (server never emits these):

| Code | When |
|---|---|
| `NETWORK_ERROR` | The request never reached the server (DNS, TCP refused, CORS, offline). The client's fetch wrapper generates it. |

## 3. Base error + subclasses

Each backend ships an abstract base error plus 8 named subclasses, each pinning
its `(code, status)` pair. Throwing the subclass by name anywhere in the
request flow produces the correct envelope automatically. A single top-level
handler converts errors to the envelope.

- Base is abstract / not directly instantiable.
- Subclasses: `ValidationError`, `UnauthenticatedError`, `ForbiddenError`,
  `NotFoundError`, `ConflictError`, `RateLimitError`, `UpstreamError`,
  `InternalError`.
- Handlers never raise raw framework exceptions (e.g. `HTTPException`) — they
  raise the base-error subclasses; the handler emits the envelope.
- No bare `catch`/`except` around the handler; catch specific types.
- The top-level handler also converts framework and middleware errors (e.g.
  Hono's `HTTPException`) by status: 400/413 → VALIDATION, 401 →
  UNAUTHENTICATED, 404 → NOT_FOUND, 429 → RATE_LIMIT, anything else → INTERNAL.
  Register it once on the root app (Hono: `app.onError` plus `app.notFound`).
- Unknown routes return the NOT_FOUND envelope. Validator failures throw
  `ValidationError` (pass a hook so the validator's own body never escapes).
  Error responses keep `X-Request-Id` and CORS headers; test it, because a
  missing CORS header turns an error into a client `NETWORK_ERROR`.

## 4. Constants module

Every adopting stack centralizes the codes and statuses so no string literal
or numeric status is scattered through route code:

- An `ERROR_CODES` / `ErrorCode` registry (string-valued, byte-equal across
  stacks).
- An `HTTP_STATUS` constants map (descriptive names: `BAD_REQUEST`,
  `UNAUTHORIZED`, `FORBIDDEN`, `NOT_FOUND`, `CONFLICT`, `TOO_MANY_REQUESTS`,
  `INTERNAL_SERVER_ERROR`, `BAD_GATEWAY`, `SERVICE_UNAVAILABLE`, …).
- An `API_VERSION` / `API_V1_PREFIX` constant (`"/api/v1"`). Routes mount under
  the prefix; no hardcoded version strings. Lint/gate against raw status
  literals and raw code strings outside the constants module.

## 5. URL versioning

All API routes mount under `/api/v1/...`. The URL version matches
`meta.version`. New endpoints that do not change the envelope stay on `v1`. A
breaking envelope change means a `v2` parallel mount with a deprecation window.
External webhooks (fixed URLs, HMAC-signed) may live at unversioned paths —
they are outside the envelope contract.

Within a version, a route's `data` changes only by adding fields. A breaking
change to a route needs a new route or a new version.

## 6. Two-type-layer rule (TypeScript frontends)

| Location | What lives there |
|---|---|
| `shared/<feature>/types.ts` | DTOs that cross the HTTP boundary (route input/output). |
| `shared/<feature>/schemas.ts` | Zod (or equivalent) schemas validating those DTOs — the schema *is* the contract. |
| `shared/<feature>/constants.ts` | Enum-like values both client and server need. |
| `<app>/<feature>/types.ts` | App-internal types (view models, state machines). Never imported across apps. |

Decision rule: in the shared layer if it crosses HTTP or ≥2 apps import it; in
the app's local layer if purely internal.

## 7. What this contract does NOT cover

- **Authentication mechanism.** The contract defines the response shape; how a
  caller authenticates is per-project.
- **Pagination.** Belongs inside `data`.
- **Rate-limit metadata.** Use HTTP headers (`Retry-After`,
  `X-RateLimit-Remaining`), not the envelope.
- **Tracing.** `traceparent` (W3C Trace Context) may be accepted and propagated
  alongside `X-Request-Id`, never instead of it. Never forward either header to
  third-party or user-supplied URLs.
- **Problem Details (RFC 9457).** Not emitted; RFC 9457 allows an existing
  format. Revisit only if third parties consume the API.
- **Streaming / SSE / WebSocket.** Different framing; out of scope.
- **File upload / download.** Multipart and binary responses are out of scope.

## 8. Versioning

- Adding an `ErrorCode`: non-breaking, minor bump, all stacks update in the
  next release.
- Removing/renaming an `ErrorCode`: breaking, major bump, all stacks + clients.
- Changing the envelope shape: breaking, major bump on the contract and every
  stack and client. Keep v1 + v2 alive during a deprecation window.

## 9. Why one shared contract

Cross-stack contracts belong between stacks, not inside one. Keeping a single
source means every stack produces byte-equal responses, a client has one type
to trust, and "add a code" is one doc change plus a lockstep bump — not a
drift-prone copy in each plugin.
