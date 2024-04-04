import Fastify from "fastify";
import { declareRoutes } from "./routes";
import { fastifyDrizzle } from "./db/plugin";

// Handle configuration
const PORT: number = parseInt(Bun.env.PORT || "8080");

// Create the Fastify instance
const fastify = Fastify({
  logger: true,
});

fastify.register(fastifyDrizzle, {
  connectionString: process.env.DATABASE_URL ?? "postgres://postgres:postgres@127.0.0.1:5432/postgres",
});

// Declare routes
declareRoutes(fastify);

// Run the server
try {
  await fastify.listen({ port: PORT });
} catch (err) {
  fastify.log.error(err);
  process.exit(1);
}
