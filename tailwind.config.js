export default {
  content: [
  './index.html',
  './src/**/*.{js,ts,jsx,tsx}'
],
  theme: {
    extend: {
      animation: {
        'spin-slow': 'spin 15s linear infinite',
      }
    }
  },
  plugins: [],
}