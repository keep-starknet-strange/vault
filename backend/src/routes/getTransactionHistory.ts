import { and, asc, eq, lt, or, sql } from 'drizzle-orm'
import type { FastifyInstance } from 'fastify'

import { usdcTransfer } from '@/db/schema'

import { addressRegex } from '.'

interface TransactionHistoryQuery {
  address: string
  first: number
  after?: number
}

export function getTransactionHistory(fastify: FastifyInstance) {
  fastify.get(
    '/transaction_history',

    async (request, reply) => {
      const { address, first, after } = request.query as TransactionHistoryQuery

      if (!address) {
        return reply.status(400).send({ error: 'Address is required.' })
      }

      if (!first) {
        return reply.status(400).send({ error: 'First is required.' })
      }

      // Validate address format
      if (!addressRegex.test(address)) {
        return reply.status(400).send({ error: 'Invalid address format.' })
      }

      try {
        const firstTimestamp = after ? Number(after) : Number(0)
        const txs = await fastify.db
          .select({
            transaction_timestamp: usdcTransfer.blockTimestamp,
            amount: usdcTransfer.amount,
            from: {
              nickname: sql`"from_user"."nickname"`,
              contract_address: sql`"from_user"."contract_address"`,
              phone_number: sql`"from_user"."phone_number"`,
            },
            to: {
              nickname: sql`"to_user"."nickname"`,
              contract_address: sql`"to_user"."contract_address"`,
              phone_number: sql`"to_user"."phone_number"`,
            },
          })
          .from(usdcTransfer)
          .leftJoin(sql`registration AS "from_user"`, eq(usdcTransfer.fromAddress, sql`"from_user"."contract_address"`))
          .leftJoin(sql`registration AS "to_user"`, eq(usdcTransfer.toAddress, sql`"to_user"."contract_address"`))
          .where(
            and(
              lt(usdcTransfer.blockTimestamp, new Date(firstTimestamp)),
              or(eq(usdcTransfer.fromAddress, address), eq(usdcTransfer.toAddress, address)),
            ),
          )
          .limit(first)
          .orderBy(asc(usdcTransfer.blockTimestamp))
          .execute()

        return reply.status(200).send({ transactions: txs })
      } catch (error) {
        console.error(error)
        return reply.status(500).send({ error: 'Internal server error' })
      }
    },
  )
}
