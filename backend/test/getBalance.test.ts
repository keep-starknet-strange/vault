import { PostgreSqlContainer, type StartedPostgreSqlContainer } from '@testcontainers/postgresql';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, test } from 'vitest';

import { buildApp } from '@/app';

import * as schema from '../src/db/schema';
describe('GET /get_balance route', () => {
  let container: StartedPostgreSqlContainer;
  let app: FastifyInstance;
  const testAddress = '0x004babd76a282efdd30b97c8a98b0f2e4ebb91e81b3542bfd124c086648a07af';

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

  test('should return the balance for a valid address', async () => {
    const response = await app.inject({
      method: 'GET',
      url: `/get_balance?address=${testAddress}`,
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toHaveProperty('balance', '1000');
  });

  test('should return error, invalid address format', async () => {
    const invalidAddress = '0x0';
    const response = await app.inject({
      method: 'GET',
      url: `/get_balance?address=${invalidAddress}`,
    });

    expect(response.statusCode).toBe(400);
    expect(response.json()).toHaveProperty('error', 'Invalid address format.');
  });

  test('should return error, no address provided', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/get_balance',
    });

    expect(response.statusCode).toBe(400);
    expect(response.json()).toHaveProperty('error', 'Address is required.');
  });

  test('should return 0, unknown address', async () => {
    const unknownAddress = '0x004babd76a282efdd30b97c8a98b0f2e4ebb91e81b3542bfd124c086648a07ae';
    const response = await app.inject({
      method: 'GET',
      url: `/get_balance?address=${unknownAddress}`,
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toHaveProperty('balance', '0');
  });
});
