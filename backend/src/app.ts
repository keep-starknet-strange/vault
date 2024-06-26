import dotenv from 'dotenv'
import Fastify from 'fastify'
import { Account } from 'starknet'
import twilio from 'twilio'

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
  const app = Fastify({ logger: true })

  dotenv.config()
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

  if (!process.env.TWILIO_ACCOUNT_SSID) {
    throw new Error('Twilio account ssid not set')
  }

  if (!process.env.TWILIO_AUTH_TOKEN) {
    throw new Error('Twilio auth token not set')
  }

  if (!process.env.TWILIO_SERVICE_ID) {
    throw new Error('Twilio service id not set')
  }

  if (!process.env.FUNKIT_API_KEY) {
    throw new Error('Funkit API key not set')
  }

  const deployer = new Account({ nodeUrl: process.env.NODE_URL }, process.env.DEPLOYER_ADDRESS, process.env.DEPLOYER_PK)
  const twilio_services = twilio(process.env.TWILIO_ACCOUNT_SSID, process.env.TWILIO_AUTH_TOKEN).verify.v2.services(
    process.env.TWILIO_SERVICE_ID,
  )
  const funkitApiKey = process.env.FUNKIT_API_KEY

  // Declare routes
  declareRoutes(app, deployer, twilio_services, funkitApiKey)

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
