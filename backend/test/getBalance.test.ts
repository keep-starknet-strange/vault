import { GenericContainer, StartedTestContainer } from 'testcontainers';
import { Pool } from 'pg';
import Fastify, { FastifyInstance } from 'fastify';
import { declareRoutes } from '../src/routes'; // Adjust the import path
import { buildAndStartApp } from '../src/index';
import { fastifyDrizzle } from '../src/db/plugin';
import {beforeAll, afterAll, describe, expect, test} from 'bun:test';

describe('GET /get_balance route', () => {
  let container: StartedTestContainer;
  let pool: Pool;
  let app: FastifyInstance;

  beforeAll(async () => {
    // Start PostgreSQL container
    container = await new GenericContainer('postgres')
      .withEnvironment({
        POSTGRES_DB: 'testdb',
        POSTGRES_USER: 'user',
        POSTGRES_PASSWORD: 'password',
      })
      .withExposedPorts(5432)
      .start();

    const mappedPort = container.getMappedPort(5432);
    const host = container.getHost();

    // Connect to the database
    pool = new Pool({
      user: 'user',
      host,
      database: 'testdb',
      password: 'password',
      port: mappedPort,
    });

    buildAndStartApp();
    // Run migrations - implement this according to your project's setup

    // Insert test data
    const testAddress = '0x0abcdef0123456789abcdef0123456789abcdef0';
    await pool.query(
      'INSERT INTO balance_usdc (address, balance) VALUES ($1, $2)',
      [testAddress, '1000'],
    );

    // Set up Fastify instance
    app = Fastify();
    fastifyDrizzle(app, { connectionString: 'abc' }, () => {});
    declareRoutes(app); // Assuming this function registers your routes
    await app.ready();
  });

  afterAll(async () => {
    await pool.end(); // Close pool connection
    await container.stop(); // Stop the container
    await app.close(); // Close Fastify server
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
