import { and, eq, gte } from 'drizzle-orm/pg-core/expressions'
import type { FastifyInstance } from 'fastify'
import { formatUnits, parseUnits } from 'viem'

import { usdcTransfer } from '@/db/schema'

import { addressRegex } from '.'

export function getCurrentExpenseRoute(fastify: FastifyInstance) {
  fastify.get(
    '/get_current_expense',

    async (request, reply) => {
      const { address } = request.query as { address?: string }
      const decimal = 6

      if (!address) {
        return reply.status(400).send({ error: 'Address is required.' })
      }

      // Validate address format
      if (!addressRegex.test(address)) {
        return reply.status(400).send({ error: 'Invalid address format.' })
      }

      try {
        const currentDate = new Date()

        // Calculate the date 7 days ago
        const sevenDaysAgo = new Date(currentDate)
        sevenDaysAgo.setDate(currentDate.getDate() - 7)

        // Use Drizzle ORM to find expense by address
        const expenses = await fastify.db
          .select()
          .from(usdcTransfer)
          .where(and(eq(usdcTransfer.fromAddress, address), gte(usdcTransfer.createdAt, sevenDaysAgo)))

        // Calculate the sum of amounts
        const totalAmount = expenses.reduce(
          (acc, curr) => acc + parseUnits(curr.amount || '0', decimal),
          parseUnits('0', decimal),
        )

        return reply.send({
          cumulated_expense: formatUnits(totalAmount, decimal),
        })
      } catch (error) {
        console.error(error)
        return reply.status(500).send({ error: 'Internal server error' })
      }
    },
  )
}
