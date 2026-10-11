# Web console deployment

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../README.md) · [Overview](../SYSTEM_OVERVIEW.md) · [AWS architecture](../AWS_ARCHITECTURE.md) · [AWS guide](../AWS_SETUP_GUIDE.md) · [API](../backend/API.md) · [Environment](../ENVIRONMENT_VARIABLES.md) · [Contracts](../CONTRACTS.md)

**Web docs:** [Runbook](../../frontend/README.md) · [Index](README.md) · [Architecture](ARCHITECTURE.md) · [Pages](PAGES.md) · [Design system](DESIGN_SYSTEM.md) · **Deployment**

<!-- nav:end -->

<p align="center">
<img src="https://img.shields.io/badge/Next.js-15-000000?logo=nextdotjs&logoColor=white" alt="Next.js">
<img src="https://img.shields.io/badge/runs%20on-Amazon%20EC2-FF9900?logo=amazonec2&logoColor=white" alt="EC2">
<img src="https://img.shields.io/badge/or-Amplify%20Hosting-FF9900?logo=awsamplify&logoColor=white" alt="Amplify">
<img src="https://img.shields.io/badge/port-3000-6E7781" alt="Port 3000">
</p>

How the Next.js officer console (`frontend/`) is built and served.

---

## Targets

| Target | How |
|---|---|
| **EC2 + PM2** (live) | `pnpm build` then `pnpm start` on port 3000 under PM2 |
| **Amplify Hosting** | Connect the repo; [`amplify.yml`](../../frontend/amplify.yml) builds with `appRoot: frontend` |

---

## Steps (EC2)

1. Build with the public backend URL (it is baked in at build time):
   ```bash
   make frontend API_URL=http://<server>:8000
   ```
2. Serve under PM2: the `hawa-frontend` app in [`ecosystem.config.cjs`](../../infrastructure/ec2/ecosystem.config.cjs).
3. Security group: open **3000**, or put Caddy in front for HTTPS ([`Caddyfile`](../../infrastructure/ec2/Caddyfile)).
4. Verify: open `/`, `/map`, `/forecast`, `/plans`, `/what-if`, `/impact`, `/fleet`, `/alerts`, `/route`.

**Update:** `git pull && make frontend API_URL=...` then `pm2 restart hawa-frontend`.

---

## Steps (Amplify Hosting)

1. **Amplify** → **Create new app** → **Host web app** → connect the repository and branch.
2. Amplify detects `frontend/amplify.yml` (pnpm install, `pnpm build`, artifacts `.next`).
3. **Environment variables:** `NEXT_PUBLIC_API_URL=https://api.<domain>` (must be HTTPS when the site is HTTPS).
4. **Save and deploy**; redeploy after changing any `NEXT_PUBLIC_*` value.

---

## Configuration (`frontend/.env.local` or Amplify variables)

| Variable | Effect |
|---|---|
| `NEXT_PUBLIC_API_URL` | Backend base URL, no trailing slash, no `/v1`. Empty = built-in mock API in the browser |
| `NEXT_PUBLIC_COGNITO_USER_POOL_ID`, `NEXT_PUBLIC_COGNITO_CLIENT_ID` | Cognito sign-in on `/login` |

- Every response is validated against the zod contracts in `src/contracts/`.
- Check a backend against them: `API_URL=http://<server>:8000 pnpm dlx tsx scripts/verify_backend_contracts.ts`.

Full list: [environment variables](../ENVIRONMENT_VARIABLES.md#3-web-console-frontendenvlocal).

---

## Related

- [Web architecture](ARCHITECTURE.md) · [Web runbook](../../frontend/README.md) · [API reference](../backend/API.md)

<!-- footer:start -->

---

**Related across the project:** [Backend deployment](../backend/DEPLOYMENT.md) · [Domain and HTTPS](../AWS_SETUP_GUIDE.md#11-optional-domain-and-https) · [Web variables](../ENVIRONMENT_VARIABLES.md#3-web-console-frontendenvlocal)

[Back to top](#web-console-deployment) · [Docs hub](../README.md) · [Project README](../../README.md)

<!-- footer:end -->
