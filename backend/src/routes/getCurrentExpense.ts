import { sql } from 'drizzle-orm';
import { and, between, eq, gte } from 'drizzle-orm/pg-core/expressions';
import type { FastifyInstance } from 'fastify';

import { usdcBalance, usdcTransfer } from '@/db/schema';

const addressRegex = /^0x0[0-9a-fA-F]{63}$/;

export function getCurrentExpenseRoute(fastify: FastifyInstance) {
  fastify.get('/get_current_expense', async (request, reply) => {
    const { address } = request.query as { address?: string };

    if (!address) {
      return reply.status(400).send({ error: 'Address is required.' });
    }
    // Validate address format
    if (!addressRegex.test(address)) {
      return reply.status(400).send({ error: 'Invalid address format.' });
    }

    try {
      // Use Drizzle ORM to find expense by address
      const expenses = await fastify.db
        .select({
          totalAmount: sql`sum(CAST(${usdcTransfer.amount} AS NUMERIC))`.mapWith(Number),
        })
        .from(usdcTransfer)
        .where(
          and(
            eq(usdcTransfer.fromAddress, address),
            between(usdcTransfer.createdAt, sql`now()`, sql`now() - interval '7 days'`),
          ),
        )
        .execute();

      const totalAmount = expenses[0].totalAmount ?? 0;

      return reply.send({ cumulated_expense: `0x${totalAmount.toString(16)}` });
    } catch (error) {
      console.error(error);
      return reply.status(500).send({ error: 'Internal server error' });
    }
  });
}
