import configPaths from "@janustack/vite-config-paths";
import { tanstackRouter } from "@tanstack/router-plugin/vite";
import tailwindCSS from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

// https://vite.dev/config/
export default defineConfig({
	plugins: [
		tanstackRouter({ target: "react", autoCodeSplitting: true }),
		react(),
		tailwindCSS(),
		configPaths()
	],
	server: {
		port: 9705,
	},
});
