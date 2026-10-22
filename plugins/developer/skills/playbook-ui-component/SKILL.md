---
name: playbook-ui-component
description: UI component mode. Use when building a reusable, production-grade UI component - props design, every state (loading, empty, error), accessibility to WCAG 2.2 AA, responsive behaviour, tests and usage examples.
---

# Playbook: UI component

Think like a senior frontend engineer building a component other people will
reuse: accessible, responsive, and correct in every state.

**Rules first.** The user's request wins, then the project's AGENTS.md and ADRs,
then the Dev Deck conventions (code-style, contract, commits), then this
playbook. If this playbook seems to conflict with a higher rule, follow the rule
and say so.

## Order of work

1. **Check what exists.** Reuse or extend the project's design system and
   existing components before making a new one.
2. **Design the API (props):** the smallest set that covers real uses.
   Controlled and uncontrolled where it matters, sensible defaults, no boolean
   pile-ups (prefer a `variant` or composition). Spread remaining native
   attributes onto the root element. React 19: take `ref` as a plain prop; don't
   add `forwardRef`. To change the rendered element, prefer composition
   (`asChild`/slot) over an `as` prop.
3. **List every state:** loading, empty, error (with a retry), disabled,
   overflowing content (long text, many items), slow network, and no data. For
   loading, show nothing under 1 s, a skeleton for a page or a spinner for one
   part from 1 to 10 s, and a progress bar beyond 10 s.
4. **Accessibility (WCAG 2.2 AA):** semantic elements first. No ARIA is better
   than bad ARIA; for custom widgets, follow the WAI-ARIA APG pattern and its
   keyboard model.
   - Full keyboard use. Focus is always visible and never fully hidden by sticky
     headers or footers. Dialogs move focus in and give it back on close.
   - Every control has an accessible name.
   - Announce async changes without moving focus: an empty `role="status"`
     region present from first render; `role="alert"` only for errors.
   - Contrast: 4.5:1 for text; 3:1 for large text, control edges and focus
     indicators.
   - Honour `prefers-reduced-motion`: drop or shorten motion that isn't needed.
5. **Responsive:** works at 320 CSS px wide (400% zoom) with no page-level
   horizontal scroll; only tables, maps and code may scroll inside their own
   box. Hit areas at least 44×44 CSS px on touch (padding counts), never below
   24×24.
6. **Build and test:** behaviour tests from the user's side (query by role, then
   label, then text; test IDs last), an automated axe check, and one manual
   keyboard pass. Axe finds about half of all issues; passing it is a floor.

## Result

- Component architecture (parts and how they compose)
- Props design, with types
- Implementation
- Usage examples covering the main states

## Rules that matter here

- Styling and tokens come from the project's design system, never hard-coded.
- Server data comes from the project's data layer (for example TanStack Query),
  not fetched inside presentational components.
- Done means the house definition of done, including an independent review.
- Related skills: the designer deck (`impeccable`, `fortify`, `break-ui`,
  `evaluate`, `include`) for critique and accessibility.
