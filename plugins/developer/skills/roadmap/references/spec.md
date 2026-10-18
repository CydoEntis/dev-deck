# Spec

Requirements and design for one piece of work, in one document, with the repo's
standards applied while it is written instead of discovered in review. Only for work
whose decisions the tickets can't hold on their own (see `add.md` step 3): what the
user sees, what data is stored, or how the work meets an existing system.

It sits next to the work's `intent.md` and never repeats it.

````markdown
# Spec: <short title>

Intent: [intent.md](intent.md) · Status: draft | accepted · Date: <YYYY-MM-DD>

## Concerns

Listed first, because they are what the reviewer reads first. Each one names the
standard or risk it touches, and your recommendation.

- **<concern>**: <what it conflicts with or risks: `DESIGN.md` §x, a new
  permission, a migration, a new dependency, data leaving the device,
  accessibility>. Recommend: <what to do>.

With no concerns, write what you checked: "None. Checked `DESIGN.md`,
`docs/api.md`, `docs/security.md`."

## Requirements

Numbered, and each one pass/fail.

- **R1.** <observable statement> — checked by <test, command, or screenshot check>
- **R2.** ...

## Design

- **Screens and states**: default, empty, loading, error, and anything else this
  feature has, each with the design source it must match (`DESIGN.md` §x, a mock).
- **Data**: new or changed fields, and any migration, with how existing data
  survives it.
- **Interfaces**: commands, endpoints, events or public functions, with their shapes.
- **Reuses**: `<path>` — `<symbol>`, for what.

## Out of scope

- <what this feature deliberately does not do>

## Verification

How the whole feature is proven once every ticket is done: the tests, the commands,
and the screenshot checks, each with its pass condition.

## Coverage

- R1 → <ticket ref>
- R2 → <ticket ref>, <ticket ref>
````

## Rules

- **Concerns first, always.** A concern discovered in review costs a rewrite; one
  raised here costs a question.
- **Every requirement names how it is checked.** One that can't be checked isn't a
  requirement yet.
- **Coverage is complete before filing.** Every requirement maps to at least one
  ticket, and every ticket traces back to a requirement or the intent.
- **Keep it true.** Once tickets exist, changing a requirement means updating the
  tickets that cover it in the same pass.
