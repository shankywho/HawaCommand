# Linting, Quality and Testing

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../README.md) · [Overview](../SYSTEM_OVERVIEW.md) · [AWS architecture](../AWS_ARCHITECTURE.md) · [AWS setup](../AWS_SETUP_GUIDE.md) · [API](../backend/API.md) · [Environment](../ENVIRONMENT_VARIABLES.md) · [Contracts](../CONTRACTS.md)

**Web docs:** [Runbook](../../frontend/README.md) · [Index](README.md) · [Context](CONTEXT.md) · [Architecture](ARCHITECTURE.md) · [Pages](PAGES.md) · [Design system](DESIGN_SYSTEM.md) · **Quality** · [Structure](STRUCTURE.md) · [Plan](PLAN.md) · [Design export](../../frontend/design/EXPORT_NOTES.md)

<!-- nav:end -->

> **Status (as built).**
> - **Configured:** the scripts in `frontend/package.json` are `dev`, `build`, `start`, `lint` (`next lint`) and `typecheck` (`tsc --noEmit`). `tsconfig.json` is strict. `scripts/verify_backend_contracts.ts` checks 14 backend endpoints against the zod schemas.
> - **Not committed:** there is no ESLint config, so `pnpm lint` opens the interactive setup and exits 1. There is also no Prettier, Husky, lint-staged, commitlint, Vitest, Playwright or `.github/` CI.
>
> Everything below that uses those tools is the target setup (Planned).


Purpose: the quality gates for `frontend/`. **Linting is a hard requirement.** This file gives the complete config sketches (ESLint 9 flat config, Prettier, tsconfig, git hooks, CI), the testing strategy, the review checklist and the Definition of Done.

Related: [README](README.md) · [CONTEXT](CONTEXT.md) · [ARCHITECTURE](ARCHITECTURE.md) · [STRUCTURE](STRUCTURE.md) · [PAGES](PAGES.md) · [DESIGN_SYSTEM](DESIGN_SYSTEM.md) · [PLAN](PLAN.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md) · [../backend/API.md](../backend/API.md)

---

## 1. Principles

1. **Zero warnings.** `pnpm lint` runs with `--max-warnings 0`. A rule is either `error` or `off`, never `warn`. That way nobody learns to ignore output.
2. **Types are generated, never hand-written** for API shapes (`pnpm gen:api`). A contract change shows up as a type error, not a runtime surprise.
3. **Architecture is enforced by lint.** Restricted imports keep the generated client, the map libraries and the mocks in their folders (§6).
4. **Fast local feedback, full checks in CI.** Pre-commit touches only staged files, pre-push runs typecheck and unit tests, and CI runs everything.
5. **Every gate is runnable locally** with the same command CI uses.
6. **Disabling a rule inline** (`// eslint-disable-next-line rule -- reason`) requires the rule name and a reason (`eslint-comments/require-description`-style review rule). Blanket disables are forbidden.

## 2. Tooling overview

| Tool | Role | Command |
|---|---|---|
| ESLint 9 (flat config) + typescript-eslint (type-aware) | Correctness, a11y, hooks, imports, architecture | `pnpm lint` |
| Prettier + `prettier-plugin-tailwindcss` | Formatting + Tailwind class order | `pnpm format` / `pnpm format:check` |
| TypeScript (`tsc --noEmit`) | Types (strict set) | `pnpm typecheck` |
| openapi-typescript | API types from `/openapi.json` | `pnpm gen:api` / `pnpm gen:api:check` |
| Vitest + React Testing Library + MSW | Unit, component, contract tests | `pnpm test`, `pnpm test:coverage` |
| Playwright + `@axe-core/playwright` | e2e golden path, a11y | `pnpm e2e` |
| Husky + lint-staged + commitlint | Git hooks | automatic |
| knip | Dead files, exports, dependencies | `pnpm knip` (advisory) |
| `scripts/check-i18n.mjs` | en/hi key parity | `pnpm i18n:check` |

Next.js 16 removed `next lint`, and `next build` no longer lints. Linting is its own step everywhere.

## 3. `package.json` (scripts and dev dependencies)

```jsonc
{
  "name": "hawacommand-web",
  "private": true,
  "type": "module",
  "packageManager": "pnpm@<latest-stable>",      // pinned by `corepack use pnpm@latest`
  "engines": { "node": ">=22" },
  "scripts": {
    "prepare": "cd .. && husky frontend/.husky",
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "eslint . --max-warnings 0",
    "lint:fix": "eslint . --fix",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "typecheck": "tsc --noEmit",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage",
    "e2e": "playwright test",
    "e2e:ui": "playwright test --ui",
    "e2e:stack": "E2E_TARGET=stack playwright test --grep @golden",
    "gen:api": "node scripts/gen-api.mjs",
    "gen:api:check": "node scripts/gen-api.mjs --check",
    "mock:api": "tsx tests/mock-api/server.ts",
    "i18n:check": "node scripts/check-i18n.mjs",
    "knip": "knip",
    "map:icons": "node scripts/build-map-icons.mjs",
    "basemap:fetch": "node scripts/fetch-basemap.mjs",
    "check": "pnpm format:check && pnpm lint && pnpm typecheck && pnpm i18n:check && pnpm test"
  },
  "devDependencies": {
    // all at latest stable, pinned in pnpm-lock.yaml
    "eslint": "…", "@eslint/js": "…", "typescript-eslint": "…", "globals": "…",
    "@next/eslint-plugin-next": "…", "eslint-plugin-react": "…", "eslint-plugin-react-hooks": "…",
    "eslint-plugin-jsx-a11y": "…", "eslint-plugin-import-x": "…", "eslint-import-resolver-typescript": "…",
    "eslint-plugin-simple-import-sort": "…", "eslint-plugin-unused-imports": "…",
    "@tanstack/eslint-plugin-query": "…", "@vitest/eslint-plugin": "…", "eslint-plugin-playwright": "…",
    "eslint-plugin-testing-library": "…", "eslint-config-prettier": "…",
    "prettier": "…", "prettier-plugin-tailwindcss": "…",
    "typescript": "…", "openapi-typescript": "…", "babel-plugin-react-compiler": "…",
    "vitest": "…", "@vitest/coverage-v8": "…", "@vitejs/plugin-react": "…", "vite-tsconfig-paths": "…",
    "jsdom": "…", "@testing-library/react": "…", "@testing-library/user-event": "…", "@testing-library/jest-dom": "…",
    "msw": "…", "@mswjs/http-middleware": "…", "ws": "…", "tsx": "…", "ajv": "…", "ajv-formats": "…",
    "@playwright/test": "…", "@axe-core/playwright": "…",
    "husky": "…", "lint-staged": "…", "@commitlint/cli": "…", "@commitlint/config-conventional": "…",
    "knip": "…"
  }
}
```

The `prepare` script installs Husky hooks from `frontend/.husky` while git's root is the repository root (Husky's documented setup for projects outside the git root).

## 4. ESLint 9 flat config (`eslint.config.mjs`)

```js
// eslint.config.mjs
import { defineConfig, globalIgnores } from "eslint/config";
import js from "@eslint/js";
import tseslint from "typescript-eslint";
import globals from "globals";
import nextPlugin from "@next/eslint-plugin-next";
import react from "eslint-plugin-react";
import reactHooks from "eslint-plugin-react-hooks";
import jsxA11y from "eslint-plugin-jsx-a11y";
import importX from "eslint-plugin-import-x";
import { createTypeScriptImportResolver } from "eslint-import-resolver-typescript";
import simpleImportSort from "eslint-plugin-simple-import-sort";
import unusedImports from "eslint-plugin-unused-imports";
import pluginQuery from "@tanstack/eslint-plugin-query";
import vitest from "@vitest/eslint-plugin";
import playwright from "eslint-plugin-playwright";
import testingLibrary from "eslint-plugin-testing-library";
import prettier from "eslint-config-prettier/flat";

// ---------- architecture boundaries (see §6) ----------
const MAP_LIBS = ["deck.gl", "@deck.gl/*", "maplibre-gl", "react-map-gl", "react-map-gl/*", "pmtiles", "@protomaps/*"];
const baseRestricted = {
  paths: [
    { name: "next/router", message: "App Router only: use next/navigation or @/lib/i18n/navigation." },
    { name: "next/link", message: "Use Link from @/lib/i18n/navigation (locale-aware)." },
    { name: "openapi-fetch", message: "Use the typed client from @/lib/api." },
    { name: "lodash", message: "Import a single function (lodash-es/<fn>) or write it." },
    { name: "react-map-gl", message: "Import react-map-gl/maplibre inside src/components/map only." },
  ],
  patterns: [
    { group: ["@/lib/api/generated", "@/lib/api/generated/*", "**/lib/api/generated/**"], message: "Generated API code is internal to src/lib/api. Import from @/lib/api." },
    { group: ["@/lib/api/*", "!@/lib/api/index"], message: "Import from @/lib/api (its index is the public surface)." },
    { group: MAP_LIBS, message: "Map libraries only inside src/components/map/** (keeps them in the lazy chunk)." },
    { group: ["@/mocks", "@/mocks/*"], message: "Mocks load only via src/mocks/enable.ts or in tests." },
    { group: ["../../*"], message: "Use the @/ alias instead of deep relative imports." },
  ],
};
const without = (r, drop) => ({
  paths: r.paths.filter((p) => !drop.includes(p.name)),
  patterns: r.patterns.filter((p) => !p.group.some((g) => drop.includes(g))),
});

export default defineConfig([
  globalIgnores([
    ".next/**", "out/**", "coverage/**", "playwright-report/**", "test-results/**",
    "public/**", "src/lib/api/generated/**", "next-env.d.ts",
  ]),

  // ---------- base ----------
  js.configs.recommended,
  tseslint.configs.strictTypeChecked,
  tseslint.configs.stylisticTypeChecked,
  {
    languageOptions: {
      parserOptions: { projectService: true, tsconfigRootDir: import.meta.dirname },
      globals: { ...globals.browser, ...globals.node },
    },
    linterOptions: { reportUnusedDisableDirectives: "error" },
  },
  { files: ["**/*.{js,mjs,cjs}"], extends: [tseslint.configs.disableTypeChecked] },

  // ---------- React, hooks (incl. React Compiler rules), a11y, Next ----------
  {
    files: ["**/*.{ts,tsx}"],
    ...react.configs.flat.recommended,
    settings: { react: { version: "detect" } },
  },
  react.configs.flat["jsx-runtime"],
  // eslint-plugin-react-hooks v6+ ships the React Compiler-derived rules (purity, refs, immutability,
  // set-state-in-render, static-components, …). Preset key by major: `configs.flat.recommended` (v7)
  // or `configs["recommended-latest"]` (v5/v6). Check the installed README.
  reactHooks.configs.flat.recommended,
  jsxA11y.flatConfigs.strict,
  {
    files: ["**/*.{ts,tsx}"],
    plugins: { "@next/next": nextPlugin },
    rules: { ...nextPlugin.configs.recommended.rules, ...nextPlugin.configs["core-web-vitals"].rules },
  },

  // ---------- imports ----------
  importX.flatConfigs.recommended,
  importX.flatConfigs.typescript,
  {
    settings: { "import-x/resolver-next": [createTypeScriptImportResolver({ alwaysTryTypes: true })] },
    plugins: { "simple-import-sort": simpleImportSort, "unused-imports": unusedImports },
    rules: {
      "simple-import-sort/imports": "error",
      "simple-import-sort/exports": "error",
      "import-x/order": "off",
      "import-x/no-duplicates": "error",
      "import-x/no-cycle": ["error", { maxDepth: 4, ignoreExternal: true }],
      "import-x/no-default-export": "error",
      "import-x/consistent-type-specifier-style": ["error", "prefer-top-level"],
      "import-x/no-named-as-default-member": "off",
      "@typescript-eslint/no-unused-vars": "off",
      "unused-imports/no-unused-imports": "error",
      "unused-imports/no-unused-vars": ["error", {
        args: "after-used", argsIgnorePattern: "^_", varsIgnorePattern: "^_",
        caughtErrors: "all", caughtErrorsIgnorePattern: "^_", ignoreRestSiblings: true,
      }],
    },
  },

  // ---------- TanStack Query ----------
  ...pluginQuery.configs["flat/recommended"],

  // ---------- project rules ----------
  {
    files: ["**/*.{ts,tsx}"],
    rules: {
      "@typescript-eslint/no-floating-promises": ["error", { ignoreVoid: true }],
      // React 19 actions and transitions accept async functions, so async JSX attributes are allowed.
      "@typescript-eslint/no-misused-promises": ["error", { checksVoidReturn: { attributes: false } }],
      "@typescript-eslint/switch-exhaustiveness-check": ["error", {
        considerDefaultExhaustiveForUnions: false, requireDefaultForNonUnion: true,
      }],
      "@typescript-eslint/consistent-type-imports": ["error", { prefer: "type-imports", fixStyle: "separate-type-imports" }],
      "@typescript-eslint/consistent-type-exports": ["error", { fixMixedExportsWithInlineTypeSpecifier: false }],
      "@typescript-eslint/no-explicit-any": "error",
      "@typescript-eslint/no-non-null-assertion": "error",
      "@typescript-eslint/no-unnecessary-condition": ["error", { allowConstantLoopConditions: true }],
      "@typescript-eslint/restrict-template-expressions": ["error", { allowNumber: true }],
      "@typescript-eslint/no-confusing-void-expression": ["error", { ignoreArrowShorthand: true }],
      "@typescript-eslint/prefer-nullish-coalescing": "error",
      "@typescript-eslint/no-deprecated": "error",
      "@typescript-eslint/consistent-type-definitions": ["error", "interface"],
      "@typescript-eslint/no-restricted-types": ["error", { types: {
        "React.FC": { message: "Type props explicitly on a function component." },
      } }],
      "no-restricted-imports": ["error", baseRestricted],
      "no-restricted-syntax": ["error",
        { selector: "TSEnumDeclaration", message: "Use string literal unions (enums come from OpenAPI)." },
        { selector: "CallExpression[callee.property.name=/^toLocale(String|DateString|TimeString)$/]",
          message: "Format via @/lib/format (IST, en-IN)." },
        { selector: "NewExpression[callee.object.name='Intl']", message: "Use @/lib/format helpers." },
      ],
      "no-restricted-properties": ["error",
        { object: "window", property: "localStorage", message: "Use @/lib/storage (no tokens, prefs only)." },
        { object: "window", property: "sessionStorage", message: "Use @/lib/storage." },
      ],
      "no-restricted-globals": ["error",
        { name: "localStorage", message: "Use @/lib/storage." }, { name: "sessionStorage", message: "Use @/lib/storage." },
      ],
      "react/no-danger": "error",
      "react/jsx-no-target-blank": "error",
      "react/no-array-index-key": "error",
      "react/jsx-key": ["error", { checkFragmentShorthand: true, warnOnDuplicates: true }],
      "react/jsx-no-useless-fragment": ["error", { allowExpressions: true }],
      "react/prop-types": "off",
      "react/self-closing-comp": "error",
      "no-console": "error",
      eqeqeq: ["error", "smart"],
      "object-shorthand": "error",
    },
  },

  // ---------- scoped relaxations of the boundaries ----------
  { files: ["src/lib/api/**"],
    rules: { "no-restricted-imports": ["error", without(baseRestricted, ["openapi-fetch", "@/lib/api/generated", "@/lib/api/generated/*", "**/lib/api/generated/**", "@/lib/api/*"])] } },
  { files: ["src/components/map/**"],
    rules: { "no-restricted-imports": ["error", without(baseRestricted, MAP_LIBS)] } },
  { files: ["src/mocks/**", "src/mocks/enable.ts", "tests/**"],
    rules: { "no-restricted-imports": ["error", without(baseRestricted, ["@/mocks", "@/mocks/*", "@/lib/api/*"])] } },
  { files: ["src/lib/storage.ts"], rules: { "no-restricted-properties": "off", "no-restricted-globals": "off" } },
  { files: ["src/lib/format/**", "src/lib/i18n/**"], rules: { "no-restricted-syntax": ["error",
      { selector: "TSEnumDeclaration", message: "Use string literal unions." }] } },
  { files: ["src/lib/logger.ts"], rules: { "no-console": "off" } },

  // Next.js files that must default-export, and config files
  { files: [
      "src/app/**/{page,layout,loading,error,not-found,global-error,template,default}.tsx",
      "src/app/**/{opengraph-image,icon,sitemap,robots,manifest}.{ts,tsx}",
      "src/proxy.ts", "src/lib/i18n/request.ts",
      "*.config.{js,mjs,ts,mts}", "eslint.config.mjs", "playwright.config.ts",
    ],
    rules: { "import-x/no-default-export": "off" } },

  // ---------- tests (one object per plugin: spreading two presets into one object would overwrite `plugins`/`rules`) ----------
  { files: ["tests/unit/**/*.{ts,tsx}", "**/*.test.{ts,tsx}"],
    ...vitest.configs.recommended,
    rules: {
      ...vitest.configs.recommended.rules,
      "vitest/expect-expect": "error",
      "vitest/no-focused-tests": "error",
      "@typescript-eslint/no-unsafe-assignment": "off",   // fixtures are JSON-typed at the edge
    } },
  { files: ["tests/unit/**/*.{ts,tsx}", "**/*.test.{ts,tsx}"],
    ...testingLibrary.configs["flat/react"] },
  { files: ["tests/e2e/**/*.ts"],
    ...playwright.configs["flat/recommended"],
    rules: {
      ...playwright.configs["flat/recommended"].rules,
      "playwright/no-focused-test": "error",
      "playwright/no-wait-for-timeout": "error",
      "playwright/prefer-web-first-assertions": "error",
    } },

  // ---------- must be last: turn off stylistic rules that Prettier owns ----------
  prettier,
]);
```

Notes:
- `eslint-config-next` is **not** used. It registers `react`, `react-hooks`, `jsx-a11y` and `import`, which would clash with our own registrations ("Cannot redefine plugin"). We compose `@next/eslint-plugin-next` directly.
- Class order: **prettier-plugin-tailwindcss** is the mechanism (it supports Tailwind v4 via `tailwindStylesheet`). The classic `eslint-plugin-tailwindcss` targets Tailwind v3. If correctness rules are wanted (unknown or conflicting classes), `eslint-plugin-better-tailwindcss` may be added **with its ordering rule off**, so ESLint and Prettier never fight.
- `projectService: true` gives type-aware linting without listing tsconfigs. JS config files are linted without type information.

## 5. Key rules explained

| Rule | Why here |
|---|---|
| `@typescript-eslint/no-floating-promises` | A forgotten `await` on a mutation or `invalidateQueries` silently loses errors. Fire-and-forget must be explicit with `void` |
| `@typescript-eslint/no-misused-promises` | Stops promises in conditions and non-async callbacks (e.g. `forEach(async …)`). JSX attributes are allowed because React 19 actions are async-aware |
| `@typescript-eslint/switch-exhaustiveness-check` (`considerDefaultExhaustiveForUnions: false`) | Every `CauseLabel`, `TaskStatus` or WebSocket event type must have a case. The `default` then handles *unknown future* values neutrally (CONTRACTS §12.5), and it does not count as exhaustive |
| `@typescript-eslint/consistent-type-imports` (`separate-type-imports`) + `import-x/consistent-type-specifier-style: prefer-top-level` | Required by `verbatimModuleSyntax`. Inline `type` specifiers would leave empty runtime imports |
| `@typescript-eslint/no-explicit-any`, `no-non-null-assertion`, `no-unnecessary-condition` | Keep the generated types meaningful. `noUncheckedIndexedAccess` + no `!` forces real handling of missing data |
| `no-restricted-imports` | Architecture boundaries (§6) |
| `no-restricted-syntax` (`toLocaleString`, `new Intl.*`) | All formatting goes through `@/lib/format`, which fixes `Asia/Kolkata` and `en-IN`. This prevents UTC or browser-timezone bugs on office PCs |
| `no-restricted-properties` / `no-restricted-globals` (storage) | No tokens in web storage. Only `@/lib/storage` touches it, for preferences |
| `TSEnumDeclaration` banned | Enums come from OpenAPI as string unions. TS enums would drift and emit runtime code |
| `react/no-danger` | LLM and citizen text is untrusted (ARCHITECTURE §15) |
| `react-hooks` compiler rules | Keep components compatible with the React Compiler (`reactCompiler: true`) |
| `jsx-a11y` strict | Baseline a11y at authoring time. axe covers the runtime |
| `@tanstack/query` recommended | Exhaustive query keys, stable query client, no rest-destructuring of query results |
| `import-x/no-cycle` | Prevents `lib ↔ components` cycles that break code-splitting |
| `import-x/no-default-export` | Named exports for greppability and refactors (Next-required files exempted) |

## 6. Architecture boundaries (restricted imports)

| Import | Allowed in | Everyone else |
|---|---|---|
| `openapi-fetch`, `src/lib/api/generated/**`, `src/lib/api/*` internals | `src/lib/api/**` | `import { planQueries, type Plan } from "@/lib/api"` |
| `deck.gl`, `@deck.gl/*`, `maplibre-gl`, `react-map-gl/*`, `pmtiles`, `@protomaps/*` | `src/components/map/**` | Use `MapCanvas` or the map components |
| `@/mocks/*` | `src/mocks/**`, `src/mocks/enable.ts`, `tests/**` | Never. `enable.ts` is loaded via dynamic import only when mocking is on |
| `next/router`, `next/link` | nowhere | `@/lib/i18n/navigation` (`Link`, `useRouter`, `redirect`) |
| `window.localStorage` / `sessionStorage` | `src/lib/storage.ts` | `storage.get/set` (preferences only) |
| `Intl.*`, `toLocale*` | `src/lib/format/**`, `src/lib/i18n/**` | `formatIst`, `formatNumber`, `formatUnit`, … |
| `server-only` modules (`src/lib/auth/server.ts`, `cookies.ts`, `src/lib/api/server-client.ts`) | server components, route handlers, `proxy.ts` | Build error if imported in a client component |

## 7. Prettier

```js
// prettier.config.mjs
/** @type {import("prettier").Config & import("prettier-plugin-tailwindcss").PluginOptions} */
export default {
  printWidth: 100,
  semi: true,
  singleQuote: false,
  trailingComma: "all",
  arrowParens: "always",
  endOfLine: "lf",
  plugins: ["prettier-plugin-tailwindcss"],
  tailwindStylesheet: "./src/app/globals.css",   // Tailwind v4 entry
  tailwindFunctions: ["cn", "cva", "clsx"],
};
```

`.prettierignore`: `.next`, `coverage`, `playwright-report`, `test-results`, `pnpm-lock.yaml`, `public/mockServiceWorker.js`, `public/basemap`, `src/lib/api/generated` (formatted by `gen:api` itself), `src/mocks/fixtures/twin-tiles`.

`frontend/.gitattributes` holds `* text=auto eol=lf`, so Windows checkouts do not fail `format:check` on CRLF.

## 8. tsconfig.json

```jsonc
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "ES2023"],
    "module": "esnext",
    "moduleResolution": "bundler",
    "jsx": "preserve",                         // Next may rewrite this on first run; accept its value
    "allowJs": false,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "verbatimModuleSyntax": true,
    "noEmit": true,
    "incremental": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,

    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noPropertyAccessFromIndexSignature": true,
    "useUnknownInCatchVariables": true,
    "allowUnreachableCode": false,
    "allowUnusedLabels": false,

    "plugins": [{ "name": "next" }],
    "baseUrl": ".",
    "paths": { "@/*": ["./src/*"] },
    "types": ["vitest/globals", "@testing-library/jest-dom"]
  },
  "include": ["next-env.d.ts", "src/**/*.ts", "src/**/*.tsx", ".next/types/**/*.ts", "tests/**/*.ts", "tests/**/*.tsx", "*.config.ts", "*.config.mts"],
  "exclude": ["node_modules", ".next", "coverage"]
}
```

Known friction and the agreed fixes:
- `exactOptionalPropertyTypes` with generated types and component props: do not pass `prop={undefined}`. Spread conditionally (`{...(x ? { x } : {})}`), or declare `prop?: T | undefined` where `undefined` is meaningful. In `next.config.ts`, use conditional spreads for `output`.
- `noUncheckedIndexedAccess`: array access returns `T | undefined`. Use `.at()` with guards, or `for…of`.
- `noPropertyAccessFromIndexSignature`: use bracket access for index-signature records (tile `properties`, JSON fixtures).

## 9. Type checking

- `pnpm typecheck` runs `tsc --noEmit` over app, tests and config files. `.next/types` (Next's generated route types, including typed routes when `typedRoutes: true`) is included, so run `next build` or `next dev` once, or `next typegen` if the pinned Next offers it, before a clean typecheck in CI. The CI order below handles this.
- Contract drift: `pnpm gen:api:check` regenerates from `$API_OPENAPI_URL` into a temp dir and diffs it against `src/lib/api/generated/schema.d.ts`. It fails with the list of changed paths. It runs in CI when the backend's OpenAPI URL is reachable (compose job) and locally before integration checkpoints.

## 10. Git hooks (Husky, lint-staged, commitlint)

`frontend/.husky/pre-commit`
```sh
# Hooks run from the repo root. Only act when frontend files are staged.
git diff --cached --name-only | grep -q '^frontend/' || exit 0
cd frontend && pnpm exec lint-staged
```

`frontend/.husky/commit-msg`
```sh
case "$1" in /*) MSG="$1" ;; *) MSG="$(pwd)/$1" ;; esac   # resolve before cd
cd frontend && pnpm exec commitlint --edit "$MSG"
```

`frontend/.husky/pre-push`
```sh
cd frontend || exit 0
if git rev-parse --verify -q '@{upstream}' >/dev/null && git diff --quiet '@{upstream}' HEAD -- . ; then
  exit 0                                    # no frontend changes to push
fi
pnpm typecheck && pnpm test
```

`lint-staged.config.mjs`
```js
export default {
  "*.{ts,tsx,js,mjs,cjs}": ["eslint --fix --max-warnings 0", "prettier --write"],
  "*.{json,md,css,yml,yaml}": ["prettier --write"],
  "messages/*.json": [() => "node scripts/check-i18n.mjs"],
};
```
lint-staged matches staged files against the closest config, so only files under `frontend/` are processed.

`commitlint.config.mjs`
```js
export default {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "header-max-length": [2, "always", 100],
    "scope-enum": [1, "always", [
      "web", "marketing", "console", "map", "plans", "what-if", "impact", "forecast", "grap", "fleet",
      "alerts", "schools", "reports", "open", "auth", "ws", "api", "i18n", "a11y", "design", "e2e",
      "lint", "ci", "deps", "docs", "backend", "aiml", "app", "infra",
    ]],
  },
};
```
Scope is level 1 (a warning in commitlint, which does not block), so commits from other teams are not rejected.

**Hook ownership conflict (flag to all leads):** git has one `core.hooksPath`. Husky sets it to `frontend/.husky` on any clone where `pnpm i` has run in `frontend/`. That disables hooks installed in `.git/hooks` by other tools, such as the Python `pre-commit` framework or Flutter tooling. Until the leads choose one repo-wide hook manager (a root `.husky`, or lefthook, that dispatches per folder), our hooks exit early when no `frontend/` files are involved. The backend and app teams should know their `.git/hooks` will not run on machines that installed the web deps.

## 11. knip (dead code, optional gate)

```json
{
  "$schema": "https://unpkg.com/knip@latest/schema.json",
  "entry": ["src/proxy.ts", "src/instrumentation*.ts", "src/lib/i18n/request.ts", "scripts/*.mjs", "tests/mock-api/server.ts"],
  "project": ["src/**/*.{ts,tsx}", "scripts/**/*.mjs", "tests/**/*.{ts,tsx}"],
  "ignore": ["src/lib/api/generated/**", "src/components/ui/**"],
  "ignoreDependencies": ["@tailwindcss/postcss", "babel-plugin-react-compiler", "tw-animate-css"]
}
```
knip's Next.js plugin adds `app/**` entries automatically. It runs in CI as advisory (does not fail the build) during the hackathon and becomes a gate afterwards.

## 12. i18n and fixture checks

- `pnpm i18n:check`: every key in `en.json` exists in `hi.json` and vice versa, no `hi` value is empty, and ICU placeholders match (`{count}`, `{time}`).
- `tests/unit/i18n.parity.test.ts` runs the same checks inside Vitest, so failures show in coverage runs.
- `tests/unit/fixtures.contract.test.ts` validates every JSON fixture in `src/mocks/fixtures/` against the matching schema in `openapi.snapshot.json` (Ajv, JSON Schema 2020-12 via OpenAPI 3.1). Fixtures for proposed endpoints validate against `src/mocks/fixtures/proposed.schema.json` until the backend publishes them.

## 13. CI (GitHub Actions)

`.github/workflows/frontend.yml` (repository root):

```yaml
name: frontend
on:
  pull_request:
    paths: ["frontend/**", ".github/workflows/frontend.yml"]
  push:
    branches: [main, dev]
    paths: ["frontend/**", ".github/workflows/frontend.yml"]
  workflow_dispatch:
    inputs:
      e2e_stack:
        description: "Also run the golden path against docker compose"
        type: boolean
        default: false

concurrency:
  group: frontend-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

defaults:
  run:
    working-directory: frontend

env:
  NEXT_TELEMETRY_DISABLED: "1"
  HUSKY: "0"

jobs:
  quality:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          package_json_file: frontend/package.json
      - uses: actions/setup-node@v4
        with:
          node-version-file: frontend/.nvmrc
          cache: pnpm
          cache-dependency-path: frontend/pnpm-lock.yaml
      - run: pnpm install --frozen-lockfile
      - run: pnpm format:check
      - run: pnpm lint                      # eslint . --max-warnings 0
      - run: pnpm i18n:check
      - run: pnpm exec next typegen || true # route types for typecheck if available; build covers it otherwise
      - run: pnpm typecheck
      - run: pnpm test:coverage            # thresholds enforced in vitest.config.mts
      - run: pnpm knip
        continue-on-error: true            # advisory during the hackathon
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: coverage
          path: frontend/coverage

  build:
    needs: quality
    runs-on: ubuntu-latest
    timeout-minutes: 15
    env:
      NEXT_PUBLIC_APP_ENV: local
      NEXT_PUBLIC_API_URL: http://localhost:4010
      NEXT_PUBLIC_WS_URL: ws://localhost:4010/v1/ws
      API_URL_INTERNAL: http://localhost:4010
      NEXT_PUBLIC_BASEMAP_PMTILES_URL: /basemap/delhi.pmtiles
      NEXT_PUBLIC_BASEMAP_ASSETS_URL: /basemap/assets
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with: { package_json_file: frontend/package.json }
      - uses: actions/setup-node@v4
        with:
          node-version-file: frontend/.nvmrc
          cache: pnpm
          cache-dependency-path: frontend/pnpm-lock.yaml
      - uses: actions/cache@v4
        with:
          path: frontend/.next/cache
          key: nextcache-${{ runner.os }}-${{ hashFiles('frontend/pnpm-lock.yaml') }}-${{ hashFiles('frontend/src/**') }}
          restore-keys: nextcache-${{ runner.os }}-${{ hashFiles('frontend/pnpm-lock.yaml') }}-
      - run: pnpm install --frozen-lockfile
      - run: pnpm build
      - run: pnpm audit --prod --audit-level high
        continue-on-error: true

  e2e-mock:
    needs: quality
    runs-on: ubuntu-latest
    timeout-minutes: 25
    env:
      NEXT_PUBLIC_APP_ENV: local
      NEXT_PUBLIC_API_URL: http://localhost:4010
      NEXT_PUBLIC_WS_URL: ws://localhost:4010/v1/ws
      API_URL_INTERNAL: http://localhost:4010
      NEXT_PUBLIC_E2E: "1"
      NEXT_PUBLIC_DEMO_BANNER: "true"
      NEXT_PUBLIC_BASEMAP_PMTILES_URL: /basemap/delhi.pmtiles
      NEXT_PUBLIC_BASEMAP_ASSETS_URL: /basemap/assets
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with: { package_json_file: frontend/package.json }
      - uses: actions/setup-node@v4
        with:
          node-version-file: frontend/.nvmrc
          cache: pnpm
          cache-dependency-path: frontend/pnpm-lock.yaml
      - run: pnpm install --frozen-lockfile
      - run: pnpm exec playwright install --with-deps chromium
      - run: pnpm build
      - run: pnpm e2e                      # webServer starts mock API (:4010) + next start (:3000)
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: playwright-report
          path: |
            frontend/playwright-report
            frontend/test-results

  e2e-stack:
    if: github.event_name == 'workflow_dispatch' && inputs.e2e_stack
    needs: build
    runs-on: ubuntu-latest
    timeout-minutes: 40
    env:
      NEXT_PUBLIC_API_URL: http://localhost:8000
      NEXT_PUBLIC_WS_URL: ws://localhost:8000/v1/ws
      API_URL_INTERNAL: http://localhost:8000
      API_OPENAPI_URL: http://localhost:8000/openapi.json
      NEXT_PUBLIC_E2E: "1"
    steps:
      - uses: actions/checkout@v4
      - name: Start the whole stack
        working-directory: .
        run: docker compose up -d --wait && make seed
      - uses: pnpm/action-setup@v4
        with: { package_json_file: frontend/package.json }
      - uses: actions/setup-node@v4
        with:
          node-version-file: frontend/.nvmrc
          cache: pnpm
          cache-dependency-path: frontend/pnpm-lock.yaml
      - run: pnpm install --frozen-lockfile
      - run: pnpm gen:api:check           # contract drift vs the running backend
      - run: pnpm exec playwright install --with-deps chromium
      - run: pnpm build
      - run: pnpm e2e:stack
      - if: always()
        working-directory: .
        run: docker compose logs --no-color > compose.log; docker compose down -v
```

Branch protection on `main` and `dev` requires `quality`, `build` and `e2e-mock`.

## 14. Testing strategy

### 14.1 Pyramid

| Layer | Tool | What | Target |
|---|---|---|---|
| Pure logic | Vitest | `lib/format` (AQI breakpoints, sub-index, AQI range, GRAP from AQI, IST, units, uncertainty), `lib/ws` (backoff, heartbeat, resubscribe, 4401, polling fallback), `lib/auth` (single-flight refresh, Web Lock, roles), WS router effects, plan diff, layer builders | ≥ 95 % lines in `lib/format`; ≥ 85 % in `lib/ws`, `lib/auth` |
| Components | Vitest + RTL + MSW (node) | `AqiChip`, `UncertaintyValue` (required interval), `CauseBadge` unknown value, `AuditorComment`, `ApproveBar` states, `ApproveDialog` summary, `PlanTaskCard`, chart data transforms and `ChartFigure` table, compose-alert validation, en/hi rendering | ≥ 70 % overall |
| Contract | Vitest + Ajv | Every fixture validates against `openapi.snapshot.json` | 100 % of fixtures |
| e2e | Playwright + mock API (HTTP + WS scenario) | Flow A golden path, map, plan edit, WS resilience, marketing, open, i18n | all BUILD acceptance criteria in PAGES |
| a11y | `@axe-core/playwright` | Every route in en + hi, WCAG 2.2 AA tags | zero violations (the map canvas is excluded, and its DOM alternatives are tested) |
| Visual (optional) | `toHaveScreenshot` | Marketing sections, FanChart, SyntheticControlChart, AqiChip grid (light/dark/CVD) | stable baselines on Linux CI |

### 14.2 Vitest config

```ts
// vitest.config.mts
import react from "@vitejs/plugin-react";
import tsconfigPaths from "vite-tsconfig-paths";
import { defineConfig } from "vitest/config";

export default defineConfig({
  plugins: [tsconfigPaths(), react()],
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: ["./tests/unit/setup.ts"],       // jest-dom, MSW server listen/reset/close, intl provider
    include: ["tests/unit/**/*.test.{ts,tsx}"],
    css: false,
    restoreMocks: true,
    coverage: {
      provider: "v8",
      reporter: ["text", "lcov", "json-summary"],
      include: ["src/**"],
      exclude: ["src/lib/api/generated/**", "src/components/ui/**", "src/mocks/**", "src/app/**", "**/*.d.ts"],
      thresholds: {
        lines: 70, statements: 70, functions: 70, branches: 60,
        "src/lib/format/**": { lines: 95, statements: 95, functions: 95, branches: 90 },
        "src/lib/ws/**": { lines: 85, statements: 85, functions: 85, branches: 75 },
        "src/lib/auth/**": { lines: 85, statements: 85, functions: 85, branches: 75 },
      },
    },
  },
});
```

WebGL is not available in jsdom. Map code is tested through the **pure layer builders** (assert ids, `data` URL, `updateTriggers`, and accessor outputs on sample features) and through e2e. `map-view.tsx` is mocked in component tests.

### 14.3 MSW

- `src/mocks/handlers/*` are shared by the browser worker (dev), `setupServer` (Vitest) and the standalone mock API (Playwright, dev). There is one source of truth.
- Handler rules: return fixtures exactly as shaped in API.md; support the problem+json error paths the UI handles (`?__error=409` or scenario flags); honour `Idempotency-Key` (a repeated key returns the same response).
- WebSocket: MSW `ws.link("*/v1/ws")` in Vitest. In the mock API, a `ws` server implements subscribe/unsubscribe/ping and plays `scenarios/golden-path.json` steps on command (`POST /__mock/scenario/golden-path/next`) or on a timer.

### 14.4 Playwright

```ts
// playwright.config.ts (sketch)
import { defineConfig, devices } from "@playwright/test";
const stack = process.env.E2E_TARGET === "stack";
export default defineConfig({
  testDir: "tests/e2e",
  timeout: 60_000,
  expect: { timeout: 10_000 },
  fullyParallel: false,                         // golden path is stateful against the scenario
  retries: process.env.CI ? 1 : 0,
  reporter: [["list"], ["html", { open: "never" }]],
  use: { baseURL: "http://localhost:3000", trace: "retain-on-failure", viewport: { width: 1920, height: 1080 },
         locale: "en-IN", timezoneId: "Asia/Kolkata" },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"],
    launchOptions: { args: ["--enable-unsafe-swiftshader", "--use-angle=swiftshader"] } } }],   // software WebGL2 in CI
  webServer: [
    ...(stack ? [] : [{ command: "pnpm mock:api", port: 4010, reuseExistingServer: !process.env.CI }]),
    { command: "pnpm start", port: 3000, reuseExistingServer: !process.env.CI },
  ],
});
```

`tests/e2e/flow-a.spec.ts` (tagged `@golden`) covers:
1. **Login** as the demo officer → lands on `/console/map`, ward preselected. Assert no token is present in `localStorage`/`sessionStorage`.
2. **Map**: legend visible; `window.__hawa.map.layers()` reports twin, hotspots, trails and fleet with counts > 0; hotspot rail has ≥ 5 cards with cause + confidence; the scenario step `twin.updated` changes the as-of chip; the cell drawer shows "80 %".
3. **Forecast**: fan chart figure with P10/P50/P90 in the table view; "3 schools in spike"; Thursday pill "Stage I".
4. **Plan**: the scenario step `plan.drafted` shows the banner → open the plan; the Auditor blocking objection is visible; apply the suggestion (optimistic) → the task shows an inspection team; the What-If card has three ranges.
5. **What-If**: the range chart and both map canvases render; the "Estimated on forecast, not measured" label is visible.
6. **Approve**: ApproveBar enabled → dialog summary equals the What-If numbers → confirm → status Approved; exactly one approve request with an `Idempotency-Key`.
7. **Live**: scenario steps `task.dispatched` … `task.verified` update the statuses without a reload.
8. **Impact**: open the intervention → synthetic-control figure, spray start/stop labels, "95 % CI", injected vs recovered, Simulated badge.
9. **axe** on each page visited.

Other specs: `map.spec.ts` (keyboard cell cursor, stale banner via the scenario's old `as_of`, CVD toggle), `plan-edit.spec.ts` (422 rollback, 409 conflict dialog, blocking objection disables approve), `ws-resilience.spec.ts` (server drop → Reconnecting → resync refetch; blocked upgrade → Polling), `marketing.spec.ts` (numbers 47 / 376 / 64 % / 38.3 % present; `/hi` renders; reduced motion), `open.spec.ts` (indicative label, 429 message), `a11y.spec.ts` (every route × en/hi).

## 15. Code review checklist

Correctness and contracts
- [ ] API types come from `@/lib/api`, with no hand-written response types. `pnpm gen:api` was run if the contract changed. Fixtures updated and valid.
- [ ] Endpoint paths, enum values and WS channels match CONTRACTS §3/§6 (or are listed as proposed in ARCHITECTURE §18 with a mock).
- [ ] Unknown enum values render neutrally (switch has cases + `default`).
- [ ] Mutations: `Idempotency-Key`, `If-Match` where versioned, the right `scope`, optimistic rollback, 409/422 handled inline.
- [ ] WebSocket events map to targeted invalidations (no global invalidate), and resync keys were added for new channels.

Product rules
- [ ] No bare model point estimates: `UncertaintyValue`, a band or a whisker, with the level printed.
- [ ] `SimulatedBadge` wherever `is_simulated` or `sim_share > 0`.
- [ ] Computed AQI says "indicative". Times are IST via `@/lib/format`. Units follow CONTRACTS §1.
- [ ] No approve or dispatch path skips the confirmation dialog.

UX, a11y and i18n
- [ ] Loading, empty, error and stale states implemented as in PAGES.
- [ ] Keyboard path works. Visible focus. No colour-only meaning. Drag has button alternatives. axe clean.
- [ ] Strings in both `en.json` and `hi.json`, reviewed by a Hindi speaker. The layout holds longer Hindi text.
- [ ] Agent and citizen text rendered as plain text.

Performance and security
- [ ] Map libraries only in `src/components/map`. Heavy components lazy-loaded. No new dependency above 30 KB gzip without a note.
- [ ] Layer `data` references stable. High-frequency updates bypass React.
- [ ] No tokens or PII in storage, URLs or logs. CSP `connect-src` updated if a new host was added.

Hygiene
- [ ] `pnpm check` passes locally. Conventional commit message. PR description links the PAGES section and includes screenshots (light + dark, en + hi) for UI changes.

## 16. Definition of Done

A change is done when **all** of these hold:

1. `pnpm format:check`, `pnpm lint` (zero warnings), `pnpm typecheck`, `pnpm i18n:check` and `pnpm test` (coverage thresholds) pass locally and in CI.
2. `pnpm build` succeeds, and the route's first-load JS stays within the budget in [ARCHITECTURE §12](ARCHITECTURE.md).
3. The acceptance criteria of the relevant [PAGES](PAGES.md) section are met and covered by at least one test (unit or e2e). BUILD pages are covered by e2e.
4. Loading, empty, error, stale, simulated and offline states exist and were exercised against the mock API.
5. Uncertainty, the "indicative" label and the Simulated badge are present wherever the rules require them.
6. English and Hindi strings exist. The page was checked in `/hi` at 1366×768 and 1920×1080, in light and dark mode.
7. axe reports zero violations. The keyboard-only path was walked once by hand.
8. MSW handlers and fixtures exist for every endpoint used, shaped per API.md (or ARCHITECTURE §18 for proposed ones), and validate in the contract test.
9. No new `eslint-disable` without a rule name and reason. No `TODO` without an issue link.
10. The PR is reviewed against §15 by one other teammate. For UI changes it includes screenshots.

<!-- footer:start -->

---

[Back to top](#linting-quality-and-testing) · [Docs hub](../README.md) · [Project README](../../README.md)

<!-- footer:end -->
