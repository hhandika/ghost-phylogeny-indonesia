// @ts-check
import { defineConfig } from "astro/config";
import preact from "@astrojs/preact";

// Cloudflare Pages serves the site at the root of the production domain.
export default defineConfig({
  site: process.env.SITE_URL || "https://ghost-phylogeny.com",
  base: process.env.BASE_PATH || "/",
  integrations: [preact()],
  // Keep spaces between prose and inline components (Astro 7 JSX whitespace).
  compressHTML: true,
});
