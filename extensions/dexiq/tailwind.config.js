/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./public/**/*.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        accent: '#10B981',      // Green - primary CTAs, bullish signals, success states
        danger: '#D73804',      // Orange - brand color, headers, bearish warnings
        darkblue: '#09003D',    // Deep blue - primary background
        midblue: '#00234D',     // Medium blue - secondary background
        secondary: '#1A385F',   // Blue - card backgrounds
        hoverblue: '#24486F',   // Hover states for interactive elements
      },
      fontFamily: {
        inter: ['Inter', 'sans-serif'],
        manrope: ['Manrope', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
