import type { Database } from '@/db/drizzle';
import { sql } from 'drizzle-orm';
import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';

import { getClaimRoute } from './claim';
import { getGenerateClaimLinkRoute } from './generateClaimLink';
import { getBalanceRoute } from './getBalance';
import { getCurrentExpenseRoute } from './getCurrentExpense';
import { getHistoricalBalanceRoute } from './getHistoricalBalance';
import { getLimitRoute } from './getLimit';
import { getOtp } from './getOtp';
import { getTransactionHistory } from './getTransactionHistory';
import { getRegisterRoute } from './register';
import { verifyOtp } from './verifyOtp';

export const addressRegex = /^0x0[0-9a-fA-F]{63}$/;

export function declareRoutes(fastify: FastifyInstance) {
  getStatusRoute(fastify);
  getBalanceRoute(fastify);
  getCurrentExpenseRoute(fastify);
  getTransactionHistory(fastify);
  getRegisterRoute(fastify);
  getOtp(fastify);
  verifyOtp(fastify);
  getHistoricalBalanceRoute(fastify);
  getGenerateClaimLinkRoute(fastify);
  getClaimRoute(fastify);
  getLimitRoute(fastify);
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
