import path from "path";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  server: {
    port: parseInt(process.env.VITE_PORT || "3002", 10),
    proxy: {
      "/auth": {
        target: process.env.VITE_API_URL || "http://localhost:8002",
        changeOrigin: true,
      },
      "/items": {
        target: process.env.VITE_API_URL || "http://localhost:8002",
        changeOrigin: true,
      },
      "/health": {
        target: process.env.VITE_API_URL || "http://localhost:8002",
        changeOrigin: true,
      },
    },
  },
});
