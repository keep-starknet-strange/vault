import { eq } from 'drizzle-orm/pg-core/expressions';
import type { FastifyInstance } from 'fastify';

import { usdcBalance } from '@/db/schema';
import { addressRegex } from '.';

export function getBalanceRoute(fastify: FastifyInstance) {
  fastify.get('/get_balance', async (request, reply) => {
    const { address } = request.query as { address?: string };
    if (!address) {
      return reply.status(400).send({ message: 'Address is required.' });
    }
    // Validate address format
    if (!addressRegex.test(address)) {
      return reply.status(400).send({ message: 'Invalid address format.' });
    }

    try {
      // Use Drizzle ORM to find the balance by address
      const balanceRecord = await fastify.db.query.usdcBalance
        .findFirst({ where: eq(usdcBalance.address, address) })
        .execute();

      const balance = balanceRecord?.balance ?? '0';

      return reply.send({ balance });
    } catch (error) {
      console.error(error);
      return reply.status(500).send({ message: 'Internal server error' });
    }
  });
}
