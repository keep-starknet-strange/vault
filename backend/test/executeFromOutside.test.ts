import { PostgreSqlContainer, type StartedPostgreSqlContainer } from '@testcontainers/postgresql'
import dotenv from 'dotenv'
import type { FastifyInstance } from 'fastify'
import { CallData } from 'starknet'
import { afterAll, assert, beforeAll, describe, expect, test } from 'vitest'

import { buildApp } from '@/app'

import * as schema from '../src/db/schema'
import { signOutsideUsdcTransfer, TESTNET_USDC } from './utils'

dotenv.config()

describe('executeFromOutside test', () => {
  let container: StartedPostgreSqlContainer
  let app: FastifyInstance
  const testAddress = process.env.DEPLOYER_ADDRESS as string

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

    // reset db
    await app.db.delete(schema.registration)
  })

  afterAll(async () => {
    await app.close()
    await container.stop()
  })

  test('should throw 500 for empty calldata', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/execute_from_outside',
      body: {
        address: testAddress,
        calldata: [],
      },
    })

    expect(response.json()).toHaveProperty('message', 'Empty calldata.')
    expect(response.statusCode).toBe(500)
  })

  test('should throw 500 for wrong format calldata', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/execute_from_outside',
      body: {
        address: testAddress,
        calldata: ['0x1'],
      },
    })
    expect(response.json()).toHaveProperty('message', 'body/calldata/0 must match pattern "^[0-9]{0,76}$"')
    expect(response.statusCode).toBe(400)
  })
  test('should throw 500 for wrong calldata', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/execute_from_outside',
      body: {
        address: testAddress,
        calldata: ['1'],
      },
    })

    expect(response.json()).toHaveProperty('message', 'Internal Server Error')
    expect(response.statusCode).toBe(500)
  })

  test(
    'should execute from outside usdc transfers',
    async () => {
      const executeFromOutsideAddress = '0x01e2c3fe6982be3263dd15ec6700ba23f8bb1c00e04eaae5a3d0c8b11fae13bb'
      const response = await app.inject({
        method: 'POST',
        url: '/execute_from_outside',
        body: {
          address: executeFromOutsideAddress,
          calldata: CallData.compile(
            signOutsideUsdcTransfer(
              executeFromOutsideAddress,
              [{ amount: 1, recipient: testAddress }],
              +new Date(), // nonce avoid duplicate
              TESTNET_USDC,
            ),
          ),
        },
      })
      assert(/^0x[0-9a-fA-F]{1,63}$/.test((await response.json()).transaction_hash))
      expect(response.statusCode).toBe(200)
    },
    120 * 1000,
    // 2 min test timeout
  )
})
