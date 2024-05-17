import { PostgreSqlContainer, type StartedPostgreSqlContainer } from '@testcontainers/postgresql'
import type { FastifyInstance } from 'fastify'
import { afterAll, beforeAll, describe, expect, test } from 'vitest'

import { buildApp } from '@/app'

import * as schema from '../src/db/schema'

describe('GET /get_limit route', () => {
  let container: StartedPostgreSqlContainer
  let app: FastifyInstance
  const testAddress = '0x064a24243f2aabae8d2148fa878276e6e6e452e3941b417f3c33b1649ea83e11'
  const testAddress1 = '0x064a24243f2aabae8d2148fa878276e6e6e452e3941b417f3c33b1649ea83e12'

  beforeAll(async () => {
    container = await new PostgreSqlContainer().start()
    const connectionUri = container.getConnectionUri()
    app = await buildApp({
      database: {
        connectionString: connectionUri,
      },
      app: {
        port: 8080,
      },
    })

    await app.ready()
    // Insert limit to mock address
    await app.db.insert(schema.mockLimit).values([
      {
        address: testAddress,
        limit: '7714789860.048896',
        blockTimestamp: new Date('2024-01-10 13:03:05'),
      },
      {
        address: testAddress1,
        limit: '6865434534.048896',
        blockTimestamp: new Date('2024-01-11 13:03:05'),
      },
    ])
  })

  afterAll(async () => {
    await app.close()
    await container.stop()
  })

  test('should return the limit for a valid first address', async () => {
    const response = await app.inject({
      method: 'GET',
      url: `/get_limit?address=${testAddress}`,
    })

    expect(response.statusCode).toBe(200)
    expect(response.json()).toHaveProperty('limit', '7714789860.048896')
  })

  test('should return the limit for a valid second address', async () => {
    const response = await app.inject({
      method: 'GET',
      url: `/get_limit?address=${testAddress1}`,
    })

    expect(response.statusCode).toBe(200)
    expect(response.json()).toHaveProperty('limit', '6865434534.048896')
  })

  test('should return error, invalid address format', async () => {
    const invalidAddress = '0x0'
    const response = await app.inject({
      method: 'GET',
      url: `/get_limit?address=${invalidAddress}`,
    })

    expect(response.statusCode).toBe(400)
    expect(response.json()).toHaveProperty('message', 'Invalid address format')
  })

  test('should return error, no address provided', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/get_limit',
    })

    expect(response.statusCode).toBe(400)
    expect(response.json()).toHaveProperty('message', 'Address is required')
  })

  test('should return 0, unknown address', async () => {
    const unknownAddress = '0x004babd76a282efdd30b97c8a98b0f2e4ebb91e81b3542bfd124c086648a07ae'
    const response = await app.inject({
      method: 'GET',
      url: `/get_limit?address=${unknownAddress}`,
    })

    expect(response.statusCode).toBe(200)
    expect(response.json()).toHaveProperty('limit', '0')
  })
})
