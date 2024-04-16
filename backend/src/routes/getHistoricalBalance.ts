import { and, eq, gte, sql } from 'drizzle-orm';
import type { FastifyInstance } from 'fastify';
import { addressRegex } from '.';
import { usdcBalance } from '../db/schema';

export function getHistoricalBalanceRoute(fastify: FastifyInstance) {
  fastify.get('/get_historical_balance', async (request, reply) => {
    const { address } = request.query as { address?: string };

    if (!address) {
      return reply.status(400).send({ error: 'Address is required' });
    }

    // Validate address format
    if (!addressRegex.test(address)) {
      return reply.status(400).send({ error: 'Invalid address format' });
    }

    try {
      const subquery = fastify.db
        .select({
          address: usdcBalance.address,
          blockTimestamp: sql`MAX(${usdcBalance.blockTimestamp}) AS maxBlockTimestamp`,
        })
        .from(usdcBalance)
        .where(
          and(
            eq(usdcBalance.address, address),
            gte(usdcBalance.blockTimestamp, sql`NOW() - INTERVAL '30 days'`),
          ),
        )
        .groupBy(usdcBalance.address, sql`DATE(${usdcBalance.blockTimestamp})`)
        .as('subquery');

      const historicalBalances = await fastify.db
        .select({
          balance: usdcBalance.balance,
          date: sql`DATE(${usdcBalance.blockTimestamp})`,
        })
        .from(usdcBalance)
        .innerJoin(
          subquery,
          and(
            eq(usdcBalance.address, subquery.address),
            eq(usdcBalance.blockTimestamp, sql`maxBlockTimestamp`),
          ),
        );

      return reply.send({
        historicalBalances,
      });
    } catch (error) {
      console.error(error);
      return reply.status(500).send({ error: 'Internal server error' });
    }
  });
}
