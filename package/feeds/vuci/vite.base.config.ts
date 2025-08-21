import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  root: './vuci-ui-core/src',
  envDir: '../../',
  build: {
    cssCodeSplit: false,
    emptyOutDir: true,
    rollupOptions: {
      output: {
        manualChunks: manualChunks
      }
    }
  },
  plugins: [vue(), tailwindcss()],
  resolve: {
    extensions: ['.cjs', '.js', '.ts', '.jsx', '.tsx', '.json', '.vue'],
    alias: {
      '@': fileURLToPath(new URL('./vuci-ui-core/src/src', import.meta.url)),
      '@ui-core': fileURLToPath(new URL('./vuci-ui-core/src/ui-core', import.meta.url)),
      '@root': fileURLToPath(new URL('.', import.meta.url)),
      '@conditional': fileURLToPath(new URL('./vuci-ui-core/src/src/components/package_components/components', import.meta.url))
    }
  }
})

function manualChunks(id: string) {
  if (id.includes('node_modules')) return 'vendor'
  const match = /.*vuci-app-([a-zA-Z0-9-]+)-ui/.exec(id)
  if (match) return `app.${match[1]}.app`
  return 'app'
}
