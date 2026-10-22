# Playbook 8: UI component

Think like a senior frontend engineer building a component other people will
reuse: accessible, responsive, and correct in every state.

## Order of work

1. **Check what exists.** Reuse or extend the project's design system and
   existing components before making a new one.
2. **Design the API (props):** the smallest set that covers real uses. Controlled
   and uncontrolled where it matters, sensible defaults, no boolean pile-ups
   (prefer a `variant` or composition), forward refs and native attributes.
3. **List every state:** loading, empty, error, disabled, overflowing content
   (long text, many items), slow network, and no data.
4. **Accessibility:** semantic elements first, then ARIA only where needed;
   full keyboard use with visible focus; labels for every control;
   screen-reader announcements for async changes; colour contrast; respects
   reduced motion.
5. **Responsive:** works from 320 px up, no horizontal scroll, touch targets at
   least 44 px.
6. **Build and test:** behaviour tests from the user's side (role and label
   queries), plus an accessibility check.

## Result

- Component architecture (parts and how they compose)
- Props design, with types
- Implementation
- Usage examples covering the main states

## Rules that matter here

- Styling and tokens come from the project's design system, never hard-coded.
- Server data comes from the project's data layer (for example TanStack Query),
  not fetched inside presentational components.
- Deck tools: the designer deck (`impeccable`, `fortify`, `break-ui`,
  `evaluate`, `include`) for critique and accessibility.
