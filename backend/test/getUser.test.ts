import { PostgreSqlContainer, type StartedPostgreSqlContainer } from '@testcontainers/postgresql'
import type { FastifyInstance } from 'fastify'
import { afterAll, beforeAll, describe, expect, test } from 'vitest'

import { buildApp } from '@/app'

import * as schema from '../src/db/schema'

describe('GET /get_user route', () => {
  let container: StartedPostgreSqlContainer
  let app: FastifyInstance
  const testAddress = '0x064a24243f2aabae8d2148fa878276e6e6e452e3941b417f3c33b1649ea83e11'
  const unknownAddress = '0x064a24243f2aabae8d2148fa878276e6e6e452e3941b417f3c33b1649ea83e12'
  const testName = 'Jean Dupont'

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
    await app.db.insert(schema.registration).values([
      {
        phone_number: '+33611223344',
        contract_address: testAddress,
        nickname: testName,
      },
    ])
  })

  afterAll(async () => {
    await app.close()
    await container.stop()
  })

  test('should return the name for a valid registered address', async () => {
    const response = await app.inject({
      method: 'GET',
      url: `/get_user?address=${testAddress}`,
    })

    expect(response.statusCode).toBe(200)
    expect(response.json()).toHaveProperty('user', testName)
  })

  test('should return an error for an unknown address', async () => {
    const response = await app.inject({
      method: 'GET',
      url: `/get_user?address=${unknownAddress}`,
    })

    expect(response.statusCode).toBe(404)
    expect(response.json()).toHaveProperty('message', 'User not found.')
  })

  test('should return error, invalid address format', async () => {
    const invalidAddress = '0x0'
    const response = await app.inject({
      method: 'GET',
      url: `/get_user?address=${invalidAddress}`,
    })

    expect(response.statusCode).toBe(400)
    expect(response.json()).toHaveProperty('message', 'Invalid address format')
  })

  test('should return error, no address provided', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/get_user',
    })

    expect(response.statusCode).toBe(400)
    expect(response.json()).toHaveProperty('message', 'Address is required')
  })
})
