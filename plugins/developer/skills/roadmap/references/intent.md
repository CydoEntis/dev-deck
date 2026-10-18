# Intent

Why a piece of work exists and what is true once it is done, written in the words of the
person who asked. Keep it short enough to read in one sitting: an intent nobody
rereads stops being true without anyone noticing.

It says nothing about implementation. That goes in the spec, if there is one, and in
the tickets.

````markdown
# Intent: <short title>

Type: feature | change | bug | task
Author: <who asked> · Status: draft | accepted | done | superseded by [<title>](<path>)
Date: <YYYY-MM-DD> · Plan: [<phase>](<path>#<anchor>)   ← only when there is a plan

## Problem

What is wrong now, in the world rather than in the code, in the author's words.
Concrete, and measured where possible: "finding a note from last month takes a
minute of scrolling", not "search is hard".

- Bug: actual versus expected, and where the expected behaviour is written down.
- Change: what works today, why it no longer fits, and the decision it overrides.
- Task: the cost to the people working on the code.

## Proposed outcome

What is true once this is done, observable from outside, in a sentence or two.

## Affected users and systems

Who is touched, and which surfaces and systems have to move. Name them.

## Constraints

What may not change, and what is already decided. Link ADRs and glossary terms.

## Out of scope

The adjacent things this does not do.

## Open questions

One per line. **This section must be empty before any ticket exists.**

## Tickets

<ticket refs, in order; filled in after filing>
````

## Rules

- **The author's words, not yours.** Tidy them, but don't translate them into
  jargon. The author has to recognise the Problem as their own. If a doc in the repo
  already states the problem, quote it with a link, and have the author confirm it.
- **Accepted means the author said so.** You draft it; the author accepts it.
- **Open questions are load-bearing.** An unanswered question that reaches a ticket
  has silently become a requirement, and nobody finds out until the built thing is
  wrong. Each one is answered, deferred, or split off, by the user.
- **Superseding, not rewriting.** When the goal itself changes, write a new intent
  and mark the old one superseded. Clarifying wording is an edit.
