import { PostgreSqlContainer, type StartedPostgreSqlContainer } from '@testcontainers/postgresql'
import type { FastifyInstance } from 'fastify'
import { afterAll, beforeAll, describe, expect, test } from 'vitest'

import { buildApp } from '@/app'

describe('POST /create_funkit_stripe_checkout route', () => {
  let container: StartedPostgreSqlContainer
  let app: FastifyInstance

  beforeAll(async () => {
    container = await new PostgreSqlContainer().start()
    app = await buildApp({
      database: {
        connectionString: container.getConnectionUri(),
      },
      app: {
        port: 8080,
      },
    })

    await app.ready()
  })

  afterAll(async () => {
    await app.close()
    await container.stop()
  })

  test('should return success with valid parameters', async () => {
    // A quote has to be generated first before creating a checkout
    const quoteResponse = await app.inject({
      method: 'GET',
      url: `/get_funkit_stripe_checkout_quote?address=0x00191f4a5635b5A51b33383190ccF2080ef53454d6A917bB3EECCD2028c82caf&tokenAmount=10&isNy=false&isEu=true`,
    })
    const quoteObject = quoteResponse.json()
    const createResponse = await app.inject({
      method: 'POST',
      url: `/create_funkit_stripe_checkout`,
      body: {
        quoteId: quoteObject.quoteId,
        paymentTokenAmount: quoteObject.paymentTokenAmount,
        estSubtotalUsd: quoteObject.estSubtotalUsd,
        isNy: false,
        isEu: true,
      },
    })
    expect(createResponse.statusCode).toBe(200)
    const resJson = createResponse.json()
    expect(resJson).toHaveProperty('stripeCheckoutId')
    expect(resJson).toHaveProperty('stripeRedirectUrl')
    expect(resJson).toHaveProperty('funkitDepositAddress')
  })

  test('should throw 500 for invalid funkit quoteId', async () => {
    const createResponse = await app.inject({
      method: 'POST',
      url: `/create_funkit_stripe_checkout`,
      body: {
        quoteId: 'invalidQuoteId',
        paymentTokenAmount: 10,
        estSubtotalUsd: 10,
        isNy: false,
        isEu: true,
      },
    })
    expect(createResponse.statusCode).toBe(500)
    expect(createResponse.json()).toHaveProperty('message', 'Failed to start a checkout.')
  })

  test('should throw 400 for missing quoteId', async () => {
    const createResponse = await app.inject({
      method: 'POST',
      url: `/create_funkit_stripe_checkout`,
      body: {},
    })
    expect(createResponse.statusCode).toBe(400)
    expect(createResponse.json()).toHaveProperty('message', 'quoteId is required.')
  })

  test('should throw 400 for missing paymentTokenAmount', async () => {
    const createResponse = await app.inject({
      method: 'POST',
      url: `/create_funkit_stripe_checkout`,
      body: { quoteId: 'dummyQuoteId' },
    })
    expect(createResponse.statusCode).toBe(400)
    expect(createResponse.json()).toHaveProperty('message', 'paymentTokenAmount is required.')
  })

  test('should throw 400 for missing estSubtotalUsd', async () => {
    const createResponse = await app.inject({
      method: 'POST',
      url: `/create_funkit_stripe_checkout`,
      body: { quoteId: 'dummyQuoteId', paymentTokenAmount: 10 },
    })
    expect(createResponse.statusCode).toBe(400)
    expect(createResponse.json()).toHaveProperty('message', 'estSubtotalUsd is required.')
  })

  test('should throw 400 for missing isNy', async () => {
    const createResponse = await app.inject({
      method: 'POST',
      url: `/create_funkit_stripe_checkout`,
      body: { quoteId: 'dummyQuoteId', paymentTokenAmount: 10, estSubtotalUsd: 10 },
    })
    expect(createResponse.statusCode).toBe(400)
    expect(createResponse.json()).toHaveProperty('message', 'isNy is a required boolean.')
  })

  test('should throw 400 for missing isEu', async () => {
    const createResponse = await app.inject({
      method: 'POST',
      url: `/create_funkit_stripe_checkout`,
      body: { quoteId: 'dummyQuoteId', paymentTokenAmount: 10, estSubtotalUsd: 10, isNy: true },
    })
    expect(createResponse.statusCode).toBe(400)
    expect(createResponse.json()).toHaveProperty('message', 'isEu is a required boolean.')
  })
})
