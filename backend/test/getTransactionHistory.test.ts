import { PostgreSqlContainer, type StartedPostgreSqlContainer } from '@testcontainers/postgresql';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, beforeEach, describe, expect, test } from 'vitest';

import { buildApp } from '@/app';

import * as schema from '../src/db/schema';

function generateMockData(
  fromAddress: string,
  upperLimit: number,
  lowerLimit?: number,
  isResponseMock?: boolean,
) {
  const mockData = [];
  const numEntries = upperLimit;
  const startCnt = lowerLimit ? lowerLimit : 1;
  const mockTxnHash = '0x71dc653ae79444baeca2f182154bbd0ebb2bff2d73a4cf4c13774b2c613e17c';
  const mockToAddrs = '0x00057c4b510d66eb1188a7173f31cccee47b9736d40185da8144377b896d5ff3';

  for (let i = startCnt; i <= numEntries; i++) {
    const transferId = `${mockTxnHash}_${i}`;
    const network = 'starknet-mainnet';
    const transactionHash = mockTxnHash;
    const toAddress = mockToAddrs;
    const amount = `0x${i.toString(16)}`;

    const blockTimestamp = null;
    if (isResponseMock) {
      mockData.push({
        network,
        transactionHash,
        fromAddress,
        toAddress,
        amount,
        blockTimestamp,
      });
    } else {
      mockData.push({
        transferId,
        network,
        transactionHash,
        fromAddress,
        toAddress,
        amount,
        blockTimestamp,
      });
    }
  }

  // Silence the type error since it's an helper for testing.
  // The issue is that `transferId` is a required field for inserting data.
  return mockData as (typeof schema.usdcTransfer.$inferInsert)[];
}

describe('GET /transaction history route', () => {
  let container: StartedPostgreSqlContainer;
  let app: FastifyInstance;
  const testAddress = '0x004babd76a282efdd30b97c8a98b0f2e4ebb91e81b3542bfd124c086648a07af';
  const invalidStarknetAddress = '0xdAC17F958D2ee523a2206206994597C13D831ec7';
  const invalidFromAddress = '0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7';
  beforeAll(async () => {
    container = await new PostgreSqlContainer().start();
    const connectionUri = container.getConnectionUri();
    app = await buildApp({
      database: {
        connectionString: connectionUri,
      },
      app: {
        port: 8080,
      },
    });

    await app.ready();
  });

  afterAll(async () => {
    await app.db.delete(schema.usdcTransfer);
    await app.close();
    await container.stop();
  });

  beforeEach(async () => {
    // clear db before custom number of mock entries
    await app.db.delete(schema.usdcTransfer);
  });

  test('should return the 10 txns obj, total 10 entries, pagination 1', async () => {
    await app.db.insert(schema.usdcTransfer).values(generateMockData(testAddress, 10));
    const paginationStr = '1';
    const response = await app.inject({
      method: 'GET',
      url: `/transaction_history?address=${testAddress}&pagination=${paginationStr}`,
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toHaveProperty('page_count', 1);

    const mockResponseObj = generateMockData(testAddress, 10, 1, true);
    expect(response.json().transactions).toMatchObject(mockResponseObj);
    expect(response.json().transactions).toHaveLength(10);
  });

  test('should return the default txns obj limit, total 9 entries, no pagination', async () => {
    await app.db.insert(schema.usdcTransfer).values(generateMockData(testAddress, 9));
    const response = await app.inject({
      method: 'GET',
      url: `/transaction_history?address=${testAddress}`,
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toHaveProperty('page_count', 1);

    const mockResponseObj = generateMockData(testAddress, 9, 1, true);
    expect(response.json().transactions).toMatchObject(mockResponseObj);
    expect(response.json().transactions).toHaveLength(9);
  });

  test('should return the 1 to 10 txns obj, total 33 entries, pagination 1 default', async () => {
    await app.db.insert(schema.usdcTransfer).values(generateMockData(testAddress, 33));
    const paginationStr = '1';
    const response = await app.inject({
      method: 'GET',
      url: `/transaction_history?address=${testAddress}&pagination=${paginationStr}`,
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toHaveProperty('page_count', 4);

    const mockResponseObj = generateMockData(testAddress, 10, 1, true);
    expect(response.json().transactions).toMatchObject(mockResponseObj);
    expect(response.json().transactions).toHaveLength(10);
  });

  test('should return the 11 to 20 txns obj, total 33 entries, pagination 2', async () => {
    await app.db.insert(schema.usdcTransfer).values(generateMockData(testAddress, 33));
    const paginationStr = '2';
    const response = await app.inject({
      method: 'GET',
      url: `/transaction_history?address=${testAddress}&pagination=${paginationStr}`,
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toHaveProperty('page_count', 4);

    const mockResponseObj = generateMockData(testAddress, 20, 11, true);
    expect(response.json().transactions).toMatchObject(mockResponseObj);
    expect(response.json().transactions).toHaveLength(10);
  });

  test('should return the 21 to 30 txns obj, total 33 entries, pagination 3', async () => {
    await app.db.insert(schema.usdcTransfer).values(generateMockData(testAddress, 33));
    const paginationStr = '3';
    const response = await app.inject({
      method: 'GET',
      url: `/transaction_history?address=${testAddress}&pagination=${paginationStr}`,
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toHaveProperty('page_count', 4);

    const mockResponseObj = generateMockData(testAddress, 30, 21, true);
    expect(response.json().transactions).toMatchObject(mockResponseObj);
    expect(response.json().transactions).toHaveLength(10);
  });

  test('should return the 31 to 33 txns obj, total 33 entries, pagination 4', async () => {
    await app.db.insert(schema.usdcTransfer).values(generateMockData(testAddress, 33));
    const paginationStr = '4';
    const response = await app.inject({
      method: 'GET',
      url: `/transaction_history?address=${testAddress}&pagination=${paginationStr}`,
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toHaveProperty('page_count', 4);

    const mockResponseObj = generateMockData(testAddress, 33, 31, true);
    expect(response.json().transactions).toMatchObject(mockResponseObj);
    expect(response.json().transactions).toHaveLength(3);
  });

  test('should return error, invalid starknet address', async () => {
    await app.db.insert(schema.usdcTransfer).values(generateMockData(testAddress, 5));
    const paginationStr = '1';
    const response = await app.inject({
      method: 'GET',
      url: `/transaction_history?address=${invalidStarknetAddress}&pagination=${paginationStr}`,
    });

    expect(response.statusCode).toBe(400);
    expect(response.json()).toHaveProperty('error', 'Invalid address format.');
  });

  test('should return error, no address provided', async () => {
    await app.db.insert(schema.usdcTransfer).values(generateMockData(testAddress, 5));
    const response = await app.inject({
      method: 'GET',
      url: '/transaction_history',
    });

    expect(response.json()).toHaveProperty('error', 'Address is required.');
  });

  test('should return empty transactions arr and zero page cnt, invalid from address', async () => {
    await app.db.insert(schema.usdcTransfer).values(generateMockData(testAddress, 5));
    const paginationStr = '1';
    const response = await app.inject({
      method: 'GET',
      url: `/transaction_history?address=${invalidFromAddress}&pagination=${paginationStr}`,
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toHaveProperty('page_count', 0);
    expect(response.json()).toHaveProperty('transactions', []);
  });

  test('should return empty transactions arr and zero page cnt, valid from address, no db entries', async () => {
    const paginationStr = '1';
    const response = await app.inject({
      method: 'GET',
      url: `/transaction_history?address=${invalidFromAddress}&pagination=${paginationStr}`,
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toHaveProperty('page_count', 0);
    expect(response.json()).toHaveProperty('transactions', []);
  });
});
