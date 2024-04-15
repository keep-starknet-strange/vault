import type { Database } from '@/db/drizzle';
import { sql } from 'drizzle-orm';
import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';

import { getBalanceRoute } from './getBalance';
import { getTransactionHistory } from './getTransactionHistory';

export const addressRegex = /^0x0[0-9a-fA-F]{63}$/;

export function declareRoutes(fastify: FastifyInstance) {
  getStatusRoute(fastify);
  getBalanceRoute(fastify);
  getTransactionHistory(fastify);
}

function getStatusRoute(fastify: FastifyInstance) {
  fastify.get('/status', async function handler(_request: FastifyRequest, _reply: FastifyReply) {
    return await handleGetStatus(fastify.db);
  });
}

async function handleGetStatus(db: Database) {
  // Check that the database is reachable.
  const query = sql`SELECT 1`;
  await db.execute(query);

  return { status: 'OK' };
}
