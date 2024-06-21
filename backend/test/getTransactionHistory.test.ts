import { PostgreSqlContainer, type StartedPostgreSqlContainer } from '@testcontainers/postgresql'
import type { FastifyInstance } from 'fastify'
import { afterAll, beforeAll, beforeEach, describe, expect, test } from 'vitest'

import { buildApp } from '@/app'

import * as schema from '../src/db/schema'
const MOCK_TX_HASH = '0x71dc653ae79444baeca2f182154bbd0ebb2bff2d73a4cf4c13774b2c613e'
const MOCK_TO_ADDRESS = '0x00057c4b510d66eb1188a7173f31cccee47b9736d40185da8144377b896d5ff3'
const MOCK_USER = {
  phone_number: '+33612345678',
  nickname: 'papa johnny',
  contract_address: MOCK_TO_ADDRESS,
}

function generateMockData(
  fromAddress: string,
  upperLimit: number,
  lowerLimit?: number,
  isResponseMock?: boolean,
  user?: { phone_number: string; nickname: string; contract_address: string },
) {
  const mockData = []
  const numEntries = (lowerLimit ?? 0) + upperLimit
  const startCnt = lowerLimit ? lowerLimit + 1 : 1

  for (let i = startCnt; i <= numEntries; i++) {
    const transferId = `${MOCK_TX_HASH}_${i}`
    const network = 'starknet-mainnet'
    const transactionHash = MOCK_TX_HASH + String(i)
    const toAddress = MOCK_TO_ADDRESS
    const amount = `0x${i.toString(16)}`

    const blockTimestamp = new Date(i)
    if (isResponseMock) {
      mockData.push({
        from:
          fromAddress === MOCK_TO_ADDRESS
            ? MOCK_USER
            : (user as {
                phone_number: string
                nickname: string
                contract_address: string
              }),
        to:
          toAddress === MOCK_TO_ADDRESS
            ? MOCK_USER
            : (user as {
                phone_number: string
                nickname: string
                contract_address: string
              }),
        amount,
        transaction_timestamp: blockTimestamp.toISOString(),
      })
    } else {
      mockData.push({
        transferId,
        network,
        transactionHash,
        fromAddress,
        toAddress,
        amount,
        blockTimestamp,
      })
    }
  }

  // Silence the type error since it's an helper for testing.
  // The issue is that `transferId` is a required field for inserting data.
  return mockData as (typeof schema.usdcTransfer.$inferInsert)[]
}

describe('GET /transaction history route', () => {
  let container: StartedPostgreSqlContainer
  let app: FastifyInstance
  const testAddress = '0x004babd76a282efdd30b97c8a98b0f2e4ebb91e81b3542bfd124c086648a07af'
  const MOCK_USER_NAME = 'coco lasticot'
  const MOCK_USER_PHONE = '+33698765432'
  const test_user = {
    phone_number: MOCK_USER_PHONE,
    nickname: MOCK_USER_NAME,
    contract_address: testAddress,
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
    await app.db.insert(schema.registration).values([MOCK_USER, test_user])
  })

  afterAll(async () => {
    await app.db.delete(schema.usdcTransfer)
    await app.close()
    await container.stop()
  })

  beforeEach(async () => {
    // clear db before custom number of mock entries
    await app.db.delete(schema.usdcTransfer)
  })

  test('should return the 9 txns obj, total 10 entries', async () => {
    await app.db.insert(schema.usdcTransfer).values(generateMockData(testAddress, 10))
    const startValue = 1
    const first = 9
    const response = await app.inject({
      method: 'GET',
      url: `/transaction_history?address=${testAddress}&after=${startValue}&first=${first}`,
    })

    expect(response.statusCode).toBe(200)

    const mockResponseObj = generateMockData(testAddress, first, startValue, true, test_user)
    expect(response.json().items).toMatchObject(mockResponseObj)
    expect(response.json().items).toHaveLength(first)
  })

  test('should return the first 9 entries', async () => {
    await app.db.insert(schema.usdcTransfer).values(generateMockData(testAddress, 10))
    const startValue = 0
    const first = 9
    const response = await app.inject({
      method: 'GET',
      url: `/transaction_history?address=${testAddress}&first=${first}`,
    })

    expect(response.statusCode).toBe(200)

    const mockResponseObj = generateMockData(testAddress, first, startValue, true, test_user)
    expect(response.json().items).toMatchObject(mockResponseObj)
    expect(response.json().items).toHaveLength(first)
  })
  test('should return all the txs', async () => {
    const txsNb = 10
    await app.db.insert(schema.usdcTransfer).values(generateMockData(testAddress, txsNb))
    const first = 30
    const response = await app.inject({
      method: 'GET',
      url: `/transaction_history?address=${testAddress}&first=${first}`,
    })

    expect(response.statusCode).toBe(200)

    const mockResponseObj = generateMockData(testAddress, txsNb, 0, true, test_user)
    expect(response.json().items).toMatchObject(mockResponseObj)
    expect(response.json().items).toHaveLength(txsNb)
  })

  test('should return empty list unknown address', async () => {
    await app.db.insert(schema.usdcTransfer).values(generateMockData(testAddress, 10))
    const first = 9
    const response = await app.inject({
      method: 'GET',
      url: `/transaction_history?address=0x0111111111111111111111111111111111111111111111111111111111111111&first=${first}`,
    })

    expect(response.statusCode).toBe(200)

    expect(response.json().items).toMatchObject([])
    expect(response.json().items).toHaveLength(0)
  })

  test('should return an error wrong address format', async () => {
    await app.db.insert(schema.usdcTransfer).values(generateMockData(testAddress, 10))
    const first = 9
    const response = await app.inject({
      method: 'GET',
      url: `/transaction_history?address=0x01&first=${first}`,
    })

    expect(response.statusCode).toBe(400)
    expect(response.json()).toHaveProperty('error', 'Invalid address format.')
  })

  test('should return error, no address provided', async () => {
    await app.db.insert(schema.usdcTransfer).values(generateMockData(testAddress, 5))
    const response = await app.inject({
      method: 'GET',
      url: '/transaction_history',
    })

    expect(response.json()).toHaveProperty('error', 'Address is required.')
  })
})
