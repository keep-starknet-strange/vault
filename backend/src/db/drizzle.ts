import type { DrizzleConfig as OgDrizzleConfig } from 'drizzle-orm';
import { type PostgresJsDatabase, drizzle as ogDrizzle } from 'drizzle-orm/postgres-js';
import { migrate as ogMigrate } from 'drizzle-orm/postgres-js/migrator';
import type postgres from 'postgres';

import * as schema from './schema';

export type DrizzleConfig = Omit<OgDrizzleConfig<typeof schema>, 'schema'>;
export type Database = PostgresJsDatabase<typeof schema>;

// biome-ignore lint: this is good enough
export function drizzle(client: postgres.Sql<{}>, config: DrizzleConfig = {}) {
  return ogDrizzle(client, { schema, ...config });
}

export async function migrate(
  // biome-ignore lint: this is good enough
  client: postgres.Sql<{}>,
  config: DrizzleConfig = {},
) {
  // Notice that the path must be relative to the application root.
  return await ogMigrate(drizzle(client, config), {
    migrationsFolder: './src/db/migrations',
  });
}
