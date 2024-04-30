import { buildApp } from '@/app';
import { PostgreSqlContainer, type StartedPostgreSqlContainer } from '@testcontainers/postgresql';
import dotenv from 'dotenv';
import type { FastifyInstance } from 'fastify';
import { assert, afterAll, beforeAll, describe, expect, test } from 'vitest';
import * as schema from '../src/db/schema';
dotenv.config();

describe('Get OTP test', () => {
  let container: StartedPostgreSqlContainer;
  let app: FastifyInstance;
  const testAddress = '0x004babd76a282efdd30b97c8a98b0f2e4ebb91e81b3542bfd124c086648a07af';
  const testPhoneNumber = process.env.TEST_PHONE_NUMBER as string;
  const testFirstName = 'Jean';
  const testLastName = 'Dupont';
  const nonRegisteredNumber = '+919999999999';

  beforeAll(async () => {
    container = await new PostgreSqlContainer().start();
    const connectionUri = container.getConnectionUri();
    // console.log(connectionUri);
    app = await buildApp({
      database: {
        connectionString: connectionUri,
      },
      app: {
        port: 8080,
      },
    });

    await app.ready();

    // reset db
    await app.db.delete(schema.registration);
    await app.db.delete(schema.otp);

    // Insert balance to mock address
    await app.db.insert(schema.usdcBalance).values({ address: testAddress, balance: '1000' });

    // adding a user
    await app.db.insert(schema.registration).values({
      address: testAddress,
      phone_number: testPhoneNumber,
      first_name: testFirstName,
      last_name: testLastName,
    });
  });

  afterAll(async () => {
    await app.close();
    await container.stop();
  });

  test('should send the otp to valid registered user : /get_otp', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/get_otp',
      body: {
        phone_number: testPhoneNumber,
        first_name: testFirstName,
        last_name: testLastName,
      },
    });

    expect(response.statusCode).toBe(200);
  });

  test('should send the otp and register user : /get_otp', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/get_otp',
      body: {
        phone_number: nonRegisteredNumber,
        first_name: testFirstName,
        last_name: testLastName,
      },
    });

    expect(response.statusCode).toBe(200);
  });

  test('should not send the otp to valid registered user (requesting twice within 15 mins of expiration time) : /get_otp', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/get_otp',
      body: {
        phone_number: testPhoneNumber,
        first_name: testFirstName,
        last_name: testLastName,
      },
    });

    const msg = {
      message: 'You have already requested the OTP',
    };

    expect(response.body).toBe(JSON.stringify(msg));
    expect(response.statusCode).toBe(400);
  });

  test('should fail for invalid phone_number', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/get_otp',
      body: {
        phone_number: '0',
        first_name: testFirstName,
        last_name: testLastName,
      },
    });

    expect(response.statusCode).toBe(400);
    expect(response.json()).toHaveProperty(
      'message',
      'body/phone_number must match pattern "^\\+[1-9]\\d{1,14}$"',
    );
  });

  test('should fail for invalid first_name', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/get_otp',
      body: {
        phone_number: testPhoneNumber,
        first_name: '',
        last_name: testLastName,
      },
    });
    expect(response.statusCode).toBe(400);
    expect(response.json()).toHaveProperty(
      'message',
      'body/first_name must match pattern "^[A-Za-z]{1,20}$"',
    );
  });
  test('should fail for invalid last_name', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/get_otp',
      body: {
        phone_number: testPhoneNumber,
        first_name: testFirstName,
        last_name: '23232',
      },
    });

    expect(response.statusCode).toBe(400);
    expect(response.json()).toHaveProperty(
      'message',
      'body/last_name must match pattern "^[A-Za-z]{1,20}$"',
    );
  });
});
