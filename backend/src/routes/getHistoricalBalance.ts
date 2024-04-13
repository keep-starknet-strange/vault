import { FastifyInstance } from 'fastify';
import { sql } from 'drizzle-orm';
import { usdcBalance } from '../db/schema';

const addressRegex = /^0x0[0-9a-fA-F]{63}$/;

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
      // Use Drizzle ORM to find historical balances by address
      const historicalBalances = await fastify.db.execute(
        sql`
          SELECT balance, DATE(block_timestamp) AS date
          FROM ${usdcBalance}
          WHERE (address, block_timestamp) IN (
            SELECT address, MAX(block_timestamp) AS max_timestamp
            FROM ${usdcBalance}
            WHERE address = ${address}
            GROUP BY address, DATE(block_timestamp) 
          )
        `,
      );

      if (!historicalBalances) {
        return reply.status(404).send({ error: 'Balance not found' });
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
