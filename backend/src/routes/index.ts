import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { Database } from '../db/plugin';
import { sql } from 'drizzle-orm';
import { getBalanceRoute } from './getBalance';

export function declareRoutes(fastify: FastifyInstance) {
  getStatusRoute(fastify);
  getBalanceRoute(fastify);
}

function getStatusRoute(fastify: FastifyInstance) {
  fastify.get(
    '/status',
    async function handler(_request: FastifyRequest, _reply: FastifyReply) {
      return await handleGetStatus(fastify.db);
    },
  );
}

async function handleGetStatus(db: Database) {
  // Check that the database is reachable.
  const query = sql`SELECT 1`;
  await db.execute(query);

  return { status: 'OK' };
}
