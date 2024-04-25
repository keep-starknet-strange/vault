import { PostgreSqlContainer, type StartedPostgreSqlContainer } from '@testcontainers/postgresql';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, test } from 'vitest';

import { buildApp } from '@/app';

import * as schema from '../src/db/schema';
describe('GET /claim route', () => {
  let container: StartedPostgreSqlContainer;
  let app: FastifyInstance;
  const testAddress = '0x004babd76a282efdd30b97c8a98b0f2e4ebb91e81b3542bfd124c086648a07af';
  const uuid = 'b444aebf-67c0-4ba9-9866-8cd44deb8b41';
  const amount = '123.456789';
  const nonce = 0;
  const signature = [testAddress, testAddress];

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
    await app.db.insert(schema.claims).values({ id: uuid, amount, nonce, signature });
  });

  afterAll(async () => {
    await app.close();
    await container.stop();
  });

  test('should return the call for a valid uuid', async () => {
    const response = await app.inject({
      method: 'GET',
      url: `/claim?id=${uuid}`,
    });
    expect(response.statusCode).toBe(200);
    expect(response.json()).toHaveProperty('call', { id: uuid, amount, nonce, signature });
  });
  test('should return an error for invalid uuid', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/claim?id=1',
    });
    expect(response.statusCode).toBe(400);
    expect(response.json()).toHaveProperty('message', 'Invalid uuid.');
  });

  test('should return an error for unknown uuid', async () => {
    const unknown_uuid = 'a444aebf-67c0-4ba9-9866-8cd44deb8b41';
    const response = await app.inject({
      method: 'GET',
      url: `/claim?id=${unknown_uuid}`,
    });
    expect(response.statusCode).toBe(400);
    expect(response.json()).toHaveProperty('message', 'Unknown uuid.');
  });
});
