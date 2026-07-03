import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { VitePWA } from "vite-plugin-pwa";

const MARKETING_ROUTES = ["/home", "/privacy", "/support"];

function marketingStaticPages() {
  const rewriteMarketingRoute = (req) => {
    const [pathname, query = ""] = (req.url ?? "").split("?");
    for (const route of MARKETING_ROUTES) {
      if (pathname === route || pathname === `${route}/`) {
        req.url = `${route}/index.html${query ? `?${query}` : ""}`;
        return;
      }
    }
  };

  const attachMiddleware = (server) => {
    server.middlewares.use((req, _res, next) => {
      const [pathname] = (req.url ?? "").split("?");
      if (pathname === "/app" || pathname === "/app/") {
        req.url = `/index.html${req.url?.includes("?") ? req.url.slice(req.url.indexOf("?")) : ""}`;
      }
      rewriteMarketingRoute(req);
      next();
    });
  };

  return {
    name: "marketing-static-pages",
    configureServer: attachMiddleware,
    configurePreviewServer: attachMiddleware,
  };
}

export default defineConfig({
  plugins: [
    react(),
    marketingStaticPages(),
    VitePWA({
      registerType: "autoUpdate",
      includeAssets: [
        "favicon.ico",
        "favicon.svg",
        "apple-touch-icon.png",
        "android-chrome-192x192.png",
        "android-chrome-512x512.png",
      ],
      manifest: {
        name: "Groceries — Smart Lists",
        short_name: "Groceries",
        description:
          "Smart grocery lists with natural input, store and category views, sharing, and dark mode.",
        theme_color: "#faf8f4",
        background_color: "#faf8f4",
        display: "standalone",
        orientation: "portrait",
        scope: "/app/",
        start_url: "/app",
        categories: ["productivity", "food", "utilities"],
        icons: [
          {
            src: "/android-chrome-192x192.png",
            sizes: "192x192",
            type: "image/png",
          },
          {
            src: "/android-chrome-512x512.png",
            sizes: "512x512",
            type: "image/png",
          },
          {
            src: "/android-chrome-512x512.png",
            sizes: "512x512",
            type: "image/png",
            purpose: "maskable",
          },
        ],
      },
      workbox: {
        globPatterns: ["**/*.{js,css,html,woff2}"],
        navigateFallbackDenylist: [
          /^\/(favicon|icon|apple-touch-icon|og-image)/,
          /^\/home(\/|$)/,
          /^\/privacy(\/|$)/,
          /^\/support(\/|$)/,
        ],
        runtimeCaching: [
          {
            urlPattern: /^https:\/\/fonts\.googleapis\.com\/.*/i,
            handler: "CacheFirst",
            options: {
              cacheName: "google-fonts-cache",
              expiration: { maxEntries: 10, maxAgeSeconds: 60 * 60 * 24 * 365 },
              cacheableResponse: { statuses: [0, 200] },
            },
          },
          {
            urlPattern: /^https:\/\/fonts\.gstatic\.com\/.*/i,
            handler: "CacheFirst",
            options: {
              cacheName: "gstatic-fonts-cache",
              expiration: { maxEntries: 10, maxAgeSeconds: 60 * 60 * 24 * 365 },
              cacheableResponse: { statuses: [0, 200] },
            },
          },
        ],
      },
    }),
  ],
});
