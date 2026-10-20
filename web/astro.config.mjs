// @ts-check
import { defineConfig } from "astro/config";
import preact from "@astrojs/preact";

// GitHub Pages serves the site under /<repo>/; the workflow sets BASE_PATH.
export default defineConfig({
  site: process.env.SITE_URL || "https://hhandika.github.io",
  base: process.env.BASE_PATH || "/",
  integrations: [preact()],
  // Keep spaces between prose and inline components (Astro 7 JSX whitespace).
  compressHTML: true,
});
