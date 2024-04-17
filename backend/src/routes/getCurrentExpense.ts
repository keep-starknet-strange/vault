import { sql } from 'drizzle-orm';
import { and, between, eq, gte } from 'drizzle-orm/pg-core/expressions';
import type { FastifyInstance } from 'fastify';

import { usdcBalance, usdcTransfer } from '@/db/schema';
import { addressRegex } from '.';

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
      const currentDate = new Date();
      // Calculate the date 7 days ago
      const sevenDaysAgo = new Date(currentDate);
      sevenDaysAgo.setDate(currentDate.getDate() - 7);
      // Use Drizzle ORM to find expense by address
      const expenses = await fastify.db.query.usdcTransfer
        .findMany({
          where: and(
            eq(usdcTransfer.fromAddress, address),
            gte(usdcTransfer.createdAt, sevenDaysAgo),
          ),
        })
        .execute();

      // Calculate the sum of amounts
      const totalAmount = expenses.reduce(
        (acc, curr) => acc + Number.parseFloat(curr.amount || '0'),
        0,
      );

      return reply.send({ cumulated_expense: `0x${totalAmount.toString(16)}` });
    } catch (error) {
      console.error(error);
      return reply.status(500).send({ error: 'Internal server error' });
    }
  });
}
