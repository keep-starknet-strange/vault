import type { FastifyInstance } from 'fastify';
import * as schema from '../db/schema';

interface ClaimRequestBody {
  amount: string;
  address: string;
  signature: string[];
}

export function getGenerateClaimLinkRoute(fastify: FastifyInstance): void {
  fastify.post<{ Body: ClaimRequestBody }>(
    '/generate_claim_link',
    {
      schema: {
        body: {
          type: 'object',
          required: ['address', 'amount', 'signature'],
          properties: {
            amount: { type: 'string', pattern: '^[0-9]{1,78}.[0-9]{6}$' },
            address: { type: 'string', pattern: '^0x0[0-9a-fA-F]{63}$' },
            signature: {
              type: 'array',
              items: { type: 'string', pattern: '^0x0[0-9a-fA-F]{63}$' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { amount, address, signature } = request.body;

      // Validate the input
      if (/^0{1,78}.000000$/.test(amount)) {
        return reply.status(400).send({ message: "Amount can't be zero." });
      }
      if (!signature.length) {
        return reply.status(400).send({ message: 'Missing signature.' });
      }

      // Generate the claim link
      try {
        const claimToken = (
          await fastify.db.insert(schema.claims).values({ amount, address }).returning()
        )[0].id;

        const claimLink = `https://vlt.finance/claim?token=${claimToken}`;
        return reply.send({ claimLink });
      } catch (error) {
        console.error('Failed to generate claim link:', error);
        return reply.status(500).send({ error: 'Failed to generate claim link.' });
      }
    },
  );
}
