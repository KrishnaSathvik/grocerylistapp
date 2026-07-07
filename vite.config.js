import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { VitePWA } from "vite-plugin-pwa";

const MARKETING_ROUTES = ["/privacy", "/support"];
const SHARE_ROUTE = /^\/s\/[^/]+\/?$/;

function marketingStaticPages() {
  const rewriteMarketingRoute = (req) => {
    const [pathname, query = ""] = (req.url ?? "").split("?");
    for (const route of MARKETING_ROUTES) {
      if (pathname === route || pathname === `${route}/`) {
        req.url = `${route}/index.html${query ? `?${query}` : ""}`;
        return;
      }
    }

    if (SHARE_ROUTE.test(pathname)) {
      req.url = `/s/index.html${query ? `?${query}` : ""}`;
    }
  };

  const attachMiddleware = (server) => {
    server.middlewares.use((req, res, next) => {
      const [pathname, query = ""] = (req.url ?? "").split("?");

      if (pathname === "/home" || pathname === "/home/") {
        res.statusCode = 301;
        res.setHeader("Location", `/${query ? `?${query}` : ""}`);
        res.end();
        return;
      }

      if (pathname === "/" || pathname === "") {
        req.url = `/home/index.html${query ? `?${query}` : ""}`;
        next();
        return;
      }

      if (pathname === "/app" || pathname === "/app/") {
        req.url = `/index.html${query ? `?${query}` : ""}`;
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
          /^\/$/,
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
