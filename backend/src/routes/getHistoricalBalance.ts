import { eq, sql } from 'drizzle-orm';
import type { FastifyInstance } from 'fastify';
import { ADDRESS_REGEX } from '.';
import { usdcBalance } from '../db/schema';

export function getHistoricalBalanceRoute(fastify: FastifyInstance) {
  fastify.get('/get_historical_balance', async (request, reply) => {
    const { address } = request.query as { address?: string };

    if (!address) {
      return reply.status(400).send({ error: 'Address is required' });
    }

    // Validate address format
    if (!ADDRESS_REGEX.test(address)) {
      return reply.status(400).send({ error: 'Invalid address format' });
    }

    try {
      const subquery = sql`
        SELECT address, MAX(block_timestamp) AS max_timestamp
        FROM ${usdcBalance}
        WHERE address = ${address} AND block_timestamp >= NOW() - INTERVAL '30 days'
        GROUP BY address, DATE(block_timestamp)
      `;

      const historicalBalances = await fastify.db
        .select({
          balance: usdcBalance.balance,
          date: sql`DATE(${usdcBalance.blockTimestamp})`,
        })
        .from(usdcBalance)
        .where(sql`(${usdcBalance.address}, ${usdcBalance.blockTimestamp}) IN (${subquery})`);

      if (!historicalBalances) {
        return reply.status(404).send({ error: 'Error while retrieving historical balance' });
      }

      return reply.send({
        historicalBalances,
      });
    } catch (error) {
      console.error(error);
      return reply.status(500).send({ error: 'Internal server error' });
    }
  });
}
