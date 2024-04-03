import Fastify from 'fastify';
import dotenv from 'dotenv';
import postgres from '@fastify/postgres';
import { declareRoutes } from './routes';

const PORT: number = parseInt(Bun.env.PORT || '8080');
dotenv.config();

async function buildAndStartApp() {
  const app = Fastify();

  app.register(postgres, {
    connectionString: process.env.DATABASE_URL,
  });

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
