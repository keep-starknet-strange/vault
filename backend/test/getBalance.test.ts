import { beforeAll, afterAll, describe, expect, test } from 'vitest';
import {
  PostgreSqlContainer,
  StartedPostgreSqlContainer,
} from '@testcontainers/postgresql';
import { FastifyInstance } from 'fastify';

import { buildApp } from '@/app';

describe('GET /get_balance route', () => {
  let container: StartedPostgreSqlContainer;
  let app: FastifyInstance;

  beforeAll(async () => {
    container = await new PostgreSqlContainer().start();

    app = buildApp({
      database: {
        connectionString: container.getConnectionUri(),
      },
      app: {
        port: 8080,
      },
    });

    await app.ready();
  });

  afterAll(async () => {
    await app.close();
    await container.stop();
  });

  test('should return the balance for a valid address', async () => {
    const testAddress = '0x0abcdef0123456789abcdef0123456789abcdef0';
    const response = await app.inject({
      method: 'GET',
      url: `/get_balance?address=${testAddress}`,
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toHaveProperty('balance', '1000');
  });
});
