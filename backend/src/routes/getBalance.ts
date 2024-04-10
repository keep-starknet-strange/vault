import { FastifyInstance } from 'fastify';
import { usdcBalance } from '../db/schema';
import { eq } from 'drizzle-orm/pg-core/expressions';

const addressRegex = /^0x0[0-9a-fA-F]{63}$/;

export function getBalanceRoute(fastify: FastifyInstance) {
  fastify.get('/get_balance', async (request, reply) => {
    const { address } = request.query as { address?: string };
    if (!address) {
      return reply.status(400).send({ error: 'Address is required' });
    }
    // Validate address format
    if (!addressRegex.test(address)) {
      return reply.status(400).send({ error: 'Invalid address format.' });
    }

    try {
      // Use Drizzle ORM to find the balance by address
      const balanceRecord = await fastify.db.query.usdcBalance
        .findFirst({ where: eq(usdcBalance.address, address) })
        .execute();
      console.log(balanceRecord);
      if (!balanceRecord) {
        return reply.status(404).send({ error: 'Balance not found' });
      }

      return reply.send({ balance: balanceRecord });
    } catch (error) {
      console.error(error);
      return reply.status(500).send({ error: 'Internal server error' });
    }
  });
}
