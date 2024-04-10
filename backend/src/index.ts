import Fastify from 'fastify';
import { declareRoutes } from './routes';
import { fastifyDrizzle } from './db/plugin';
import dotenv from 'dotenv';
import postgres from '@fastify/postgres';

const PORT: number = parseInt(Bun.env.PORT || '8080');
dotenv.config();

export async function buildAndStartApp() {
  const app = Fastify();

  app.register(fastifyDrizzle, {
    connectionString:
      process.env.DATABASE_URL ??
      'postgres://postgres:postgres@127.0.0.1:5432/postgres',
  });

  // Declare routes
  declareRoutes(app);

  try {
    await app.listen({ port: PORT });
    console.log(`Server listening on port ${PORT}`);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

// Start the server if this file is run directly (not imported as a module).
if (import.meta.main) {
  buildAndStartApp();
}
