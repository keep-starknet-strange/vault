import { buildApp } from '@/app';
import { PostgreSqlContainer, type StartedPostgreSqlContainer } from '@testcontainers/postgresql';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, test } from 'vitest';
import * as schema from '../src/db/schema';

describe('Verify OTP test', () => {
  let container: StartedPostgreSqlContainer;
  let app: FastifyInstance;
  const testAddress = '0x004babd76a282efdd30b97c8a98b0f2e4ebb91e81b3542bfd124c086648a07af';
  const testPhoneNumber = '+918591509868';
  const testFirstName = 'Jean';
  const testLastName = 'Dupont';

  beforeAll(async () => {
    container = await new PostgreSqlContainer().start();
    const connectionUri = container.getConnectionUri();
    // console.log(connectionUri);
    app = buildApp({
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

    // adding a mock otp
    await app.db.insert(schema.otp).values({
      phone_number: testPhoneNumber,
      otp: '666665',
      used: true,
    });
  });

  afterAll(async () => {
    await app.close();
    await container.stop();
  });

  test('should throw 500 if otp not requested : /verify_otp', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/verify_otp',
      body: {
        phone_number: testPhoneNumber,
        sent_otp: '666666',
      },
    });

    const msg = {
      message: 'You need to request the otp first | Invalid OTP provided',
    };

    expect(response.body).toBe(JSON.stringify(msg));
    expect(response.statusCode).toBe(500);
  });

  test('should verify the otp sent to the phone number : /verify_otp', async () => {
    // adding the otp to db
    await app.db.insert(schema.otp).values({
      phone_number: testPhoneNumber,
      otp: '666666',
    });

    const response = await app.inject({
      method: 'POST',
      url: '/verify_otp',
      body: {
        phone_number: testPhoneNumber,
        sent_otp: '666666',
      },
    });

    const msg = {
      message: 'OTP verified successfully',
    };

    expect(response.body).toBe(JSON.stringify(msg));
    expect(response.statusCode).toBe(200);
  });

  test('should not be able verify the otp already sent to the phone number : /verify_otp', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/verify_otp',
      body: {
        phone_number: testPhoneNumber,
        sent_otp: '666666',
      },
    });

    const msg = {
      message: 'You need to request the otp first | Invalid OTP provided',
    };

    expect(response.body).toBe(JSON.stringify(msg));
    expect(response.statusCode).toBe(500);
  });
});
