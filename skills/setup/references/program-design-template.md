# Program Design Section Template

Copy this structure into `design.md` under `## Program Design` whenever the change introduces
a non-trivial new call flow, more than ~2 new functions/methods, or changes an existing call
flow beyond a one-line edit.

One level below Architecture: the shape of the code itself, decided before implementation —
not the architecture (services/contracts, see `docs/architecture/TEMPLATE.md`) and not the
implementation (bodies).

---

## Call-Stack Diff Tree

Use diff syntax when only part of an existing stack is changing.

```diff
 handleRequest(req)
   validateInput(req.body)
+  enrichWithContext(req.body, ctx)      # new: pulls tenant context before dispatch
   dispatchToService(payload)
+    retryWithBackoff(dispatchToService, payload)  # new: wraps the existing call
-  logAndReturn(result)
+  logAndReturn(result, ctx)             # changed: now logs tenant context too
```

## File-Tree Diff

One line per entry, stating the reason it changed.

```diff
 src/
   services/
+    context-enricher.ts          # NEW — builds tenant context for dispatch
     dispatcher.ts                 # MODIFIED — wraps call in retryWithBackoff
   handlers/
     request-handler.ts            # MODIFIED — calls enrichWithContext before dispatch
   utils/
+    retry.ts                      # NEW — generic backoff/retry helper
```

## Typed Signatures

Signatures only — no bodies — for every new/changed function crossing a module boundary.

```
function enrichWithContext(payload: RequestPayload, ctx: TenantContext): EnrichedPayload
function retryWithBackoff<T>(fn: (payload: T) => Promise<Result>, payload: T, maxAttempts: number): Promise<Result>
function dispatchToService(payload: EnrichedPayload): Promise<Result>
```
