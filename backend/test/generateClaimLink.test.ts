import { buildApp } from "@/app";
import {
	PostgreSqlContainer,
	type StartedPostgreSqlContainer,
} from "@testcontainers/postgresql";
import type { FastifyInstance } from "fastify";
import { assert, afterAll, beforeAll, describe, expect, test } from "vitest";

describe("POST /generate_claim_link route", () => {
	let container: StartedPostgreSqlContainer;
	let app: FastifyInstance;
	const testAddress =
		"0x004babd76a282efdd30b97c8a98b0f2e4ebb91e81b3542bfd124c086648a07af";
	const testAmount = "111.222333";
	const claimUrlRegex =
		/^https:\/\/vlt\.finance\/claim\?token=([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})$/;

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
		await app.close();
		await container.stop();
	});

	test("should return a claimlink for valid (amount, signature)", async () => {
		const response = await app.inject({
			method: "POST",
			url: "/generate_claim_link",
			body: {
				amount: testAmount,
				nonce: 0,
				address: testAddress,
				signature: [testAddress, testAddress],
			},
		});

		expect(response.statusCode).toBe(200);
		assert(claimUrlRegex.test((await response.json()).claimLink));
	});

	test("should fail nonce already used", async () => {
		const response = await app.inject({
			method: "POST",
			url: "/generate_claim_link",
			body: {
				amount: testAmount,
				nonce: 0,
				address: testAddress,
				signature: [testAddress, testAddress],
			},
		});

		expect(response.statusCode).toBe(400);
		expect(response.json()).toHaveProperty("message", "Nonce already used.");
	});

	test("should fail for negative amount", async () => {
		const response = await app.inject({
			method: "POST",
			url: "/generate_claim_link",
			body: {
				amount: "-123.2",
				address: testAddress,
				nonce: 0,
				signature: [testAddress, testAddress],
			},
		});

		expect(response.statusCode).toBe(400);
		expect(response.json()).toHaveProperty(
			"message",
			'body/amount must match pattern "^[0-9]{1,78}.[0-9]{1,6}$"',
		);
	});

	test("should fail for too many decimals amount", async () => {
		const response = await app.inject({
			method: "POST",
			url: "/generate_claim_link",
			body: {
				amount: "123.4567891",
				address: testAddress,
				nonce: 0,
				signature: [testAddress, testAddress],
			},
		});

		expect(response.statusCode).toBe(400);
		expect(response.json()).toHaveProperty(
			"message",
			'body/amount must match pattern "^[0-9]{1,78}.[0-9]{1,6}$"',
		);
	});

	test("should fail for amount = 0", async () => {
		const response = await app.inject({
			method: "POST",
			url: "/generate_claim_link",
			body: {
				amount: "0.0000",
				address: testAddress,
				nonce: 0,
				signature: [testAddress, testAddress],
			},
		});

		expect(response.statusCode).toBe(400);
		expect(response.json()).toHaveProperty("message", "Amount can't be zero.");
	});

	test("should fail for missing signature", async () => {
		const response = await app.inject({
			method: "POST",
			url: "/generate_claim_link",
			body: {
				amount: testAmount,
				address: testAddress,
				nonce: 0,
				signature: [],
			},
		});

		expect(response.statusCode).toBe(400);
		expect(response.json()).toHaveProperty("message", "Missing signature.");
	});
});
