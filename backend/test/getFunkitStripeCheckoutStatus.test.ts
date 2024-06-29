import { PostgreSqlContainer, type StartedPostgreSqlContainer } from '@testcontainers/postgresql'
import type { FastifyInstance } from 'fastify'
import { afterAll, beforeAll, describe, expect, test } from 'vitest'

import { buildApp } from '@/app'

describe('GET /get_funkit_stripe_checkout_status route', () => {
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
      url: `/get_funkit_stripe_checkout_status?funkitDepositAddress=0x305090C47639CDCe075D6626cF1D2240a16A9Bf9`,
    })
    expect(response.statusCode).toBe(200)
    expect(response.json()).toHaveProperty('state', 'COMPLETED')
  })

  test('should throw 500 for invalid funkitDepositAddress', async () => {
    const response = await app.inject({
      method: 'GET',
      url: `/get_funkit_stripe_checkout_status?funkitDepositAddress=someInvalidAddress`,
    })
    expect(response.statusCode).toBe(500)
    expect(response.json()).toHaveProperty('message', 'Failed to get a funkit checkout.')
  })

  test('should throw 400 for empty query parameters', async () => {
    const response = await app.inject({
      method: 'GET',
      url: `/get_funkit_stripe_checkout_status`,
    })
    expect(response.statusCode).toBe(400)
    expect(response.json()).toHaveProperty('message', 'funkitDepositAddress is required.')
  })
})
