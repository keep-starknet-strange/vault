import { PostgreSqlContainer, type StartedPostgreSqlContainer } from '@testcontainers/postgresql'
import type { FastifyInstance } from 'fastify'
import { afterAll, beforeAll, describe, expect, test } from 'vitest'

import { buildApp } from '@/app'

describe('GET /get_funkit_stripe_checkout_quote route', () => {
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
    const response = await app.inject({
      method: 'GET',
      url: `/get_funkit_stripe_checkout_quote?address=0x00191f4a5635b5A51b33383190ccF2080ef53454d6A917bB3EECCD2028c82caf&tokenAmount=10&isNy=false`,
    })
    expect(response.statusCode).toBe(200)
    const resJson = response.json()
    expect(resJson).toHaveProperty('quoteId')
    expect(resJson).toHaveProperty('estSubtotalUsd')
    expect(resJson).toHaveProperty('paymentTokenAmount')
    expect(resJson).toHaveProperty('paymentTokenChain')
    expect(resJson).toHaveProperty('paymentTokenSymbol')
    expect(resJson).toHaveProperty('networkFees')
    expect(resJson).toHaveProperty('cardFees')
    expect(resJson).toHaveProperty('totalUsd')
  })

  test('should throw 400 for empty query parameters', async () => {
    const response = await app.inject({
      method: 'GET',
      url: `/get_funkit_stripe_checkout_quote`,
    })
    expect(response.statusCode).toBe(400)
    expect(response.json()).toHaveProperty('message', 'Address is required.')
  })

  test('should throw 400 for bad address format', async () => {
    const response = await app.inject({
      method: 'GET',
      url: `/get_funkit_stripe_checkout_quote?address=someInvalidAddress`,
    })
    expect(response.statusCode).toBe(400)
    expect(response.json()).toHaveProperty('message', 'Invalid address format.')
  })

  test('should throw 400 for missing tokenAmount input', async () => {
    const response = await app.inject({
      method: 'GET',
      url: `/get_funkit_stripe_checkout_quote?address=0x00191f4a5635b5A51b33383190ccF2080ef53454d6A917bB3EECCD2028c82caf&isNy=false`,
    })
    expect(response.statusCode).toBe(400)
    expect(response.json()).toHaveProperty('message', 'Token amount is required.')
  })

  test('should throw 400 for missing isNy input', async () => {
    const response = await app.inject({
      method: 'GET',
      url: `/get_funkit_stripe_checkout_quote?address=0x00191f4a5635b5A51b33383190ccF2080ef53454d6A917bB3EECCD2028c82caf&tokenAmount=2`,
    })
    expect(response.statusCode).toBe(400)
    expect(response.json()).toHaveProperty('message', 'isNy is a required boolean.')
  })
})
