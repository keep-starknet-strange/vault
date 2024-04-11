import { beforeAll, afterAll, describe, expect, test } from 'vitest';
import {
  PostgreSqlContainer,
  StartedPostgreSqlContainer,
} from '@testcontainers/postgresql';
import { FastifyInstance } from 'fastify';

import { buildApp } from '@/app';

describe('GET /status route', () => {
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

  test('should return success', async () => {
    const response = await app.inject({
      method: 'GET',
      url: `/status`,
    });

    expect(response.statusCode).toBe(200);
  });
});
