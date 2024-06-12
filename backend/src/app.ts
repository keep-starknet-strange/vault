import Fastify from 'fastify'
import { Account } from 'starknet'

import { fastifyDrizzle } from '@/db/plugin'

import { declareRoutes } from './routes'

export type AppConfiguration = {
  database: {
    connectionString: string
  }
  app: {
    port: number
    host?: string
  }
}

export async function buildApp(config: AppConfiguration) {
  const app = Fastify()

  app.register(fastifyDrizzle, {
    connectionString: config.database.connectionString,
  })

  // verify env
  if (!process.env.DEPLOYER_ADDRESS) {
    throw new Error('Deployer address not set')
  }

  if (!process.env.NODE_URL) {
    throw new Error('Starknet node url not set')
  }

  if (!process.env.DEPLOYER_PK) {
    throw new Error('Deployer private key not set')
  }

  const deployer = new Account({ nodeUrl: process.env.NODE_URL }, process.env.DEPLOYER_ADDRESS, process.env.DEPLOYER_PK)

  // Declare routes
  declareRoutes(app, deployer)

  return app
}

export async function buildAndStartApp(config: AppConfiguration) {
  const app = await buildApp(config)

  try {
    await app.listen({ port: config.app.port, host: config.app.host })
    console.log(`Server listening on port ${config.app.port}`)
  } catch (err) {
    console.error(err)
    process.exit(1)
  }
}
