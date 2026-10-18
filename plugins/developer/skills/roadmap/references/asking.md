# Asking

Every decision, confirmation and approval is a question. Use the session's question
pop-up whenever it has one; plain text is the fallback.

## Which tool, and its limits

| Session | Question tool | Its limits |
|---|---|---|
| Claude Code | `AskUserQuestion` | 1–4 questions per call, each with 2–4 options and a header of 12 characters or fewer. "Other" is added automatically. `multiSelect` for choices that aren't exclusive; `preview` to compare drafts, layouts or ticket bodies side by side (single-select only). |
| Codex, Plan mode | `request_user_input` | 1–3 questions per call (prefer 1). Each has a snake_case `id`, a header of 12 characters or fewer, a one-sentence question, and at least one option. Free text is added automatically. |
| Codex, Default mode | `request_user_input`, only when it is listed in your tools (an experimental Codex feature turns it on) | Same limits as Plan mode. If it is listed, use it for every decision round and approval. If it isn't, ask one plain-text question per turn, with your recommendation. Codex's own rules forbid multiple-choice lists in chat, so don't write one. |
| Anything else | whatever question tool the session lists | Follow that tool's own limits. |

## Fitting a round into the tool

- **Split big rounds.** A round bigger than one call allows becomes consecutive calls.
  It is still one round.
- **One decision per question.** Don't bundle two decisions into one set of options.
- **Short headers.** Name the decision: "Type", "Filing", "Phase 2", "Approve".
- **Approvals** are Approve / Change something / Not yet, with what's being approved
  shown just above the question.

## With no question tool at all

Use this format in plain text (except in Codex Default mode, as above):

```
Q1 — <title>: <the question, the options you see, and what each costs>
Recommended: <your answer, and why>
```

Number the questions in a round, and wait for the answers before the next round.
