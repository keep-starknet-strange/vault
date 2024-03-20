import Fastify from "fastify";
import { declareRoutes } from "./routes";

// Handle configuration
const PORT: number = parseInt(Bun.env.PORT || "8080");

// Create the Fastify instance
const fastify = Fastify({
  logger: true,
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
