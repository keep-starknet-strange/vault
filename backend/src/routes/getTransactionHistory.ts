import { and, asc, desc, eq, lt, or, sql } from 'drizzle-orm'
import type { FastifyInstance } from 'fastify'

import { usdcTransfer } from '@/db/schema'
import { fromCursorHash, toCursorHash } from '@/utils/pagination'

import { addressRegex } from '.'

const MAX_PAGE_SIZE = 20

function getCursorQuery(cursor?: string): Parameters<typeof and> {
  const [transferId, timestamp] = fromCursorHash(cursor)

  return [
    or(
      and(
        timestamp ? eq(usdcTransfer.blockTimestamp, new Date(Number(timestamp) * 1000)) : undefined,
        transferId ? lt(usdcTransfer.transferId, transferId) : undefined,
      ),
      timestamp ? lt(usdcTransfer.blockTimestamp, new Date(Number(timestamp) * 1000)) : undefined,
    ),
  ]
}

interface TransactionHistoryQuery {
  address?: string
  first?: string
  after?: string
}

export function getTransactionHistory(fastify: FastifyInstance) {
  fastify.get(
    '/transaction_history',

    async (request, reply) => {
      const { address, first: firstStr, after } = request.query as TransactionHistoryQuery
      const first = Number(firstStr ?? MAX_PAGE_SIZE)

      if (!address) {
        return reply.status(400).send({ error: 'Address is required.' })
      }

      if (first > MAX_PAGE_SIZE) {
        return reply.status(400).send({ error: `First cannot exceed ${MAX_PAGE_SIZE}.` })
      }

      // Validate address format
      if (!addressRegex.test(address)) {
        return reply.status(400).send({ error: 'Invalid address format.' })
      }

      const afterQuery = getCursorQuery(after)

      try {
        const txs = await fastify.db
          .select({
            transaction_timestamp: usdcTransfer.blockTimestamp,
            amount: usdcTransfer.amount,
            transfer_id: usdcTransfer.transferId,
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
          .where(and(...afterQuery, or(eq(usdcTransfer.fromAddress, address), eq(usdcTransfer.toAddress, address))))
          .limit(Number(first) + 1)
          .orderBy(desc(usdcTransfer.blockTimestamp), asc(usdcTransfer.transferId))
          .execute()

        // get pagination infos
        const lastTx = txs.length ? txs[Math.min(txs.length - 1, first - 1)] : null

        const endCursor = lastTx
          ? toCursorHash(lastTx.transfer_id, (lastTx.transaction_timestamp!.getTime() / 1000).toString())
          : null

        const hasNext = txs.length > first

        return reply.status(200).send({ items: txs.slice(0, first), endCursor, hasNext })
      } catch (error) {
        console.error(error)
        return reply.status(500).send({ error: 'Internal server error' })
      }
    },
  )
}
