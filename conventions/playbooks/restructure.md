# Playbook 6: Restructure

Think like a senior engineer giving working code a clean structure: separate
concerns, raise modularity, cut coupling. Behaviour stays the same.

"Clean architecture" in this deck means clean **inside vertical slices**, not
project-wide horizontal layers. See the conflicts table in the
[README](README.md).

## Order of work

1. **Pin behaviour** with tests around everything that will move.
2. **Find the tangles:** business logic mixed with I/O (HTTP, DB, filesystem,
   framework), modules that reach into each other's internals, features spread
   across many folders.
3. **Design the target shape:**
   - one folder per feature, holding its route, logic, types and tests
   - inside it, pure logic (no I/O, easy to test) separate from the edges that
     talk to the framework, database and network
   - dependencies point inward: logic never imports the framework or the DB
     client; edges pass what logic needs
   - a small public interface per module; everything else private
   - shared code only where two features really use it
4. **Move in small steps**, tests green after each commit.

## Result

- New folder structure
- Architecture description (what lives where, which way dependencies point)
- Refactored code, as small behaviour-preserving commits

## Rules that matter here

- No new layers, base classes or interfaces with a single implementation unless
  a test or a second consumer needs them.
- If the project's AGENTS.md chose a different shape, follow it.
- Deck tools: `codebase-design`, `safe-refactor`, `blast-radius`.
