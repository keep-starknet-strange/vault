import { FastifyInstance } from 'fastify';

const addressRegex = /^0x0[0-9a-fA-F]{63}$/;

export function getBalanceRoute(fastify: FastifyInstance) {
  fastify.get('/get_balance', async (request, reply) => {
    const { address } = request.query as { address?: string };

    if (!address || !addressRegex.test(address)) {
      reply.status(400).send({ error: 'Invalid address format' });
      return;
    }

    try {
      const { rows } = await fastify.pg.query<{ balance: string }>(
        'SELECT balance FROM balance_usdc WHERE address = $1 ORDER BY block_number DESC LIMIT 1',
        [address],
      );

      if (rows.length === 0) {
        reply
          .status(404)
          .send({ error: 'Balance not found for the provided address' });
      } else {
        reply.send({ balance: rows[0].balance });
      }
    } catch (err) {
      fastify.log.error(err);
      reply.status(500).send({ error: 'Internal Server Error' });
    }
  });
}
