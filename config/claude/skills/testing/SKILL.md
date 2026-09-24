---
name: testing
description: Write, fix or plan tests across the user's stacks — Vitest + React Testing Library and Playwright for TypeScript projects, Angular (Jest/Karma → Vitest) and xUnit for the .NET day job. Use when adding tests, debugging failing tests, or setting up a test runner.
---

# Testing

The TypeScript/React baseline (Vitest config, React Testing Library patterns,
Next.js route and server-action tests, mocking, Playwright, file naming, run
commands) lives in `~/.claude/rules/testing.md` — **follow it; don't restate
it**. This skill adds the workflow plus the stacks that file doesn't cover.

## Workflow

1. Find the existing runner and conventions first (`package.json` scripts,
   `vitest.config.*`, `karma.conf.js`, `jest.config.*`, `*.csproj` test
   projects). Match them — don't introduce a second runner.
2. Test behaviour through the public surface, not internals. One behaviour
   per test; name it as the behaviour (`returns 400 for invalid input`).
3. Cover the error path and one boundary for anything non-trivial.
4. Run the tests and show the real output. A test that was never run doesn't
   count. If one fails, fix the code or the test deliberately — never delete
   or `.skip` a test to get green without saying so.

## Angular (day job)

- Newer projects: Vitest via `@analogjs/vitest-angular`, or Jest via
  `jest-preset-angular`. Legacy: Karma + Jasmine — keep it unless migration
  is the task.
- Use `TestBed` with **standalone components** where the project does:
  ```ts
  await TestBed.configureTestingModule({ imports: [UserCardComponent] }).compileComponents();
  const fixture = TestBed.createComponent(UserCardComponent);
  fixture.componentRef.setInput('user', mockUser);
  fixture.detectChanges();
  ```
- Prefer **Angular Testing Library** (`@testing-library/angular`, `render`,
  `screen.getByRole`) for components — same philosophy as React Testing Library.
- Services: inject real instances, mock HTTP with `provideHttpClientTesting()`
  and `HttpTestingController`; always `httpMock.verify()` in `afterEach`.
- RxJS: `fakeAsync` + `tick()` for timers; marble tests (`TestScheduler`) for
  complex streams; for signals, just read the signal after acting.

## .NET / C# (day job)

- **xUnit** is the default; match the project if it uses NUnit/MSTest.
- Arrange / Act / Assert; `[Fact]` for single cases, `[Theory]` +
  `[InlineData]` for tables.
- Assertions: plain `Assert.*`, or FluentAssertions if already referenced
  (`result.Should().Be(...)`) — don't add it to a project that doesn't use it.
- Mocking: whatever the project uses (Moq / NSubstitute); mock at boundaries
  (repositories, HTTP clients, clocks), not domain logic.
- API tests: `WebApplicationFactory<Program>` for real HTTP-level integration
  tests; replace external dependencies in `ConfigureTestServices`.
- EF Core: prefer **Testcontainers** (real SQL Server/Postgres) over the
  InMemory provider, which hides query-translation bugs.
- Run: `dotnet test` (filter with `--filter "FullyQualifiedName~UserService"`).

## Mobile (Expo)

Jest + React Native Testing Library (`jest-expo` preset); same query
philosophy (`getByRole`, `getByText`). Keep native modules mocked in
`jest.setup.ts`.
