import { eq } from 'drizzle-orm/pg-core/expressions';
import type { FastifyInstance } from 'fastify';
import * as schema from '../db/schema';

interface ClaimRequestBody {
  amount: string;
  signature: string[];
}

export function getClaimRoute(fastify: FastifyInstance): void {
  fastify.get<{ Body: ClaimRequestBody }>('/claim', async (request, reply) => {
    const { id } = request.query as { id?: string };

    // Generate the claim link
    try {
      const calls = await fastify.db
        .select()
        .from(schema.claims)
        .where(eq(schema.claims.id, id || ''));
      if (!calls.length) {
        return reply.status(400).send({ message: 'Unknown uuid.' });
      }

      const { nonce, address, amount, signature } = calls[0];

      return reply.send({ call: { address, amount, nonce, signature } });
      // biome-ignore lint: has to be typed any or unknown otherwise typescript cries
    } catch (error: any) {
      if (error.code === '22P02') {
        return reply.status(400).send({ message: 'Invalid uuid.' });
      }
      console.error('Unknown uuid:', error);
      return reply.status(500).send({ message: 'Internal server error.' });
    }
  });
}
