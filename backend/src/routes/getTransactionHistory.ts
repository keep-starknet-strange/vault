import type { FastifyInstance } from 'fastify';

import { usdcTransfer } from '@/db/schema';
import { count, eq } from 'drizzle-orm';

import { addressRegex } from '.';

interface TransactionHistoryQuery {
  address: string;
  pagination?: string;
}

export function getTransactionHistory(fastify: FastifyInstance) {
  fastify.get('/transaction_history', async (request, reply) => {
    const { address, pagination = '1' } = request.query as TransactionHistoryQuery;

    if (!address) {
      return reply.status(400).send({ error: 'Address is required.' });
    }
    // Validate address format
    if (!addressRegex.test(address)) {
      return reply.status(400).send({ error: 'Invalid address format.' });
    }
    // Hardcoding the limit to 10 entries per page
    const limit = 10;
    const offset = (Number.parseInt(pagination) - 1) * limit;

    try {
      const transactionCount = await fastify.db
        .select({ count: count() })
        .from(usdcTransfer)
        .where(eq(usdcTransfer.fromAddress, address))
        .execute();
      const transactionList = await fastify.db.query.usdcTransfer
        .findMany({
          where: eq(usdcTransfer.fromAddress, address),
          columns: {
            transactionHash: true,
            fromAddress: true,
            toAddress: true,
            amount: true,
            network: true,
            blockTimestamp: true,
          },
          limit: limit,
          offset: offset,
        })
        .execute();

      const pageCount = Math.ceil(transactionCount[0].count / limit);
      return reply.status(200).send({ page_count: pageCount, transactions: transactionList });
    } catch (error) {
      console.error(error);
      return reply.status(500).send({ error: 'Internal server error' });
    }
  });
}
