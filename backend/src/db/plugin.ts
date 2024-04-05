import { FastifyPluginCallback } from "fastify";
import { fastifyPlugin } from "fastify-plugin";
import { drizzle, type PostgresJsDatabase } from "drizzle-orm/postgres-js";
import { migrate } from "drizzle-orm/postgres-js/migrator";
import postgres from "postgres";

import * as schema from "./schema";

export type FastifyDrizzleOptions = {
  connectionString: string;
};

const plugin: FastifyPluginCallback<FastifyDrizzleOptions> = (
  fastify,
  opts: FastifyDrizzleOptions,
  next,
) => {
  if (!opts.connectionString) {
    return next(new Error("connectionString is required"));
  }

  // Hook postgres notices to the Fastify logger.
  const onnotice = (msg: postgres.Notice) => {
    fastify.log.info(msg);
  };

  const pool = postgres(opts.connectionString, {
    onnotice,
  });

  const db = drizzle(pool, { schema });

  fastify.decorate("db", db).addHook("onReady", async () => {
    fastify.log.info("Database migration started");

    // Migration requires a single connection to work.
    const client = postgres(opts.connectionString, { max: 1, onnotice });
    // Notice that the path must be relative to the application root.
    await migrate(drizzle(client), {
        migrationsFolder: "./src/db/migrations",
    });

    fastify.log.info("Database migration finished");
  });

  next();
};

export const fastifyDrizzle = fastifyPlugin(plugin);
export type Database = PostgresJsDatabase<typeof schema>;
