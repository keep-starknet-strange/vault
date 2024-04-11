import tsconfigPaths from 'vite-tsconfig-paths';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  plugins: [tsconfigPaths()],
  test: {
    hookTimeout: 50000,
    coverage: { provider: 'istanbul', reporter: ['text', 'json-summary', 'json'] },
  },
});
