import { PostgreSqlContainer, type StartedPostgreSqlContainer } from '@testcontainers/postgresql'
import type { FastifyInstance } from 'fastify'
import { afterAll, beforeAll, describe, expect, test } from 'vitest'

import { buildApp } from '@/app'

import * as schema from '../src/db/schema'

describe('/get_current_expense route', () => {
  let container: StartedPostgreSqlContainer
  let app: FastifyInstance
  const testAddress = '0x004babd76a282efdd30b97c8a98b0f2e4ebb91e81b3542bfd124c086648a07af'
  const amount = '1000.000000'
  const transactionHash = '0x040d8bb0da6fdfb7825567920fceb1bee209cde3310b1548d17d06cde847348c'

  const getDate = (daysDifference?: number): Date => {
    if (daysDifference) {
      const date = new Date()
      const formatDate = new Date(date)
      formatDate.setDate(date.getDate() - daysDifference)
      return formatDate
    }
    const currentDate = new Date()
    return currentDate
  }

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
    // Insert transfer to mock address

    await app.db.insert(schema.usdcTransfer).values({
      transferId: `${transactionHash}_1`,
      fromAddress: testAddress,
      amount,
      createdAt: getDate(10),
    })

    await app.db.insert(schema.usdcTransfer).values({
      transferId: `${transactionHash}_2`,
      fromAddress: testAddress,
      amount,
      createdAt: getDate(),
    })

    await app.db.insert(schema.usdcTransfer).values({
      transferId: `${transactionHash}_3`,
      fromAddress: testAddress,
      amount,
      createdAt: getDate(),
    })
  })

  afterAll(async () => {
    await app.close()
    await container.stop()
  })

  test('should return the expense for a valid address', async () => {
    const response = await app.inject({
      method: 'GET',
      url: `/get_current_expense?address=${testAddress}`,
    })

    expect(response.statusCode).toBe(200)
    expect(response.json()).toHaveProperty('cumulated_expense', '2000')
  })

  test('should return error, invalid address format', async () => {
    const invalidAddress = '0x0'
    const response = await app.inject({
      method: 'GET',
      url: `/get_current_expense?address=${invalidAddress}`,
    })

    expect(response.statusCode).toBe(400)
    expect(response.json()).toHaveProperty('error', 'Invalid address format.')
  })

  test('should return error, no address provided', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/get_current_expense',
    })

    expect(response.statusCode).toBe(400)
    expect(response.json()).toHaveProperty('error', 'Address is required.')
  })

  test('should return 0, unknown address', async () => {
    const unknownAddress = '0x004babd76a282efdd30b97c8a98b0f2e4ebb91e81b3542bfd124c086648a07ae'
    const response = await app.inject({
      method: 'GET',
      url: `/get_current_expense?address=${unknownAddress}`,
    })

    expect(response.statusCode).toBe(200)
    expect(response.json()).toHaveProperty('cumulated_expense', '0')
  })
})
