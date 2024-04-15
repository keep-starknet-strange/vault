import { PostgreSqlContainer, type StartedPostgreSqlContainer } from '@testcontainers/postgresql';
import type { FastifyInstance } from 'fastify';
import { assert, afterAll, beforeAll, describe, expect, test } from 'vitest';

import { buildApp } from '@/app';

import * as schema from '../src/db/schema';
describe('GET /get_balance route', () => {
  let container: StartedPostgreSqlContainer;
  let app: FastifyInstance;
  const testAddress = '0x004babd76a282efdd30b97c8a98b0f2e4ebb91e81b3542bfd124c086648a07af';
  const testPhoneNumber = '+33606060606';
  const testFirstName = 'Jean';
  const testLastName = 'Dupont';

  beforeAll(async () => {
    container = await new PostgreSqlContainer().start();
    const connectionUri = container.getConnectionUri();
    app = buildApp({
      database: {
        connectionString: connectionUri,
      },
      app: {
        port: 8080,
      },
    });

    await app.ready();
    // Insert balance to mock address
    await app.db.insert(schema.usdcBalance).values({ address: testAddress, balance: '1000' });
  });

  afterAll(async () => {
    await app.close();
    await container.stop();
  });

  test('should return true for a valid (address, phone_number, first_name, last_name)', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/register',
      body: {
        address: testAddress,
        phone_number: testPhoneNumber,
        first_name: testFirstName,
        last_name: testLastName,
      },
    });

    expect(response.statusCode).toBe(200);
    assert(await response.json());
  });

  test('should fail for invalid address', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/register',
      body: {
        address: '0x0',
        phone_number: testPhoneNumber,
        first_name: testFirstName,
        last_name: testLastName,
      },
    });

    expect(response.statusCode).toBe(400);
    expect(response.json()).toHaveProperty(
      'message',
      'body/address must match pattern "^0x0[0-9a-fA-F]{63}$"',
    );
  });

  test('should fail for invalid phone_number', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/register',
      body: {
        address: testAddress,
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
      url: '/register',
      body: {
        address: testAddress,
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
      url: '/register',
      body: {
        address: testAddress,
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
  test('should fail for already registered user', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/register',
      body: {
        address: testAddress,
        phone_number: testPhoneNumber,
        first_name: testFirstName,
        last_name: testFirstName,
      },
    });

    expect(response.statusCode).toBe(409);
    expect(response.json()).toHaveProperty(
      'message',
      'A user with the given phone number already exists.',
    );
  });
});
