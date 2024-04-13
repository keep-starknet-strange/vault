import {
  PostgreSqlContainer,
  type StartedPostgreSqlContainer,
} from '@testcontainers/postgresql';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, test } from 'vitest';

import { buildApp } from '@/app';
import * as schema from '../db/schema';

describe('GET /get_historical_balance route', () => {
  let container: StartedPostgreSqlContainer;
  let app: FastifyInstance;
  const testAddress =
    '0x064a24243f2aabae8d2148fa878276e6e6e452e3941b417f3c33b1649ea83e11';

  beforeAll(async () => {
    container = await new PostgreSqlContainer().start();
    const connectionUri = 'postgres://postgres:postgres@0.0.0.0:5432/postgres';
    app = buildApp({
      database: {
        connectionString: connectionUri,
      },
      app: {
        port: 8080,
      },
    });

    await app.ready();
    await app.db.insert(schema.usdcBalance).values([
      {
        address: testAddress,
        blockTimestamp: new Date('2024-04-10 13:03:05'),
        balance: '3.8AE83A109D0635A426BB',
      },
      {
        address: testAddress,
        blockTimestamp: new Date('2024-04-10 14:03:05'),
        balance: '3.8AE83A109D0635A426BB',
      },
      {
        address: testAddress,
        blockTimestamp: new Date('2024-04-11 13:03:05'),
        balance: '3.8AE83A109D0635A426BB',
      },
      {
        address: testAddress,
        blockTimestamp: new Date('2024-04-11 14:03:05'),
        balance: '3.8AE83A109D0635A426BB',
      },
    ]);
  });

  afterAll(async () => {
    await app.close();
    await container.stop();
  });

  test('should return the historical balances for a valid address', async () => {
    const response = await app.inject({
      method: 'GET',
      url: `/get_historical_balance?address=${testAddress}`,
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toBe([
      {
        date: '2024-04-10',
        balance: '3.8AE83A109D0635A426BB',
      },
      {
        date: '2024-04-11',
        balance: '3.8AE83A109D0635A426BB',
      },
    ]);
  });

  test('should return error, invalid address format', async () => {
    const invalidAddress = '0x0';
    const response = await app.inject({
      method: 'GET',
      url: `/get_historical_balance?address=${invalidAddress}`,
    });

    expect(response.statusCode).toBe(400);
    expect(response.json()).toHaveProperty('error', 'Invalid address format.');
  });

  test('should return error, no address provided', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/get_historical_balance',
    });

    expect(response.statusCode).toBe(400);
    expect(response.json()).toHaveProperty('error', 'Address is required.');
  });

  test('should return 0, unknown address', async () => {
    const unknownAddress =
      '0x004babd76a282efdd30b97c8a98b0f2e4ebb91e81b3542bfd124c086648a07ae';
    const response = await app.inject({
      method: 'GET',
      url: `/get_historical_balance?address=${unknownAddress}`,
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toHaveProperty('balance', '0');
  });
});
