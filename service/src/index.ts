const PORT = Bun.env.PORT || 8080;

Bun.serve({
  port: PORT,
  async fetch(request: Request) {
    const { method } = request;
    const { pathname } = new URL(request.url);

    if (method === "GET" && pathname === "/status") {
      return handleGetStatus();
    }
    return new Response("Not Found", { status: 404 });
  },
});

console.log(`Listening on http://localhost:${PORT} ...`);

function handleGetStatus() {
  return new Response(JSON.stringify({ status: "OK" }), {
    headers: { "Content-Type": "application/json" },
  });
}
