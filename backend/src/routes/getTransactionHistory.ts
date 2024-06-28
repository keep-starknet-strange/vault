import { and, asc, desc, eq, gt, lt, or, sql } from 'drizzle-orm'
import { PgSelectQueryBuilderBase } from 'drizzle-orm/pg-core'
import type { FastifyInstance } from 'fastify'

import { usdcTransfer } from '@/db/schema'
import { fromCursorHash, toCursorHash } from '@/utils/pagination'

import { addressRegex } from '.'

const MAX_PAGE_SIZE = 20

interface GetCursorQueryResult {
  where: Parameters<typeof and>
  order: Parameters<PgSelectQueryBuilderBase<any, any, any, any>['orderBy']>
}

function getCursorQuery(cursor: string | undefined, isReversed: boolean): GetCursorQueryResult {
  const [indexInBlock, timestamp] = fromCursorHash(cursor)

  const sortingExpression = isReversed ? asc : desc
  const compareExpression = isReversed ? gt : lt

  return {
    where: [
      or(
        and(
          timestamp ? eq(usdcTransfer.blockTimestamp, new Date(Number(timestamp) * 1000)) : undefined,
          indexInBlock ? compareExpression(usdcTransfer.indexInBlock, +indexInBlock) : undefined,
        ),
        timestamp ? compareExpression(usdcTransfer.blockTimestamp, new Date(Number(timestamp) * 1000)) : undefined,
      ),
    ],
    order: [sortingExpression(usdcTransfer.blockTimestamp), sortingExpression(usdcTransfer.indexInBlock)],
  }
}

interface CursorableTransaction {
  index_in_block: number | null
  transaction_timestamp: Date | null
}

function getCursor(tx: CursorableTransaction): string {
  return toCursorHash((tx.index_in_block ?? 0).toString(), (tx.transaction_timestamp!.getTime() / 1000).toString())
}

interface TransactionHistoryQuery {
  address?: string
  first?: string
  after?: string
  before?: string
}

export function getTransactionHistory(fastify: FastifyInstance) {
  fastify.get(
    '/transaction_history',

    async (request, reply) => {
      const { address, first: firstStr, after, before } = request.query as TransactionHistoryQuery
      const first = Number(firstStr ?? MAX_PAGE_SIZE)

      if (!address) {
        return reply.status(400).send({ error: 'Address is required.' })
      }

      if (first > MAX_PAGE_SIZE) {
        return reply.status(400).send({ error: `First cannot exceed ${MAX_PAGE_SIZE}.` })
      }

      if (after && before) {
        return reply.status(400).send({ error: 'After and before are clashing' })
      }

      // Validate address format
      if (!addressRegex.test(address)) {
        return reply.status(400).send({ error: 'Invalid address format.' })
      }

      const isReversed = !!before

      const paginationQuery = getCursorQuery(after ?? before, isReversed)

      try {
        const txs = await fastify.db
          .select({
            transaction_timestamp: usdcTransfer.blockTimestamp,
            amount: usdcTransfer.amount,
            index_in_block: usdcTransfer.indexInBlock,
            from: {
              nickname: sql`"from_user"."nickname"`,
              contract_address: sql`"from_user"."contract_address"`,
              phone_number: sql`"from_user"."phone_number"`,
              balance: usdcTransfer.senderBalance,
            },
            to: {
              nickname: sql`"to_user"."nickname"`,
              contract_address: sql`"to_user"."contract_address"`,
              phone_number: sql`"to_user"."phone_number"`,
              balance: usdcTransfer.recipientBalance,
            },
          })
          .from(usdcTransfer)
          .leftJoin(sql`registration AS "from_user"`, eq(usdcTransfer.fromAddress, sql`"from_user"."contract_address"`))
          .leftJoin(sql`registration AS "to_user"`, eq(usdcTransfer.toAddress, sql`"to_user"."contract_address"`))
          .where(
            and(
              ...paginationQuery.where,
              or(eq(usdcTransfer.fromAddress, address), eq(usdcTransfer.toAddress, address)),
            ),
          )
          .limit(Number(first) + 1)
          .orderBy(...paginationQuery.order)
          .execute()

        // get pagination infos
        const firstTx = txs[0] ?? null
        const lastTx = txs.length ? txs[Math.min(txs.length - 1, first - 1)] : null

        const firstCursor = firstTx ? getCursor(firstTx) : null
        const lastCursor = lastTx ? getCursor(lastTx) : null

        const hasNext = txs.length > first

        return reply.status(200).send({
          items: txs.slice(0, first),
          startCursor: isReversed ? lastCursor : firstCursor,
          endCursor: isReversed ? firstCursor : lastCursor,
          hasNext,
        })
      } catch (error) {
        console.error(error)
        return reply.status(500).send({ error: 'Internal server error' })
      }
    },
  )
}
