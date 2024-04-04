# vault-service

## Getting started

**Install dependencies**

```bash
bun install
```

**Run the server**

```bash
bun run index.ts
```

**Updating the database schema**

1. Update the tables in `src/db/schema.ts`.
2. Run `bunx drizzle-kit generate:pg` to generate the SQL migrations. 
