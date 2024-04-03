import type { FastifyInstance } from 'fastify';
import { addressRegex } from '.';

interface GenerateClaimRequestBody {
  amount: number;
  address: string;
}

export function generateClaimLinkRoute(fastify: FastifyInstance) {
  fastify.post<{
    Body: GenerateClaimRequestBody;
  }>('/generate_claim_link', async (request, reply) => {
    const { amount, address } = request.body;

    // Validate the address using the regex from your spec
    if (!addressRegex.test(address)) {
      return reply.status(400).send({ error: 'Invalid address format.' });
    }

    // Additional validation for amount
    if (amount <= 0) {
      return reply.status(400).send({ error: 'Amount must be greater than 0.' });
    }

    try {
      // Logic to generate the claim link goes here
      const claimLink = await generateClaimLink(amount, address);

      return reply.status(200).send({ claimLink });
    } catch (error) {
      console.error(error);
      return reply.status(500).send({ error: 'Internal server error' });
    }
  });
}

async function generateClaimLink(amount: number, address: string): Promise<string> {
  // Placeholder for the link generation logic
  // This could involve interacting with a smart contract, database, or other services
  const claimLink = `https://example.com/claim?amount=${amount}&address=${address}`;
  return claimLink;
}
