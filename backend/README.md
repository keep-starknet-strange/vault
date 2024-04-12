# vault-service

## Getting started

**Install dependencies**

```bash
pnpm install
```

**Run the server**

```bash
pnpm start
```

**Run tests**

```bash
pnpm test
```

If you get an error like `Failed to connect to Reaper` you must set the following environment variable.

```bash
export TESTCONTAINERS_HOST_OVERRIDE=127.0.0.1
```

**Updating the database schema**

1. Update the tables in `src/db/schema.ts`.
2. Run `pnpm drizzle:generate` to generate the SQL migrations.
