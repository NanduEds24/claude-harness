---
name: verify
description: Check that the current feature really works. Use after finishing each feature, before committing.
---

1. Run `.\mvnw.cmd test` in backend/ and `npm test`, `npm run lint`, `npm run build` in frontend/.
   Fix failures first.
2. Make sure both servers are running (8080 and 5173). If a port is busy, check what holds it before
   starting another server; it may be the user's own.
3. Exercise the feature through the running app: call its endpoints through
   http://localhost:5173/api/..., and if a browser tool is available, open http://localhost:5173 and go
   through the feature's "done when" from SPEC.md, checking the console and backend log for errors.
4. Report what you checked and what you saw in 3 lines or fewer. Say plainly if anything failed or
   could not be checked (for example, no browser available), so the user knows to look.
