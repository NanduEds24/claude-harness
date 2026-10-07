---
name: spec
description: Turn a brief into SPEC.md with a ranked feature list. Use at the start of a timed build or when the brief changes.
---

1. Read the brief. Ask at most 3 questions, only where the answer changes what gets built.
2. Write SPEC.md with:
   - Goal: one sentence, the user and the problem.
   - Must-haves: 3 to 5 features, each with a one-line "done when", including what happens on
     empty, invalid and edge cases.
   - Nice-to-haves: ranked, each small.
   - Out of scope: what we deliberately won't build.
   - Entities and API endpoints: a short list (method, path, purpose).
   - React pages: a short list.
   - Build order: the must-haves as vertical slices, smallest first.
   - Demo script: the 5 clicks that show it off.
3. Stop and wait for approval. Don't write code.
