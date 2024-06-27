import { sql } from 'drizzle-orm'
import type { FastifyInstance } from 'fastify'
import type { Account } from 'starknet'
import { ServiceContext } from 'twilio/lib/rest/verify/v2/service'

import type { Database } from '@/db/drizzle'

import { getClaimRoute } from './claim'
import { getExecuteFromOutsideRoute } from './executeFromOutside'
import { getGenerateClaimLinkRoute } from './generateClaimLink'
import { getCurrentExpenseRoute } from './getCurrentExpense'
import { getHistoricalBalanceRoute } from './getHistoricalBalance'
import { getLimitRoute } from './getLimit'
import { getOtp } from './getOtp'
import { getTransactionHistory } from './getTransactionHistory'
import { verifyOtp } from './verifyOtp'

export const addressRegex = /^0x0[0-9a-fA-F]{63}$/

export function declareRoutes(fastify: FastifyInstance, deployer: Account, twilio_services: ServiceContext) {
  getStatusRoute(fastify)
  getCurrentExpenseRoute(fastify)
  getTransactionHistory(fastify)
  getOtp(fastify, twilio_services.verifications)
  verifyOtp(fastify, deployer, twilio_services.verificationChecks)
  getHistoricalBalanceRoute(fastify)
  getGenerateClaimLinkRoute(fastify)
  getClaimRoute(fastify)
  getLimitRoute(fastify)
  getExecuteFromOutsideRoute(fastify, deployer)
}

function getStatusRoute(fastify: FastifyInstance) {
  fastify.get('/status', async () => handleGetStatus(fastify.db))
}

async function handleGetStatus(db: Database) {
  // Check that the database is reachable.
  const query = sql`SELECT 1`
  await db.execute(query)

  return { status: 'OK' }
}
