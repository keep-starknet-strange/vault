import { PostgreSqlContainer, type StartedPostgreSqlContainer } from '@testcontainers/postgresql'
import dotenv from 'dotenv'
import type { FastifyInstance } from 'fastify'
import { afterAll, beforeAll, describe, expect, test } from 'vitest'

import { buildApp } from '@/app'

import * as schema from '../src/db/schema'

dotenv.config()

describe('Verify OTP test', () => {
  let container: StartedPostgreSqlContainer
  let app: FastifyInstance
  const testPhoneNumber = process.env.TEST_PHONE_NUMBER as string
  const otherPhoneNumber = process.env.TWILIO_PHONE_NUMBER as string
  const testPublicKeyX = '0x817e6fe65ffaf529a672dc3f6b4c709db8e88f163a7831739df91cf0daf81133'
  const testPublicKeyY = '0x4bdae6ef158afd49d946c36d8bf3c8efc359a50e1f2bc043368230ed9e6d610d'
  const testNickname = 'Jean Dupont'

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

    // adding a user
    await app.db.insert(schema.registration).values({
      phone_number: testPhoneNumber,
      nickname: testNickname,
    })
  })

  afterAll(async () => {
    await app.close()
    await container.stop()
  })

  test('should throw 500 if otp not requested : /verify_otp', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/verify_otp',
      body: {
        phone_number: otherPhoneNumber,
        sent_otp: '666666',
        public_key_x: testPublicKeyX,
        public_key_y: testPublicKeyY,
      },
    })

    const msg = {
      message: 'Otp is unrequested.',
    }

    expect(response.body).toBe(JSON.stringify(msg))
    expect(response.statusCode).toBe(400)
  })

  test('should not be able verify the otp no public key x sent: /verify_otp', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/verify_otp',
      body: {
        phone_number: testPhoneNumber,
        sent_otp: '666666',
        public_key_y: testPublicKeyY,
      },
    })

    expect(response.json()).toHaveProperty('message', "body must have required property 'public_key_x'")
    expect(response.statusCode).toBe(400)
  })

  test('should not be able verify the otp no public key y sent: /verify_otp', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/verify_otp',
      body: {
        phone_number: testPhoneNumber,
        sent_otp: '666666',
        public_key_x: testPublicKeyX,
      },
    })

    expect(response.json()).toHaveProperty('message', "body must have required property 'public_key_y'")
    expect(response.statusCode).toBe(400)
  })

  test('should not be able verify the otp invalid public key x sent: /verify_otp', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/verify_otp',
      body: {
        phone_number: testPhoneNumber,
        sent_otp: '666666',
        public_key_x: '0x1',
        public_key_y: testPublicKeyY,
      },
    })

    expect(response.json()).toHaveProperty('message', 'body/public_key_x must match pattern "^0x[0-9a-fA-F]{64}$"')
    expect(response.statusCode).toBe(400)
  })

  test('should not be able verify the otp invalid public key y sent: /verify_otp', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/verify_otp',
      body: {
        phone_number: testPhoneNumber,
        sent_otp: '666666',
        public_key_x: testPublicKeyX,
        public_key_y: '0x1',
      },
    })

    expect(response.json()).toHaveProperty('message', 'body/public_key_y must match pattern "^0x[0-9a-fA-F]{64}$"')
    expect(response.statusCode).toBe(400)
  })
})
