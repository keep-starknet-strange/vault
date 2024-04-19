import { desc, eq } from 'drizzle-orm/pg-core/expressions';
import type { FastifyInstance } from 'fastify';

import { mockLimit } from '@/db/schema';
import { addressRegex } from '.';

export function getLimitRoute(fastify: FastifyInstance) {
  fastify.get('/get_limit', async (request, reply) => {
    const { address } = request.query as { address?: string };
    if (!address) {
      return reply.status(400).send({ message: 'Address is required' });
    }
    // Validate address format
    if (!addressRegex.test(address)) {
      return reply.status(400).send({ message: 'Invalid address format' });
    }

    try {
      // Use Drizzle ORM to find the balance by address
      const limit = await fastify.db
        .select({ limit: mockLimit.limit })
        .from(mockLimit)
        .where(eq(mockLimit.address, address))
        .orderBy(desc(mockLimit.blockTimestamp))
        .limit(1);

      const result = limit[0]?.limit ?? '0';

      return reply.send({ limit: result });
    } catch (error) {
      console.error(error);
      return reply.status(500).send({ message: 'Internal server error' });
    }
  });
}
