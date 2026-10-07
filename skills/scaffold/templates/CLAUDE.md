# Project

Timed build: a full-stack app built against the clock. Scope lives in SPEC.md; read it before starting
any feature (it is created by /spec when the brief arrives).
The team is new to Java and React: after each change, explain what you did in 3 lines or fewer.

## Stack
- backend/: Spring Boot <BOOT>, Java <JAVA>, Maven wrapper, Spring Web MVC + Data JPA + H2 (in-memory) +
  Validation + DevTools. Package com.example.app, one package per feature (entity, repository,
  service, controller), like `health/`. Use Java records for DTOs. Never return entities from
  controllers. No Lombok.
- frontend/: React + TypeScript on Vite, Tailwind CSS, Vitest + Testing Library. Call the API with
  relative URLs (`/api/...`) through the Vite proxy; never call localhost:8080 directly.

## Commands (Windows, PowerShell)
- Backend run: `cd backend; .\mvnw.cmd spring-boot:run`   (port 8080; use `.\mvnw.cmd`, not `./mvnw`)
- Backend test: `cd backend; .\mvnw.cmd test`
- Frontend run: `cd frontend; npm run dev`   (port 5173, open http://localhost:5173)
- Frontend test / lint / build: `npm test`, `npm run lint`, `npm run build`
- Database browser: http://localhost:8080/h2-console (JDBC URL `jdbc:h2:mem:appdb`, user `sa`)

## How we work
- One feature at a time, top to bottom: entity, endpoint, React page, tests on both sides.
- After each feature: run the tests, check the page in the browser, then commit.
- Simplest thing that works. No new dependencies without asking.
- Work on main. One-line commit messages. After committing, show `git log --oneline -1` as proof.
- If something fails twice, stop and explain instead of trying a third approach.
- Match the existing code style. Don't run formatters or tools that aren't installed in the project.

## Known traps
- Spring Boot 4 moved test annotations: `org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest`
  and `...webmvc.test.autoconfigure.AutoConfigureMockMvc`. Older imports don't compile.
- DevTools restarts on recompiled classes only. After changing application.properties, restart the backend.
- H2 is in memory: data is gone after every restart. Put demo data in `backend/src/main/resources/data.sql`.
- A 204 No Content response has no body; don't call `res.json()` on it.
- PATCH requests with optional fields: `@NotBlank` also rejects a missing field. Use
  `@Pattern(regexp = "(?s).*\\S.*")` when a field is optional but must not be blank if sent.
- Frontend test cleanup runs from `src/test-setup.ts`; keep it there.
- In tests, wait for the new element (`findByText`) before checking a list's order.
