import { type DrizzleConfig as OgDrizzleConfig } from 'drizzle-orm';
import {
  PostgresJsDatabase,
  drizzle as ogDrizzle,
} from 'drizzle-orm/postgres-js';
import { migrate as ogMigrate } from 'drizzle-orm/postgres-js/migrator';
import postgres from 'postgres';

import * as schema from './schema';

export type DrizzleConfig = Omit<OgDrizzleConfig<typeof schema>, 'schema'>;
export type Database = PostgresJsDatabase<typeof schema>;

export function drizzle(client: postgres.Sql<{}>, config: DrizzleConfig = {}) {
  return ogDrizzle(client, { schema, ...config });
}

export async function migrate(
  client: postgres.Sql<{}>,
  config: DrizzleConfig = {},
) {
  // Notice that the path must be relative to the application root.
  return await ogMigrate(drizzle(client, config), {
    migrationsFolder: './src/db/migrations',
  });
}
